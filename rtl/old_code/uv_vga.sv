/** Line buffer to VGA Interface
*
*  input lbuffer is the line buffer.
*  For column c, 0 <= c < 640, where 0 is left and 639 is right,
*  lbuffer[c][0] is RED, where 4'hF is the most intense red and
*  4'h0 is the least intense red.
*  lbuffer[c][1] is GREEN and lbuffer[c][2] is BLUE.
*
*  output line_number indicates the current row, where the top
*  of the screen is 0 and 479 is the bottom of the screen. Other
*  values indicate that no line is currently being drawn.
*
*  clk should be hooked up to a 25MHz clock (or 25.175 if available.)
*  reset should be hooked up to system reset.
*  RED, GREEN, BLUE, HSync, and VSync should be hooked up to the
*  appropriate VGA pins.
**/

//`define FRAMEBUF


//              33.5 cycles @1.79 MHz       80 cycles @1.79 MHz
//               134 cycles @7.16 MHz      320 cycles @7.16 MHz
//     NTSC    <--67 pixels--> <-----------160 pixels------------->   PAL
//      ______|_______________|____________________________________|_____
//       ^    |               |                  ^                 |   ^
//       |    |               |                  |                 |   |
//       16   |<---HBLANK---->|               VBLANK               |   16
//       |    |               |                  |                 |   |
//       |    |               |                  |                 |   |
// ______v____|_______________|__________________v_________________|___v______
//  ^    ^    |               |                  ^                 |   ^    ^
//  |    |    |               |                  |                 |   |    |
//  |    25   |               |                  |                 |   25   |
//  |    |    |               |                  |                 |   |    |
//  |    |    |               |                  |                 |   |    |
//  |   -v----|---------------|------------------|-----------------|---v-   |
//  |    ^    |               |                  |                 |   ^    |
//  |    |    |               |                  |                 |   |    |
//  |    |    |               |                  |                 |   |    |
//  |    |    |               |                  |                 |   |    |
//  |    |    |               |                  |                 |   |    |
// 243  192   |               |               VISIBLE              |  242  293
//  |    |    |               |                  |                 |   |    |
//  |    |    |               |                  |                 |   |    |
//  |    |    |               |                  |                 |   |    |
//  |    |    |               |                  |                 |   |    |
//  |    |    |               |                  |                 |   |    |
//  |   -v----|---------------|------------------|-----------------|---v-   |
//  |    ^    |               |                  |                 |   ^    |
//  |    |    |               |                  |                 |   |    |
//  |    26   |               |                  |                 |   26   |
//  |    |    |               |                  |                 |   |    |
//  |    |    |               |                  |                 |   |    |
// _v____v____|_______________|__________________v_________________|___v____v_
//       ^    |               |                  ^                 |   ^
//       |    |               |                  |                 |   |
//       4    |               |               VBLANK               |   4
//       |    |               |                  |                 |   |
//       |    |               |                  |                 |   |
//      _v____|_______________|__________________v_________________|___v_
//            |<-------------------227 pixels--------------------->|
//            |                    454 cycles @7.16 Mhz            |
//                               113.5 cycles @1.79 MHz

