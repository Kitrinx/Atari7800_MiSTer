`include "atari7800.vh"

`define OLD_TIA

module Atari7800(
input  logic       clock_25, sysclk_7_143, reset,
output logic [7:0] RED, GREEN, BLUE,
output logic       HSync, VSync, HBlank, VBlank,
output logic       ce_pix,

output logic [15:0] AUDIO,

output logic        cart_sel, bios_sel,
input  logic        cart_region,
input  logic [7:0]  cart_out, bios_out,
output logic [16:0] AB,
output logic [17:0] cart_addr_out,
input  logic [9:0]  cart_flags,
input  logic [31:0] cart_size,
output logic        RW,
output logic        pclk_0,
output logic        pclk_2,

input logic         loading,

output logic [7:0] ld,

// Tia inputs
input  logic [3:0] idump,
input  logic [1:0] ilatch,

output logic tia_en,

// Riot inputs
input logic [7:0] PAin, PBin,
output logic [7:0] PAout, PBout
);

	assign ld[5:1] = '0;
	assign ld[0] = lock_ctrl;
	assign cart_sel = cart_cs;
	assign bios_sel = bios_cs;
	assign ce_pix = tia_clk;

	assign bios_DB_out = bios_out;
//	assign cart_DB_out = cart_out;

	/////////////
	// Signals //
	/////////////

	// Clock Signals
	logic             tia_clk, sel_slow_clock, pokey_clock;


	// MARIA Signals
	logic                   m_int_b, maria_RDY;
	logic                   maria_rw;
	logic                   halt_b, maria_drive_AB;
	logic [7:0]             uv_maria, uv_tia;
	logic [15:0]            maria_AB_out;

	// TIA Signals
	logic hblank_tia, vblank_tia, aud0, aud1, tia_RDY;
	logic [3:0] audv0, audv1;
	logic [7:0] tia_db_out;
	logic [15:0] aud_signal_out;

	// RIOT Signals
	logic riot_RS_b;

	// 6502 Signals
	logic RDY, IRQ_n, CPU_NMI;
	logic [7:0] core_DB_out;
	logic [15:0] core_AB_out;

	logic cpu_reset, core_halt_b;
	logic [2:0] cpu_reset_counter;

	assign IRQ_n = 1'b1;

	//ctrl Signals
	logic maria_en, lock_ctrl, bios_en_b;
	logic [1:0] ctrl_writes;

	// Buses
	// AB and RW defined in port declaration
	logic [7:0] read_DB, write_DB;

	logic [7:0] tia_DB_out, riot_DB_out, maria_DB_out, ram0_DB_out, ram1_DB_out, bios_DB_out, cart_DB_out;

	`chipselect       CS_maria_buf, CS_core_buf, CS_buf, CS;

	logic dma_latch;
	logic [15:0] pokey_audio;

	always_ff @(posedge sysclk_7_143) begin
		if (reset)
			CS_buf <= `CS_NONE;
		else
			CS_buf <= CS;

		dma_latch <= maria_drive_AB;
	end

	wire dma_en = maria_drive_AB;


	//CS LOGIC
	logic ram0_cs, ram1_cs, bios_cs, tia_cs, riot_cs, cart_cs, riot_ram_cs;

	always_comb begin
		ram0_cs = 1'b0;
		ram1_cs = 1'b0;
		bios_cs = 1'b0;
		tia_cs = 1'b0;
		riot_cs = 1'b0;
		cart_cs = 1'b0;
		riot_ram_cs = 1'b0;
		casex (CS)
			`CS_RAM0: ram0_cs = 1'b1;
			`CS_RAM1: ram1_cs = 1'b1;
			`CS_BIOS: bios_cs = 1'b1;
			`CS_TIA: tia_cs = 1'b1;
			`CS_RIOT_IO: riot_cs = 1'b1;
			`CS_CART: cart_cs = 1'b1;
			`CS_RIOT_RAM: begin riot_cs = 1'b1; riot_ram_cs = 1'b1; end
			default: cart_cs = 0;
		endcase
	end

	always_comb begin
		// FIXME: this is super janky, find out why DMA needs a delayed cs
		casex (dma_en || dma_latch ? CS_buf : CS)
			`CS_RAM0: read_DB = ram0_DB_out;
			`CS_RAM1: read_DB = ram1_DB_out;
			`CS_RIOT_IO,
			`CS_RIOT_RAM: read_DB = riot_DB_out;
			`CS_TIA: read_DB = tia_DB_out;
			`CS_BIOS: read_DB = bios_DB_out;
			`CS_MARIA: read_DB = maria_DB_out;
			`CS_CART: read_DB = cart_DB_out;
			// Otherwise, nothing is driving the data bus. THIS SHOULD NEVER HAPPEN
			default: read_DB = 8'h46;
		endcase

		write_DB = core_DB_out;

		AB = dma_en ? maria_AB_out : core_AB_out;
		RW = dma_en ? 1'b1 : cpu_rwn;
	end

	// Memory
	logic [10:0] clear_addr;

	always_ff @(posedge sysclk_7_143) clear_addr <= clear_addr + loading;

	dpram_dc #(.widthad_a(11)) ram0
	(
		.clock_a(sysclk_7_143),
		.address_a(AB[10:0]),
		.data_a(write_DB),
		.wren_a(~RW & ram0_cs & pclk_2 & ~dma_latch),
		.q_a(ram0_DB_out),
		.byteena_a(~loading),

		.clock_b(sysclk_7_143),
		.address_b(clear_addr),
		.wren_b(loading)
	);

	dpram_dc #(.widthad_a(11)) ram1
	(
		.clock_a(sysclk_7_143),
		.address_a(AB[10:0]),
		.data_a(write_DB),
		.wren_a(~RW & ram1_cs & pclk_2 & ~dma_latch),
		.q_a(ram1_DB_out),
		.byteena_a(~loading),

		.clock_b(sysclk_7_143),
		.address_b(clear_addr),
		.wren_b(loading)
	);

	// Clock
	//assign pclk_2 = ~pclk_0;
	logic maria_vblank, maria_vsync, maria_hblank, maria_hsync;
	logic [3:0] maria_red, maria_green, maria_blue;

	// MARIA
	maria maria_inst(
		.AB_in           (AB),
		.AB_out          (maria_AB_out),
		.drive_AB        (maria_drive_AB),
		.read_DB_in      (read_DB),
		.write_DB_in     (write_DB),
		.DB_out          (maria_DB_out),
		.bios_en         (~bios_en_b),
		.reset_s         (reset),
		.sysclk          (sysclk_7_143),
		.pclk_2          (pclk_2),
		.sel_slow_clock  (sel_slow_clock),
		.tia_en          (tia_en),
		.tia_clk         (tia_clk),
		.pokey_clock     (pokey_clock),
		.pclk_0          (pclk_0),
		.CS              (CS),
		.RW              (RW),
		.enable          (maria_en),
		.UV_out          (uv_maria),
		.int_b           (m_int_b),
		.halt_b          (halt_b),
		.ready           (maria_RDY),
		.red             (maria_red),
		.green           (maria_green),
		.blue            (maria_blue),
		.vsync           (maria_vsync),
		.vblank          (maria_vblank),
		.hsync           (maria_hsync),
		.hblank          (maria_hblank)
	);

	logic tia_vblank, tia_vsync, tia_hblank, tia_blank_n, tia_hsync;
	logic [3:0] tia_color;
	logic [2:0] tia_luma;
	logic [7:0] tia_red, tia_green, tia_blue;

	// TIA
	`ifdef OLD_TIA

	tia tia_inst (
		.clk           (sysclk_7_143),
		.master_reset  (reset),
		.pix_ref       (),
		.sys_rst       (),
		.cpu_p0_ref    (),
		.cpu_p0_ref_180(),
		.ref_newline   (),
		.cpu_p0        (),
		.cpu_clk       (pclk_2),
		.cpu_cs0n      (~tia_cs),
		.cpu_cs1       (tia_cs),
		.cpu_cs2n      (~tia_cs),
		.cpu_cs3n      (~tia_cs),
		.cpu_rwn       (RW),
		.cpu_addr      ({(AB[5] & tia_en), AB[4:0]}),
		.cpu_din       (write_DB),
		.cpu_dout      (tia_DB_out),
		.cpu_rdy       (tia_RDY),
		.ctl_in        ({ilatch, idump}),
		.vid_csync     (),
		.vid_hsync     (tia_hsync),
		.vid_vsync     (tia_vsync),
		.vid_vblank    (tia_vblank),
		.vid_hblank    (tia_hblank),
		.vid_lum       (tia_luma),
		.vid_color     (tia_color),
		.vid_cb        (),
		.vid_blank_n   (tia_blank_n),
		.aud_ch0       (audv0),
		.aud_ch1       (audv1)
	);

