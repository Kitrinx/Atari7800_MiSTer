// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.


module maria(
	// Busses
	input  logic [15:0] AB_in,
	output logic [15:0] AB_out,
	input  logic  [7:0] d_in,
	input  logic  [7:0] write_DB_in,
	output logic  [7:0] DB_out,

	// Clocking
	input logic         reset,
	input logic         clk_sys,
	input logic         ce,
	output logic        mclk0,     // This serves as tia_clk
	output logic        mclk1,
	output logic        tia_clk_x2,
	output logic        pclk0,
	output logic        pclk1,
	input logic         pclk2,

	// Chip Select lines
	output logic        cs_ram0,
	output logic        cs_ram1,
	output logic        cs_riot,
	output logic        cs_tia,
	output logic        cs_maria,

	// Maria configuration
	input logic         RW,
	input logic         maria_en,

	// Video
	output logic [7:0]  YC,
	output logic        hsync,
	output logic        vsync,
	output logic        hblank,
	output logic        vblank,
	output logic        vblank_ex,

	// CPU
	output logic        NMI_n,
	output logic        halt_n,
	output logic        ready,

	// Abstract Pins
	output logic        drive_AB,    // Used to overcome the lack of a bidirectional bus
	input  logic        hide_border, // Option to hide the boarder
	input  logic        bypass_bios, // Flag to tell maria to initialize to a post-bios state
	input  logic        PAL          // Indicates the system is in either NTSC or PAL

);

	/* Original Pins:
		A0-A15        memory address bus
		D0-D7         memory data bus
		Vss           ground
		Vdd           power
		/NMI          output to cpu
		XTAL1         14 MHz input
		XTAL2         main clock output
		MEN           Maria enable input. When lo, video is off and memory map is 2600
		Ø2            phase 2 clock input
		TCLK          TIA main/4 clock
		Ø0            phase 0 clock output. 1.79M or 1.19M
		DEL           delay line control voltage input
		/SRAM0-1      RAM chipselects
		/SEL32        RIOT chipselect
		/TIASEL       TIA chipselect
		R/W           Read/write input
		/HALT         cpu halt output
		READY         cpu ready output
		LUM0-3        luminance output
		COLOR         color output
		BLANK         blank output
		SYNC          video sync output
	*/

	logic [7:0]       ctrl;
	logic [24:0][7:0] color_map;
	logic [7:0]       char_base;
	logic [15:0]      ZP;
	logic [2:0]       palette;
	logic [1:0]       zp_written;
	logic [7:0]       UV_out;
	logic [2:0]       clock_div;
	logic [1:0]       edge_counter;
	logic [7:0]       pal_counter;
	logic             wsync;
	logic             border;
	logic             prst;
	logic             vbe;
	logic             hbs;
	logic             lrc;
	logic             wm;
	logic             latch_hpos;
	logic             halt_en;
	logic             DLI_en;
	logic             dli_latch;
	logic             clk_toggle;
	logic             old_dli;
	logic             latch_byte;
	logic             pclk_toggle;
	logic             sel_slow_clock;
	logic             NMI_ung_n;
	logic             slow_clk_latch;
	logic             ready_int;
	logic             cram_sel;
	logic             ABEN;
	logic             old_ready;
	logic             old_men;
	logic [3:0]       men_count;
	logic             noslow;
	logic             pclk;
	logic             tia_clk_en;
	logic [3:0]       tia_enable_count;

	// Apply color kill if needed
	assign YC = UV_out & (ctrl[7] ? 8'h0F : 8'hFF);
	assign drive_AB = ABEN && maria_en;

	// Maria being enabled is a condition for NMI
	assign NMI_n = NMI_ung_n || ~maria_en;
	assign halt_n = ~halt_en;
	assign ready = ~pclk ? (lrc || ready_int) : old_ready;

	assign tia_clk_en = ~|tia_enable_count;
	assign tia_clk_x2 = tia_clk_en && mclk0;

	always @(posedge clk_sys) begin
		if (reset) begin
			clock_div <= bypass_bios ? 2'd1 : 2'd2;
			clk_toggle <= 0;
			pclk_toggle <= bypass_bios ? 1'd1: 1'd0;
			old_ready <= 1;
			pal_counter <= 0;
			mclk1 <= 0;
			mclk0 <= 0;
			pclk0 <= 0;
			pclk1 <= 0;
			ready_int <= 1;
			slow_clk_latch <= 0;
			tia_enable_count <= 2;
		end else begin
			// if (PAL)
			// 	pal_counter <= pal_counter + 1'd1;
			// else
			// 	pal_counter <= 0;

			mclk1 <= 0;
			mclk0 <= 0;
			pclk0 <= 0;
			pclk1 <= 0;
			if (ce) begin
				old_men <= maria_en;

				// If maria enabled rises, the CPU clock is held in a state
				// of reset for 5 master oscillator cycles.
				if (~old_men && maria_en) begin
					men_count <= 5;
				end

				if (mclk1 && |tia_enable_count)
					tia_enable_count <= tia_enable_count - 1'd1;

				if (|men_count)
					men_count <= men_count - 1'd1;

				if (mclk0) begin
					if (pclk1)
						pclk <= 0;
					else if (pclk0)
						pclk <= 1;
				end

				if (pal_counter == 109) begin
					pal_counter <= 0;
					mclk0 <= 0;
					mclk1 <= 0;
				end else begin
					mclk0 <= clk_toggle;
					mclk1 <= ~clk_toggle;
					clk_toggle <= ~clk_toggle;
				end

				if (wsync)
					ready_int <= 1'b0;
				else

				if (lrc) begin
					ready_int <= 1'b1;
				end

				if (pclk0)
					slow_clk_latch <= sel_slow_clock;

				if (~pclk) begin
					old_ready <= ready_int;
				end

				// FIXME: Redo clocks based on combinational logic with CE
				if (mclk1) begin
					if (clock_div)
						clock_div <= clock_div - 1'd1;
					else begin
						pclk_toggle <= ~pclk_toggle;
						pclk1 <= pclk_toggle;
						pclk0 <= ~pclk_toggle;
						clock_div <= (~pclk_toggle ? sel_slow_clock : slow_clk_latch) ? 3'd2 : 2'd1;
					end
				end
				if (|men_count) begin
					pclk_toggle <= 0;
					clock_div <= sel_slow_clock ? 3'd2 : 2'd1;
				end
			end
		end
	end

	line_ram line_ram_inst (
		.mclk0           (mclk0),
		.mclk1           (mclk1),
		.border          (border),
		.clk_sys         (clk_sys),
		.latch_byte      (latch_byte),
		.latch_hpos      (latch_hpos),
		.RESET           (reset || ~maria_en),
		.PLAYBACK        (UV_out),
		.PALETTE         (palette),
		.d_in            (d_in),
		.WM              (wm),
		.COLOR_MAP       (color_map),
		.RM              (ctrl[1:0]),
		.KANGAROO_MODE   (ctrl[2]),
		.BORDER_CONTROL  (ctrl[3]),
		.COLOR_KILL      (ctrl[7]),
		.lrc             (lrc),
		.cram_write      (cram_sel)
	);

	control control_inst (
		.mclk0           (mclk0),
		.mclk1           (mclk1),
		.pclkp           (pclk),
		.maria_en        (maria_en),
		.AB              (AB_in),
		.ABEN            (drive_AB),
		.DB_in           (write_DB_in),
		.DB_out          (DB_out),
		.RW              (RW),
		.drive_AB        (drive_AB),
		.ctrl            (ctrl),
		.color_map       (color_map),
		.status_read     ({vblank, 7'b0}),
		.noslow          (noslow),
		.char_base       (char_base),
		.ZP              (ZP),
		.pal             (PAL),
		.sel_slow_clock  (sel_slow_clock),
		.wsync           (wsync),
		.clk_sys         (clk_sys),
		.reset           (reset),
		.pclk0           (pclk2),
		.bypass_bios     (bypass_bios),
		.cs_ram0         (cs_ram0),
		.cs_ram1         (cs_ram1),
		.cs_riot         (cs_riot),
		.cs_tia          (cs_tia),
		.cs_maria        (cs_maria),
		.cram_select     (cram_sel)
	);

	dma dma_inst (
		.clk_sys         (clk_sys),
		.reset           (reset),
		.mclk0           (mclk0),
		.mclk1           (mclk1),
		.vblank          (vblank),
		.vbe             (vbe),
		.hbs             (hbs),
		.lrc             (lrc),
		.pclk1           (pclk1),
		.pclk0           (pclk0),
		.DM              (ctrl[6:5]),
		.AB              (AB_out),
		.ABEN            (ABEN),
		.PCLKEDGE        (~pclk_toggle),
		.pclk            (pclk),
		.latch_byte      (latch_byte),
		.d_in            (d_in),
		.latch_hpos      (latch_hpos),
		.HALT            (halt_en),
		.DLI             (DLI_en),
		.WM              (wm),
		.PAL             (palette),
		.noslow          (noslow),
		.ZP              (ZP),
		.char_width      (ctrl[4]),
		.char_base       (char_base),
		.bypass_bios     (bypass_bios),
		.nmi_n           (NMI_ung_n)
		);

	video_sync sync_inst (
		.mclk0           (mclk0),
		.mclk1           (mclk1),
		.clk             (clk_sys),
		.reset           (reset || ~maria_en),
		.bypass_bios     (bypass_bios),
		.PAL             (PAL),
		.HSync           (hsync),
		.VSync           (vsync),
		.hblank          (hblank),
		.vblank          (vblank),
		.vblank_ex       (vblank_ex),
		.border          (border),
		.hide_border     (hide_border),
		.lrc             (lrc),
		.prst            (prst),
		.vbe             (vbe),
		.hbs             (hbs)
	);

endmodule
