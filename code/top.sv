`timescale 1ns / 1ps
`include "atari7800.vh"


module Atari7800(
input  logic       clock_25, sysclk_7_143, reset, locked,
output logic [3:0] RED, GREEN, BLUE,
output logic       HSync, VSync, HBlank, VBlank,
output logic       ce_pix,

output logic [15:0] AUDIO,

output logic        cart_sel, bios_sel, memclk_o,
input  logic        cart_region,
input  logic [7:0]  cart_out, bios_out,
output logic [16:0] AB,
output logic [17:0] cart_addr_out,
input  logic [9:0]  cart_flags,
input  logic [31:0] cart_size,
output logic        RW,
output logic        pclk_0,

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

	assign ld[0] = lock_ctrl;
	assign cart_sel = cart_cs;
	assign bios_sel = bios_cs;
	assign clock_divider_locked = locked;
	assign ce_pix = tia_clk;

	assign bios_DB_out = bios_out;
//	assign cart_DB_out = cart_out;

	/////////////
	// Signals //
	/////////////

	// Clock Signals
	logic             pclk_2, tia_clk, sel_slow_clock;
	logic             clock_divider_locked;

	// VGA Signals
	logic [9:0]             vga_row, vga_col;
	logic tia_hsync, tia_vsync, vga_hsync, vga_vsync;

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

	logic cpu_reset, core_halt_b, core_latch_data;
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

	logic memclk;
	assign memclk = (~halt_b & maria_drive_AB) ? sysclk_7_143 : pclk_0;
	assign memclk_o = memclk;

	always_ff @(posedge memclk, posedge reset)
		if (reset)
		CS_buf <= `CS_NONE;
		else
		CS_buf <= CS;


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
		endcase
	end

	always_comb begin
		casex (CS_buf)
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

		AB = (maria_drive_AB) ? maria_AB_out : core_AB_out;
	end

	// Memory
	logic [10:0] clear_addr;

	always_ff @(posedge memclk) clear_addr <= clear_addr + loading;

	dpram_dc #(.widthad_a(11)) ram0
	(
		.clock_a(memclk),
		.address_a(AB[10:0]),
		.data_a(write_DB),
		.wren_a(~RW & ram0_cs),
		.q_a(ram0_DB_out),
		.byteena_a(~loading),

		.clock_b(sysclk_7_143),
		.address_b(clear_addr),
		.wren_b(loading)
	);

	dpram_dc #(.widthad_a(11)) ram1
	(
		.clock_a(memclk),
		.address_a(AB[10:0]),
		.data_a(write_DB),
		.wren_a(~RW & ram1_cs),
		.q_a(ram1_DB_out),
		.byteena_a(~loading),

		.clock_b(sysclk_7_143),
		.address_b(clear_addr),
		.wren_b(loading)
	);

	// Clock
	assign pclk_2 = ~pclk_0;

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
		.core_latch_data (core_latch_data),
		.tia_en          (tia_en),
		.tia_clk         (tia_clk),
		.pclk_0          (pclk_0),
		.CS              (CS),
		.RW              (RW),
		.enable          (maria_en),
		.UV_out          (uv_maria),
		.int_b           (m_int_b),
		.halt_b          (halt_b),
		.ready           (maria_RDY),
		.red             (RED),
		.green           (GREEN),
		.blue            (BLUE),
		.vsync           (VSync),
		.vblank          (VBlank),
		.hsync           (HSync),
		.hblank          (HBlank)
	);

	// TIA
	TIA tia_inst(
		.A({(AB[5] & tia_en), AB[4:0]}), // Address bus input
		.Din(write_DB),                  // Data bus input
		.Dout(tia_DB_out),               // Data bus output
		.CS_n({2'b0,~tia_cs}),           // Active low chip select input
		.CS(tia_cs),                     // Chip select input
		.R_W_n(RW),                      // Active low read/write input
		.RDY(tia_RDY),                   // CPU ready output
		.MASTERCLK(tia_clk),             // 3.58 Mhz pixel clock input
		.CLK2(pclk_0),                   // 1.19 Mhz bus clock input
		.idump_in(idump),                // Dumped I/O
		.Ilatch(ilatch),                 // Latched I/O
		.HSYNC(tia_hsync),               // Video horizontal sync output
		.HBLANK(hblank_tia),             // Video horizontal blank output
		.VSYNC(tia_vsync),               // Video vertical sync output
		.VBLANK(vblank_tia),             // Video vertical sync output
		.COLOROUT(uv_tia),               // Indexed color output
		.RES_n(~reset),                  // Active low reset input
		.AUD0(aud0),                     //audio pin 0
		.AUD1(aud1),                     //audio pin 1
		.audv0(audv0),                   //audio volume for use with external xformer module
		.audv1(audv1)                    //audio volume for use with external xformer module
	);

	audio_xformer audio_xformer
	(
		.POKEY(),
		.AUD0(aud0),
		.AUD1(aud1),
		.AUDV0(audv0),
		.AUDV1(audv1),
		.AUD_SIGNAL(AUDIO)
	);

//RIOT
RIOT riot_inst
(
	.A(AB[6:0]),         // Address bus input
	.Din(write_DB),      // Data bus input
	.Dout(riot_DB_out),  // Data bus output
	.CS(riot_cs),        // Chip select input
	.CS_n(~riot_cs),     // Active low chip select input
	.R_W_n(RW),          // Active high read, active low write input
	.RS_n(~riot_ram_cs), // Active low rom select input
	.RES_n(~reset),      // Active low reset input
	.IRQ_n(),            // Active low interrupt output
	.CLK(pclk_0),        // Clock input
	.PAin(PAin),         // 8 bit port A input
	.PAout(PAout),       // 8 bit port A output
	.PBin(PBin),         // 8 bit port B input
	.PBout(PBout)        // 8 bit port B output
);

//6502
assign cpu_reset = cpu_reset_counter != 3'b111;

always_ff @(posedge pclk_0, posedge reset) begin
	if (reset) begin
		cpu_reset_counter <= 3'b0;
	end else begin
		if (cpu_reset_counter != 3'b111)
			cpu_reset_counter <= cpu_reset_counter + 3'b001;
	end
end

assign RDY = maria_en ? maria_RDY : ((tia_en) ? tia_RDY : clock_divider_locked);
assign core_halt_b = (ctrl_writes == 2'd2) ? halt_b : 1'b1;
assign CPU_NMI = (lock_ctrl) ? (~m_int_b) : (~m_int_b & ~bios_en_b);


M6502C cpu_inst
(
	.clk(pclk_0),
	.sysclk(sysclk_7_143),
	.reset(cpu_reset),
	.AB(core_AB_out),
	.DB_IN(read_DB),
	.DB_OUT(core_DB_out),
	.RD(RW),
	.IRQ(~IRQ_n),
	.NMI(CPU_NMI),
	.RDY(RDY),
	.halt_b(core_halt_b),
	.latch_data(core_latch_data)
);

assign ld[6] = tia_en;
assign ld[7] = maria_en;

ctrl_reg ctrl
(
	.clk(pclk_0),
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
	.clock(pclk_0),
	.clock100(),
	.pclk_2(pclk_2),
	.reset(reset),
	.address_in(AB[15:0]),
	.din(write_DB),
	.rom_din(cart_out),
	.cart_flags(cart_flags),
	.cart_size(cart_size),
	.cart_cs(cart_cs),
	.rw(RW),
	.dout(cart_DB_out),
	.pokey_audio(),
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

module M6502C
(
	input clk,              // CPU clock
	input sysclk,           // MARIA Clock
	input reset,            // reset signal
	output [15:0] AB,       // address bus
	input  [7:0] DB_IN,     // data in,
	output [7:0] DB_OUT,    // data_out,
	output RD,              // read enable
	input IRQ,              // interrupt request
	input NMI,              // non-maskable interrupt request
	input RDY,              // Ready signal. Pauses CPU when RDY=0
	input halt_b,           // halt!
	input latch_data        // ???
);

logic res;
logic rdy_in;
logic WE_OUT;
logic WE, holding;
logic [7:0] DB_hold;
logic old_clk;

cpu core
(
	.clk   (clk),
	.reset (reset),
	.AB    (AB2),
	.DI    (DB_hold),
	.DO    (DB_OUT2),
	.WE    (WE_OUT2),
	.IRQ   (IRQ),
	.NMI   (NMI),
	.RDY   (rdy_in),
	.res   (res)
);

logic [15:0] AB2;
wire [7:0] DB_OUT2;
logic WE_OUT2;

T65 cpu (
	.mode (0),
	.BCD_en(1),

	.Res_n(~reset),
	.Clk(sysclk),
	.Enable((~old_clk & clk) & halt_b),
	.Rdy(rdy_in),

	.IRQ_n(~IRQ),
	.NMI_n(~NMI),
	.R_W_n(WE_OUT),
	.A(AB),
	.DI(R_W_n ? DB_hold : DB_OUT),
	.DO(DB_OUT)
);

// The purpose of res appears to be to align Maria to the reset vector
// always @(posedge sysclk)
// 	if (reset)
// 		res <= 1;
// 	else if (AB == 16'hFFFD)
// 		res <= 0;

always @(posedge sysclk)
	old_clk <= clk;

assign RD = ~(WE & ~res & ~reset);
assign WE = ~WE_OUT & rdy_in;// & ~latch_data;

assign DB_hold = (holding) ? DB_hold : DB_IN;

assign holding = ~rdy_in;

always_ff @(negedge clk, posedge reset)
	if (reset)
		rdy_in <= 1'b1;
	else if (halt_b & RDY)
		rdy_in <= 1'b1;
	else
		rdy_in <= 1'b0;

endmodule: M6502C
