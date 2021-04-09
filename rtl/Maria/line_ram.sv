// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.

module line_ram(
	input  logic               clk_sys, 
	input  logic               RESET,
	output logic [7:0]         PLAYBACK,
	// Databus inputs
	input  logic [2:0]         PALETTE,
	input  logic [7:0]         d_in,
	input  logic               WM,
	input  logic               border,
	// Write enable for databus inputs
	input  logic               latch_byte,
	input  logic               latch_hpos,
	// Memory mapped registers
	input  logic [24:0][7:0]   COLOR_MAP,
	input  logic [1:0]         RM,
	input  logic               KANGAROO_MODE,
	input  logic               BORDER_CONTROL,
	input  logic               COLOR_KILL,
	input  logic               lrc,
	// VGA Control signal
	input  logic [8:0]         LRAM_OUT_COL,
	input  logic               mclk0,
	input  logic               mclk1,
	input  logic               cram_write
);

// The behavior of these make them work poorly in bram.
// The real system can flash-clear them and also writes
// to multiple cells at a time.
logic [159:0][4:0] lram_in, lram_out;

logic [2:0] playback_palette;
logic [1:0] playback_color;
logic [4:0] playback_cell;
logic [8:0] playback_ix;
logic [7:0] lram_ix;
logic [7:0] hpos;

logic [5:0] pb_map_index[8];
assign pb_map_index = '{5'd0, 5'd3, 5'd6, 5'd9, 5'd12, 5'd15, 5'd18, 5'd21};