`else

	TIA2 tia_inst
	(
		.clk(sysclk_7_143),
		.phi0(),
		.phi2(pclk_2),
		.RW_n(RW),
		.rdy(tia_RDY),
		.addr({(AB[5] & tia_en), AB[4:0]}),
		.d_in(write_DB),
		.d_out(tia_DB_out),
		.i(idump),     // On real hardware, these would be ADC pins. i0..3
		.i4(ilatch[0]),
		.i5(ilatch[1]),
		.aud0(audv0),
		.aud1(audv1),
		.col(),
		.lum(tia_luma),
		.BLK_n(),
		.sync(),
		.cs0_n(~tia_cs),
		.cs2_n(~tia_cs),
		.rst(reset),
		.ce(1),     // Clock enable for CLK generation only
		.video_ce(),
		.vblank(),
		.hblank(),
		.vsync(),
		.hsync(),
		.phi2_gen()
	);

	assign aud1 = 1;
	assign aud0 = 1;


`endif
	logic [23:0] stella_palette[128];
	assign stella_palette = '{
		24'h000000, 24'h4a4a4a, 24'h6f6f6f, 24'h8e8e8e,
		24'haaaaaa, 24'hc0c0c0, 24'hd6d6d6, 24'hececec,
		24'h484800, 24'h69690f, 24'h86861d, 24'ha2a22a,
		24'hbbbb35, 24'hd2d240, 24'he8e84a, 24'hfcfc54,
		24'h7c2c00, 24'h904811, 24'ha26221, 24'hb47a30,
		24'hc3903d, 24'hd2a44a, 24'hdfb755, 24'hecc860,
		24'h901c00, 24'ha33915, 24'hb55328, 24'hc66c3a,
		24'hd5824a, 24'he39759, 24'hf0aa67, 24'hfcbc74,
		24'h940000, 24'ha71a1a, 24'hb83232, 24'hc84848,
		24'hd65c5c, 24'he46f6f, 24'hf08080, 24'hfc9090,
		24'h840064, 24'h97197a, 24'ha8308f, 24'hb846a2,
		24'hc659b3, 24'hd46cc3, 24'he07cd2, 24'hec8ce0,
		24'h500084, 24'h68199a, 24'h7d30ad, 24'h9246c0,
		24'ha459d0, 24'hb56ce0, 24'hc57cee, 24'hd48cfc,
		24'h140090, 24'h331aa3, 24'h4e32b5, 24'h6848c6,
		24'h7f5cd5, 24'h956fe3, 24'ha980f0, 24'hbc90fc,
		24'h000094, 24'h181aa7, 24'h2d32b8, 24'h4248c8,
		24'h545cd6, 24'h656fe4, 24'h7580f0, 24'h8490fc,
		24'h001c88, 24'h183b9d, 24'h2d57b0, 24'h4272c2,
		24'h548ad2, 24'h65a0e1, 24'h75b5ef, 24'h84c8fc,
		24'h003064, 24'h185080, 24'h2d6d98, 24'h4288b0,
		24'h54a0c5, 24'h65b7d9, 24'h75cceb, 24'h84e0fc,
		24'h004030, 24'h18624e, 24'h2d8169, 24'h429e82,
		24'h54b899, 24'h65d1ae, 24'h75e7c2, 24'h84fcd4,
		24'h004400, 24'h1a661a, 24'h328432, 24'h48a048,
		24'h5cba5c, 24'h6fd26f, 24'h80e880, 24'h90fc90,
		24'h143c00, 24'h355f18, 24'h527e2d, 24'h6e9c42,
		24'h87b754, 24'h9ed065, 24'hb4e775, 24'hc8fc84,
		24'h303800, 24'h505916, 24'h6d762b, 24'h88923e,
		24'ha0ab4f, 24'hb7c25f, 24'hccd86e, 24'he0ec7c,
		24'h482c00, 24'h694d14, 24'h866a26, 24'ha28638,
		24'hbb9f47, 24'hd2b656, 24'he8cc63, 24'hfce070
	};

	wire [6:0] pal_index = {tia_color, tia_luma};

	assign {tia_red, tia_green, tia_blue} = stella_palette[pal_index];

	assign RED = maria_en ? {maria_red, maria_red} : tia_red;
	assign GREEN = maria_en ? {maria_green, maria_green} : tia_green;
	assign BLUE = maria_en ? {maria_blue, maria_blue} : tia_blue;
	assign VSync = maria_en ? maria_vsync : tia_vsync;
	assign VBlank = maria_en ? maria_vblank : tia_vblank;
	assign HSync = maria_en ? maria_hsync : tia_hsync;
	assign HBlank = maria_en ? maria_hblank : tia_hblank;

	logic [15:0] audio_lut[32];
	assign audio_lut = '{
		16'h0000, 16'h0842, 16'h0FFF, 16'h1745, 16'h1E1D, 16'h2492, 16'h2AAA, 16'h306E,
		16'h35E4, 16'h3B13, 16'h3FFF, 16'h44AE, 16'h4924, 16'h4D64, 16'h5173, 16'h5554,
		16'h590A, 16'h5C97, 16'h5FFF, 16'h6343, 16'h6665, 16'h6968, 16'h6C4D, 16'h6F17,
		16'h71C6, 16'h745C, 16'h76DA, 16'h7942, 16'h7B95, 16'h7DD3, 16'h7FFF, 16'hFFFF
	};

	wire [5:0] aud_index = audv0 + audv1;
	assign AUDIO = audio_lut[aud_index] + pokey_audio;