module uv_to_vga (
	input logic        clk, reset,
	input logic [7:0]  uv_in,

	output logic [9:0] row, col,
	output logic [3:0] RED, GREEN, BLUE,
	output logic       HSync, VSync,

	input logic tia_en, tia_clk,
	input logic tia_hblank,
	input logic tia_vblank
);



	logic               col_clear, row_clear;
	logic               col_enable, row_enable;

	// Chrominance-Luminance palettes (represented as rgb)
	logic [255:0][3:0]  red_palette, green_palette, blue_palette;

	logic [3:0] rbuf, gbuf, bbuf;
	logic [7:0] uv;

	logic visible, tia_visible;
	assign visible = (row < 10'd480) & (col < 10'd640);

	`ifdef FRAMEBUF
	assign tia_visible = (row >= 10'd48) & (row <10'd432) & (col < 10'd640);

	logic [9:0] tia_row, tia_col;
	assign tia_row = row - 10'd48;
	assign tia_col = col;

	logic [7:0] fbuf_uv1, fbuf_uv2;
	(* keep = "true" *) logic [7:0] fbuf_uv1_kept, fbuf_uv2_kept;
	assign fbuf_uv1_kept = fbuf_uv1;
	assign fbuf_uv2_kept = fbuf_uv2;

	logic [14:0] buf_w_addr, buf_r_addr;
	(* keep = "true" *) logic [14:0] buf_w_addr_kept;
	(* keep = "true" *) logic [14:0] buf_r_addr_kept;
	assign buf_w_addr = tia_write_row*14'd160+tia_write_col;
	assign buf_r_addr = tia_row[8:1]*14'd160+tia_col[9:2];
	assign buf_w_addr_kept = buf_w_addr;
	assign buf_r_addr_kept = buf_r_addr;
	logic write_buf1;

	Frame_Buf frame_buffer1(
	.clka(tia_clk),    // input wire clka
	.ena(~tia_vblank & ~tia_hblank & write_buf1),      // input wire ena
	.wea(write_buf1),      // input wire [0 : 0] wea
	.addra(buf_w_addr),  // input wire [14 : 0] addra
	.dina(uv_in),    // input wire [7 : 0] dina
	.clkb(clk),    // input wire clkb
	.enb(tia_visible),      // input wire enb
	.addrb(buf_r_addr),  // input wire [14 : 0] addrb
	.doutb(fbuf_uv1)  // output wire [7 : 0] doutb
	);

	Frame_Buf frame_buffer2(
	.clka(tia_clk),    // input wire clka
	.ena(~tia_vblank & ~tia_hblank & ~write_buf1),      // input wire ena
	.wea(~write_buf1),      // input wire [0 : 0] wea
	.addra(buf_w_addr),  // input wire [14 : 0] addra
	.dina(uv_in),    // input wire [7 : 0] dina
	.clkb(clk),    // input wire clkb
	.enb(tia_visible),      // input wire enb
	.addrb(buf_r_addr),  // input wire [14 : 0] addrb
	.doutb(fbuf_uv2)  // output wire [7 : 0] doutb
	);

	logic [7:0] tia_write_row;
	logic [7:0] tia_write_col;
	(* keep = "true" *) logic [7:0] tia_write_row_kept;
	(* keep = "true" *) logic [7:0] tia_write_col_kept;
	assign tia_write_row_kept = tia_write_row;
	assign tia_write_col_kept = tia_write_col;

	logic tia_hblank_buf, tia_vblank_buf;

	always_ff @(posedge tia_clk, posedge reset) begin
		if (reset) begin
			tia_write_row <= 0;
			tia_write_col <= 0;
			tia_hblank_buf <= 0;
			tia_vblank_buf <= 0;
		end else begin
			tia_hblank_buf <= tia_hblank;
			tia_vblank_buf <= tia_vblank;
			if (~tia_vblank_buf & tia_vblank)
				write_buf1 <= ~write_buf1;
			if (tia_hblank) begin
				tia_write_col <= 8'b0;
				if (~tia_hblank_buf & ~tia_vblank) begin
					tia_write_row <= tia_write_row + 1;
				end
			end else begin
				tia_write_col <= tia_write_col + 1;
			end

			if (tia_vblank)
				tia_write_row <= 8'd0;
		end
	end

	logic [7:0] uv_from_fbuf;
	assign uv_from_fbuf = (write_buf1) ? fbuf_uv2 : fbuf_uv1;
	assign uv = tia_en ? (tia_visible ? uv_from_fbuf : 8'd0) : (visible ? uv_in : 8'd0);
	`else
	assign uv = uv_in;
	`endif


	assign RED = rbuf;
	assign GREEN = gbuf;
	assign BLUE = bbuf;
	// UV Palette data found at: http://atariage.com/forums/topic/209210-complete-ntsc-pal-color-palettes/
	// These three assign statements generated by Atari7800/palettes.py
	assign red_palette = {4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0};
	assign rbuf = red_palette[uv];

	assign green_palette = {4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h1, 4'h0, 4'h0, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h1, 4'h0, 4'h0, 4'h0, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h0, 4'h0, 4'h0, 4'h0, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'he, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0};
	assign gbuf = green_palette[uv];

	assign blue_palette = {4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hb, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0};
	assign bbuf = blue_palette[uv];


	// Row counter counts from 0 to 520
	//     count of   0 - 479 is display time (row == line_number here)
	//     count of 480 - 489 is front porch
	//     count of 490 - 491 is VS=0 pulse width
	//     count of 492 - 525 is back porch

	always @(posedge clk, posedge reset)
	if (reset) begin
		row <= 10'd519;
	end else if (row_clear)
		row <= 10'd0;
	else
		row <= row + row_enable;

	assign row_clear  = (row == 10'd526) & row_enable;
	assign row_enable = (col == 10'd799);
	assign VSync      = (row < 10'd490) | (row > 10'd491);

	// Col counter counts from 0 to 799
	//     count of   0 - 639 is display time
	//     count of 640 - 655 is front porch
	//     count of 656 - 751 is HS=0 pulse width
	//     count of 752 - 799 is back porch

	always @(posedge clk or posedge reset)
	if (reset)
		col <= 10'd0;
	else if(col_clear)
		col <= 10'd0;
	else
		col <= col + col_enable;

	/*logic [7:0] tia_buf_col;
	logic write_buf1;
	logic [7:0][159:0] tia_buf1;
	logic [7:0][159:0] tia_buf2;
	integer i;

	always @(posedge tia_hblank)
	write_buf1 <= ~write_buf1;

	always @(posedge tia_clk, posedge reset) begin
		if (reset) begin
			tia_buf_col <= 7'b0;
			tia_buf1 <= 1280'b0;
			tia_buf2 <= 1280'b0;
		end else if (tia_en & tia_vsync_delta) begin
			tia_buf_col <= 7'b0;
			for (i=0;i<160;i=i+1) begin
				tia_buf1[i] <= 8'b0;
				tia_buf2[i] <= 8'b0;
			end
		end else if (tia_hblank)
			tia_buf_col <= 8'd160;
		else if (tia_buf_col == 8'd227)
			tia_buf_col <= 8'd0;
		else begin
			tia_buf_col <= tia_buf_col + 1;
			if (write_buf1)
				tia_buf1[tia_buf_col] <= uv_in;
			else
				tia_buf2[tia_buf_col] <= uv_in;
		end
	end*/

	assign col_clear  = row_enable;
	assign col_enable = 1'b1;
	assign HSync      = (col < 10'd656) | (col > 10'd751);

endmodule
