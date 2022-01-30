// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.

module Atari7800(
	input  logic        clk_sys,
	input  logic        reset,
	input  logic        pause,
	output logic  [7:0] RED,
	output logic  [7:0] GREEN,
	output logic  [7:0] BLUE,
	output logic        HSync,
	output logic        VSync,
	output logic        HBlank,
	output logic        VBlank,
	output logic        ce_pix,
	input  logic        PAL,
	input  logic [1:0]  pal_temp,
	input  logic        hsc_en,
	output logic        hsc_ram_cs,
	input  logic  [7:0] hsc_ram_dout,
	output logic  [7:0] dout,
	output logic        cpu_ce,

	output logic [15:0] AUDIO_R,
	output logic [15:0] AUDIO_L,
	input logic         show_border,
	input logic         show_overscan,
	input logic         bypass_bios,
	input logic         tia_mode,
	input logic         cpu_driver,

	input  logic [7:0]  cart_xm,
	output logic        cart_read,
	input  logic [7:0]  cart_out, bios_out,
	output logic [15:0] AB,
	output logic [24:0] cart_addr_out,
	input  logic [15:0] cart_flags,
	input  logic  [7:0] cart_save,
	input  logic [31:0] cart_size,
	output logic  [7:0] cart_din,
	output logic        RW,
	input  logic        loading,
	
	output       [17:0] cartram_addr,
	output              cartram_wr,
	output              cartram_rd,
	output       [7:0]  cartram_wrdata,
	input        [7:0]  cartram_data,

	// Tia inputs
	input  logic  [3:0] idump,
	output logic  [3:0] i_out,
	input  logic  [1:0] ilatch,
	input  logic        tia_stab,
	output logic        tia_f1,
	output logic        tia_pal,
	output logic        tia_en,

	// Riot inputs
	input  logic  [7:0] PAin,
	input  logic  [7:0] PBin,
	output logic  [7:0] PAout,
	output logic  [7:0] PBout,
	output logic        PAread,

	// 2600 Cart force flags based on detection
	input logic [4:0]  force_bs,
	input logic        sc,
	input logic [7:0]  clearval,
	input logic [7:0]  random,
	input logic [1:0]  tape_in,
	output logic       tia_hsync,
	input  logic       use_stereo,
	input [10:0]       ps2_key,
	input              pokey_irq,
	input              decomb,
	input [4:0]        mapper,
	input              pal_load,
	input [9:0]        pal_addr,
	input              pal_wr,
	input [7:0]        pal_data,
	input              blend,
	input              ar_control,
	output [3:0]       i_read
);

	/////////////
	// Signals //
	/////////////

	logic           NMI_n;
	logic           maria_RDY;
	logic           halt_n;
	logic           maria_drive_AB;
	logic [15:0]    maria_AB_out;
	logic           tia_RDY;
	logic [3:0]     audv0, audv1;
	logic [7:0]     tia_db_out;
	logic           RDY;
	logic           IRQ_n;
	logic [15:0]    cpu_AB;
	logic           cpu_halt_n;
	logic           cpu_released;
	logic           maria_en;
	logic           lock_ctrl;
	logic           bios_en_b;
	logic [1:0]     ctrl_writes;
	logic [7:0]     read_DB;
	logic [7:0]     write_DB;
	logic [7:0]     tia_DB_out, riot_DB_out, maria_DB_out, ram0_DB_out, ram1_DB_out, cart_DB_out;
	logic [15:0]    pokey_audio_r, pokey_audio_l, ym_audio_r, ym_audio_l;
	logic           mclk0;
	logic           mclk1;
	logic           cs_ram0, cs_ram1, cs_tia, cs_riot, cs_maria;
	logic [7:0]     open_bus;
	wire            cart_read_flag;
	logic [24:0]    cart_2600_addr_out, cart_7800_addr_out;
	logic [7:0]     cart_2600_DB_out, cart_7800_DB_out;
	logic           cpu_rwn;
	logic [15:0]    covox_r, covox_l;
	logic [15:0]    last_address;
	logic           pclk1, pclk0, pclk1_m, pclk0_m, pclk1_t, pclk0_t;
	logic           tia_clk_x2;
	logic           read_2600;
	logic [1:0]     pause_clock;
	logic [17:0]    cartram_addr78, cartram_addr26;
	logic           cartram_wr78, cartram_wr26;
	logic [7:0]     cartram_wrdata78, cartram_wrdata26;
	logic           cartram_rd78, cartram_rd26;
	logic [7:0]     cartram_data_bram;

	assign RDY = maria_RDY && tia_RDY;
	assign cpu_halt_n = (ctrl_writes == 2'd2) ? halt_n : 1'b1;
	assign cart_read = tia_en ? (pause ? ~|pause_clock : read_2600) : ((pause ? pause_clock[0] : (cart_read_flag & mclk1)));
	assign cart_addr_out = tia_en ? cart_2600_addr_out : cart_7800_addr_out;
	assign cart_DB_out = tia_en ? cart_2600_DB_out : cart_7800_DB_out;
	assign PAread = cs_riot && ~|AB[4:0] && RW && pclk0;
	assign cpu_ce = pclk1;

	// Track the open bus since FPGA's don't use bidirectional logic internally
	always_ff @(posedge clk_sys) begin
		pause_clock <= pause ? pause_clock + 1'd1 : {1'b0, mclk1};
		open_bus <= (~RW ? write_DB : read_DB);
		last_address <= AB;
	end

	wire cs_cart = ~|{cs_ram0, cs_ram1, cs_tia, cs_riot, cs_maria};

	always_comb begin
		read_DB = open_bus;
		if (cs_ram0)  read_DB = ram0_DB_out;
		if (cs_ram1)  read_DB = ram1_DB_out;
		if (cs_tia)   read_DB = {tia_DB_out[7:6], open_bus[5:0]};
		if (cs_riot)  read_DB = riot_DB_out;
		if (cs_cart)  read_DB = (~bios_en_b && AB[15]) ? bios_out : cart_DB_out;
		if (cs_maria) read_DB = maria_DB_out;

		case ({~cpu_released, maria_drive_AB})
			2'b00 : AB = last_address;
			2'b01 : AB = maria_AB_out;
			2'b10 : AB = cpu_AB;
			2'b11 : AB = cpu_AB & maria_AB_out;
		endcase
		RW = cpu_released ? 1'b1 : cpu_rwn;
		
		if (cpu_driver && tia_en) begin
			pclk0 = pclk0_t;
			pclk1 = pclk1_t;
		end else begin
			pclk0 = pclk0_m;
			pclk1 = pclk1_m;
		end
	end

	assign dout = write_DB;

	// Memory
	logic [10:0] clear_addr;
	always_ff @(posedge clk_sys) clear_addr <= clear_addr + loading;

	spram #(.addr_width(11), .mem_name("RAM0")) ram0
	(
		.clock          (clk_sys),
		.address        (loading ? clear_addr : AB[10:0]),
		.data           (loading ? clearval : write_DB),
		.wren           ((~RW & cs_ram0 & pclk0) || loading),
		.q              (ram0_DB_out),
		.cs             (~pause)
	);

	spram #(.addr_width(11), .mem_name("RAM1")) ram1
	(
		.clock          (clk_sys),
		.address        (loading ? clear_addr : AB[10:0]),
		.data           (loading ? clearval : write_DB),
		.wren           ((~RW & cs_ram1 & pclk0) || loading),
		.q              (ram1_DB_out),
		.cs             (~pause)
	);

	// MARIA
	logic maria_vblank, maria_vblank_ex, maria_vsync, maria_hblank, maria_hsync;
	logic [3:0] maria_luma, maria_chroma;

	maria maria_inst(
		.ce             (~pause),
		.mclk0          (mclk0),
		.mclk1          (mclk1),
		.tia_clk_x2     (tia_clk_x2),
		.AB_in          (AB),
		.AB_out         (maria_AB_out),
		.drive_AB       (maria_drive_AB),
		.hide_border    (~show_border),
		.bypass_bios    (bypass_bios),
		.PAL            (PAL),
		.d_in           (read_DB),
		.write_DB_in    (write_DB),
		.DB_out         (maria_DB_out),
		.reset          (reset),
		.clk_sys        (clk_sys),
		.pclk0          (pclk0_m),
		.pclk1          (pclk1_m),
		.pclk2          (pclk0_m),
		.RW             (RW),
		.maria_en       (maria_en),
		.YC             ({maria_chroma, maria_luma}),
		.cs_ram0        (cs_ram0),
		.cs_ram1        (cs_ram1),
		.cs_riot        (cs_riot),
		.cs_tia         (cs_tia),
		.cs_maria       (cs_maria),
		.NMI_n          (NMI_n),
		.halt_n         (halt_n),
		.ready          (maria_RDY),
		.vsync          (maria_vsync),
		.vblank         (maria_vblank),
		.vblank_ex      (maria_vblank_ex),
		.hsync          (maria_hsync),
		.hblank         (maria_hblank)
	);

	logic tia_vblank, tia_vsync, tia_hblank, tia_blank_n;
	logic [3:0] tia_chroma;
	logic [2:0] tia_luma;
	logic tia_pix_ce;
	logic cart_ce_2600;

	TIA tia_inst
	(
		.clk            (clk_sys),
		.ce             (tia_clk_x2),     // Clock enable for CLK generation only
		.is_7800        (~(cpu_driver && tia_en)),
		.phi0           (pclk0_t),
		.phi1           (pclk1_t),
		.phi2           (pclk0),
		.RW_n           (RW),
		.rdy            (tia_RDY),
		.addr           ({(AB[5] & tia_en), AB[4:0]}),
		.d_in           (write_DB),
		.d_out          (tia_DB_out),
		.i              (idump),     // On real hardware, these would be ADC pins. i0..3
		.i_out          (i_out),
		.i4             (ilatch[0]),
		.i5             (ilatch[1]),
		.aud0           (audv0),
		.aud1           (audv1),
		.col            (tia_chroma),
		.lum            (tia_luma),
		.BLK_n          (tia_blank_n),
		.sync           (),
		.cs0_n          (~cs_tia),
		.cs2_n          (~cs_tia),
		.rst            (reset),
		.video_ce       (tia_pix_ce),
		.vblank         (tia_vblank),
		.hblank         (),
		.hgap           (tia_hblank),
		.vsync          (tia_vsync),
		.hsync          (tia_hsync),
		.phi1_in        (pclk1),
		.open_bus       (open_bus),
		.cart_ce        (cart_ce_2600),
		.decomb         (decomb),
		.is_pal         (tia_pal),
		.stabilize      (tia_stab),
		.is_f1          (tia_f1),
		.paddle_read    (i_read)
	);

	video_mux mux
	(
		.clk_sys        (clk_sys),
		.maria_luma     (maria_luma),
		.maria_chroma   (maria_chroma),
		.maria_hblank   (maria_hblank),
		.maria_vblank   (show_overscan ? maria_vblank : maria_vblank_ex),
		.maria_hsync    (maria_hsync),
		.maria_vsync    (maria_vsync),
		.maria_pix_ce   (mclk1),
		.tia_luma       (tia_luma),
		.tia_chroma     (tia_chroma),
		.tia_hblank     (tia_hblank),
		.tia_vblank     (tia_vblank),
		.tia_hsync      (tia_hsync),
		.tia_vsync      (tia_vsync),
		.tia_pix_ce     (tia_pix_ce),
		.is_maria       (maria_en),
		.pal_temp       (pal_temp),
		.pal_load       (pal_load),
		.pal_data       (pal_data),
		.pal_addr       (pal_addr),
		.pal_wr         (pal_wr),
		.is_PAL         (PAL),
		.hblank         (HBlank),
		.vblank         (VBlank),
		.hsync          (HSync),
		.vsync          (VSync),
		.red            (RED),
		.green          (GREEN),
		.blue           (BLUE),
		.pix_ce         (ce_pix),
		.blend          (blend)
	);

	// Audio output is non-linear, and this table represents the proper compressed values of
	// audv0 + audv1.
	// Generated based on the info here:
	// https://atariage.com/forums/topic/271920-tia-sound-abnormalities/
	logic [15:0] audio_lut[32];
	assign audio_lut = '{
		16'h0000, 16'h0842, 16'h0FFF, 16'h1745, 16'h1E1D, 16'h2492, 16'h2AAA, 16'h306E,
		16'h35E4, 16'h3B13, 16'h3FFF, 16'h44AE, 16'h4924, 16'h4D64, 16'h5173, 16'h5554,
		16'h590A, 16'h5C97, 16'h5FFF, 16'h6343, 16'h6665, 16'h6968, 16'h6C4D, 16'h6F17,
		16'h71C6, 16'h745C, 16'h76DA, 16'h7942, 16'h7B95, 16'h7DD3, 16'h7FFF, 16'hFFFF
	};

	logic [15:0] audio_lut_single[16];
	assign audio_lut_single = '{
		16'h0000, 16'h0C63, 16'h17FF, 16'h22E8, 16'h2D2C, 16'h36DB, 16'h3FFF, 16'h48A5,
		16'h50D6, 16'h589C, 16'h5FFF, 16'h6705, 16'h6DB6, 16'h7416, 16'h7A2D, 16'h7FFF
	};

	logic tape_audio;

	wire [5:0] aud_index = audv0 + audv1;
	wire [15:0] tia_r = (use_stereo ? audio_lut_single[audv0] : audio_lut[aud_index]);
	wire [15:0] tia_l = (use_stereo ? audio_lut_single[audv1] : audio_lut[aud_index]);

	assign AUDIO_R = tia_r + pokey_audio_r + ym_audio_r + covox_r + {tape_audio, 12'd0};
	assign AUDIO_L = tia_l + pokey_audio_l + ym_audio_l + covox_l + {tape_audio, 12'd0};

	logic [7:0] ar_ram_addr;
	M6532 #(.init_7800(1)) riot_inst
	(
		.clk          (clk_sys),
		.ce           (pclk0),     // PHI 2 Clock enable
		.res_n        (~reset),
		.addr         (AB[6:0]),
		.RW_n         (RW),
		.d_in         (write_DB),
		.d_out        (riot_DB_out),
		.RS_n         (AB[9]),
		.IRQ_n        (),
		.CS1          (AB[7]),
		.CS2_n        (~cs_riot),
		.PA_in        (PAin),
		.PA_out       (PAout),
		.PB_in        (PBin),
		.PB_out       (PBout)
	);

	M6502C cpu_inst
	(
		.pclk1        (pclk1),
		.clk_sys      (clk_sys),
		.reset        (reset),
		.AB           (cpu_AB),
		.DB_IN        (read_DB),
		.DB_OUT       (write_DB),
		.RD           (cpu_rwn),
		.IRQ_n        (IRQ_n),
		.NMI_n        (NMI_n),
		.RDY          (RDY),
		.halt_n       (cpu_halt_n),
		.is_halted    (cpu_released)
	);


	ctrl_reg ctrl
	(
		.clk          (clk_sys),
		.pclk0        (pclk0),
		.d_in         (write_DB[3:0]),
		.cs           (cs_tia),
		.latch_b      (RW | lock_ctrl),
		.rst          (reset),
		.lock_out     (lock_ctrl),
		.bypass_bios  (bypass_bios),
		.maria_en_out (maria_en),
		.bios_en_out  (bios_en_b),
		.tia_en_out   (tia_en),
		.writes       (ctrl_writes),
		.tia_mode     (tia_mode)
	);

	assign cartram_wr = tia_en ? cartram_wr26 : cartram_wr78;
	assign cartram_rd = tia_en ? cartram_rd26 : cartram_rd78;
	assign cartram_addr = tia_en ? cartram_addr26 : cartram_addr78;
	assign cartram_wrdata = tia_en ? cartram_wrdata26 : cartram_wrdata78;

	logic [16:0] reset_addr; // Clear ram while reset is held
	always @(posedge clk_sys) begin :reset_cart
		logic old_reset;
		old_reset <= reset;
		reset_addr <= (reset && ~old_reset) ? 16'd0 : reset_addr + 1'd1;
	end

	spram #(.addr_width(17), .mem_name("CART")) cart_ram
	(
		.clock   (clk_sys),
		.address (reset ? reset_addr : cartram_addr),
		.data    (reset ? 8'd0 : cartram_wrdata),
		.wren    (reset ? 1'd1 : cartram_wr),
		.q       (cartram_data_bram),
		.cs      (~pause)
	);

	cart cart
	(
		.clk_sys        (clk_sys),
		.pclk0          (pclk0),
		.pclk1          (pclk1),
		.IRQ_n          (IRQ_n),
		.halt_n         (cpu_halt_n),
		.reset          (reset),
		.address_in     (AB[15:0]),
		.din            (write_DB),
		.rom_din        (cart_out),
		.cart_flags     (cart_flags),
		.cart_size      (cart_size),
		.cart_save      (cart_save),
		.cart_cs        (cs_cart),
		.cart_xm        (cart_xm),
		.cart_read      (cart_read_flag),
		.cartram_addr   (cartram_addr78),
		.cartram_wr     (cartram_wr78),
		.cartram_rd     (cartram_rd78),
		.cartram_wrdata (cartram_wrdata78),
		.cartram_data   (cartram_data_bram),
		.hsc_en         (hsc_en),
		.hsc_ram_cs     (hsc_ram_cs),
		.hsc_ram_din    (hsc_ram_dout),
		.rw             (RW),
		.dout           (cart_7800_DB_out),
		.pokey_audio_r  (pokey_audio_r),
		.pokey_audio_l  (pokey_audio_l),
		.ym_audio_r     (ym_audio_r),
		.ym_audio_l     (ym_audio_l),
		.rom_address    (cart_7800_addr_out),
		.open_bus       (open_bus),
		.covox_r        (covox_r),
		.covox_l        (covox_l),
		.ps2_key        (ps2_key),
		.pokey_irq_en   (pokey_irq)
	);

	assign cart_2600_addr_out[24:19] = '0;
	assign cart_din = cpu_rwn ? read_DB : write_DB;

	cart2600 cart2600
	(
		.d_out          (cart_2600_DB_out),
		.d_in           (cart_din),
		.a_in           (AB[12:0]),
		.reset          (reset),
		.clk            (clk_sys),
		.ce             (cart_ce_2600),
		.phi1           (pclk1),
		.sc             (sc),
		.mapper         (|mapper ? mapper : force_bs),
		.rom_do         (cart_out),
		.rom_size       (cart_size),
		.rom_a          (cart_2600_addr_out[18:0]),
		.rom_read       (read_2600),
		.cartram_addr   (cartram_addr26),
		.cartram_wr     (cartram_wr26),
		.cartram_rd     (cartram_rd26),
		.cartram_wrdata (cartram_wrdata26),
		.cartram_data   (cartram_data_bram),
		.oe             (),
		.open_bus       (open_bus),
		.tape_in        (tape_in),
		.tape_audio     (tape_audio)
	);

endmodule

// INPUTCTRL register. Uses TIA CS.
module ctrl_reg
(
	input  logic       clk,
	input  logic       latch_b,
	input  logic       rst,
	input  logic [3:0] d_in,
	input  logic       cs,
	input  logic       bypass_bios,
	input  logic       tia_mode,
	input  logic       pclk0,
	output logic       lock_out,
	output logic       maria_en_out,
	output logic       bios_en_out,
	output logic       tia_en_out,
	output logic [1:0] writes
);

	always_ff @(posedge clk) begin
		reg wrote_once;
		if (rst) begin
			lock_out <= 0;
			maria_en_out <= 0;
			bios_en_out <= 0;
			tia_en_out <= 0;
			wrote_once <= 0;
			writes <= 0;
		end else if (bypass_bios && ~wrote_once) begin
			lock_out <= tia_mode ? 1'd1 : 1'd0;
			maria_en_out <= tia_mode ? 1'd0 : 1'd1;
			bios_en_out <= 1;
			wrote_once <= 1;
			tia_en_out <= tia_mode ? 1'd1 : 1'd0;
			writes <= 2'd2;
		end else if (~latch_b && cs && pclk0) begin
			wrote_once <= 1;
			lock_out <= d_in[0];
			maria_en_out <= d_in[1];
			bios_en_out <= d_in[2];
			tia_en_out <= d_in[3];
			if (writes < 2'd2)
				writes <= writes + 1'b1;
		end
	end
endmodule

module M6502C
(
	input         pclk1,     // CPU clock (Phi1)
	input         clk_sys,   // MARIA Clock
	input         reset,     // reset signal
	input  [7:0]  DB_IN,     // data in,
	input         IRQ_n,     // interrupt request
	input         NMI_n,     // non-maskable interrupt request
	input         RDY,       // Ready signal. Pauses CPU when RDY=0
	input         halt_n,    // halt!
	output [15:0] AB,        // address bus
	output [7:0]  DB_OUT,    // data_out,
	output        RD,        // read enable
	output        is_halted  // This is used to indicate that sally has released the bus
);

	logic cpu_halt_n = 1;
	logic rdy_delay = 1;
	
	T65 cpu (
		.mode (0),
		.BCD_en(1),

		.Res_n(~reset),
		.Clk(clk_sys),
		.Enable(pclk1 && cpu_halt_n),
		.Rdy(rdy_delay),

		.IRQ_n(IRQ_n),
		.NMI_n(NMI_n),
		.R_W_n(RD),
		.A(AB),
		.DI(RD ? DB_IN : DB_OUT),
		.DO(DB_OUT)
	);

	always @(posedge clk_sys) begin
		is_halted <= ~cpu_halt_n;
		if (reset) begin
			is_halted <= 0;
			cpu_halt_n <= 1;
			rdy_delay <= 1;
		end else if (pclk1) begin
			cpu_halt_n <= halt_n;
			rdy_delay <= RDY;
		end
	end

endmodule: M6502C