//RIOT
// RIOT riot_inst
// (
// 	.A(AB[6:0]),         // Address bus input
// 	.Din(write_DB),      // Data bus input
// 	.Dout(riot_DB_out),  // Data bus output
// 	.CS(riot_cs),        // Chip select input
// 	.CS_n(~riot_cs),     // Active low chip select input
// 	.R_W_n(RW),          // Active high read, active low write input
// 	.RS_n(~riot_ram_cs), // Active low rom select input
// 	.RES_n(~reset),      // Active low reset input
// 	.IRQ_n(),            // Active low interrupt output
// 	.CLK(pclk_2),        // Clock input
// 	.PAin(PAin),         // 8 bit port A input
// 	.PAout(PAout),       // 8 bit port A output
// 	.PBin(PBin),         // 8 bit port B input
// 	.PBout(PBout)        // 8 bit port B output
// );

M6532 #(.init_7800(1)) riot_inst_2
(
	.clk(pclk_2), // PHI 2
	.ce(1),  // Clock enable
	.res_n(~reset), // reset
	.addr(AB[6:0]), // Address
	.RW_n(RW), // 1 = read, 0 = write
	.d_in(write_DB),
	.d_out(riot_DB_out),
	.RS_n(~riot_ram_cs), // RAM select
	.IRQ_n(),
	.CS1(riot_cs), // Chip select 1, 1 = selected
	.CS2_n(~riot_cs),// Chip select 2, 0 = selected
	.PA_in(PAin),
	.PA_out(PAout),
	.PB_in(PBin),
	.PB_out(PBout)
);

