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

`include "atari7800.vh"
//`define OLD_TIA

module Atari7800(
input  logic        clk_sys,
input  logic        reset,
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

output logic [15:0] AUDIO_R,
output logic [15:0] AUDIO_L,
input logic         show_border,
input logic         show_overscan,
input logic         bypass_bios,
input logic         tia_mode,

input  logic [7:0]  cart_xm,
output logic        cart_read,
input  logic [7:0]  cart_out, bios_out,
output logic [15:0] AB,
output logic [24:0] cart_addr_out,
input  logic [15:0] cart_flags,
input  logic  [7:0] cart_save,
input  logic [31:0] cart_size,
output logic        RW,
input  logic        loading,

// Tia inputs
input  logic  [3:0] idump,
output logic  [3:0] i_out,
input  logic  [1:0] ilatch,

output logic        tia_en,

// Riot inputs
input  logic  [7:0] PAin,
input  logic  [7:0] PBin,
output logic  [7:0] PAout,
output logic  [7:0] PBout,
output logic        PAread,
// 2600 Cart force flags based on detection
input logic [3:0]  force_bs,
input logic        sc,
input logic [7:0]  clearval,
output logic       tia_hsync,
input  logic       use_stereo,
input [10:0]       ps2_key

);
	assign bios_DB_out = bios_out;
	assign PAread = (CS == `CS_RIOT_IO) && ~|AB[4:0] && RW && pclk0;

	/////////////
	// Signals //
	/////////////


	// MARIA Signals
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
	logic [7:0]     core_DB_out;
	logic [15:0]    core_AB_out;
	logic           cpu_halt_n;
	logic           cpu_released;
	logic           maria_en;
	logic           lock_ctrl;
	logic           bios_en_b;
	logic [1:0]     ctrl_writes;
	logic [7:0]     read_DB;
	logic [7:0]     write_DB;
	logic [7:0]     tia_DB_out, riot_DB_out, maria_DB_out, ram0_DB_out, ram1_DB_out, bios_DB_out, cart_DB_out;
	`chipselect     CS;
	logic [15:0]    pokey_audio_r, pokey_audio_l, ym_audio_r, ym_audio_l;
	logic           mclk0;
	logic           mclk1;
	logic           ram0_cs, ram1_cs, tia_cs, riot_cs, cart_cs;
	logic [7:0]     open_bus;
	wire            cart_read_flag;
	logic [24:0]    cart_2600_addr_out, cart_7800_addr_out;
	logic [7:0]     cart_2600_DB_out, cart_7800_DB_out;
	logic           cpu_rwn;

	assign RDY = maria_RDY && tia_RDY;
	assign cpu_halt_n = (ctrl_writes == 2'd2) ? halt_n : 1'b1;
	assign cart_read = cart_read_flag & mclk1;
	assign cart_addr_out = cart_7800_addr_out; //tia_en ? cart_2600_addr_out : cart_7800_addr_out;
	assign cart_DB_out = cart_7800_DB_out; //tia_en ? cart_2600_DB_out : cart_7800_DB_out;

	// Track the open bus since FPGA's don't use bidirectional logic internally
	always_ff @(posedge clk_sys)
		if (cpu_released && mclk0 || ~cpu_released && pclk1 || ~RW)
			open_bus <= ~RW ? write_DB : read_DB;

	always_comb begin
		ram0_cs = 1'b0;
		ram1_cs = 1'b0;
		tia_cs = 1'b0;
		riot_cs = 1'b0;
		cart_cs = 1'b0;
		read_DB = open_bus;
		case (CS)
			`CS_RAM0:     begin ram0_cs = 1'b1;  read_DB = ram0_DB_out; end
			`CS_RAM1:     begin ram1_cs = 1'b1;  read_DB = ram1_DB_out; end
			`CS_BIOS:     begin                  read_DB = bios_DB_out; end
			`CS_TIA:      begin tia_cs = 1'b1;   read_DB = {tia_DB_out[7:6], open_bus[5:0]}; end
			`CS_RIOT_IO:  begin riot_cs = 1'b1;  read_DB = riot_DB_out; end
			`CS_CART:     begin cart_cs = 1'b1;  read_DB = cart_DB_out; end
			`CS_MARIA:    begin                  read_DB = maria_DB_out; end
			`CS_RIOT_RAM: begin riot_cs = 1'b1;  read_DB = riot_DB_out; end
			default: cart_cs = 0;
		endcase

		write_DB = core_DB_out;
		AB = (cpu_released ? 16'hFFFF : core_AB_out) & (maria_drive_AB ? maria_AB_out : 16'hFFFF);
		RW = cpu_released ? 1'b1 : cpu_rwn;
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
		.wren           ((~RW & ram0_cs & pclk0) || loading),
		.q              (ram0_DB_out)
	);

	spram #(.addr_width(11), .mem_name("RAM1")) ram1
	(
		.clock          (clk_sys),
		.address        (loading ? clear_addr : AB[10:0]),
		.data           (loading ? clearval : write_DB),
		.wren           ((~RW & ram1_cs & pclk0) || loading),
		.q              (ram1_DB_out)
	);

	// MARIA
	logic maria_vblank, maria_vblank_ex, maria_vsync, maria_hblank, maria_hsync;
	logic pclk1, pclk0;
	logic [3:0] maria_luma, maria_chroma;

	maria maria_inst(
		.mclk0          (mclk0),
		.mclk1          (mclk1),
		.AB_in          (AB),
		.AB_out         (maria_AB_out),
		.drive_AB       (maria_drive_AB),
		.hide_border    (~show_border),
		.bypass_bios    (bypass_bios),
		.PAL            (PAL),
		.read_DB_in     (read_DB),
		.write_DB_in    (write_DB),
		.DB_out         (maria_DB_out),
		.bios_en        (~bios_en_b),
		.reset          (reset),
		.clk_sys        (clk_sys),
		.pclk0          (pclk0),
		.pclk1          (pclk1),
		.pclk2          (pclk0),
		.tia_en         (tia_en),
		.CS             (CS),
		.RW             (RW),
		.maria_en       (maria_en),
		.YC             ({maria_chroma, maria_luma}),
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

	TIA2 tia_inst
	(
		.clk            (clk_sys),
		.ce             (mclk0),     // Clock enable for CLK generation only
		.phi0           (),
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
		.cs0_n          (~tia_cs),
		.cs2_n          (~tia_cs),
		.rst            (reset),
		.video_ce       (tia_pix_ce),
		.vblank         (tia_vblank),
		.hblank         (),
		.hgap           (tia_hblank),
		.vsync          (tia_vsync),
		.hsync          (tia_hsync),
		.phi2_gen       (),
		.open_bus       (open_bus)
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
		.is_PAL         (PAL),
		.hblank         (HBlank),
		.vblank         (VBlank),
		.hsync          (HSync),
		.vsync          (VSync),
		.red            (RED),
		.green          (GREEN),
		.blue           (BLUE),
		.pix_ce         (ce_pix)
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

	wire [5:0] aud_index = audv0 + audv1; // FIXME: should this ever hit > index 30?
	wire [15:0] tia_r = (use_stereo ? audio_lut_single[audv0] : audio_lut[aud_index]);
	wire [15:0] tia_l = (use_stereo ? audio_lut_single[audv1] : audio_lut[aud_index]);

	assign AUDIO_R = tia_r + pokey_audio_r + ym_audio_r;
	assign AUDIO_L = tia_l + pokey_audio_l + ym_audio_l;

	M6532 #(.init_7800(1)) riot_inst_2
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
		.CS2_n        (~riot_cs),
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
		.AB           (core_AB_out),
		.DB_IN        (read_DB),
		.DB_OUT       (core_DB_out),
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
		.cs           (tia_cs),
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

	cart cart
	(
		.clk_sys      (clk_sys),
		.pclk0        (pclk0),
		.pclk1        (pclk1),
		.IRQ_n        (IRQ_n),
		.halt_n       (cpu_halt_n),
		.reset        (reset),
		.address_in   (AB[15:0]),
		.din          (write_DB),
		.rom_din      (cart_out),
		.cart_flags   (cart_flags),
		.cart_size    (cart_size),
		.cart_save    (cart_save),
		.cart_cs      (cart_cs),
		.cart_xm      (cart_xm),
		.cart_read    (cart_read_flag),
		.hsc_en       (hsc_en),
		.hsc_ram_cs   (hsc_ram_cs),
		.hsc_ram_din  (hsc_ram_dout),
		.rw           (RW),
		.dout         (cart_7800_DB_out),
		.pokey_audio_r(pokey_audio_r),
		.pokey_audio_l(pokey_audio_l),
		.ym_audio_r   (ym_audio_r),
		.ym_audio_l   (ym_audio_l),
		.rom_address  (cart_7800_addr_out),
		.open_bus     (open_bus),
		.ps2_key      (ps2_key)
	);

	cart2600 cart2600
	(
		.reset        (reset),
		.clk          (clk_sys),
		.ph0_en       (pclk0),
		.cpu_d_out    (cart_2600_DB_out),
		.cpu_d_in     (write_DB),
		.cpu_a        (AB[12:0]),
		.sc           (sc),
		.force_bs     (force_bs),
		.rom_a        (cart_2600_addr_out),
		.rom_do       (cart_out),
		.rom_size     (cart_size),
		.open_bus     (open_bus)
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
		end	else if (bypass_bios && ~wrote_once) begin
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

	assign is_halted = ~(cpu_halt_n && halt_n);

	logic cpu_halt_n = 0;

	T65 cpu (
		.mode (0),
		.BCD_en(1),

		.Res_n(~reset),
		.Clk(clk_sys),
		.Enable(pclk1 && cpu_halt_n && halt_n),
		.Rdy(RDY),

		.IRQ_n(IRQ_n),
		.NMI_n(NMI_n),
		.R_W_n(RD),
		.A(AB),
		.DI(RD ? DB_IN : DB_OUT),
		.DO(DB_OUT)
	);

	always @(posedge clk_sys) begin
		if (reset) begin
			cpu_halt_n <= 1;
		end else if (pclk1) begin
			cpu_halt_n <= halt_n;
		end
	end

endmodule: M6502C
