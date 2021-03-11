`include "atari7800.vh"

module maria(
	output logic        mclk0,
	output logic        mclk1,
	input  logic        halt_unlock,
	input  logic [15:0] AB_in,
	output logic [15:0] AB_out,
	output logic        drive_AB,
	input  logic        hide_border,
	input  logic        PAL,

	input  logic  [7:0] read_DB_in,
	input  logic  [7:0] write_DB_in,
	output logic  [7:0] DB_out,
	output logic        pclk0,
	output logic        pclk1,
	input logic         pclk2,

	// Clocking
	input logic         reset,
	input logic         clk_sys, 
	output logic        tia_clk, 
	output logic        sel_slow_clock, 

	// Memory Map Select lines
	output `chipselect  CS,
	input logic         bios_en,
	input logic         tia_en,

	// Maria configuration
	input logic         RW, 
	input logic         maria_en,

	// VGA Interface
	output logic [7:0]  UV_out,
	output logic [3:0]  red,
	output logic [3:0]  green,
	output logic [3:0]  blue,
	output logic        hsync,
	output logic        vsync,
	output logic        hblank,
	output logic        vblank,
	output logic [12:0] cpu_ticks,
	output logic [12:0] halted_ticks,
	output logic [12:0] driven_ticks,

	// Outputs to 6502
	output logic        int_b,
	output logic        halt_b,
	output logic        ready
);

	assign halt_b = ~halt_en;

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

	//// Memory Mapped Registers
	// Control register format:
	// {CK, DM1, DM0, CW, BC, KM, RM1, RM0}
	// CK: Color Kill
	// {DM1, DM0}: DMA Control. 0: Test A. 1: Test B.
	//                          2: Normal DMA. 3: No DMA.
	// CW: Character Width (For indirect mode). 0=>2bytes. 1=>1byte.
	// BC: Border Control: 0=>Black Border. 1=>Background Color.
	// KM: Kangaroo Mode: 0=>Transparency, 1=>No transparency
	// {RM1, RM0}: Read mode.
	logic [7:0]       ctrl;
	logic [24:0][7:0] color_map;
	logic [7:0]       char_base;
	logic [15:0]      ZP;

	logic deassert_ready;	
	logic [3:0] reset_delay;
	logic border;
	logic prst;
	logic vbe;
	logic hbs;
	logic lrc;
	logic [2:0] palette;
	logic wm;
	logic [7:0] hpos;
	logic clear_hpos;
	logic halt_en;
	logic DLI_en;
	logic dli_latch;
	logic [1:0] edge_counter;
	logic clk_toggle;
	logic old_dli;
	logic [2:0] clock_div, clock_p1_div;
	logic latch_byte;
	logic ctrl_written;
	logic pclk_toggle;
	logic old_ssc;

	// Normally this would be one cpu cycle, but T65 appears to
	// need this low for two cpu cycles to take action.
	assign int_b = ~(edge_counter == 1 || edge_counter == 2);

	wire dma_en = (ctrl[6:5] == 2'b10);

	wire PCLKEDGE = clock_div == 1 && pclk_toggle;
	assign mclk0 = clk_toggle;
	assign mclk1 = ~clk_toggle;
	assign tia_clk = clk_toggle;

	always @(posedge clk_sys) begin
		if (reset) begin
			edge_counter <= 2'd3;
			dli_latch <= 0;
			old_dli <= 0;
			ready <= 1;
			clock_div <= 0;
			clk_toggle <= 0;
			pclk_toggle <= 0;
			pclk0 <= 0;
			pclk1 <= 0;
			old_ssc <= 0;
		end else begin
			clk_toggle <= ~clk_toggle;
			old_dli <= DLI_en;

			if (~old_dli & DLI_en) begin
				dli_latch <= 1;
				edge_counter <= 0;
			end

			if (pclk0)
				cpu_ticks <= cpu_ticks + 1'd1;
			if (mclk0) begin
				if (halt_en) halted_ticks <= halted_ticks + 1'd1;
				if (drive_AB) driven_ticks <= driven_ticks + 1'd1;
			end
			if (lrc) begin
				cpu_ticks <= 0;
				halted_ticks <= 0;
				driven_ticks <= 0;
			end


			if (pclk1) begin
				if (~&edge_counter && dli_latch)
					edge_counter <= edge_counter + 1'd1;
				if (edge_counter == 3)
					dli_latch <= 0;
			end

			if (deassert_ready)
				ready <= 1'b0;
			else if (lrc)
				ready <= 1'b1;

			pclk0 <= 0;
			pclk1 <= 0;

			if (mclk1) begin
				if (~(halt_en & halt_unlock)) begin
					old_ssc <= sel_slow_clock;
					if (clock_div)
						clock_div <= clock_div - 1'd1;
					else begin
						pclk_toggle <= ~pclk_toggle;
						pclk1 <= ~pclk_toggle;
						pclk0 <= pclk_toggle;
						clock_div <= sel_slow_clock ? 3'd2 : 2'd1;
					end
					if (old_ssc != sel_slow_clock) begin
						// In theory this should only happen 1 cycle after pclk1
						// when the addresses change.
						clock_div <= sel_slow_clock ? 3'd1 : 2'd0;
					end
				end else begin
					pclk0 <= 1;
				end
			end
		end
	end

	line_ram line_ram_inst(
		.mclk0         (mclk0),
		.mclk1         (mclk1),
		.border        (border),
		.clk_sys       (clk_sys),
		.latch_byte    (latch_byte),
		.clear_hpos    (clear_hpos),
		.RESET         (reset),
		.PLAYBACK      (UV_out),
		.hpos          (hpos),
		.PALETTE       (palette),
		.PIXELS        (read_DB_in),
		.WM            (wm),
		.COLOR_MAP     (color_map),
		.RM            (ctrl[1:0]),
		.KANGAROO_MODE (ctrl[2]),
		.BORDER_CONTROL(ctrl[3]),
		.DMA_EN        (dma_en),
		.COLOR_KILL    (ctrl[7]),
		.lrc           (lrc)
	);

	memory_map memory_map_inst(
		.mclk0          (mclk0),
		.mclk1          (mclk1),
		.maria_en       (maria_en),
		.tia_en         (tia_en),
		.AB             (AB_in),
		.DB_in          (write_DB_in),
		.DB_out         (DB_out),
		.halt_b         (halt_b),
		.we_b           (RW),
		.cs             (CS),
		.bios_en        (bios_en),
		.drive_AB       (drive_AB),
		.ctrl           (ctrl),
		.color_map      (color_map),
		.status_read    ({vblank, 7'b0}),
		.char_base      (char_base),
		.ZP             (ZP),
		.pal            (PAL),
		.sel_slow_clock (sel_slow_clock),
		.deassert_ready (deassert_ready),
		.sysclock       (clk_sys),
		.reset_b        (~reset),
		.pclk0          (pclk2)
	);

	dma_ctrl dma_ctrl_inst (
		.clk_sys         (clk_sys),
		.reset           (reset),
		.mclk0           (mclk0),
		.mclk1           (mclk1),
		.PCLKEDGE        (PCLKEDGE),
		.vblank          (vblank),
		.vbe             (vbe),
		.hbs             (hbs),
		.lrc             (lrc),
		.dma_en          (dma_en),
		.pclk1           (pclk1),
		.AddrB           (AB_out),
		.drive_AB        (drive_AB),
		.latch_byte      (latch_byte),
		.DataB           (read_DB_in),
		.clear_hpos      (clear_hpos),
		.HALT            (halt_en),
		.HPOS            (hpos),
		.DLI             (DLI_en),
		.WM              (wm),
		.PAL             (palette),
		.ZP              (ZP),
		.character_width (ctrl[4]),
		.char_base       (char_base)
	);

	video_sync sync (
		.mclk0  (mclk0),
		.mclk1  (mclk1),
		.clk    (clk_sys),
		.reset  (reset),
		.uv_in  (UV_out),
		.PAL    (PAL),
		.RED    (red),
		.GREEN  (green),
		.BLUE   (blue),
		.HSync  (hsync),
		.VSync  (vsync),
		.hblank (hblank),
		.vblank (vblank),
		.border (border),
		.hide_border (hide_border),
		.lrc    (lrc),
		.prst   (prst),
		.vbe    (vbe),
		.hbs    (hbs)
	);

endmodule

