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
	input logic        mclk0,
	input logic        mclk1,
	input logic        hide_border,
	input logic        PAL,
	input logic        bypass_bios,

	output logic       HSync, VSync,
	output logic       hblank, vblank, vblank_ex,
	output logic       border,
	output logic       lrc,
	output logic       prst, // no clue, but it's there
	output logic       vbe,  // vblank_end
	output logic       hbs   // hblank start
);

logic [8:0] row, col;

localparam MAX_ROW      = 9'd262;
localparam MAX_ROW_PAL  = 9'd312;
localparam MAX_COLUMN   = 9'd453;

localparam BORDER_START = 413;
localparam BORDER_END = 93;
localparam HBLANK_START = 440;
localparam HBLANK_END = 68;
localparam HSYNC_START = 0;
localparam HSYNC_END = 34; // Typo in schematic?
localparam LINE_RESET_COUNT = 412;
localparam RESET_PRST = 418; // wtf is this
localparam HCBURSTS = 38;

localparam VSYNC_END = 3;
localparam VSYNC_START = 0;
localparam VBLANK_START = 258;
localparam VBLANK_START_PAL = 308;
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
assign lrc        = (col == LINE_RESET_COUNT);
assign vbe        = (row == VBLANK_END) && (col == 0);
assign hbs        = col == HBLANK_START;
assign prst       = col == RESET_PRST;

always_ff @(posedge clk) if (reset) begin
	row <= bypass_bios ? 9'd39 : 9'd0;
	col <= bypass_bios ? 9'd255 : 9'd0;
end else if (mclk0) begin
	col <= col + 9'd1;

	if (col >= MAX_COLUMN) begin
		col <= 0;
		row <= row + 9'd1;

		if (row >= (PAL ? MAX_ROW_PAL : MAX_ROW))
			row <= 0;
	end
end

endmodule
