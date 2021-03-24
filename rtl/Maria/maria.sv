/************************************************************************
* (C) Jamie Blanks, 2021                                                *
*                                                                       *
* This program is free software: you can redistribute it and/or modify  *
* it under the terms of the GNU General Public License as published by  *
* the Free Software Foundation, either version 3 of the License, or     *
* (at your option) any later version.                                   *
*                                                                       *
* This program is distributed in the hope that it will be useful,       *
* but WITHOUT ANY WARRANTY; without even the implied warranty of        *
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
* GNU General Public License for more details.                          *
*                                                                       *
* You should have received a copy of the GNU General Public License     *
* along with this program.  If not, see <https://www.gnu.org/licenses/>.*
************************************************************************/

`include "atari7800.vh"

module maria(
	output logic        mclk0,
	output logic        mclk1,
	input  logic [15:0] AB_in,
	output logic [15:0] AB_out,

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

	// Memory Map Select lines
	output `chipselect  CS,
	input logic         bios_en,
	input logic         tia_en,

	// Maria configuration
	input logic         RW, 
	input logic         maria_en,

	// VGA Interface
	output logic [7:0]  YC,
	output logic        hsync,
	output logic        vsync,
	output logic        hblank,
	output logic        vblank,
	output logic        vblank_ex,

	// Outputs to 6502
	output logic        NMI_n,
	output logic        halt_n,
	output logic        ready,

	// Abstract Pins
	output logic        drive_AB,
	input  logic        hide_border,
	input  logic        bypass_bios
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
	logic [7:0]       hpos;
	logic [1:0]       edge_counter;
	logic [7:0]       pal_counter;
	logic             deassert_ready;	
	logic             border;
	logic             prst;
	logic             vbe;
	logic             hbs;
	logic             lrc;
	logic             wm;
	logic             clear_hpos;
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
	// Apply color kill if needed
	assign YC = UV_out & (ctrl[7] ? 8'h0F : 8'hFF);

	assign halt_n = ~halt_en;

	// Maria being enabled is a condition for NMI
	assign NMI_n = NMI_ung_n || ~maria_en;

	wire dma_en = (ctrl[6:5] == 2'b10);

	always @(posedge clk_sys) begin
		if (reset) begin
			ready <= 1;
			clock_div <= 0;
			clk_toggle <= 0;
			pclk_toggle <= 0;
			pal_counter <= 0;
			mclk1 <= 0;
			mclk0 <= 0;
			pclk0 <= 0;
			pclk1 <= 0;
			slow_clk_latch <= 0;
		end else begin
			// if (PAL)
			// 	pal_counter <= pal_counter + 1'd1;
			// else
			// 	pal_counter <= 0;

			mclk1 <= 0;
			mclk0 <= 0;

			if (pal_counter == 109)
				pal_counter <= 0;
			else begin
				mclk0 <= clk_toggle;
				mclk1 <= ~clk_toggle;
				clk_toggle <= ~clk_toggle;
			end

			if (deassert_ready)
				ready <= 1'b0;
			else if (lrc)
				ready <= 1'b1;

			pclk0 <= 0;
			pclk1 <= 0;

			if (pclk_toggle)
				slow_clk_latch <= sel_slow_clock;

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
		end
	end

	line_ram line_ram_inst(
		.mclk0         (mclk0),
		.mclk1         (mclk1),
		.border        (border),
		.clk_sys       (clk_sys),
		.latch_byte    (latch_byte),
		.clear_hpos    (clear_hpos),
		.RESET         (reset || ~maria_en),
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
		.RW             (RW),
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
		.clk_sys        (clk_sys),
		.reset_b        (~reset),
		.pclk0          (pclk2),
		.bypass_bios    (bypass_bios)
	);

	dma_ctrl dma_ctrl_inst (
		.clk_sys         (clk_sys),
		.reset           (reset || ~maria_en),
		.mclk0           (mclk0),
		.mclk1           (mclk1),
		.vblank          (vblank),
		.vbe             (vbe),
		.hbs             (hbs),
		.lrc             (lrc),
		.dma_en          (dma_en),
		.pclk1           (pclk1),
		.pclk0           (pclk0),
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
		.char_base       (char_base),
		.bypass_bios     (bypass_bios),
		.nmi_n           (NMI_ung_n)
	);

	video_sync sync (
		.mclk0       (mclk0),
		.mclk1       (mclk1),
		.clk         (clk_sys),
		.reset       (reset || ~maria_en),
		.bypass_bios (bypass_bios),
		.PAL         (PAL),
		.HSync       (hsync),
		.VSync       (vsync),
		.hblank      (hblank),
		.vblank      (vblank),
		.vblank_ex   (vblank_ex),
		.border      (border),
		.hide_border (hide_border),
		.lrc         (lrc),
		.prst        (prst),
		.vbe         (vbe),
		.hbs         (hbs)
	);

endmodule
