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

assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign AUDIO_S   = 0;
assign AUDIO_MIX = status[3:2];

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

// 7.1590909 = NTSC pixel clock
// 14.318189 = NTSC Master clock
// 7.093788  = PAL Pixel Clock // Skip every 109 cycles?
// 14.187576 = PAL Master Clock

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
// XXXXXXX XXXXXXXXXXXXX XXXXXXXXXX XXX XXXXXXXXXX

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
	"P1O23,Stereo Mix,None,25%,50%,100%;",
	"P1O4,Stereo TIA,No,Yes;",
	"d0P1OM,Vertical Crop,Disabled,216p(5x);",
	"d0P1ONQ,Crop Offset,0,2,4,8,10,12,-12,-10,-8,-6,-4,-2;",
	"P1ORS,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"P1-;",
	"P1O8,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P1O9B,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"P1OT,Show Overscan,No,Yes;",
	"P1OE,Show Border,Yes,No;",
	"P1OK,Composite Blending,No,Yes;",
	"P1OUV,Color Temperature,Warm,Cool,Hot;",
	"P2,Peripherals;",
	"P2OIJ,High Score Cart,Auto,On,Off;",
	"P2O7,Swap Joysticks,No,Yes;",
	"P2-;",
	"P2o69,Port1 Input,Auto,None,Joystick,Lightgun,Paddle,Trakball,Keypad,Driving,STMouse,AmigaMouse,SNAC;",
	"P2oAD,Port2 Input,Auto,None,Joystick,Lightgun,Paddle,Trakball,Keypad,Driving,STMouse,AmigaMouse,SNAC;",
	"h1P2O5,SNAC Analog,Yes,No;",
	"h1P2O6,Sega Phaser Mode,No,Yes;",
	"P2-;",
	"P2o01,Gun Control,Joy1,Joy2,Mouse;",
	"P2o2,Gun Fire,Joy,Mouse;",
	"P2o45,Cross,Small,Medium,Big,None;",

	// TODO: snac mode phaser
	// TODO: paddle arrangement
	"P3,Advanced;",
	"P3OH,Bypass Bios,Yes,No;",
	"P3O1,Clear Memory,Zero,Random;",
	"-;",
	"R0,Reset;",
	"J,Fire1,Fire2,Pause,Select,Start,Paddle;",
	"jn,A|P,B,R,Select,Start,L;",
	"jp,B|P,Y,R,Select,Start,L;",
	"V,v",`BUILD_DATE
};


wire  [1:0] buttons;
wire [63:0] status;
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

wire [15:0] joy0,joy1,joy2,joy3;
wire [15:0] joya_0,joya_1,joya_2,joya_3;
wire  [7:0] pd_0,pd_1,pd_2,pd_3;
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
wire [24:0] ps2_mouse;
logic [10:0] ps2_key;
logic [15:0] ps2_mouse_ext;
logic is_snac0, is_snac1;

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
	.joystick_2(joy2),
	.joystick_3(joy3),
	.joystick_analog_0(joya_0),
	.joystick_analog_1(joya_1),
	.joystick_analog_2(joya_2),
	.joystick_analog_3(joya_3),
	.paddle_0(pd_0),
	.paddle_1(pd_1),
	.paddle_2(pd_2),
	.paddle_3(pd_3),

	.ps2_mouse(ps2_mouse),
	.ps2_mouse_ext(ps2_mouse_ext),
	.ps2_key (ps2_key),
	.status(status),
	.status_menumask({(is_snac0 | is_snac1),en216p}),

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
reg [7:0] joy0_type, joy1_type, cart_region, cart_save;

logic [15:0] cart_flags;
logic [39:0] cart_header;
logic [31:0] cart_size;
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
logic ce_pix_raw;
wire [3:0] force_bs;
wire sc;

logic [15:0] rnd;
wire PAread;

lfsr #(.N(15)) random(rnd);

wire region_select = ~|status[16:15] ? cart_region[0] : (status[16] ? 1'b1 : 1'b0);
logic [3:0] iout;
logic tia_hsync;
logic [7:0] rval;

always @(posedge clk_sys)
	rval <= rnd[7:0];

Atari7800 main
(
	.clk_sys      (clk_sys),
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
	.ce_pix       (ce_pix_raw),
	.show_border  (~status[14]),
	.show_overscan(status[29]),
	.PAL          (region_select),
	.pal_temp     (status[31:30]),
	.tia_mode     (tia_mode),
	.bypass_bios  (~status[17]),
	.hsc_en       (~|status[19:18] && (|cart_save || cart_xm[0]) ? 1'b1 : status[18]),
	.hsc_ram_dout (hsc_ram_dout),
	.hsc_ram_cs   (hsc_ram_cs),

	// Audio
	.AUDIO_R      (AUDIO_R), // 16 bit
	.AUDIO_L      (AUDIO_L), // 16 bit

	// Cart Interface
	.cart_out     (cart_loaded ? cart_data_sd : cart_data),
	.cart_read    (cart_read),
	.cart_size    (cart_size),
	.cart_addr_out(cart_addr),
	.cart_flags   (cart_is_7800 ? cart_flags[15:0] : 16'd0),
	.cart_save    (cart_save),
	.cart_xm      (cart_is_7800 ? cart_xm : 8'h0),
	.ps2_key      (ps2_key),

	// BIOS
	.bios_out     (bios_data),
	.AB           (bios_addr), // Address
	.RW           (RW), // inverted write
	.dout         (din),

	// Tia
	.idump        (idump),  // Paddle {A0, B0, A1, B1}
	.ilatch       (ilatch), // Buttons {FireB, FireA}
	.i_out         (iout),
	.tia_en       (tia_en),
	.tia_hsync    (tia_hsync),
	.use_stereo   (status[4]),

	// RIOT
	.PAin         (PAin),  // Direction {RA, LA, DA, UA, RB, LB, DB, UB}
	.PBin         (PBin),  // Port B input
	.PAout        (PAout), // Port A output
	.PBout        (PBout),  // Peanut butter
	.PAread       (PAread),

	// 2600 Cart Flags from detect2600
	.force_bs     (force_bs),
	.sc           (sc),
	.clearval     (status[1] ? rval : 8'h00)
);

////////////////////////////  MEMORY  ///////////////////////////////////
logic [14:0] bios_mask;

detect2600 detect2600
(
	.clk(clk_sys),
	.addr(ioctl_addr[12:0]),
	.cart_size(cart_size),
	.enable(ioctl_wr & cart_download),
	.data(ioctl_dout),
	.force_bs(force_bs),
	.sc(sc)
);

initial begin
	cart_header = "ATARI";
	cart_size = 32'h00008000;
	cart_flags = 0;
	cart_region = 0;
	bios_mask = 0;
	cart_save = 0;
	cart_xm = 0;
	tia_mode = 0;
end

always_ff @(posedge clk_sys) begin
	cart_is_7800 <= (cart_header == "ATARI");
	if (bios_download && ioctl_wr) // This assumes bootrom is always power of two
		bios_mask <= ioctl_addr[14:0];
	if (cart_download && ioctl_wr)
		cart_size <= (ioctl_addr - (cart_is_7800 ? 8'd128 : 1'b0)) + 1'd1; // 32 bit 1
	if (cart_download) begin
		tia_mode <= ioctl_index[7:6] != 0;
		cart_loaded <= 1;
		if (!tia_mode) begin
			case (ioctl_addr)
				'd01: cart_header[39:32] <= ioctl_dout;
				'd02: cart_header[31:24] <= ioctl_dout;
				'd03: cart_header[23:16] <= ioctl_dout;
				'd04: cart_header[15:8] <= ioctl_dout;
				'd05: cart_header[7:0] <= ioctl_dout;
				// 'd49: hcart_size[31:24] <= ioctl_dout;
				// 'd50: hcart_size[23:16] <= ioctl_dout;
				// 'd51: hcart_size[15:8] <= ioctl_dout;
				// 'd52: hcart_size[7:0] <= ioctl_dout;
				'd53: cart_flags[15:8] <= ioctl_dout;
				'd54: cart_flags[7:0] <= ioctl_dout;
				'd55: joy0_type <= ioctl_dout;   // 0=none, 1=joystick, 2=lightgun
				'd56: joy1_type <= ioctl_dout;
				'd57: cart_region <= ioctl_dout; // 0=ntsc, 1=pal
				'd58: cart_save <= ioctl_dout;   // 0=none, 1=high score cart, 2=savekey
				'd63: cart_xm <= ioctl_dout; // 1 = Has XM
			endcase
		end else begin
			cart_header <= 0;
			cart_flags <= 0;
			cart_region <= 0;
			cart_save <= 0;
			cart_xm <= 0;
		end
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
spram #(.addr_width(15), .mem_name("BIOS")) bios
(
	.address (bios_download ? ioctl_addr : (bios_addr[14:0] & bios_mask)),
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
	.ch0_rd     (cart_read & ~cart_download & ~reset),
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

// RIOT Ports:
// 4 bits of PA are used for first stick, other 4 bits for second stick.
// 2600: Bits PB 0,1,3,6,7 are used for reset, select, b/w, left diff, right diff
// 7800: Bits PB 0,1,3,6,7 are used for reset, select, pause, left diff, right diff
// 7800: Bits PB 2 & 4 are used for output to select 2 button mode.

assign PBin[7] = ~status[12];              // Right diff
assign PBin[6] = ~status[13];              // Left diff
assign PBin[5] = PBout[5];                 // Unused (Not connected)
assign PBin[4] = PBout[4];                 // Unused (used for 2 button sensing)
assign PBin[3] = (~joya[6] & ~joyb[6]);    // Pause/B&W
assign PBin[2] = PBout[2];                 // Unused (used for 2 button sensing)
assign PBin[1] = (~joya[7] & ~joyb[7]);    // Select
assign PBin[0] = (~joya[8] & ~joyb[8]);    // Start/Reset

wire [7:0] porta_type, portb_type;
wire [1:0] gun_mode = status[33:32];
wire       gun_btn_mode = status[34];
wire       gun_port = (portb_type == 2) ? 1'b1 : 1'b0;
wire       gun_en = (porta_type == 2 || portb_type == 2);
wire       gun_target;
wire       gun_sensor;
wire       gun_trigger;

lightgun lightgun
(
	.CLK(clk_sys),
	.RESET(reset),

	.MOUSE(ps2_mouse),
	.MOUSE_XY(gun_mode[1]),

	.LIGHT (|{R, G, B}),

	.JOY_X(~|gun_mode ? joya_0[7:0] : joya_1[7:0]),
	.JOY_Y(~|gun_mode ? joya_0[15:8] : joya_1[15:8]),
	.JOY_TRIG(~|gun_mode ? (joya[4] || joya[5]) :(joyb[4] || joyb[5])),

	.HDE(~HBlank),
	.VDE(~VBlank),
	.CE_PIX(ce_pix_raw),

	.BTN_MODE(gun_btn_mode),
	.SIZE(status[37:36]),
	.SENSOR_DELAY(46),

	.TARGET(gun_target),
	.SENSOR(gun_sensor),
	.TRIGGER(gun_trigger)
);

logic [3:0] pad_b;
logic [7:0] pad_ax[4];
logic [3:0] pad_wire;
logic [15:0] joya_a, joya_b, joya_c, joya_d;
logic [7:0] pd_a, pd_b, pd_c, pd_d;
logic sb_a, sb_b, sb_c, sb_d;
logic pdb_a, pdb_b, pdb_c, pdb_d;

assign joya_a = status[7] ? joya_2 : joya_0;
assign joya_b = status[7] ? joya_3 : joya_1;
assign joya_c = status[7] ? joya_0 : joya_2;
assign joya_d = status[7] ? joya_1 : joya_3;

assign pd_a = status[7] ? pd_2 : pd_0;
assign pd_b = status[7] ? pd_3 : pd_1;
assign pd_c = status[7] ? pd_0 : pd_2;
assign pd_d = status[7] ? pd_1 : pd_3;

assign sb_a = status[7] ? joy2[4] : joy0[4];
assign sb_b = status[7] ? joy3[4] : joy1[4];
assign sb_c = status[7] ? joy0[4] : joy2[4];
assign sb_d = status[7] ? joy1[4] : joy3[4];

assign pdb_a = status[7] ? joy2[9] : joy0[9];
assign pdb_b = status[7] ? joy3[9] : joy1[9];
assign pdb_c = status[7] ? joy0[9] : joy2[9];
assign pdb_d = status[7] ? joy1[9] : joy3[9];

paddle_ctl paddle0
(
	.clk       (clk_sys),
	.inv       (1),
	.stick_btn (sb_a),
	.joy_a     (joya_a),
	.paddle_btn(pdb_a),
	.paddle    (pd_a),
	.ps2_mouse (ps2_mouse),
	.b_out     (pad_b[0]),
	.a_out     (pad_ax[0])
);

paddle_ctl paddle1
(
	.clk       (clk_sys),
	.inv       (1),
	.stick_btn (sb_b),
	.joy_a     (joya_b),
	.paddle_btn(pdb_b),
	.paddle    (pd_b),
	.ps2_mouse (ps2_mouse),
	.b_out     (pad_b[1]),
	.a_out     (pad_ax[1])
);

paddle_ctl paddle2
(
	.clk       (clk_sys),
	.inv       (1),
	.stick_btn (sb_c),
	.joy_a     (joya_c),
	.paddle_btn(pdb_c),
	.paddle    (pd_c),
	.ps2_mouse (ps2_mouse),
	.b_out     (pad_b[2]),
	.a_out     (pad_ax[2])
);

paddle_ctl paddle3
(
	.clk       (clk_sys),
	.inv       (1),
	.stick_btn (sb_d),
	.joy_a     (joya_d),
	.paddle_btn(pdb_d),
	.paddle    (pd_d),
	.ps2_mouse (ps2_mouse),
	.b_out     (pad_b[3]),
	.a_out     (pad_ax[3])
);

paddle_timer pt0 (clk_sys, 1, {~pad_ax[0][7], pad_ax[0][6:0], 1'b0}, ~iout[1], pad_wire[0]);
paddle_timer pt1 (clk_sys, 1, {~pad_ax[1][7], pad_ax[1][6:0], 1'b0}, ~iout[1], pad_wire[1]);
paddle_timer pt2 (clk_sys, 1, {~pad_ax[2][7], pad_ax[2][6:0], 1'b0}, ~iout[1], pad_wire[2]);
paddle_timer pt3 (clk_sys, 1, {~pad_ax[3][7], pad_ax[3][6:0], 1'b0}, ~iout[1], pad_wire[3]);

logic [7:0] mouse_x, mouse_y;
logic dir_x, dir_y;

logic [3:0] trackball;
logic trackball_button;

wire pada_0, pada_1, padb_0, padb_1;

always @(posedge clk_sys) begin
	logic ps2_old;
	logic xtog, ytog;

	ps2_old <= ps2_mouse[24];

	// Feed out the trackball movement one pixel per cpu cycle.
	if (PAread) begin
		if (mouse_y > 0) begin
			ytog <= ~ytog;
			mouse_y <= mouse_y - 1'd1;
		end
		if (mouse_x > 0) begin
			xtog <= ~xtog;
			mouse_x <= mouse_x - 1'd1;
		end
		trackball <= {ytog, dir_y, xtog, dir_x};

	end
	if (ps2_old != ps2_mouse[24]) begin
		trackball_button <= ps2_mouse[0] | ps2_mouse[1]; // Allow either right or left button to trigger
		mouse_x <= ps2_mouse[4] ? ~ps2_mouse[15:8] : ps2_mouse[15:8]; // Record the absolute values of the 2's complement numbers
		mouse_y <= ps2_mouse[5] ? ~ps2_mouse[23:16] : ps2_mouse[23:16];
		dir_x <= ~ps2_mouse[4]; // Record the directions (x is inverted for this trackball)
		dir_y <= ps2_mouse[5];
	end
end



// -- PS2 to pokey
// keyboard_map1 : entity work.ps2_to_atari800
// generic map (ps2_enable => 0, direct_enable => 1)
// PORT MAP
// ( 
// 	CLK => clk,
// 	RESET_N => reset_n,

// 	INPUT => x"000" & "000" & ps2_key(9) & "000" & ps2_key(8) & x"0" & ps2_key(7 downto 0),

// 	KEYBOARD_SCAN => KEYBOARD_SCAN,
// 	KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

// 	CONSOL_START => CONSOL_START,
// 	CONSOL_SELECT => CONSOL_SELECT,
// 	CONSOL_OPTION => CONSOL_OPTION,

// 	FKEYS => FKEYS,
// 	FREEZER_ACTIVATE => freezer_activate,

// 	PS2_KEYS_NEXT_OUT => open,
// 	PS2_KEYS => ps2_keys
// );

logic [6:0] st_mouse;
logic [3:0] st_m_cnt;

always @(posedge clk_sys)
	st_m_cnt <= st_m_cnt + 1'd1;
ps2 mouse_st (
	.clk           (clk_sys),
	.ce            (!st_m_cnt),
	.reset         (reset),
	.ps2_key       (ps2_key),
	.ps2_mouse     (ps2_mouse),
	.ps2_mouse_ext (ps2_mouse_ext),
	.mouse_atari   (st_mouse)
);

wire joya_b2 = ~PBout[2] && ~tia_en && joy0_type != 5;
wire joyb_b2 = ~PBout[4] && ~tia_en && joy1_type != 5;

logic [15:0] joya, joyb;
assign joya = status[7] ? joy1 : joy0;
assign joyb = status[7] ? joy0 : joy1;

//    Col0  Col1  Col2
logic key3, key2, key1; // Row 0
logic key6, key5, key4; // Row 1
logic key9, key8, key7; // Row 2
logic keyh, key0, keya; // Row 3

// Follows the format of il, id[1:0], pa[3:0]
logic [6:0] keypad0, keypad1;
wire [3:0] kp_out0 = PAout[7:4];
wire [3:0] kp_out1 = PAout[3:0];

//  1,2,3 ---> 1,2,3
//  4,5,6 ---> Q,W,E
//  7,8,9 ---> A,S,D
//  *,0,# ---> Z,X,C

// Matrix-ify the keypad
always @(posedge clk_sys) begin
	logic last_ps2key10;
	if(last_ps2key10 != ps2_key[10]) begin
		last_ps2key10 <= ps2_key[10];
		case (ps2_key[8:0])
			9'h16: key1 <= ps2_key[9]; // 1
			9'h1E: key2 <= ps2_key[9]; // 2
			9'h26: key3 <= ps2_key[9]; // 3

			// Number row
			9'h25: key4 <= ps2_key[9]; // 4
			9'h2E: key5 <= ps2_key[9]; // 5
			9'h36: key6 <= ps2_key[9]; // 6
			9'h3D: key7 <= ps2_key[9]; // 7
			9'h3E: key8 <= ps2_key[9]; // 8
			9'h46: key9 <= ps2_key[9]; // 9
			9'h45: key0 <= ps2_key[9]; // 0
			9'h4E: keyh <= ps2_key[9]; // -
			9'h55: keya <= ps2_key[9]; // =

			// Numpad Layout
			9'h15: key4 <= ps2_key[9]; // Q
			9'h1d: key5 <= ps2_key[9]; // W
			9'h24: key6 <= ps2_key[9]; // E
			9'h1c: key7 <= ps2_key[9]; // A
			9'h1b: key8 <= ps2_key[9]; // S
			9'h23: key9 <= ps2_key[9]; // D
			9'h1a: keya <= ps2_key[9]; // Z
			9'h22: key0 <= ps2_key[9]; // X
			9'h21: keyh <= ps2_key[9]; // C

		endcase
	end
	if (reset)
		{key1, key2, key3, key4, key5, key6, key7, key8, key9, key0, keyh, keya} <= '0;

	// These have pull-ups in an undisturbed state
	keypad0 <= '1;
	keypad1 <= '1;
	// Row 0
	if (key3) begin keypad0[6] <= kp_out0[0]; keypad1[6] <= kp_out1[0]; end
	if (key2) begin keypad0[5] <= kp_out0[0]; keypad1[5] <= kp_out1[0]; end
	if (key1) begin keypad0[4] <= kp_out0[0]; keypad1[4] <= kp_out1[0]; end

	// Row 1
	if (key6) begin keypad0[6] <= kp_out0[1]; keypad1[6] <= kp_out1[1]; end
	if (key5) begin keypad0[5] <= kp_out0[1]; keypad1[5] <= kp_out1[1]; end
	if (key4) begin keypad0[4] <= kp_out0[1]; keypad1[4] <= kp_out1[1]; end

	// Row 2
	if (key9) begin keypad0[6] <= kp_out0[2]; keypad1[6] <= kp_out1[2]; end
	if (key8) begin keypad0[5] <= kp_out0[2]; keypad1[5] <= kp_out1[2]; end
	if (key7) begin keypad0[4] <= kp_out0[2]; keypad1[4] <= kp_out1[2]; end

	// Row 3
	if (keyh) begin keypad0[6] <= kp_out0[3]; keypad1[6] <= kp_out1[3]; end
	if (key0) begin keypad0[5] <= kp_out0[3]; keypad1[5] <= kp_out1[3]; end
	if (keya) begin keypad0[4] <= kp_out0[3]; keypad1[4] <= kp_out1[3]; end

end

wire [7:0] snac_type = 8'd9;
wire [3:0] snac_pa_in = {USER_IN[3], USER_IN[5], USER_IN[0], (status[6] ? ~USER_IN[2] : USER_IN[1])};
wire [1:0] snac_id_in = {USER_IN[6], USER_IN[4]} & ((~status[5] || status[6]) ? 2'b00 : 2'b11); // FIXME: These may be backwards.
wire snac_il_in = (status[6] ? USER_IN[4] : USER_IN[2]);

wire tape_sync;
reg   [23:0] adc_out;
ltc2308 ltc2308
(
	.clk(CLK_50M),
	.ADC_BUS(ADC_BUS),
	.dout_sync(tape_sync),
	.dout(adc_out)
);

// Controller      Lightgun   Trakball   Paddle   Keypad  AmigaM   STM       Mister Pin
// Pin 1 - Up      Trigger    Dir X               Row 0   VPulse   VHPulse   USER_IN[1]
// Pin 2 - Down               Tog X               Row 1   HPulse   HPulse    USER_IN[0]
// Pin 3 - Left               Dir Y      ButtonB  Row 2   VQPulse  VQPulse   USER_IN[5]
// Pin 4 - Right              Tog Y      ButtonA  Row 3   VHPulse  VPulse    USER_IN[3]
// Pin 5 - B Button                      Axis A   Col 2   Button3  Button3   USER_IN[4]
// Pin 6 - Fire    Light      Button              Col 0   Button1  Button1   USER_IN[2]
// Pin 9 - A Button                      Axis B   Col 1   Button2  Button2   USER_IN[6]
// Pin 7 - +5v
// Pin 8 - Gnd

//   0 = none
//   1 = 7800 joystick
//   2 = lightgun
//   3 = paddle
//   4 = trakball
//   5 = 2600 joystick
//   6 = 2600 driving
//   7 = 2600 keypad
//   8 = ST mouse
//   9 = Amiga mouse
wire [6:0] amiga_mouse = {st_mouse[6:5], st_mouse[0], st_mouse[2:1], st_mouse[3]};

logic [7:0] header_type0, header_type1;
always_comb begin
	case (joy0_type)
		0: header_type0 = 8'd0;
		1: header_type0 = 8'd1;
		2: header_type0 = 8'd2;
		3: header_type0 = 8'd3;
		4: header_type0 = 8'd4;
		5: header_type0 = 8'd1;
		6: header_type0 = 8'd6;
		7: header_type0 = 8'd5;
		8: header_type0 = 8'd7;
		9: header_type0 = 8'd8;
		default: header_type0 = 8'd0;
	endcase

	case (joy1_type)
		0: header_type1 = 8'd0;
		1: header_type1 = 8'd1;
		2: header_type1 = 8'd2;
		3: header_type1 = 8'd3;
		4: header_type1 = 8'd4;
		5: header_type1 = 8'd1;
		6: header_type1 = 8'd6;
		7: header_type1 = 8'd5;
		8: header_type1 = 8'd7;
		9: header_type1 = 8'd8;
		default: header_type1 = 8'd0;
	endcase

	is_snac0 = porta_type == snac_type;
	is_snac1 = portb_type == snac_type;
	USER_OUT = '1;
	if (is_snac0) begin
		{USER_OUT[6], USER_OUT[4], USER_OUT[3], USER_OUT[5], USER_OUT[0], USER_OUT[1]} = {iout[1:0], PAout[7:4]};
	end else if (is_snac1) begin
		{USER_OUT[6], USER_OUT[4], USER_OUT[3], USER_OUT[5], USER_OUT[0], USER_OUT[1]} = {iout[3:2], PAout[3:0]};
	end
	porta_type = |status[41:38] ? {4'd0, status[41:38] - 1'd1} : header_type0;
	portb_type = |status[45:42] ? {4'd0, status[45:42] - 1'd1} : header_type1;

	idump = {joyb[4], joyb[5], joya[4], joya[5]}; // P2 F1, P2 F2, P1 F1, P1 F2 or Analog
	PAin[7:4] = {~joya[0], ~joya[1], ~joya[2], ~joya[3]}; // P1: R L D U
	PAin[3:0] = {~joyb[0], ~joyb[1], ~joyb[2], ~joyb[3]}; // P2: R L D U
	ilatch[0] = ~(joya[4] || joya[5]); // P1 Fire
	ilatch[1] = ~(joyb[4] || joyb[5]); // P2 Fire

	case (porta_type)
		0: begin PAin[7:4] = 4'b1111; ilatch[0] = 1'b1; idump[1:0] = 2'b00; end
		2: if (~gun_port) begin PAin[7:4] = {3'b111, gun_trigger}; ilatch[0] = ~gun_sensor; idump[1:0] = 2'b00; end
		3: begin PAin[7:4] = {pad_b[1:0], 2'b11}; idump[1:0] = pad_wire[1:0]; ilatch[0] = 1'b1; end
		4: begin PAin[7:4] = trackball; ilatch[0] = ~trackball_button; idump[1:0] = 2'b00; end
		5: begin PAin[7:4] = PAout[7:4]; ilatch[0] = keypad0[6]; idump[1:0] = keypad0[5:4]; end
		6: begin PAin[7:4] = {2'b11, st_mouse[1:0]}; ilatch[0] = st_mouse[5]; idump[1:0] = 2'b00; end
		7: begin PAin[7:4] = st_mouse[3:0]; ilatch[0] = ~st_mouse[5]; idump[1:0] = st_mouse[6:5]; end
		8: begin PAin[7:4] = amiga_mouse[3:0]; ilatch[0] = ~amiga_mouse[5]; idump[1:0] = amiga_mouse[6:5]; end
		snac_type: begin PAin[7:4] = snac_pa_in; ilatch[0] = snac_il_in; idump[1:0] = snac_id_in[1:0]; end
		default: ;
	endcase

	case (portb_type)
		0: begin PAin[3:0] = 4'b1111; ilatch[1] = 1'b1; idump[3:2] = 2'b00; end
		2: if (gun_port) begin PAin[3:0] = {3'b111, gun_trigger}; ilatch[1] = ~gun_sensor; idump[3:2] = 2'b00; end
		3: begin PAin[3:0] = {pad_b[3:2], 2'b11}; idump[3:2] = pad_wire[3:2]; ilatch[1] = 1'b1; end
		4: if (porta_type != 4) begin PAin[3:0] = trackball; ilatch[1] = ~trackball_button; idump[3:2] = 2'b00; end
		5: begin PAin[3:0] = PAout[3:0]; ilatch[1] = keypad1[6]; idump[3:2] = keypad1[5:4]; end
		6: begin PAin[3:0] = {2'b11, st_mouse[1:0]}; ilatch[1] = st_mouse[5]; idump[3:2] = 2'b00; end
		7: begin PAin[3:0] = st_mouse[3:0]; ilatch[1] = ~st_mouse[5]; idump[3:2] = st_mouse[6:5]; end
		8: begin PAin[3:0] = amiga_mouse[3:0]; ilatch[1] = ~amiga_mouse[5]; idump[3:2] = amiga_mouse[6:5]; end
		snac_type: if (~is_snac0) begin PAin[3:0] = snac_pa_in; ilatch[1] = snac_il_in; idump[3:2] = snac_id_in[1:0]; end
		default: ;
	endcase

	// In two button mode, pin 6 is pulled up strongly, and won't lower
	// In one button mode, it will lower if *either* pin 5 or 9 are pressed
	if (joya_b2)
		ilatch[0] = 1;
	if (joyb_b2)
		ilatch[1] = 1;
end


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

always_comb begin
	arx = 0;
	ary = 0;
	if (~region_select) begin // NTSC
		if (~status[14]) begin // Show border
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
		if (~status[14]) begin // Show border
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

reg ce_pix_old;
assign ce_pix = ce_pix_raw & ~ce_pix_old;

always @(posedge CLK_VIDEO) begin : pix_edge_gen
	ce_pix_old <= ce_pix_raw;
end

video_mixer #(.LINE_LENGTH(372), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
(
	.*,

	.VGA_DE(vga_de),
	.hq2x(scale==1),
	.HSync(hs_cofi),
	.HBlank(hb_cofi),
	.VSync(vs_cofi),
	.VBlank(vb_cofi),

	.R((gun_en & gun_target) ? 8'd255 : r_cofi),
	.G((gun_en & gun_target) ? 8'd0 : g_cofi),
	.B((gun_en & gun_target) ? 8'd0 : b_cofi)
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

wire bk_load    = 0;
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


module lfsr(
	output [N-1:0] rnd
);

parameter N = 63;

lcell lc0(~(rnd[N - 1] ^ rnd[N - 3] ^ rnd[N - 4] ^ rnd[N - 6] ^ rnd[N - 10]), rnd[0]);
generate
	genvar i;
	for (i = 0; i <= N - 2; i = i + 1) begin : lcn
		lcell lc(rnd[i], rnd[i + 1]);
	end
endgenerate

endmodule
