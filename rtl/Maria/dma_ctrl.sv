// (C) Jamie Dickson, 2020
// For MiSTer use only

module dma_ctrl(
	input logic         clk_sys, 
	input logic         reset,
	input  logic        mclk0,
	input  logic        mclk1,
	input  logic        PCLKEDGE,
	input  logic        vblank,
	input  logic        vbe,
	input  logic        hbs,
	input  logic        lrc,
	input  logic        dma_en,
	input  logic        pclk1,
	output logic [15:0] AddrB,
	output logic        drive_AB,
	output logic        latch_byte,
	input  logic [7:0]  DataB,
	output logic        clear_hpos,
	output logic        HALT,
	output logic [7:0]  HPOS,
	output logic        DLI,
	output logic        WM,
	output logic [2:0]  PAL,
	input logic [15:0]  ZP,
	input logic         character_width,
	input logic [7:0]   char_base
);

typedef enum logic [4:0] {
	DMA_HEADER_0,
	DMA_HEADER_1,
	DMA_HEADER_2,
	DMA_HEADER_3,
	DMA_HEADER_4,
	DMA_DIRECT,
	DMA_INDIRECT_PTR,
	DMA_INDIRECT_BYTE,
	DMA_END,
	DMA_ZONE_END_0,
	DMA_ZONE_END_1,
	DMA_ZONE_END_2,
	DMA_ZP,
	DMA_WAIT_ZP,
	DMA_WAIT_DP,
	DMA_START_ZP,
	DMA_START_DP,
	DMA_HOLEY_COOLDOWN
} DMA_STATE;



// 4 Byte Header format:
// byte 0: Address Low
// byte 1: PPPWWWWW where P is palette data and W is width of request. If byte is 0, DMA ends for the line. If Width is 0, it's 5 byte.
// byte 2: Address High
// byte 3: Horizontal Position

// 5 Byte Header Format:
// byte 0: Address Low
// byte 1: Mode - 1'bWM, 1'bINDIRECT, 6'b000000
// byte 2: High Address
// byte 3: PPPWWWWW where P is palette data and W is width of request. If Width (or the byte) is 0, DMA ends for the line. In this mode width of zero is 32.
// byte 4: Horizontal Position

// DLL Format
// byte 0: 1'bDLI, 1'bHoley16, 1'bHoley8, 1'b0, 4'bOFFSET (added to Address High to make address)
// byte 1: High DL address
// byte 2: Low DL address

// Header and DLL byte reads are from RAM, and take 2 cycles each
// Graphics bytes are assumed to be in ROM, and take 3 cycles each

logic LONGHDR;

logic [4:0] substate;
logic [3:0] OFFSET; // Added an extra bit so we can use 0 as done rather than -1;

DMA_STATE state;

logic [15:0] DP;

logic [7:0] addr_low, addr_high;

logic IND;

logic [4:0] WIDTH;
logic [7:0] AHPO;
logic [15:0] DL_PTR;
logic [15:0] PIX_PTR;
logic [15:0] CHR_PTR;
logic [15:0] ZONE_PTR;
logic A11en;
logic A12en;
logic wrote_one;
logic hbs_latch;
logic vbe_latch;
logic width_ovr;
logic shutting_down;

always_ff @(posedge clk_sys) if (reset) begin
	state <= DMA_WAIT_ZP;
	substate <= 0;
	hbs_latch <= 0;
	vbe_latch <= 0;
	width_ovr <= 0;
	shutting_down <= 1;
	latch_byte <= 0;
	drive_AB <= 0;
	wrote_one <= 0;
	OFFSET <= 0;
	WM <= 0;
	A12en <= 0;
	A11en <= 0;
	HALT <= 0;
	DLI <= 0;
	PAL <= 0;
	clear_hpos <= 0;
