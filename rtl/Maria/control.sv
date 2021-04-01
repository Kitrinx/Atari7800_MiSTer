// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.

module control (
	input  logic             mclk0,
	input  logic             mclk1,
	input  logic             maria_en,
	input  logic [15:0]      AB,
	input  logic [7:0]       DB_in,
	output logic [7:0]       DB_out,
	input  logic             RW,

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
	input  logic             reset,
	input  logic             pclk0,
	input  logic             bypass_bios,
	output logic             cs_ram0,
	output logic             cs_ram1,
	output logic             cs_riot,
	output logic             cs_tia,
	output logic             cs_maria
);

	// Internal Memory Mapped Registers
	logic [7:0]              ZPH, ZPL;
	assign sel_slow_clock = ((~maria_en) ? 1'b1 : cs_tia || cs_riot);

	assign ZP = {ZPH, ZPL};

	always_comb begin
		{cs_ram0, cs_ram1, cs_riot, cs_tia, cs_maria} = 0;
		if (maria_en) casex (AB[15:5])
				// RIOT RAM: "Do Not Use" in 7800 mode.
				11'b0000_010x_1xx,
				11'b0000_001x_1xx: cs_riot = 1;

				// 1800-1FFF: 2K RAM.
				11'b0001_1xxx_xxx: cs_ram1 = 1;

				// 0040-00FF: Zero Page (Local variable space)
				// 0140-01FF: Stack
				11'b0000_000x_01x,
				11'b0000_000x_1xx,

				// 2000-27FF: 2K RAM. Zero Page and Stack mirrored from here.
				11'b0010_0xxx_xxx: cs_ram0 = 1;

				// TIA Registers:
				// 0000-001F, 0100-001F, 0200-021F, 0300-031F
				// All mirrors are ranges of the same registers
				11'b0000_00xx_000: cs_tia = 1;

				// MARIA Registers:
				// 0020-003F, 0120-003F, 0220-023F, 0320-033F
				// All ranges are mirrors of the same registers
				11'b0000_00xx_001: cs_maria = 1;
				default: ;

		endcase else casex (AB[15:5])
				11'bXXX0_XX0X_1XX,
				11'bxxx0_xx1x_1xx: cs_riot = 1;
				11'bxxx0_xxxx_0xx: cs_tia = 1;
				default: ;
		endcase
	end

	logic [7:0] ctrl_1;
	always_ff @(posedge clk_sys) begin
		if (reset || ~maria_en) begin
			ctrl_1 <= '1; // Allow skipping bios by disabling dma on reset
			ctrl <= '1;
			color_map <= 200'b0; // FIXME: convert this to RAM?
			char_base <= 8'b0;
			DB_out <= 0;
			{ZPH,ZPL} <= bypass_bios ? (pal ? {8'h27, 8'h30} : {8'h00, 8'h84}) : 8'd0;
		end else if (pclk0) begin
			ctrl <= ctrl_1;
			deassert_ready <= 1'b0;
			if (cs_maria) begin
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
					6'h3c: ctrl_1 <= DB_in;
					6'h3d: color_map[22] <= DB_in;
					6'h3e: color_map[23] <= DB_in;
					6'h3f: color_map[24] <= DB_in;
					default: ;
				endcase
			end else if (RW && cs_maria) begin
				// Maria reads will return 0 if invalid. Not open bus or anything else.
				if (AB[5:0] == 6'h28)
					DB_out <= status_read;
				else
					DB_out <= 8'h0;
			end
		end
	end
endmodule
