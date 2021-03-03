module dma_ctrl(
	output logic [15:0] AddrB,
	output logic        drive_AB,
	output logic        end_of_zone,
	input  logic [7:0]  DataB,
	// from memory map
	input logic [15:0]  ZP,

	output logic        palette_w, input_w, pixels_w,
	output logic        wm_w,

	input  logic        zp_dma_start, dp_dma_start, dp_dma_kill,
	output logic        zp_dma_done, dp_dma_done, dp_dma_done_dli,

	input logic         character_width,
	input logic [7:0]   char_base,

	input logic         sysclk, reset, last_line
);
	logic [15:0]        DP;
	logic [15:0]        DP_saved;
	logic [15:0]        PP; 
	logic [15:0]        ZP_saved, ZP_saved_next;
	logic [15:0]         CHAR_PTR;
	logic [2:0]         char_ptr_cycles;
	logic               char_bytes_fetched;
	logic [4:0]         WIDTH;
	logic [3:0]         OFFSET;

	logic               INDIRECT_MODE;

	// control regs
	logic               DLIen, DLIen_prev, A12en, A11en;

	// states
	enum logic [1:0] {waiting = 2'b00, zp_dma = 2'b01, dp_dma = 2'b10} state;
	enum logic [2:0] {drive_zp_addr = 3'b000, w_offset = 3'b001, w_DPH = 3'b010 ,w_DPL = 3'b100} zp_state;
	enum logic [4:0] {
		drive_dp_addr = 5'h00,
		w_PPL = 5'h01,
		w_PALETTE_WIDTH = 5'h02,
		w_PPH = 5'h03,
		w_PALETTE_WIDTH_2 = 5'h04,
		w_INPUT = 5'h05,
		drive_pp_addr = 5'h06,
		w_WAIT = 5'h07,
		w_PIXELS_slow = 5'h08,
		drive_char_addr = 5'h09,
		w_CHAR_PTR = 5'ha,
		w_CHAR_PIXELS = 5'hb,
		drive_next_zp_addr = 5'hc,
		w_next_offset = 5'hd,
		w_next_DPL = 5'he,
		w_next_DPH = 5'hf
	} dp_state;

	logic five_byte_mode, null_width, null_data, zero_offset;
	
	logic PP_in_cart;
	assign PP_in_cart = |(PP_plus_offset[15:14]);
	
	logic [7:0] CB_plus_offset;
	assign CB_plus_offset = char_base + {4'b0, OFFSET};

	logic [15:0] CB_addr;
	assign CB_addr = {CB_plus_offset, DataB};
	
	logic CB_in_cart;
	assign CB_in_cart = |(CB_plus_offset[7:6]);

	assign null_width = (DataB[4:0] == 5'b0);
	assign null_data = (DataB == 8'b0);
	assign zero_offset = (OFFSET == 4'b0);

	assign drive_AB = (state != waiting);

	assign ZP_saved_next = ZP_saved + 1'd1;
	
	logic [15:0] PP_plus_offset;
	assign PP_plus_offset = PP + {4'b0, OFFSET, 8'b0};

	always_ff @(negedge sysclk) begin
		AddrB <= 'h1234;
		wm_w <= 0;
		palette_w <= 0;
		input_w <= 0;
		pixels_w <= 0;
		case (state)
			zp_dma: begin
				AddrB <= ZP_saved;
			end
			dp_dma: begin
				AddrB <= 16'hx;
				case (dp_state)
					drive_dp_addr: begin
						AddrB <= DP_saved;
					end

					w_PPL: begin
						AddrB <= DP_saved;
					end

					w_PALETTE_WIDTH: begin
						AddrB <= DP_saved;
						if (~null_data) begin
							wm_w <= null_width;
							palette_w <= ~null_width;
						end
					end

					w_PPH: begin
						AddrB <= DP_saved;
					end

					w_PALETTE_WIDTH_2: begin
						AddrB <= DP_saved;
						palette_w <= 1;
					end

					w_INPUT: begin
						AddrB <= DP_saved;
						input_w <= 1;
					end

					drive_pp_addr: begin
						AddrB <= PP_plus_offset;
					end

					w_WAIT: begin
						AddrB <= DP_saved;
					end

					w_PIXELS_slow: begin
						if (char_ptr_cycles == 3'd2) begin
							pixels_w <= 1'd1;
							AddrB <= PP + 1'd1;
						end else begin
							AddrB <= PP;
						end
					end

					drive_char_addr: begin
						AddrB <= PP;
					end

					w_CHAR_PTR: begin
						AddrB <= {CB_plus_offset, DataB};
					end

					w_CHAR_PIXELS: begin
						if (char_ptr_cycles == (character_width ? 3'd6 : 3'd4)) begin
							pixels_w <= 1;
							if (~char_bytes_fetched & character_width) begin
								AddrB <= CHAR_PTR + 1'd1;
							end else begin
								AddrB <= PP;
							end
						end else begin
							AddrB <= CHAR_PTR;
						end
					end

					drive_next_zp_addr: begin
							AddrB <= ZP_saved;
						end
						w_next_offset: begin
							AddrB <= ZP_saved;
						end
						w_next_DPL: begin
							AddrB <= ZP_saved;
						end
						w_next_DPH: begin
							AddrB <= ZP_saved;
					end
				endcase
			end
		endcase
	end

	logic kill_dma;
	always_ff @(posedge sysclk, posedge reset) begin
		if (reset) begin
			state <= waiting;
			zp_state <= drive_zp_addr;
			dp_state <= drive_dp_addr;
			zp_dma_done <= 0;
			dp_dma_done <= 0;
			dp_dma_done_dli <= 0;
			five_byte_mode <= 0;
			INDIRECT_MODE <= 0;
		end else begin
			case (state)
			waiting: begin
				kill_dma <= 0;
				if (zp_dma_start) begin
					state <= zp_dma;
					ZP_saved <= ZP;
				end else if (dp_dma_start) begin
					state <= dp_dma;
					DP_saved <= DP;
				end
				zp_dma_done <= 0;
				dp_dma_done <= 0;
				dp_dma_done_dli <= 0;
			end
			////////////////////////////////////////////////////////////
			zp_dma: begin
				case (zp_state)
					drive_zp_addr: begin // Read zp
						zp_state <= w_offset;
						ZP_saved <= ZP_saved_next;
					end
					w_offset: begin //write cbits and offset
						zp_state <= w_DPH;
						{DLIen,A12en,A11en} <= DataB[7:5];
						OFFSET <= DataB[3:0];
						ZP_saved <= ZP_saved_next;
					end
					w_DPH: begin //Write DPH
						zp_state <= w_DPL;
						DP[15:8] <= DataB;
						ZP_saved <= ZP_saved_next;
					end
					w_DPL: begin //Write DPL
						zp_state <= drive_zp_addr;
						state <= waiting;
						DP[7:0] <= DataB;
						DP_saved <= {DP[15:8], DataB};
						zp_dma_done <= 1'b1;
						dp_dma_done_dli <= DLIen;
					end
				endcase // case (zp_state)
			end // case: zp_dma

			//////////////////////////////////////////////////////////////
			dp_dma: begin
				if (dp_dma_kill) begin
					dp_state <= drive_dp_addr;
					kill_dma <= 1;
				end else case (dp_state)
					drive_dp_addr: begin //read from dp Byte 0 read
						dp_state <= w_PPL;
						DP_saved <= DP_saved + 1'd1;
						five_byte_mode <= 0;
						INDIRECT_MODE <= 0;
					end
					w_PPL: begin //Write PPL // Byte 1 read
						dp_state <= w_PALETTE_WIDTH;
						PP[7:0] <= DataB;
						DP_saved <= DP_saved + 1'd1;
					end
					w_PALETTE_WIDTH: // Byte 2 read
						// Write palette/width or determine 5b
						// mode or find end of DP list
						if (null_data || kill_dma) begin //Found end of DP list
							kill_dma <= 0;
							if (last_line) begin // Found end of frame
								dp_state <= drive_dp_addr;
								state <= waiting;
								dp_dma_done <= 1;
								end_of_zone <= 1;
								dp_dma_done_dli <= 1'b0;
							end else if (zero_offset) begin // Found end of zone, but not end of frame
								dp_state <= drive_next_zp_addr;
								end_of_zone <= 1;
								state <= dp_dma;
							end else begin // Not at end of zone or frame. Get ready for next line in zone.
								state <= waiting;
								end_of_zone <= 0;
								dp_state <= drive_dp_addr;
								OFFSET <= OFFSET - 1'd1;
								dp_dma_done <= 1'd1;
							end
						end else begin
							// Write palette and width or determine its 5b mode
							dp_state <= w_PPH;
							char_ptr_cycles <= 0;
							five_byte_mode <= null_width;
							INDIRECT_MODE <= null_width & DataB[5];
							WIDTH <= DataB[4:0];
							DP_saved <= DP_saved + 1'd1;
						end
					w_PPH: begin //Write PPH // Byte 3 read
							dp_state <= (five_byte_mode) ? w_PALETTE_WIDTH_2 : w_INPUT;
							PP[15:8] <= DataB;
							DP_saved <= DP_saved + 1'd1;

					end
					w_PALETTE_WIDTH_2: begin //Write palette and width for realzies // Five byte mode byte 4.
						dp_state <= w_INPUT;
						WIDTH <= DataB[4:0];
						DP_saved <= DP_saved + 1'd1;
					end
					w_WAIT: begin //Write Pixel data
						if (char_ptr_cycles == (five_byte_mode ? 3'd1 : 3'd0)) begin // Random whatever to get timing working
							if (INDIRECT_MODE) begin
								if (CB_addr[15] && (A12en & CB_addr[12]) | (A11en & CB_addr[11]))
									dp_state <= drive_dp_addr;
								else
									dp_state <= drive_char_addr;
							end else begin
								if (PP_plus_offset[15] && (A12en & PP_plus_offset[12]) | (A11en & PP_plus_offset[11]))
									dp_state <= drive_dp_addr;
								else
									dp_state <= drive_pp_addr;
							end
						end else begin
							char_ptr_cycles <= char_ptr_cycles + 1'd1;
						end
					end
					// Really, each byte of the header should consume two maria clocks each. In this design,
					// they only consume 1 cycle each. Consequently, we burn off the extra cycles to make
					// timing correct. The input block consumes an unaccounted for cycle itself, so it
					// counts as part of the padding.
					w_INPUT: begin // Startup cycle - not a byte?
						dp_state <= w_WAIT;
						char_ptr_cycles <= 0;
					end
					drive_pp_addr: begin //read from pp
						dp_state <= w_PIXELS_slow;
						char_ptr_cycles <= 3'd0;

						WIDTH <= WIDTH + 1'd1;
						PP <= PP_plus_offset;
					end

					w_PIXELS_slow: begin
						if (char_ptr_cycles == 3'd2) begin
							// Data is ready on the data bus
							WIDTH <= WIDTH + 1'd1;
							PP <= PP + 1'd1;
							dp_state <= (WIDTH == 5'b0) ? drive_dp_addr: w_PIXELS_slow;
							char_ptr_cycles <= 0;
						end else begin
							char_ptr_cycles <= char_ptr_cycles + 1'b1;
						end
					end
					drive_char_addr: begin // read character pointer from pp
						dp_state <= w_CHAR_PTR;
						WIDTH <= WIDTH + 1'b1;
						PP <= PP + 1'd1;
					end
					w_CHAR_PTR: begin
						dp_state <= w_CHAR_PIXELS;
						CHAR_PTR <= {CB_plus_offset, DataB};
						char_bytes_fetched <= 1'b0;
						char_ptr_cycles <= 0;
					end

					w_CHAR_PIXELS: begin
						if (char_ptr_cycles == (character_width ? 3'd6 : 3'd4)) begin
							if (~char_bytes_fetched & character_width) begin
								dp_state <= w_CHAR_PIXELS;
								char_bytes_fetched <= 1'b1;
								CHAR_PTR <= CHAR_PTR + 1'b1;
							end else begin
								if (WIDTH == 5'b0) begin
									dp_state <= drive_dp_addr;
								end else begin
									dp_state <= w_CHAR_PTR;
									WIDTH <= WIDTH + 1'b1;
									PP <= PP + 1'd1;
								end
							end
						end else begin
							char_ptr_cycles <= char_ptr_cycles + 1'b1;
						end
					end

					/////////////////////////////////////////////////
					//Loading next zp when OFFSET has been decremented to 0
					drive_next_zp_addr: begin //Read zp
						dp_state <= w_next_offset;
						ZP_saved <= ZP_saved_next;
					end
					w_next_offset: begin //write cbits and offset
						dp_state <= w_next_DPH;
						{DLIen,A12en,A11en} <= DataB[7:5];
						OFFSET <= DataB[3:0];
						ZP_saved <= ZP_saved_next;
					end
					w_next_DPH: begin //Write DPH
						dp_state <= w_next_DPL;
						DP[15:8] <= DataB;
						ZP_saved <= ZP_saved_next;
					end
					w_next_DPL: begin //Write DPH
						dp_state <= drive_dp_addr;
						state <= waiting;
						DP[7:0] <= DataB;
						DP_saved <= {DP[15:8], DataB};
						dp_dma_done <= 1;
						dp_dma_done_dli <= DLIen;
					end
				endcase // case (dp_state)
			end // case: dp_dma
			endcase
		end
	end // always_ff @
endmodule // dma_ctrl
