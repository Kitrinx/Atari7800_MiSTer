// (C) Jamie Blanks, 2021
// For MiSTer use only.

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

// From the schematic. (note that the schematic may not be accurate to final)
// HRESET:   111000100 452 This attempts to reset at 452, but I believe due to an error it takes one extra cycle
// HBORDERS: 110011101 413
// HBORDERR: 001011101 93
// HBLANKS:  110111000 440
// HBLANKR:  001000100 68
// HSYNCS:   000000000 0
// HSYNCR:   001000010 66
// HLRC:     110011100 412
// HRPRST:   110100010 418
// HCBURSTS: 000100110 38
// HCBURSTR: 000111000 56

// VRESET:  100000110 262
// VSYNCR:  000000011 3
// VSYNCS:  000000000 0
// VBLANKR: 000010000 16
// VBLANKS: 100000010 258

module video_sync (
	input logic        clk, reset,
	input logic [7:0]  uv_in,
	input logic        mclk0,
	input logic        mclk1,
	input logic        hide_border,
	input logic        PAL,

	output logic [9:0] row, col,
	output logic [3:0] RED, GREEN, BLUE,
	output logic       HSync, VSync,
	output logic       hblank, vblank,
	output logic       border,
	output logic       lrc,
	output logic       prst, // no clue, but it's there
	output logic       vbe,  // vblank_end
	output logic       hbs   // hblank start
);

logic visible;

localparam MAX_ROW      = 10'd262;
localparam MAX_ROW_PAL  = 10'd312;
localparam MAX_COLUMN   = 10'd453;

localparam BORDER_START = 413;
localparam BORDER_END = 93;
localparam HBLANK_START = 440;
localparam HBLANK_END = 68;
localparam HSYNC_START = 0;
localparam HSYNC_END = 66;
localparam LINE_RESET_COUNT = 412;
localparam RESET_PRST = 418; // wtf is this

localparam VSYNC_END = 3;
localparam VSYNC_START = 0;
localparam VBLANK_START = 258;
localparam VBLANK_START_PAL = 309;
localparam VBLANK_END = 16;

assign VSync      = (row < VSYNC_END);
assign vblank     = (row >= (PAL ? VBLANK_START_PAL : VBLANK_START)) || (row < VBLANK_END);

assign HSync      = col < HSYNC_END;
assign hblank     = hide_border ? border : ((col >= HBLANK_START) || (col < HBLANK_END));
assign border     = (col >= BORDER_START) || (col < BORDER_END);
assign visible    = ~(vblank | hblank);
assign lrc        = (col == LINE_RESET_COUNT);
assign vbe        = (row == VBLANK_END) && (col == 0);
assign hbs        = col == HBLANK_START;
assign prst       = col == RESET_PRST;

always_ff @(posedge clk) if (reset) begin
	row <= 0;
	col <= 0;
end else if (mclk0) begin
	col <= col + 10'd1;

	if (col >= MAX_COLUMN) begin
		col <= 0;
		row <= row + 10'd1;

		if (row >= (PAL ? MAX_ROW_PAL : MAX_ROW))
			row <= 0;
	end
end


// Chrominance-Luminance palettes (represented as rgb)
logic [255:0][3:0]  red_palette, green_palette, blue_palette;

always @(posedge clk) begin
	RED   <= visible ? red_palette[uv_in] : 4'd0;
	GREEN <= visible ? green_palette[uv_in] : 4'd0;
	BLUE  <= visible ? blue_palette[uv_in] : 4'd0;
end

// UV Palette data found at: http://atariage.com/forums/topic/209210-complete-ntsc-pal-color-palettes/
// These three assign statements generated by Atari7800/palettes.py
assign red_palette = {
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1,
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0,
	4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0,
	4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0,
	4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
	4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
	4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0,
	4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0,
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0,
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3,
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1,
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0
};

assign green_palette = {
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0,
	4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1,
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2,
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2,
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1,
	4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0,
	4'hf, 4'hf, 4'he, 4'hd, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h1, 4'h0, 4'h0,
	4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h1, 4'h0, 4'h0, 4'h0,
	4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0,
	4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h0, 4'h0, 4'h0, 4'h0,
	4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0,
	4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0,
	4'he, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0,
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0,
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0
};

assign blue_palette = {
	4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
	4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
	4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
	4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
	4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0,
	4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4,
	4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1,
	4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0,
	4'hb, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
	4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0
};


endmodule
