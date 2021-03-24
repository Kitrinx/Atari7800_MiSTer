`include "atari7800.vh"

module memory_map (
	input  logic             mclk0,
	input  logic             mclk1,
	input  logic             maria_en,
	input  logic             tia_en,
	input  logic [15:0]      AB,
	input  logic [7:0]       DB_in,
	output logic [7:0]       DB_out,
	input  logic             RW,

	output `chipselect       cs,
	input  logic             bios_en,
	input  logic             drive_AB,

	output logic [7:0]       ctrl,
	output logic [24:0][7:0] color_map,
	input  logic [7:0]       status_read,
	output logic [7:0]       char_base,
	output logic [15:0]      ZP,
	input  logic             pal,

	// whether to slow pclk_0 for slow memory accesses
	output logic             sel_slow_clock,

	// when wait_sync is written to, ready is deasserted
	output logic             deassert_ready,

	input  logic             clk_sys,
	input  logic             reset_b,
	input  logic             pclk0,
	input  logic             bypass_bios
);

	// Internal Memory Mapped Registers
	logic [7:0]              ZPH, ZPL;
	assign sel_slow_clock = ((~maria_en) ? 1'b1 : ((cs == `CS_TIA) || (cs == `CS_RIOT_IO) || (cs == `CS_RIOT_RAM)));

	assign ZP = {ZPH, ZPL};

	always_comb begin
		cs = `CS_CART;

		if (~tia_en) casex (AB[15:5])
				// RIOT RAM: "Do Not Use" in 7800 mode.
				11'b0000_010x_1xx: cs = `CS_RIOT_RAM;
				11'b0000_001x_1xx: cs = `CS_RIOT_IO;

				// 1800-1FFF: 2K RAM.
				11'b0001_1xxx_xxx: cs = `CS_RAM1;

				// 0040-00FF: Zero Page (Local variable space)
				// 0140-01FF: Stack
				11'b0000_000x_01x,
				11'b0000_000x_1xx,

				// 2000-27FF: 2K RAM. Zero Page and Stack mirrored from here.
				11'b0010_0xxx_xxx: cs = `CS_RAM0;

				// TIA Registers:
				// 0000-001F, 0100-001F, 0200-021F, 0300-031F
				// All mirrors are ranges of the same registers
				11'b0000_00xx_000: cs = `CS_TIA;

				// MARIA Registers:
				// 0020-003F, 0120-003F, 0220-023F, 0320-033F
				// All ranges are mirrors of the same registers
				11'b0000_00xx_001: cs = `CS_MARIA;
				default: ;

		endcase else casex (AB[15:5])
				11'bXXX0_XX0X_1XX: cs = `CS_RIOT_RAM;
				11'bxxx0_xx1x_1xx: cs = `CS_RIOT_IO;
				11'bxxx0_xxxx_0xx: cs = `CS_TIA;
				default: ;
		endcase

		if (bios_en & AB[15])
			cs = `CS_BIOS;
	end

	always_ff @(posedge clk_sys) begin
		if (~reset_b || ~maria_en) begin
			ctrl <= {1'b0, 2'b11, 1'b1, 4'b0000}; // Allow skipping bios by disabling dma on reset
			color_map <= 200'b0; // FIXME: convert this to RAM?
			char_base <= 8'b0;
			DB_out <= 0;
			{ZPH,ZPL} <= bypass_bios ? (pal ? {8'h27, 8'h30} : {8'h00, 8'h84}) : 8'd0;
		end else if (pclk0) begin
			deassert_ready <= 1'b0;
			if (~RW && cs == `CS_MARIA) begin
				case(AB[5:0])
					6'h20: color_map[0] <= DB_in; // Background color
					6'h21: color_map[1] <= DB_in;
					6'h22: color_map[2] <= DB_in;
					6'h23: color_map[3] <= DB_in;
					6'h24: deassert_ready <= 1'b1;
					6'h25: color_map[4] <= DB_in;
					6'h26: color_map[5] <= DB_in;
					6'h27: color_map[6] <= DB_in;
					6'h29: color_map[7] <= DB_in;
					6'h2a: color_map[8] <= DB_in;
					6'h2b: color_map[9] <= DB_in;
					6'h2c: ZPH <= DB_in;
					6'h2d: color_map[10] <= DB_in;
					6'h2e: color_map[11] <= DB_in;
					6'h2f: color_map[12] <= DB_in;
					6'h30: ZPL <= DB_in;
					6'h31: color_map[13] <= DB_in;
					6'h32: color_map[14] <= DB_in;
					6'h33: color_map[15] <= DB_in;
					6'h34: char_base <= DB_in;
					6'h35: color_map[16] <= DB_in;
					6'h36: color_map[17] <= DB_in;
					6'h37: color_map[18] <= DB_in;
					6'h39: color_map[19] <= DB_in;
					6'h3a: color_map[20] <= DB_in;
					6'h3b: color_map[21] <= DB_in;
					6'h3c: ctrl <= DB_in;
					6'h3d: color_map[22] <= DB_in;
					6'h3e: color_map[23] <= DB_in;
					6'h3f: color_map[24] <= DB_in;
					default: ;
				endcase
			end else if (RW && cs == `CS_MARIA) begin
				// Maria reads will return 0 if invalid. Not open bus or anything else.
				if (AB[5:0] == 6'h28)
					DB_out <= status_read;
				else
					DB_out <= 8'h0;
			end
		end
	end
endmodule
