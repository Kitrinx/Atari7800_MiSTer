//============================================================================
//  Atari 7800 for MiSTer
//  Copyright (C) 2017,2018 Srg320
//  Copyright (C) 2018 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================ 

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output  [1:0] VGA_SL,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS   = 'Z;

assign BUTTONS   = 0;
assign USER_OUT  = '1;

assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign AUDIO_S   = 1;
assign AUDIO_MIX = 0;

assign LED_USER  = ld[7];
assign LED_DISK  = ld[6];
assign LED_POWER = 0;

assign VIDEO_ARX = status[8] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[8] ? 8'd9  : 8'd3;

assign {SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 6'b111111;
assign SDRAM_DQ = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;


///////////////////////  CLOCK/RESET  ///////////////////////////////////

wire clock_locked;
wire clk_vid;
wire clk_sys;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_vid),
	.locked(clock_locked)
);

wire reset = RESET | buttons[1] | status[0] | ioctl_download | initial_pause;

wire cart_download = ioctl_download & (ioctl_index != 8'd0);
wire bios_download = ioctl_download & (ioctl_index == 8'd0);


reg old_cart_download;
reg initial_pause = 1'b1;

always @(posedge clk_sys) begin
	old_cart_download <= cart_download;
	if (old_cart_download & ~cart_download) initial_pause <= 1'b0;
end

////////////////////////////  HPS I/O  //////////////////////////////////

`include "build_id.v"
parameter CONF_STR = {
	"ATARI7800;;",
	"F,A78A26;",
	"O8,Aspect ratio,4:3,16:9;",
	"O9B,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O7,Swap Joysticks,No,Yes;",
	"OC,Difficulty Right,Low,High;",
	"OD,Difficulty Left,Low,High;",
	"-;",
	"R0,Reset;",
	"J1,Fire1,Fire2,Pause,Select,Start,PU,PD;",
	"V,v",`BUILD_DATE
};

wire  [1:0] buttons;
wire [31:0] status;
wire        forced_scandoubler;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire        ioctl_download;
wire [24:0] ioctl_addr;
wire [7:0] ioctl_dout;
wire        ioctl_wr;
wire [7:0]  ioctl_index;

wire [15:0] joy0,joy1;

hps_io #(.STRLEN(($size(CONF_STR)>>3))) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.conf_str(CONF_STR),

	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),

	.joystick_0(joy0),
	.joystick_1(joy1),

	.status(status),

	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wr(ioctl_wr),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size)
);

////////////////////////////  SYSTEM  ///////////////////////////////////

Atari7800 main
(
	.sysclk_7_143 (clk_sys),
	.clock_25     (clk_vid),
	.reset        (reset),
	.locked       (clock_locked),
	.memclk_o     (clk_mem),
	.pclk_0       (pclk_0),
	.loading      (ioctl_download),

	// Video
	.RED          (R),
	.GREEN        (G),
	.BLUE         (B),
	.HSync        (HSync),
	.VSync        (VSync),
	.HBlank       (HBlank),
	.VBlank       (VBlank),
	.ce_pix       (),

	// Audio
	.AUDIO        (AUDIO_R), // 16 bit

	// Cart Interface
	.cart_sel     (cart_sel),
	.cart_out     (cart_data),
	.cart_size    (cart_size),
	.cart_addr_out(cart_addr),
	.cart_flags   (cart_flags[9:0]),
	.cart_region  (cart_region[0]),

	// BIOS
	.bios_sel     (bios_sel),
	.bios_out     (bios_data),
	.AB           (bios_addr), // Address
	.RW           (), // inverted write

	// Debug
	.ld           (ld), // LED control

	// Tia
	.idump        (idump),  // Paddle {A0, B0, A1, B1}
	.ilatch       (ilatch), // Buttons {FireB, FireA}
	.tia_en       (tia_en),

	// RIOT
	.PAin         (PAin),  // Direction {RA, LA, DA, UA, RB, LB, DB, UB}
	.PBin         (PBin),  // Port B input
	.PAout        (PAout), // Port A output
	.PBout        (PBout)  // Peanut butter
);

wire [7:0] ld;
assign AUDIO_L = AUDIO_R;


////////////////////////////  MEMORY  ///////////////////////////////////

wire [16:0] bios_addr;
reg [7:0] cart_data, bios_data;
wire cart_sel, bios_sel;
wire clk_mem;
wire pclk_0;
reg [7:0] joy0_type, joy1_type, cart_region, cart_save;

logic [15:0] cart_flags;
logic [39:0] cart_header;
logic [31:0] hcart_size, cart_size;
logic [17:0] cart_addr;

wire cart_is_7800 = (cart_header == "ATARI");

