`include "atari7800.vh"

module memory_map (
	input  logic             mclk0,
	input  logic             mclk1,
	input  logic             maria_en,
	input  logic             tia_en,
	input  logic [15:0]      AB,
	input  logic [7:0]       DB_in,
	output logic [7:0]       DB_out,
	input  logic             halt_b,
	input  logic             we_b,

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

	input  logic             sysclock,
	input  logic             reset_b,
	input  logic             pclk0
);

	// Internal Memory Mapped Registers
	logic [7:0]              ZPH, ZPL;

	assign sel_slow_clock = (drive_AB) ? 1'b0 : ((tia_en) ? 1'b1 : ((cs == `CS_TIA) || (cs == `CS_RIOT_IO) || (cs == `CS_RIOT_RAM)));

	assign ZP = {ZPH, ZPL};

	always_comb begin
		cs = `CS_CART;

		if (~tia_en) casex (AB)
				// RIOT RAM: "Do Not Use" in 7800 mode.
				16'b0000_010x_1xxx_xxxx: cs = `CS_RIOT_RAM;
				16'b0000_0010_1xxx_xxxx: cs = `CS_RIOT_IO;

				// 1800-1FFF: 2K RAM.
				16'b0001_1xxx_xxxx_xxxx: cs = `CS_RAM1;

				// 0040-00FF: Zero Page (Local variable space)
				// 0140-01FF: Stack
				16'b0000_000x_01xx_xxxx,
				16'b0000_000x_1xxx_xxxx,

				// 2000-27FF: 2K RAM. Zero Page and Stack mirrored from here.
				16'b0010_0xxx_xxxx_xxxx: cs = `CS_RAM0;

				// TIA Registers:
				// 0000-001F, 0100-001F, 0200-021F, 0300-031F
				// All mirrors are ranges of the same registers
				16'b0000_00xx_000x_xxxx: cs = `CS_TIA;

				// MARIA Registers:
				// 0020-003F, 0120-003F, 0220-023F, 0320-033F
				// All ranges are mirrors of the same registers
				16'b0000_00xx_001x_xxxx: cs = `CS_MARIA;
				default: cs = `CS_CART;

		endcase else casex (AB)
				16'bxxx0_xx0x_1xxx_xxxx: cs = `CS_RIOT_RAM;
				16'bxxx0_xx1x_1xxx_xxxx: cs = `CS_RIOT_IO;
				16'bxxx0_xxxx_0xxx_xxxx: cs = `CS_TIA;
				default: cs = `CS_CART;
		endcase

		if (bios_en & AB[15])
			cs = `CS_BIOS;
	end

	always_ff @(posedge sysclock) begin
		if (~reset_b) begin
			ctrl <= {1'b0, 2'b11, 1'b1, 4'b0000}; // Allow skipping bios by disabling dma on reset
			color_map <= 200'b0;
			char_base <= 8'b0;
			DB_out <= 0;
			{ZPH,ZPL} <= pal ? {8'h27, 8'h30} : {8'h00, 8'h84};
		end else if (pclk0) begin
			deassert_ready <= 1'b0;
			if (~we_b && cs == `CS_MARIA) begin
				case(AB[7:0])
					8'h20: color_map[0] <= DB_in; // Background color
					8'h21: color_map[1] <= DB_in;
					8'h22: color_map[2] <= DB_in;
					8'h23: color_map[3] <= DB_in;
					8'h24: deassert_ready <= 1'b1;
					8'h25: color_map[4] <= DB_in;
					8'h26: color_map[5] <= DB_in;
					8'h27: color_map[6] <= DB_in;
					8'h29: color_map[7] <= DB_in;
					8'h2a: color_map[8] <= DB_in;
					8'h2b: color_map[9] <= DB_in;
					8'h2c: ZPH <= DB_in;
					8'h2d: color_map[10] <= DB_in;
					8'h2e: color_map[11] <= DB_in;
					8'h2f: color_map[12] <= DB_in;
					8'h30: ZPL <= DB_in;
					8'h31: color_map[13] <= DB_in;
					8'h32: color_map[14] <= DB_in;
					8'h33: color_map[15] <= DB_in;
					8'h34: char_base <= DB_in;
					8'h35: color_map[16] <= DB_in;
					8'h36: color_map[17] <= DB_in;
					8'h37: color_map[18] <= DB_in;
					8'h39: color_map[19] <= DB_in;
					8'h3a: color_map[20] <= DB_in;
					8'h3b: color_map[21] <= DB_in;
					8'h3c: ctrl <= DB_in;
					8'h3d: color_map[22] <= DB_in;
					8'h3e: color_map[23] <= DB_in;
					8'h3f: color_map[24] <= DB_in;
					default: ;
				endcase
			end else if (we_b && cs == `CS_MARIA) begin
				if (AB[7:0] == 8'h28)
					DB_out <= status_read;
				else
					DB_out <= 8'h0;
			end
		end
	end
endmodule