//6502

assign RDY = maria_en ? maria_RDY : ((tia_en) ? tia_RDY : 1'b1);
assign core_halt_b = (ctrl_writes == 2'd2) ? halt_b : 1'b1;
assign CPU_NMI = ~m_int_b;

logic cpu_rwn;

M6502C cpu_inst
(
	.pclk_0(pclk_0),
	.pclk_2(pclk_2),
	.sysclk(sysclk_7_143),
	.reset(reset),
	.AB(core_AB_out),
	.DB_IN(read_DB),
	.DB_OUT(core_DB_out),
	.RD(cpu_rwn),
	.IRQ(~IRQ_n),
	.NMI(CPU_NMI),
	.RDY(RDY),
	.halt_b(core_halt_b)
);

assign ld[6] = tia_en;
assign ld[7] = maria_en;

ctrl_reg ctrl
(
	.clk(pclk_2),
	.lock_in(write_DB[0]),
	.maria_en_in(write_DB[1]),
	.bios_en_in(write_DB[2]),
	.tia_en_in(write_DB[3]),
	.latch_b(RW | ~tia_cs | lock_ctrl),
	.rst(reset),
	.lock_out(lock_ctrl),
	.maria_en_out(maria_en),
	.bios_en_out(bios_en_b),
	.tia_en_out(tia_en),
	.writes(ctrl_writes)
);

cart cart
(
	.maria_clock(sysclk_7_143),
	.clock(pclk_2),
	.pokey_clock(pokey_clock),
	.dma_read(dma_en),
	.reset(reset),
	.address_in(AB[15:0]),
	.din(write_DB),
	.rom_din(cart_out),
	.cart_flags(cart_flags),
	.cart_size(cart_size),
	.cart_cs(cart_cs),
	.rw(RW),
	.dout(cart_DB_out),
	.pokey_audio(pokey_audio),
	.rom_address(cart_addr_out)
);

endmodule

// The infamous hidden control register.
// Resides at $0000-001F when tia_en is low.
module ctrl_reg
(
	input logic clk, lock_in, maria_en_in, bios_en_in, tia_en_in, latch_b, rst,
	output logic lock_out, maria_en_out, bios_en_out, tia_en_out,
	output logic [1:0] writes
);

always_ff @(posedge clk, posedge rst) begin
	if (rst) begin
		lock_out <= 0;
		maria_en_out <= 0;
		bios_en_out <= 0;
		tia_en_out <= 0;
		writes <= 0;
	end
	else if (~latch_b) begin
		lock_out <= lock_in;
		maria_en_out <= maria_en_in;
		bios_en_out <= bios_en_in;
		tia_en_out <= tia_en_in;
		if (writes < 2'd2)
		writes <= writes + 1'b1;
	end
end
endmodule

module audio_xformer
(
	input [3:0] POKEY,
	input logic AUD0, AUD1, POKEY_EN,
	input logic [3:0] AUDV0, AUDV1,
	output logic [15:0] AUD_SIGNAL
);

logic [15:0] audio0,audio1;

assign AUD_SIGNAL = audio0 + audio1;

always_comb begin
	case (AUD0)
		1: audio0 = 16'h3FF * AUDV0;
		0: audio0 = 16'hFC00 * AUDV0;
	endcase
	case (AUD1)
		1: audio1 = 16'h3FF * AUDV1;
		0: audio1 = 16'hFC00 * AUDV1;
	endcase
end

endmodule

//`define OLD_CPU

module M6502C
(
	input pclk_0,           // CPU clock (Phi0)
	output pclk_2,           // Phi2
	input sysclk,           // MARIA Clock
	input reset,            // reset signal
	output [15:0] AB,       // address bus
	input  [7:0] DB_IN,     // data in,
	output [7:0] DB_OUT,    // data_out,
	output RD,              // read enable
	input IRQ,              // interrupt request
	input NMI,              // non-maskable interrupt request
	input RDY,              // Ready signal. Pauses CPU when RDY=0
	input halt_b            // halt!
);

logic res;
logic rdy_in;
logic WE_OUT;
logic WE, holding;
logic [7:0] DB_hold;
logic old_clk;

`ifdef OLD_CPU

cpu core
(
	.clk   (pclk_0),
	.reset (reset),
	.AB    (AB),
	.DI    (DB_hold),
	.DO    (DB_OUT),
	.WE    (WE_OUT),
	.IRQ   (IRQ),
	.NMI   (NMI),
	.RDY   (rdy_in),
	.res   (res)
);

assign RD = ~(WE & ~res & ~reset);
assign WE = WE_OUT & rdy_in;

assign DB_hold = (holding) ? DB_hold : DB_IN;

assign holding = ~rdy_in;

always_ff @(negedge clk, posedge reset)
	if (reset)
		rdy_in <= 1'b1;
	else if (halt_b & RDY)
		rdy_in <= 1'b1;
	else
		rdy_in <= 1'b0;

`else

wire cpu_ce = ~old_clk & pclk_0;
wire p2_ce = old_clk & ~pclk_0;
logic cpu_halt;
logic p2_halt;

assign pclk_2 = ~pclk_0 & ~p2_halt;

T65 cpu (
	.mode (0),
	.BCD_en(1),

	.Res_n(~reset),
	.Clk(pclk_0 && ~cpu_halt),
	.Enable(1),
	.Rdy(RDY),

	.IRQ_n(~IRQ),
	.NMI_n(~NMI),
	.R_W_n(WE_OUT),
	.A(AB),
	.DI(WE_OUT ? DB_IN : DB_OUT),
	.DO(DB_OUT)
);


always @(posedge sysclk) begin
	old_clk <= pclk_0;
	if (p2_ce && ~halt_b)
		cpu_halt <= 1;

	if (p2_ce && halt_b)
		cpu_halt <= 0;
	
	if (cpu_ce && cpu_halt)
		p2_halt <= 1;

	if (cpu_ce && ~cpu_halt)
		p2_halt <= 0;

	if (reset) begin
		cpu_halt <= 0;
		p2_halt <= 0;
		old_clk <= 0;
	end
end

assign RD = WE_OUT | cpu_halt;

`endif


endmodule: M6502C