always_ff @(posedge clk_sys) begin
	logic old_cart_download;
	logic [24:0] old_addr;

	old_cart_download <= cart_download;
	if (old_cart_download & ~cart_download)
		cart_size <= (old_addr - (cart_is_7800 ? 8'd128 : 1'b0)) + 1; // 32 bit 1
	if (cart_download) begin
		old_addr <= ioctl_addr;
		case (ioctl_addr)
			'd01: cart_header[39:32] <= ioctl_dout;
			'd02: cart_header[31:24] <= ioctl_dout;
			'd03: cart_header[23:16] <= ioctl_dout;
			'd04: cart_header[15:8] <= ioctl_dout;
			'd05: cart_header[7:0] <= ioctl_dout;
			'd49: hcart_size[31:24] <= ioctl_dout; //This appears to be useless.
			'd50: hcart_size[23:16] <= ioctl_dout;
			'd51: hcart_size[15:8] <= ioctl_dout;
			'd52: hcart_size[7:0] <= ioctl_dout;
			'd53: cart_flags[15:8] <= ioctl_dout;
			'd54: cart_flags[7:0] <= ioctl_dout;
			'd55: joy0_type <= ioctl_dout;   // 0=none, 1=joystick, 2=lightgun
			'd56: joy1_type <= ioctl_dout;
			'd57: cart_region <= ioctl_dout; // 0=ntsc, 1=pal
			'd58: cart_save <= ioctl_dout;   // 0=none, 1=high score cart, 2=savekey
		endcase
	end
end

logic [17:0] cart_write_addr, fixed_addr;
assign cart_write_addr = (ioctl_addr >= 8'd128) && cart_is_7800 ? (ioctl_addr[17:0] - 8'd128) : ioctl_addr[17:0];

dpram_dc #(.widthad_a(18)) cart
(
	.address_a(cart_addr),
	.clock_a(pclk_0),
	.byteena_a(~cart_download),
	.q_a(cart_data),

	.address_b(cart_write_addr),
	.clock_b(clk_sys),
	.data_b(ioctl_dout),
	.wren_b(ioctl_wr & cart_download),
	.byteena_b(1'b1)
);

dpram_dc #(.widthad_a(12)) bios
(
	.address_a(bios_addr[11:0]),
	.clock_a(clk_mem),
	.byteena_a(bios_sel & ~bios_download),
	.q_a(bios_data),

	.address_b(ioctl_addr),
	.clock_b(clk_sys),
	.data_b(ioctl_dout),
	.wren_b(ioctl_wr & bios_download),
	.byteena_b(1'b1)
);

//////////////////////////////  IO  /////////////////////////////////////

logic tia_en;
logic [3:0] idump;

logic [1:0] ilatch;
logic [7:0] PAin, PBin, PAout, PBout;

wire joya_b2 = ~PBout[2] & ~tia_en;
wire joyb_b2 = ~PBout[4] & ~tia_en;

logic [15:0] joya, joyb;
assign joya = status[7] ? joy1 : joy0;
assign joyb = status[7] ? joy0 : joy1;

// RIOT Ports:
// 4 bits of PA are used for first stick, other 4 bits for second stick.
// 2600: Bits PB 0,1,4,6,7 are used for reset, select, b/w, left diff, right diff
// 7800: Bits PB 0,1,3,6,7 are used for reset, select, pause, left diff, right diff
// 7800: Bits PB 2 & 4 are used for output to select 2 button mode.

assign PBin[7] = status[13];              // Right diff
assign PBin[6] = status[14];              // Left diff
assign PBin[5] = 1'b1;                     // Unused
assign PBin[4] = 1'b1;                     // 2600 B/W?
assign PBin[3] = (~joya[6] & ~joyb[6]);    // Pause
assign PBin[2] = 1'b1;                     // Unused
assign PBin[1] = (~joya[7] & ~joyb[7]);    // Select
assign PBin[0] = (~joya[8] & ~joyb[8]);    // Start/Reset 

assign PAin[7:4] = {~joya[0], ~joya[1], ~joya[2], ~joya[3]}; // P1: R L D U or PA PB 1 1
assign PAin[3:0] = {~joyb[0], ~joyb[1], ~joyb[2], ~joyb[3]}; // P2: R L D U or PA PB 1 1

assign ilatch[0] = ~joya[4]; // P1 Fire
assign ilatch[1] = ~joyb[4]; // P2 Fire

wire pada_0 = joya_b2 ? joya[4] : joya[9];
wire pada_1 = joya_b2 ? joya[5] : joya[10];
wire padb_0 = joyb_b2 ? joyb[4] : joyb[9];
wire padb_1 = joyb_b2 ? joyb[5] : joyb[10];

assign idump = {padb_0, padb_1, pada_0, pada_1}; // // P2 F1, P2 F2, P1 F1, P1 F2 (or analog?)

////////////////////////////  VIDEO  ////////////////////////////////////

wire [3:0] R,G,B;
wire HSync;
wire VSync;
wire HBlank;
wire VBlank;


assign VGA_F1 = 1'b0;
assign CLK_VIDEO = clk_vid;
assign VGA_SL = sl[1:0];

wire [2:0] scale = status[11:9];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
wire       scandoubler = (scale || forced_scandoubler);

wire ce_pix = clk_sys;

video_mixer video_mixer
(
	.*,

	.clk_sys(CLK_VIDEO),
	.ce_pix_out(CE_PIXEL),

	.scanlines(0),
	.hq2x(scale==1),
	.mono(0),

	.R({R,R}),
	.G({G,G}),
	.B({B,B})
);

endmodule
