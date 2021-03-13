// (C) Jamie Blanks, 2021

// For MiSTer use only.

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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

// clkedge, (blk/vbe + halt), (dli + out1 + (halt/vbe)), con1, con2
// out0 0xx00
// out1 00x11
// out2 x0x01
// out3 1x001
// out4 01001
// out5 1xx00
// out6 0xx11

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
	output logic       hblank, vblank, vblank_ex,
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
localparam HCBURSTS = 38;

localparam VSYNC_END = 3;
localparam VSYNC_START = 0;
localparam VBLANK_START = 259;
localparam VBLANK_START_PAL = 309;
localparam VBLANK_END = 16;

localparam VBLANK_EX_START = 248;
localparam VBLANK_EX_START_PAL = 298;
localparam VBLANK_EX_END = 24;

assign VSync      = (row < VSYNC_END);
assign vblank     = (row >= (PAL ? VBLANK_START_PAL : VBLANK_START)) || (row < VBLANK_END);
assign vblank_ex  = (row >= (PAL ? VBLANK_EX_START_PAL : VBLANK_EX_START)) || (row < VBLANK_EX_END);

assign HSync      = col < HSYNC_END;
assign hblank     = hide_border ? border : ((col >= HBLANK_START) || (col < HBLANK_END));
assign border     = (col >= BORDER_START) || (col < BORDER_END);
assign visible    = ~(vblank | hblank);
assign lrc        = (col == LINE_RESET_COUNT);
assign vbe        = (row == VBLANK_END) && col == HBLANK_START;
assign hbs        = col == HBLANK_START && ~vblank;
assign prst       = col == RESET_PRST;

always_ff @(posedge clk) if (reset) begin
	row <= 0;
	col <= 0;
end else if (mclk0) begin
	col <= col + 10'd1;

	if (col >= MAX_COLUMN) begin
		col <= 0;
	end
	if (col == HBLANK_START - 1) begin
		row <= row + 10'd1;

		if (row >= (PAL ? MAX_ROW_PAL : MAX_ROW))
			row <= 0;
	end
end

function bit [3:0] chroma_blend (
	input [3:0] color_prev,
	input [3:0] color_curr,
	input blank_last
);
var
	reg [4:0] sum;
begin
	sum = color_curr;
	if(!blank_last) sum = sum + color_prev;
	chroma_blend = sum[4:1];
end
endfunction


// Chrominance-Luminance palettes (represented as rgb)
logic [255:0][3:0]  red_palette, green_palette, blue_palette;

logic [3:0] PAL_LUT [16];
assign PAL_LUT = '{
	4'h0, 4'hD, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9, 4'hA, 4'hB, 4'hC, 4'hD, 4'hE
};
// NTSC $1x <--> PAL $2x
// NTSC $2x <--> PAL $3x
// NTSC $3x <--> PAL $4x
// NTSC $4x <--> PAL $5x
// NTSC $5x <--> PAL $6x
// NTSC $6x <--> PAL $7x
// NTSC $7x <--> PAL $8x
// NTSC $8x <--> PAL $9x
// NTSC $9x <--> PAL $Ax
// NTSC $Ax <--> PAL $Bx
// NTSC $Bx <--> PAL $Cx
// NTSC $Cx <--> PAL $Dx
// NTSC $Dx <--> PAL $Ex
// NTSC $Ex <--> PAL $Fx
// NTSC $Fx <--> N/A - Best nearest PAL $2x
// PAL $1x <--> N/A - Best nearest NTSC $Dx

wire [3:0] luma = uv_in[3:0];
wire [3:0] chroma = PAL ? PAL_LUT[uv_in[7:4]] : uv_in[7:4];
logic[7:0] yuv_blend;
logic is_cb_high;

// If luma alternates intensity at 320 pixels per line:
// If colorburst is low, it will manifest as +blue
// If colorburst is high, it will manifest as +yellow
// Luma will become filtered and blend
// Chroma will end up blending more smoothly

always @(posedge clk) begin
	logic [3:0] chroma_last;
	logic blank_last;

	if (mclk0) begin
		yuv_blend <= {chroma, luma};
	end
	if (mclk1)
		is_cb_high <= ~is_cb_high;
	RED   <= visible ? red_palette[yuv_blend] : 4'd0;
	GREEN <= visible ? green_palette[yuv_blend] : 4'd0;
	BLUE  <= visible ? blue_palette[yuv_blend] : 4'd0;
end

// 119 == light blue
// 248 == medium grey

// 1111 1000
// 0111 0111

// UV Palette data found at: http://atariage.com/forums/topic/209210-complete-ntsc-pal-color-palettes/
// These three assign statements generated by Atari7800/palettes.py
assign red_palette = {
//Luma F     E     D     C     B     A     9     8     7     6     5     4     3     2     1     0  // Chroma
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, // F
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, // E
	4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, // D
	4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, // C
	4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, // B
	4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, // A
	4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, // 9
	4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, // 8
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, // 7
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, // 6
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, // 5
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, // 4
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, // 3
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, // 2
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, // 1
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0  // 0
};

assign green_palette = {
//Luma F     E     D     C     B     A     9     8     7     6     5     4     3     2     1     0  // Chroma
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, // F
	4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, // E
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, // D
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, // C
	4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, // B
	4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, // A
	4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, // 9
	4'hf, 4'hf, 4'he, 4'hd, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h1, 4'h0, 4'h0, // 8
	4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h1, 4'h0, 4'h0, 4'h0, // 7
	4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, // 6
	4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h0, 4'h0, 4'h0, 4'h0, // 5
	4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, // 4
	4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, // 3
	4'he, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, // 2
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, // 1
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0  // 0
};

assign blue_palette = {
	//Luma F     E     D     C     B     A     9     8     7     6     5     4     3     2     1     0  // Chroma
	4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, // F
	4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, // E
	4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, // D
	4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, // C
	4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, // B
	4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, // A
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, // 9
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, // 8
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, // 7
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, // 6
	4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, // 5
	4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, // 4
	4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, // 3
	4'hb, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, // 2
	4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, // 1
	4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0  // 0
};



endmodule