end else if (mclk0) begin
	if (hbs)
		hbs_latch <= 1;
	if (vbe)
		vbe_latch <= 1;
	case (state)
		// Wait for starting condition
		DMA_WAIT_ZP: begin
			if (pclk1) begin
				hbs_latch <= 0;
				//if ((hbs || hbs_latch)) begin
					vbe_latch <= 0;
					if ((vbe || vbe_latch) && dma_en) begin
						substate <= 0;
						ZONE_PTR <= ZP;
						AddrB <= ZP;
						shutting_down <= 1;
						state <= DMA_START_ZP;
						drive_AB <= 1;
						HALT <= 1;
						DLI <= 0;
					end
				//end
			end
		end

		DMA_WAIT_DP: begin
			// Technically this is prevented by having no edges on the combined "blank" signal, but
			// this is tidier for FPGA
			if (vblank)
				state <= DMA_WAIT_ZP;
			if (pclk1) begin
				vbe_latch <= 0;
				hbs_latch <= 0;
				if ((hbs || hbs_latch) && dma_en) begin
					drive_AB <= 1;
					substate <= 0;
					AddrB <= DP;
					shutting_down <= 0;
					DL_PTR <= DP;
					state <= DMA_START_DP;
					HALT <= 1;
					DLI <= 0;
				end
			end
		end

		DMA_START_ZP:begin
			substate <= substate + 1'd1;
			case (substate)
				11: begin // Just burn cycles.
					substate <= 0;
					state <= DMA_ZONE_END_0;
				end
			endcase
		end

		DMA_START_DP:begin
			substate <= substate + 1'd1;
			case (substate)
				11: begin // Just burn cycles.
					substate <= 0;
					state <= DMA_HEADER_0;
				end
			endcase
		end

		DMA_HOLEY_COOLDOWN:begin
			substate <= substate + 1'd1;
			case (substate)
				3:begin
					substate <= 0;
					state <= DMA_HEADER_0;
				end
			endcase
		end


		// Fetch Address Low byte
		DMA_HEADER_0: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= DL_PTR;
				1: begin
					IND <= 0;
					width_ovr <= 0;
					PIX_PTR[7:0] <= DataB;
					DL_PTR <= DL_PTR + 1'd1;
					state <= DMA_HEADER_1;
					substate <= 0;
				end
			endcase
		end

		// Fetch byte 1 which varies;
		DMA_HEADER_1: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= DL_PTR;
				1: begin
					DL_PTR <= DL_PTR + 1'd1;
					substate <= 0;
					if (~|DataB) begin// End of line
						state <= OFFSET ? DMA_END : DMA_ZONE_END_0;
						shutting_down <= 1;
					end else if (~|DataB[4:0]) begin/// Long header
						LONGHDR <= 1;
						WM <= DataB[7];
						IND <= DataB[5];
						state <= DMA_HEADER_2;
					end else begin // four byte header
						LONGHDR <= 0;
						{PAL, WIDTH} <= DataB;
						state <= DMA_HEADER_2;
					end
				end
			endcase
		end

		// Fetch High Address
		DMA_HEADER_2: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= DL_PTR;
				1: begin
					PIX_PTR[15:8] <= IND ? DataB : DataB + OFFSET;
					if (IND)
						AHPO <= char_base + OFFSET;
					else
						AHPO <= DataB + OFFSET;
					DL_PTR <= DL_PTR + 1'd1;
					state <= LONGHDR ? DMA_HEADER_3 : DMA_HEADER_4;
					substate <= 0;
				end
			endcase
		end

		// Fetch 5-byte width and palette
		DMA_HEADER_3: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= DL_PTR;
				1: begin
					DL_PTR <= DL_PTR + 1'd1;
					{PAL, WIDTH} <= DataB;
					state <= DMA_HEADER_4;
					substate <= 0;
				end
			endcase
		end

		// Fetch line ram address (horizontal position)
		DMA_HEADER_4: begin
			substate <= substate + 1'd1;
			case (substate)
				0: begin AddrB <= DL_PTR; clear_hpos <= 1; end
				1: begin
					clear_hpos <= 0;
					DL_PTR <= DL_PTR + 1'd1;
					HPOS <= DataB;
					if (~IND)
						WIDTH <= WIDTH + 1'd1;
					state <= IND ? DMA_INDIRECT_PTR : DMA_DIRECT;
					// Check for holey DMA
					if (((AHPO[3] & A11en) | (AHPO[4] & A12en)) & AHPO[7]) begin
						state <= DMA_HOLEY_COOLDOWN;
					end
					substate <= 0;
				end
			endcase
		end

		// Fetch the low address for indirect read
		DMA_INDIRECT_PTR: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= PIX_PTR;
				1: PIX_PTR <= PIX_PTR + 1'd1;
				2: begin
					wrote_one <= 0;
					CHR_PTR <= {AHPO, DataB};
					// 0 width means value 32, so we have to catch overflow
					{width_ovr, WIDTH} <= {1'b0, WIDTH} + 1'd1; 
					state <= DMA_INDIRECT_BYTE;
					substate <= 0;
				end
			endcase
		end

		// Fetch one or two char bytes
		DMA_INDIRECT_BYTE: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= CHR_PTR;
				1: begin
					latch_byte <= 1;
				end
				2: begin
					latch_byte <= 0;
					wrote_one <= 1;
					if (~wrote_one & character_width) begin
						state <= DMA_INDIRECT_BYTE;
						CHR_PTR <= CHR_PTR + 1'd1;
					end else if (width_ovr) begin
						state <= DMA_HEADER_0;
					end else begin
						state <= DMA_INDIRECT_PTR;
					end
					substate <= 0;
				end
			endcase
		end

		// Fetch direct bytes
		DMA_DIRECT: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= PIX_PTR;
				1: latch_byte <= 1;
				2: begin
					latch_byte <= 0;
					PIX_PTR <= PIX_PTR + 1'd1;
					if (~|WIDTH) begin
						state <= DMA_HEADER_0;
					end else begin
						WIDTH <= WIDTH + 1'd1;
						state <= DMA_DIRECT;
					end
					substate <= 0;
				end
			endcase
		end

		// Decrement offset and terminate DMA
		DMA_END: begin
			// substate <= substate + 1'd1;
			// case (substate)
			// 	0: drive_AB <= 0;
			// 	// 1: wait
			// 	1: begin
					drive_AB <= 0;
					HALT <= 0;
					OFFSET <= OFFSET - 1'd1;
					state <= DMA_WAIT_DP;
					latch_byte <= 0;
					substate <= 0;
					drive_AB <= 0;
			// 	end
			// endcase
		end

		// Fetch DL header
		DMA_ZONE_END_0: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= ZONE_PTR;
				1: begin
					ZONE_PTR <= ZONE_PTR + 1'd1;
					{DLI, A12en, A11en} <= DataB[7:5];
					OFFSET <= DataB[3:0];
					state <= DMA_ZONE_END_1;
					substate <= 0;
				end
			endcase
		end

		// Fetch DL address upper byte
		DMA_ZONE_END_1: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= ZONE_PTR;
				1: begin
					ZONE_PTR <= ZONE_PTR + 1'd1;
					DP[15:8] <= DataB;
					state <= DMA_ZONE_END_2;
					substate <= 0;
				end
			endcase
		end

		// Fetch DL address lower byte and terminate DMA
		DMA_ZONE_END_2: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= ZONE_PTR;
				1: begin
					ZONE_PTR <= ZONE_PTR + 1'd1;
					DP[7:0] <= DataB;
					drive_AB <= 0;
				// end
				// 2: begin
					HALT <= 0;
					state <= DMA_WAIT_DP;
					substate <= 0;
				end
			endcase
		end

	endcase

	// If we reach the line ram swap point, terminate DMA. This is a convienience to
	// avoid a massive state machine surrounding this.
	if (lrc && dma_en && !shutting_down) begin
		state <= OFFSET ? DMA_END : DMA_ZONE_END_0;
		latch_byte <= 0;
		substate <= 0;
		clear_hpos <= 0;
		shutting_down <= 1;
	end
		

end

endmodule // dma_ctrl