always @(posedge clk_sys) begin
	if (mclk0) begin
		if (~border)
			playback_ix <= playback_ix + 1'd1;
		else
			playback_ix <= 0;
	end
	// The color ram will be delayed by one if there's a cram write
	// Uncomment to enable this bug (it's ugly)
	if (mclk0 /*&& ~cram_write*/) begin
		if (playback_color == 2'b0 || border) begin
			PLAYBACK <= (border & ~BORDER_CONTROL) ? 8'd0 : COLOR_MAP[0];
		end else begin
			PLAYBACK <= COLOR_MAP[pb_map_index[playback_palette] + playback_color];
		end
	end

end

always_comb begin
	lram_ix = playback_ix[8:1]; // 2 pixels per lram cell
	playback_cell = lram_out[lram_ix];
	playback_palette = playback_cell[4:2]; // Default to 160A/B
	playback_color = playback_cell[1:0];
	casex (RM)
		2'b0x: begin
			// 160A is read as four double-pixels per byte:
			//      <P2 P1 P0> <D7 D6>
			//      <P2 P1 P0> <D5 D4>
			//      <P2 P1 P0> <D3 D2>
			//      <P2 P1 P0> <D1 D0>
			// 160B is read as two double-pixels per byte:
			//      <P2 D3 D2> <D7 D6>
			//      <P2 D1 D0> <D5 D4>
			// In both cases, the lineram cells are stored in
			// exactly the order specified above. They can be
			// read directly.
			playback_palette = playback_cell[4:2];
			playback_color = playback_cell[1:0];
		end
		2'b10: begin
			// 320B is read as four pixels per byte:
			//      <P2  0  0> <D7 D3>
			//      <P2  0  0> <D6 D2>
			//      <P2  0  0> <D5 D1>
			//      <P2  0  0> <D4 D0>
			// 320B is stored as two cells per byte (wm=1):
			//      [P2 D3 D2 D7 D6]
			//      [P2 D1 D0 D5 D4]
			//
			// 320D is read as eight pixels per byte:
			//      <P2  0  0> <D7 P1>
			//      <P2  0  0> <D6 P0>
			//      <P2  0  0> <D5 P1>
			//      <P2  0  0> <D4 P0>
			//      <P2  0  0> <D3 P1>
			//      <P2  0  0> <D2 P0>
			//      <P2  0  0> <D1 P1>
			//      <P2  0  0> <D0 P0>
			// 320D is stored as four cells per byte (wm=0):
			//      [P2 P1 P0 D7 D6]
			//      [P2 P1 P0 D5 D4]
			//      [P2 P1 P0 D3 D2]
			//      [P2 P1 P0 D1 D0]
			//
			// In both cases, the palette is always <cell[4], 0, 0>
			// For a given pair of pixels, the color selectors
			// are, from left to right, <cell[1], cell[3]> and <cell[0], cell[2]>
			// Example: Either D7,D3:D6,D2 (320B) or D7,P1:D6,P0 (320D)
			playback_palette = {playback_cell[4], 2'b0};
			if (playback_ix[0]) begin
				// Right pixel
				playback_color = {playback_cell[0], playback_cell[2]};
			end else begin
				// Left pixel
				playback_color = {playback_cell[1], playback_cell[3]};
			end
		end
		2'b11: begin
			// 320A is read as eight pixels per byte:
			//      <P2 P1 P0> <D7  0>
			//      <P2 P1 P0> <D6  0>
			//      <P2 P1 P0> <D5  0>
			//      <P2 P1 P0> <D4  0>
			//      <P2 P1 P0> <D3  0>
			//      <P2 P1 P0> <D2  0>
			//      <P2 P1 P0> <D1  0>
			//      <P2 P1 P0> <D0  0>
			// 320A is stored as four cells per byte (wm=0):
			//      [P2 P1 P0 D7 D6]
			//      [P2 P1 P0 D5 D4]
			//      [P2 P1 P0 D3 D2]
			//      [P2 P1 P0 D1 D0]
			//
			// 320C is read as four pixels per byte:
			//      <P2 D3 D2> <D7  0>
			//      <P2 D3 D2> <D6  0>
			//      <P2 D1 D0> <D5  0>
			//      <P2 D1 D0> <D4  0>
			// 320C is stored as two cells per byte (wm=1):
			//      [P2 D3 D2 D7 D6]
			//      [P2 D1 D0 D5 D4]
			//
			// In both cases, the palette is always <cell[4], cell[3], cell[2]>
			// For a given pair of pixels, the color selectors
			// are, from left to right, <cell[1], 0> and <cell[0], 0>
			playback_palette = playback_cell[4:2];
			if (playback_ix[0]) begin
				// Right pixel
				playback_color = {playback_cell[0], 1'b0};
			end else begin
				// Left pixel
				playback_color = {playback_cell[1], 1'b0};
			end
		end
	endcase
end

always_ff @(posedge clk_sys) begin
	if (RESET) begin
		hpos <= 0;
	end else if (mclk0) begin

		if (lrc) begin
			lram_in <= 800'd0; // All background color
			lram_out <= lram_in;
		end

		if (latch_hpos) begin
			hpos <= d_in;
		end

		if (latch_byte) begin
			// Load d_in byte into lram_in
			case (WM)
			1'b0: begin
				// "When wm = 0, each byte specifies four pixel cells
				//  of the lineram"
				// This encompasses:
				// 160A:
				//      [P2 P1 P0 D7 D6]
				//      [P2 P1 P0 D5 D4]
				//      [P2 P1 P0 D3 D2]
				//      [P2 P1 P0 D1 D0]
				// 320A:
				//      [P2 P1 P0 D7  0]
				//      [P2 P1 P0 D6  0]
				//      [P2 P1 P0 D5  0]
				//      [P2 P1 P0 D4  0]
				//      [P2 P1 P0 D3  0]
				//      [P2 P1 P0 D2  0]
				//      [P2 P1 P0 D1  0]
				//      [P2 P1 P0 D0  0]
				// 320D:
				//      [P2  0  0 D7 P1]
				//      [P2  0  0 D6 P0]
				//      [P2  0  0 D5 P1]
				//      [P2  0  0 D4 P0]
				//      [P2  0  0 D3 P1]
				//      [P2  0  0 D2 P0]
				//      [P2  0  0 D1 P1]
				//      [P2  0  0 D0 P0]
				// These can all be written into the cells using
				// the same format and read out differently.
				hpos <= hpos + 3'd4;
				if (|d_in[7:6] || KANGAROO_MODE)
					lram_in[hpos + 8'd0] <= {PALETTE, d_in[7:6]};
				if (|d_in[5:4] || KANGAROO_MODE)
					lram_in[hpos + 8'd1] <= {PALETTE, d_in[5:4]};
				if (|d_in[3:2] || KANGAROO_MODE)
					lram_in[hpos + 8'd2] <= {PALETTE, d_in[3:2]};
				if (|d_in[1:0] || KANGAROO_MODE)
					lram_in[hpos + 8'd3] <= {PALETTE, d_in[1:0]};
			end
			1'b1: begin
				// "When wm = 1, each byte specifies two cells within the lineram."
				// This encompasses:
				// 160B:
				//      [P2 D3 D2 D7 D6]
				//      [P2 D1 D0 D5 D4]
				// 320B:
				//      [P2  0  0 D7 D3]
				//      [P2  0  0 D6 D2]
				//      [P2  0  0 D5 D1]
				//      [P2  0  0 D4 D0]
				// 320C:
				//      [P2 D3 D2 D7  0]
				//      [P2 D3 D2 D6  0]
				//      [P2 D1 D0 D5  0]
				//      [P2 D1 D0 D4  0]
				// Again, these can be written into the cells in
				// the same format and read out differently. Note:
				// transparency may not be correct in 320B mode here
				// since the color bits are different than 160B and 320C.
				hpos <= hpos + 2'd2;
				if (|d_in[7:6] || KANGAROO_MODE)
					lram_in[hpos + 8'd0] <= {PALETTE[2], d_in[3:2], d_in[7:6]};
				if (|d_in[5:4] || KANGAROO_MODE)
					lram_in[hpos + 8'd1] <= {PALETTE[2], d_in[1:0], d_in[5:4]};
			end
			endcase
		end
	end
end

endmodule
