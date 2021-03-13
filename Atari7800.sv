//============================================================================
//  Atari 7800 for MiSTer
//  Copyright (C) 2021 Kitrinx
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
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,

`ifdef USE_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif

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

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

`ifdef USE_DDRAM
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
`endif

`ifdef USE_SDRAM
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
`endif

`ifdef DUAL_SDRAM
	//Secondary SDRAM
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

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

assign AUDIO_S   = 0;
assign AUDIO_MIX = 0;

assign LED_USER  = cart_download | bk_state |  bk_pending;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign VGA_SCALER = 0;

assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;


///////////////////////  CLOCK/RESET  ///////////////////////////////////

wire clock_locked;
wire clk_vid;
wire clk_sys;
wire clk_tia;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_vid),
	.outclk_2(clk_tia),
	.locked(clock_locked)
);

// 7.1590909 half
// 14318189 = NTSC
// 14.187576 = PAL (7.093788)
// Skip every 109 cycles?
logic reset;
always @(posedge clk_vid)
	reset <= RESET | buttons[1] | status[0] | ioctl_download;


wire cart_download = ioctl_download & (ioctl_index[5:0] == 6'd1);
wire bios_download = ioctl_download & (ioctl_index[5:0] == 6'd0) && (ioctl_index[7:6] == 0);

reg old_cart_download;

////////////////////////////  HPS I/O  //////////////////////////////////
// Status Bit Map:
// 0         1         2         3          4         5         6
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// X       XXXXXXXXXXXXXXXXXXXXXX

`include "build_id.v"
parameter CONF_STR = {
	"ATARI7800;;",
	"FS1,A78A26;",
	"-;",
	"OFG,Region,Auto,NTSC,PAL;",
	"OC,Difficulty Right,Right,Left;",
	"OD,Difficulty Left,Right,Left;",
	"-;",
	"P1,Audio & Video;",
	"P1-;",
	"d0P1OM,Vertical Crop,Disabled,216p(5x);",
	"d0P1ONQ,Crop Offset,0,2,4,8,10,12,-12,-10,-8,-6,-4,-2;",
	"P1ORS,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"P1-;",
	"P1O8,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P1O9B,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"P1OT,Show Overscan,No,Yes;",
	"P1OE,Show Border,No,Yes;",
	"P1OK,Composite Blending,No,Yes;",
	"P2,Peripherals;",
	"P2OIJ,High Score Cart,Auto,On,Off;",
	"P2OH,Bypass Bios,Yes,No;",
	"P2O7,Swap Joysticks,No,Yes;",
	"P3,Atari2600;",
	"P3OL,Black & White,Off,On;",
	"-;",
	"R0,Reset;",
	"J1,Fire1,Fire2,Pause,Select,Start;",
	"jn,B|P,A,R,Select,Start;",
	"jp,Y|P,B,R,Select,Start;",
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
wire [7:0]  ioctl_dout;
wire        ioctl_wr;
wire [7:0]  ioctl_index;
wire [21:0] gamma_bus;

wire [15:0] joy0,joy1;
wire        ioctl_wait;

reg  [31:0] sd_lba;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
reg         en216p;

hps_io #(.STRLEN(($size(CONF_STR)>>3))) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.conf_str(CONF_STR),

	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.joystick_0(joy0),
	.joystick_1(joy1),

	.status(status),
	.status_menumask({en216p}),

	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wr(ioctl_wr),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size)
);

////////////////////////////  SYSTEM  ///////////////////////////////////
logic tia_en;
logic [3:0] idump;

logic [1:0] ilatch;
logic [7:0] PAin, PBin, PAout, PBout;
wire [7:0] R,G,B;
wire HSync;
wire VSync;
wire HBlank;
wire VBlank;

wire [15:0] bios_addr;
reg [7:0] cart_data, bios_data;
wire cart_sel, bios_sel;
reg [7:0] joy0_type, joy1_type, cart_region, cart_save;

logic [15:0] cart_flags;
logic [39:0] cart_header;
logic [31:0] hcart_size, cart_size;
logic [24:0] cart_addr;
logic [7:0] cart_xm;
logic cart_busy;
logic cart_read;
logic [7:0] cart_data_sd;
reg cart_loaded = 0;
logic RW;

logic cart_is_7800;
logic [7:0] hsc_ram_dout, din;
logic hsc_ram_cs;
logic tia_mode;

wire region_select = ~|status[16:15] ? cart_region[0] : (status[16] ? 1'b1 : 1'b0);

Atari7800 main
(
	.clk_sys      (clk_sys),
	.clk_tia      (clk_tia),
	.reset        (reset),
	.loading      (ioctl_download),

	// Video
	.RED          (R),
	.GREEN        (G),
	.BLUE         (B),
	.HSync        (HSync),
	.VSync        (VSync),
	.HBlank       (HBlank),
	.VBlank       (VBlank),
	.ce_pix       (ce_pix),
	.show_border  (status[14]),
	.show_overscan(status[29]),
	.PAL          (region_select),
	.tia_mode     (tia_mode),
	.bypass_bios  (~status[17]),
	.hsc_en       (~|status[19:18] && (|cart_save || cart_xm[0]) ? 1'b1 : status[18]),
	.hsc_ram_dout (hsc_ram_dout),
	.hsc_ram_cs   (hsc_ram_cs),

	// Audio
	.AUDIO_R      (AUDIO_R), // 16 bit
	.AUDIO_L      (AUDIO_L), // 16 bit

	// Cart Interface
	.cart_sel     (cart_sel),
	.cart_out     (cart_loaded ? cart_data_sd : cart_data),
	.cart_read    (cart_read),
	.cart_size    (cart_is_7800 ? hcart_size : cart_size),
	.cart_addr_out(cart_addr),
	.cart_flags   (cart_is_7800 ? cart_flags[15:0] : 16'd0),
	.cart_region  (cart_is_7800 ? cart_region[0] : 1'b0),
	.cart_save    (cart_save),
	.cart_xm      (cart_xm),

	// BIOS
	.bios_sel     (bios_sel),
	.bios_out     (bios_data),
	.AB           (bios_addr), // Address
	.RW           (RW), // inverted write
	.dout         (din),

	// Tia
	.idump        (idump),  // Paddle {A0, B0, A1, B1}
	.ilatch       (ilatch), // Buttons {FireB, FireA}
	.tia_en       (tia_en),

	// RIOT
	.PAin         (PAin),  // Direction {RA, LA, DA, UA, RB, LB, DB, UB}
	.PBin         (PBin),  // Port B input
	.PAout        (PAout), // Port A output
	.PBout        (PBout),  // Peanut butter
	
	// 2600 Cart Flags from detect2600
	.force_bs     (force_bs),
	.sc           (sc)
);

////////////////////////////  MEMORY  ///////////////////////////////////
wire [3:0] force_bs;
wire sc;

detect2600 detect2600
(
	.clk(clk_sys),
	.addr(ioctl_addr[12:0]),
	.enable(ioctl_wr & cart_download),
	.data(ioctl_dout),
	.force_bs(force_bs),
	.sc(sc)
);

initial begin
	cart_header = "ATARI";
	hcart_size = 32'h00008000;
	cart_flags = 0;
	cart_region = 0;
	cart_save = 0;
	cart_xm = 0;
	tia_mode = 0;
end

always_ff @(posedge clk_sys) begin
	logic old_cart_download;
	logic [24:0] old_addr;
	cart_is_7800 <= (cart_header == "ATARI");
	old_cart_download <= cart_download;
	if (cart_download && ioctl_wr)
		cart_size <= (ioctl_addr - (cart_is_7800 ? 8'd128 : 1'b0)) + 1'd1; // 32 bit 1
	if (cart_download) begin
		tia_mode <= ioctl_index[7:6] != 0;
		old_addr <= ioctl_addr;
		case (ioctl_addr)
			'd01: cart_header[39:32] <= ioctl_dout;
			'd02: cart_header[31:24] <= ioctl_dout;
			'd03: cart_header[23:16] <= ioctl_dout;
			'd04: cart_header[15:8] <= ioctl_dout;
			'd05: cart_header[7:0] <= ioctl_dout;
			'd49: hcart_size[31:24] <= ioctl_dout;
			'd50: hcart_size[23:16] <= ioctl_dout;
			'd51: hcart_size[15:8] <= ioctl_dout;
			'd52: hcart_size[7:0] <= ioctl_dout;
			'd53: cart_flags[15:8] <= ioctl_dout;
			'd54: cart_flags[7:0] <= ioctl_dout;
			// 'd55: joy0_type <= ioctl_dout;   // 0=none, 1=joystick, 2=lightgun
			// 'd56: joy1_type <= ioctl_dout;
			'd57: cart_region <= ioctl_dout; // 0=ntsc, 1=pal
			'd58: cart_save <= ioctl_dout;   // 0=none, 1=high score cart, 2=savekey
			'd63: cart_xm <= ioctl_dout; // 1 = Has XM
			'd64: cart_loaded <= 1;
		endcase
	end
end

logic [24:0] cart_write_addr, fixed_addr;
assign cart_write_addr = (ioctl_addr >= 8'd128) && cart_is_7800 ? (ioctl_addr[24:0] - 8'd128) : ioctl_addr[24:0];

spram #(
	.addr_width(15),
	.mem_name("Cart"),
	.mem_init_file("mem0.mif")
) cart
(
	.address (cart_addr),
	.clock   (clk_sys),
	.data    (),
	.wren    (),
	.q       (cart_data)
);

// FIXME: Make bios loadable, expand to optional size for pal and prototype bioses
spram #(.addr_width(12), .mem_name("BIOS")) bios
(
	.address (bios_download ? ioctl_addr : bios_addr[11:0]),
	.clock   (clk_sys),
	.data    (ioctl_dout),
	.wren    (ioctl_wr & bios_download),
	.q       (bios_data)
);

always @(posedge clk_vid)
	ioctl_wait <= cart_download && cart_busy;

sdram sdram
(
	.*,

	// system interface
	.clk        ( clk_vid         ),
	.init       ( !clock_locked   ),

	// cpu/chipset interface
	.ch0_addr   (cart_download ? cart_write_addr : cart_addr),
	.ch0_wr     (ioctl_wr & cart_download),
	.ch0_din    (ioctl_dout),
	.ch0_rd     (cart_read & ~cart_download),
	.ch0_dout   (cart_data_sd),
	.ch0_busy   (cart_busy),

	.ch1_addr   (  ),
	.ch1_wr     (  ),
	.ch1_din    (  ),
	.ch1_rd     (  ),
	.ch1_dout   (  ),
	.ch1_busy   ( ),

	// reserved for backup ram save/load
	.ch2_addr   ( ),
	.ch2_wr     (  ),
	.ch2_din    (  ),
	.ch2_rd     (  ),
	.ch2_dout   (  ),
	.ch2_busy   (  )
);

//////////////////////////////  IO  /////////////////////////////////////

// https://atariage.com/forums/topic/23003-light-gun-pinout/
// Pin 1 - Trigger
// Pin 6 - Light Sensor
// Pin 7 - +5V
// Pin 8 - Ground

// Controller
// Pin 1 - Up
// Pin 2 - Down
// Pin 3 - Left
// Pin 4 - Right
// Pin 5 - B input paddle (7800 right button)
// Pin 6 - Fire (7800 both buttons) // 2600 legacy
// Pin 7 - +5v
// Pin 8 - Gnd
// Pin 9 - A input paddle (7800 left button)

wire joya_b2 = ~PBout[2] && ~tia_en;
wire joyb_b2 = ~PBout[4] && ~tia_en;

logic [15:0] joya, joyb;
assign joya = status[7] ? joy1 : joy0;
assign joyb = status[7] ? joy0 : joy1;

// RIOT Ports:
// 4 bits of PA are used for first stick, other 4 bits for second stick.
// 2600: Bits PB 0,1,4,6,7 are used for reset, select, b/w, left diff, right diff
// 7800: Bits PB 0,1,3,6,7 are used for reset, select, pause, left diff, right diff
// 7800: Bits PB 2 & 4 are used for output to select 2 button mode.

assign PBin[7] = ~status[13];              // Right diff
assign PBin[6] = ~status[14];              // Left diff
assign PBin[5] = 1'b1;                     // Unused
assign PBin[4] = ~status[21];              // 2600 B/W?
assign PBin[3] = (~joya[6] & ~joyb[6]);    // Pause
assign PBin[2] = 1'b1;                     // Unused
assign PBin[1] = (~joya[7] & ~joyb[7]);    // Select
assign PBin[0] = (~joya[8] & ~joyb[8]);    // Start/Reset 

assign PAin[7:4] = {~joya[0], ~joya[1], ~joya[2], ~joya[3]}; // P1: R L D U or PA PB 1 1
assign PAin[3:0] = {~joyb[0], ~joyb[1], ~joyb[2], ~joyb[3]}; // P2: R L D U or PA PB 1 1

// In two button mode, pin 6 is pulled up strongly, and won't lower
// In one button mode, it will lower if *either* pin 5 or 9 are pressed
assign ilatch[0] = joya_b2 ? 1'b1 : ~(joya[4] || joya[5]); // P1 Fire
assign ilatch[1] = joyb_b2 ? 1'b1 : ~(joyb[4] || joyb[5]); // P2 Fire

// These will continue to weakly pull up when pressed, even in one button mode.
wire pada_0 = joya[4];
wire pada_1 = joya[5];
wire padb_0 = joyb[4];
wire padb_1 = joyb[5];

//      4     5     6     7      8     9  10
// 	"J1,Fire1,Fire2,Pause,Select,Start,PU,PD;",

assign idump = {padb_0, padb_1, pada_0, pada_1}; // // P2 F1, P2 F2, P1 F1, P1 F2 (or analog?)

////////////////////////////  VIDEO  ////////////////////////////////////

logic hb_cofi, hs_cofi, vb_cofi, vs_cofi;
logic [7:0] r_cofi, g_cofi, b_cofi;
reg ce_pix;

cofi coffee (
	.clk        (CLK_VIDEO),
	.pix_ce     (ce_pix),
	.enable     (status[20]),
	.hblank     (HBlank),
	.vblank     (VBlank),
	.hs         (HSync),
	.vs         (VSync),
	.red        (R),
	.green      (G),
	.blue       (B),

	.hblank_out (hb_cofi),
	.vblank_out (vb_cofi),
	.hs_out     (hs_cofi),
	.vs_out     (vs_cofi),
	.red_out    (r_cofi),
	.green_out  (g_cofi),
	.blue_out   (b_cofi)
);

assign VGA_F1 = 1'b0;
assign CLK_VIDEO = clk_vid;
assign VGA_SL = sl[1:0];

wire       vcrop_en = status[22];
wire [3:0] vcopt    = status[26:23];
reg  [4:0] voff;
wire [1:0] ar = {1'd0, status[8]};
wire [11:0] arx,ary;

always @(posedge CLK_VIDEO) begin
	en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);
	voff <= (vcopt < 6) ? {vcopt,1'b0} : ({vcopt,1'b0} - 5'd24);
end

// Status[29]
// 224x320: 3200:2611
// 224x372: 3720:2611

// 
/* PAL
372x292 = 12'd3968 12'd2993
320x292 = 12'd1819 12'd1595
372x272 = 12'd992 12'd697
320x272 = 12'd2560 12'd2091

*/
always_comb begin
	arx = 0;
	ary = 0;
	if (~region_select) begin // NTSC
		if (status[14]) begin // Show border
			if (status[29]) begin // Show Overscan
				arx = 12'd3471;
				ary = 12'd2632;
			end else begin
				arx = 12'd3720;
				ary = 12'd2611;
			end
		end else begin
			if (status[29]) begin // Show Overscan
				arx = 12'd2979;
				ary = 12'd2626;
			end else begin
				arx = 12'd3200;
				ary = 12'd2611;
			end
		end
	end else begin // PAL
		if (status[14]) begin // Show border
			if (status[29]) begin // Show Overscan
				arx = 12'd3968;
				ary = 12'd2993;
			end else begin
				arx = 12'd992;
				ary = 12'd697;
			end
		end else begin
			if (status[29]) begin // Show Overscan
				arx = 12'd1819;
				ary = 12'd1595;
			end else begin
				arx = 12'd2560;
				ary = 12'd2091;
			end
		end
	end
end

wire vga_de;
video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? arx : (ar - 1'd1)),
	.ARY((!ar) ? ary : 12'd0),
	.CROP_SIZE((en216p & vcrop_en) ? 10'd216 : 10'd0),
	.CROP_OFF(voff),
	.SCALE(status[28:27])
);

wire [2:0] scale = status[11:9];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
wire       scandoubler = (scale || forced_scandoubler);

// always @(posedge CLK_VIDEO) begin : pix_div
// 	reg [2:0] div;
// 	div <= div + 1'd1;
// 	ce_pix <= !div;
// end

video_mixer #(.LINE_LENGTH(372), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
(
	.*,

	.VGA_DE(vga_de),
	.hq2x(scale==1),
	.HSync(hs_cofi),
	.HBlank(hb_cofi),
	.VSync(vs_cofi),
	.VBlank(vb_cofi),

	.R(r_cofi),
	.G(g_cofi),
	.B(b_cofi)
);

/////////////////////////  STATE SAVE/LOAD  /////////////////////////////
wire bk_save_write = ~RW & hsc_ram_cs;

reg bk_pending;

always @(posedge clk_sys) begin
	if (bk_ena && ~OSD_STATUS && bk_save_write)
		bk_pending <= 1'b1;
	else if (bk_state)
		bk_pending <= 1'b0;
end

dpram_dc #(.widthad_a(11)) hsc_ram
(
	.clock_a   (clk_sys),
	.address_a (bios_addr),
	.data_a    (din),
	.wren_a    (~RW & hsc_ram_cs),
	.q_a       (hsc_ram_dout),

	.clock_b   (clk_sys),
	.address_b ({sd_lba[1:0],sd_buff_addr}),
	.data_b    (sd_buff_dout),
	.wren_b    (sd_buff_wr & sd_ack),
	.q_b       (sd_buff_din)
);

wire downloading = cart_download;
reg old_downloading = 0;
reg bk_ena = 0;
always @(posedge clk_sys) begin
	
	old_downloading <= downloading;
	if(~old_downloading & downloading) bk_ena <= 0;
	
	//Save file always mounted in the end of downloading state.
	if(downloading && img_mounted && !img_readonly) bk_ena <= 1;
end

wire bk_load    = 0;//status[6];
wire bk_save    = (bk_pending & OSD_STATUS);
reg  bk_loading = 0;
reg  bk_state   = 0;

always @(posedge clk_sys) begin : save_block
	reg old_load = 0, old_save = 0, old_ack;

	old_load <= bk_load & bk_ena;
	old_save <= bk_save & bk_ena;
	old_ack  <= sd_ack;
	
	if(~old_ack & sd_ack) {sd_rd, sd_wr} <= 0;
	
	if(!bk_state) begin
		if((~old_load & bk_load) | (~old_save & bk_save)) begin
			bk_state <= 1;
			bk_loading <= bk_load;
			sd_lba <= 0;
			sd_rd <=  bk_load;
			sd_wr <= ~bk_load;
		end
		if(old_downloading & ~downloading & |img_size & bk_ena) begin
			bk_state <= 1;
			bk_loading <= 1;
			sd_lba <= 0;
			sd_rd <= 1;
			sd_wr <= 0;
		end 
	end else begin
		if(old_ack & ~sd_ack) begin
			if(&sd_lba[1:0]) begin
				bk_loading <= 0;
				bk_state <= 0;
			end else begin
				sd_lba <= sd_lba + 1'd1;
				sd_rd  <=  bk_loading;
				sd_wr  <= ~bk_loading;
			end
		end
	end
end

endmodule
