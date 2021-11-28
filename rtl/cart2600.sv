// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.

module cart2600
(
	// Physical Pins
	output   [7:0]  d_out, // Data bus
	input    [7:0]  d_in,  // Data bus
	input    [12:0] a_in,  // Address bus

	// Helpers
	input           clk,        // Master Clock
	input           reset,      // System warm reset
	input           ce,         // Original system clock enable (~3.579mhz) used to divide into crystals
	input           phi1,       // CPU Phase 1 Signal (used for FE to catch data at the right moment)
	output   [7:0]  oe,         // Output Enable mask
	input    [7:0]  open_bus,   // Input open bus to use when not driving data bus (Obselete, use oe)

	// Autodetect info
	input           sc,         // Superchip Enable
	input    [4:0]  mapper,     // Bankswitching type (ie Mapper)
	
	// SDRAM ROM storage interface
	input    [7:0]  rom_do,     // Incoming ROM data from the sdram
	input   [18:0]  rom_size,   // Full rom size for address masking
	output  [18:0]  rom_a,      // Outgoing absolute rom address for image.
	output          rom_read,   // Initiate read from SDRAM
	
	output   [17:0] cartram_addr,
	output          cartram_wr,
	output          cartram_rd,
	output   [7:0]  cartram_wrdata,
	input    [7:0]  cartram_data,

	// Tape Signals
	output          tape_audio, // Tape audio output
	input    [1:0]  tape_in     // ADC tape input
);
	`define NUM_MAPPERS BANKEND

	// Muxxing signals
	logic [18:0] rom_addr[`NUM_MAPPERS];
	logic [7:0] direct_do[`NUM_MAPPERS];
	logic [15:0] flags_out[`NUM_MAPPERS]; // Flag bit 0 is direct_do in use, bit 1 is output enable used;
	logic [7:0]  out_en[`NUM_MAPPERS];
	logic        ram_rw[`NUM_MAPPERS];
	logic        ram_sel[`NUM_MAPPERS];
	logic [17:0] ram_a[`NUM_MAPPERS];
	logic [12:0] old_ain;
	logic [7:0]  bg_data;
	logic        ar_read;
	logic [7:0]  cr_do;


	logic [18:0] sel_rom_addr;
	logic [7:0] sel_direct_do;
	logic [15:0] sel_flags_out;
	logic [7:0]  sel_out_en;
	logic        sel_ram_rw;
	logic        sel_ram_sel;
	logic [17:0] sel_ram_a;
	logic [18:0] rom_mask;

	assign rom_mask = rom_size - 1'd1;
	assign rom_read = mapper == BANKAR ? ar_read : ~address_change;
	wire is_bad_game = mapper == BANKDPCP || mapper == BANKCDF;

	// Handle unsupportable ARM mappers :(
	spram #(.addr_width(11), .mem_init_file("ooo.mif")) badgame_ram
	(
		.clock      (clk),
		.address    (a_in[10:0]),
		.wren       (0),
		.q          (bg_data)
	);

	// Flags:
	// bit 0 - direct_do in use
	// bit 1 - bitwise & direct_do and rom_do
	assign sel_flags_out = flags_out[mapper];
	assign sel_direct_do = direct_do[mapper];
	assign sel_out_en = out_en[mapper];
	assign sel_ram_rw = ram_rw[mapper];
	assign sel_ram_sel = ram_sel[mapper];
	assign sel_ram_a = ram_a[mapper];
	assign rom_a = rom_addr[mapper] & ((mapper == BANKE7 || mapper == BANK3F) ? rom_mask : {19{1'b1}});
	assign oe = out_en[mapper];

	always_comb begin
		d_out = open_bus;
		if (is_bad_game)
			d_out = bg_data;
		else if (|sel_out_en) begin
			if (sel_flags_out[0])
				d_out = sel_direct_do;
			else if (sel_flags_out[1])
				d_out = (sel_direct_do & rom_do);
			else if (sel_ram_sel) begin
				if (sel_ram_rw)
					d_out = cr_do;
			end else
				d_out = rom_do;
		end
	end

	// Since atari added no clock signal to the cart slot, for most mappers this will be the
	// primary way that they detected when to take action. The address changes typically
	// occur just before or just after phi2 on a real system. On some 7800 systems, A12 is delayed
	// in an atypical way causing this to trigger incorrectly for some games, however this
	// design does not reproduce that issue.
	wire address_change = old_ain != a_in;

	always @(posedge clk) begin :reset_2600_cart
		old_ain <= a_in;
	end

	// Bank CTY is compatible with F4 minus the ARM enhanced music
	assign direct_do[BANKCTY]     = direct_do[BANKF4];
	assign flags_out[BANKCTY]     = flags_out[BANKF4];
	assign out_en[BANKCTY]        = out_en[BANKF4];
	assign ram_sel[BANKCTY]       = ram_sel[BANKF4];
	assign ram_rw[BANKCTY]        = ram_rw[BANKF4];
	assign ram_a[BANKCTY]         = ram_a[BANKF4];
	assign rom_addr[BANKCTY]      = rom_addr[BANKF4];

	// CDF and DPC+ arm code won't run here
	assign direct_do[BANKCDF]     = bg_data;
	assign flags_out[BANKCDF]     = 16'd1;
	assign out_en[BANKCDF]        = 8'hFF;
	assign ram_sel[BANKCDF]       = 0;
	assign ram_rw[BANKCDF]        = 1;
	assign ram_a[BANKCDF]         = '0;
	assign rom_addr[BANKCDF]      = '0;

	assign direct_do[BANKDPCP]    = bg_data;
	assign flags_out[BANKDPCP]    = 16'd1;
	assign out_en[BANKDPCP]       = 8'hFF;
	assign ram_sel[BANKDPCP]      = 0;
	assign ram_rw[BANKDPCP]       = 1;
	assign ram_a[BANKDPCP]        = '0;
	assign rom_addr[BANKDPCP]     = '0;

	assign cartram_addr = sel_ram_a;
	assign cartram_wr = ~sel_ram_rw && sel_ram_sel && ~address_change;
	assign cartram_rd = sel_ram_sel && ~cartram_wr;
	assign cartram_wrdata = d_in;
	assign cr_do = cartram_data;

	// Other?
	// SV   -- Spectravideo Compumate (seems useless)
	// 0840 -- Econobanking (can't find any games that use it)
	// MC   -- Megacart (doesn't seem like it works on real hardware, also no games)
	// X07  -- X07 Atariage (seems impossible, also cant find any games with it)
	// 4A50 -- 4A50 (never found a game with this)
	// FA2  -- FA2 (some kind of flash cart abstraction? Only one homebrew uses)

	mapper_none mapper_none
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANK00]),
		.flags_out  (flags_out[BANK00]),
		.oe         (out_en[BANK00]),
		.ram_sel    (ram_sel[BANK00]),
		.ram_rw     (ram_rw[BANK00]),
		.ram_a      (ram_a[BANK00]),
		.rom_a      (rom_addr[BANK00])
	);

	mapper_F8 mapper_F8
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKF8]),
		.flags_out  (flags_out[BANKF8]),
		.oe         (out_en[BANKF8]),
		.ram_sel    (ram_sel[BANKF8]),
		.ram_rw     (ram_rw[BANKF8]),
		.ram_a      (ram_a[BANKF8]),
		.rom_a      (rom_addr[BANKF8])
	);

	mapper_F6 mapper_F6
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKF6]),
		.flags_out  (flags_out[BANKF6]),
		.oe         (out_en[BANKF6]),
		.ram_sel    (ram_sel[BANKF6]),
		.ram_rw     (ram_rw[BANKF6]),
		.ram_a      (ram_a[BANKF6]),
		.rom_a      (rom_addr[BANKF6])
	);

	mapper_FE mapper_FE
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKFE]),
		.flags_out  (flags_out[BANKFE]),
		.oe         (out_en[BANKFE]),
		.ram_sel    (ram_sel[BANKFE]),
		.ram_rw     (ram_rw[BANKFE]),
		.ram_a      (ram_a[BANKFE]),
		.rom_a      (rom_addr[BANKFE]),
		.ce         (phi1)
	);

	mapper_E0 mapper_E0
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKE0]),
		.flags_out  (flags_out[BANKE0]),
		.oe         (out_en[BANKE0]),
		.ram_sel    (ram_sel[BANKE0]),
		.ram_rw     (ram_rw[BANKE0]),
		.ram_a      (ram_a[BANKE0]),
		.rom_a      (rom_addr[BANKE0])
	);

	mapper_3F mapper_3F
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANK3F]),
		.flags_out  (flags_out[BANK3F]),
		.oe         (out_en[BANK3F]),
		.ram_sel    (ram_sel[BANK3F]),
		.ram_rw     (ram_rw[BANK3F]),
		.ram_a      (ram_a[BANK3F]),
		.rom_a      (rom_addr[BANK3F])
	);

	mapper_F4 mapper_F4
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKF4]),
		.flags_out  (flags_out[BANKF4]),
		.oe         (out_en[BANKF4]),
		.ram_sel    (ram_sel[BANKF4]),
		.ram_rw     (ram_rw[BANKF4]),
		.ram_a      (ram_a[BANKF4]),
		.rom_a      (rom_addr[BANKF4])
	);

	mapper_P2 mapper_P2
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKP2]),
		.flags_out  (flags_out[BANKP2]),
		.oe         (out_en[BANKP2]),
		.ram_sel    (ram_sel[BANKP2]),
		.ram_rw     (ram_rw[BANKP2]),
		.ram_a      (ram_a[BANKP2]),
		.rom_a      (rom_addr[BANKP2]),
		.ce         (ce)
	);

	mapper_FA mapper_FA
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKFA]),
		.flags_out  (flags_out[BANKFA]),
		.oe         (out_en[BANKFA]),
		.ram_sel    (ram_sel[BANKFA]),
		.ram_rw     (ram_rw[BANKFA]),
		.ram_a      (ram_a[BANKFA]),
		.rom_a      (rom_addr[BANKFA])
	);

	mapper_CV mapper_CV
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKCV]),
		.flags_out  (flags_out[BANKCV]),
		.oe         (out_en[BANKCV]),
		.ram_sel    (ram_sel[BANKCV]),
		.ram_rw     (ram_rw[BANKCV]),
		.ram_a      (ram_a[BANKCV]),
		.rom_a      (rom_addr[BANKCV])
	);

	mapper_2K mapper_2K
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANK2K]),
		.flags_out  (flags_out[BANK2K]),
		.oe         (out_en[BANK2K]),
		.ram_sel    (ram_sel[BANK2K]),
		.ram_rw     (ram_rw[BANK2K]),
		.ram_a      (ram_a[BANK2K]),
		.rom_a      (rom_addr[BANK2K])
	);

	mapper_UA mapper_UA
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKUA]),
		.flags_out  (flags_out[BANKUA]),
		.oe         (out_en[BANKUA]),
		.ram_sel    (ram_sel[BANKUA]),
		.ram_rw     (ram_rw[BANKUA]),
		.ram_a      (ram_a[BANKUA]),
		.rom_a      (rom_addr[BANKUA])
	);

	mapper_E7 mapper_E7
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKE7]),
		.flags_out  (flags_out[BANKE7]),
		.oe         (out_en[BANKE7]),
		.ram_sel    (ram_sel[BANKE7]),
		.ram_rw     (ram_rw[BANKE7]),
		.ram_a      (ram_a[BANKE7]),
		.rom_a      (rom_addr[BANKE7])
	);

	mapper_F0 mapper_F0
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKF0]),
		.flags_out  (flags_out[BANKF0]),
		.oe         (out_en[BANKF0]),
		.ram_sel    (ram_sel[BANKF0]),
		.ram_rw     (ram_rw[BANKF0]),
		.ram_a      (ram_a[BANKF0]),
		.rom_a      (rom_addr[BANKF0])
	);

	mapper_32 mapper_32
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANK32]),
		.flags_out  (flags_out[BANK32]),
		.oe         (out_en[BANK32]),
		.ram_sel    (ram_sel[BANK32]),
		.ram_rw     (ram_rw[BANK32]),
		.ram_a      (ram_a[BANK32]),
		.rom_a      (rom_addr[BANK32]),
		.cold_reset (mapper != BANK32)
	);

	mapper_AR mapper_AR
	(
		.clk        (clk),
		.reset      (reset || mapper != BANKAR),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKAR]),
		.flags_out  (flags_out[BANKAR]),
		.oe         (out_en[BANKAR]),
		.ram_sel    (ram_sel[BANKAR]),
		.ram_rw     (ram_rw[BANKAR]),
		.ram_a      (ram_a[BANKAR]),
		.rom_a      (rom_addr[BANKAR]),
		.ce         (ce),
		.ar_read    (ar_read),
		.rom_do     (rom_do),
		.rom_size   (rom_size),
		.audio_data (tape_audio),
		.tape_in    (tape_in)
	);

	mapper_WD mapper_WD
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKWD]),
		.flags_out  (flags_out[BANKWD]),
		.oe         (out_en[BANKWD]),
		.ram_sel    (ram_sel[BANKWD]),
		.ram_rw     (ram_rw[BANKWD]),
		.ram_a      (ram_a[BANKWD]),
		.rom_a      (rom_addr[BANKWD])
	);

	mapper_3E mapper_3E
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANK3E]),
		.flags_out  (flags_out[BANK3E]),
		.oe         (out_en[BANK3E]),
		.ram_sel    (ram_sel[BANK3E]),
		.ram_rw     (ram_rw[BANK3E]),
		.ram_a      (ram_a[BANK3E]),
		.rom_a      (rom_addr[BANK3E]),
		.rom_size   (rom_size)
	);

	mapper_SB mapper_SB
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKSB]),
		.flags_out  (flags_out[BANKSB]),
		.oe         (out_en[BANKSB]),
		.ram_sel    (ram_sel[BANKSB]),
		.ram_rw     (ram_rw[BANKSB]),
		.ram_a      (ram_a[BANKSB]),
		.rom_a      (rom_addr[BANKSB])
	);

	mapper_EF mapper_EF
	(
		.clk        (clk),
		.reset      (reset),
		.a_change   (address_change),
		.sc         (sc),
		.a_in       (a_in),
		.d_in       (d_in),
		.d_out      (direct_do[BANKEF]),
		.flags_out  (flags_out[BANKEF]),
		.oe         (out_en[BANKEF]),
		.ram_sel    (ram_sel[BANKEF]),
		.ram_rw     (ram_rw[BANKEF]),
		.ram_a      (ram_a[BANKEF]),
		.rom_a      (rom_addr[BANKEF])
	);

endmodule
