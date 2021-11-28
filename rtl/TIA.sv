// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.

// Based on Stella Programmer's Guide, TIA Schematics, and Decapped TIA.

// This design is not the most efficient in the world. There's combinational loops, and there's
// places that seem like they could use clock enables rather continuous logic. The reason I
// ultimately did it this way is because there is frankly tons of analog delays and asynchronous
// clocking that make the outcome of various scenarios fairly unpredictable, and almost
// all of these edge cases seem to come up in one game or another. Thus, I erred on the side
// of accuracy at the price of efficiency.

typedef enum bit [5:0] {
	VSYNC   = 6'h00,  // Write: vertical sync set-clear (D1)
	VBLANK  = 6'h01,  // Write: vertical blank set-clear (D7-6,D1)
	WSYNC   = 6'h02,  // Write: wait for leading edge of hrz. blank (strobe)
	RSYNC   = 6'h03,  // Write: reset hrz. sync counter (strobe)
	NUSIZ0  = 6'h04,  // Write: number-size player-missle 0 (D5-0)
	NUSIZ1  = 6'h05,  // Write: number-size player-missle 1 (D5-0)
	COLUP0  = 6'h06,  // Write: color-lum player 0 (D7-1)
	COLUP1  = 6'h07,  // Write: color-lum player 1 (D7-1)
	COLUPF  = 6'h08,  // Write: color-lum playfield (D7-1)
	COLUBK  = 6'h09,  // Write: color-lum background (D7-1)
	CTRLPF  = 6'h0a,  // Write: cntrl playfield ballsize & coll. (D5-4,D2-0)
	REFP0   = 6'h0b,  // Write: reflect player 0 (D3)
	REFP1   = 6'h0c,  // Write: reflect player 1 (D3)
	PF0     = 6'h0d,  // Write: playfield register byte 0 (D7-4)
	PF1     = 6'h0e,  // Write: playfield register byte 1 (D7-0)
	PF2     = 6'h0f,  // Write: playfield register byte 2 (D7-0)
	RESP0   = 6'h10,  // Write: reset player 0 (strobe)
	RESP1   = 6'h11,  // Write: reset player 1 (strobe)
	RESM0   = 6'h12,  // Write: reset missle 0 (strobe)
	RESM1   = 6'h13,  // Write: reset missle 1 (strobe)
	RESBL   = 6'h14,  // Write: reset ball (strobe)
	AUDC0   = 6'h15,  // Write: audio control 0 (D3-0)
	AUDC1   = 6'h16,  // Write: audio control 1 (D4-0)
	AUDF0   = 6'h17,  // Write: audio frequency 0 (D4-0)
	AUDF1   = 6'h18,  // Write: audio frequency 1 (D3-0)
	AUDV0   = 6'h19,  // Write: audio volume 0 (D3-0)
	AUDV1   = 6'h1a,  // Write: audio volume 1 (D3-0)
	GRP0    = 6'h1b,  // Write: graphics player 0 (D7-0)
	GRP1    = 6'h1c,  // Write: graphics player 1 (D7-0)
	ENAM0   = 6'h1d,  // Write: graphics (enable) missle 0 (D1)
	ENAM1   = 6'h1e,  // Write: graphics (enable) missle 1 (D1)
	ENABL   = 6'h1f,  // Write: graphics (enable) ball (D1)
	HMP0    = 6'h20,  // Write: horizontal motion player 0 (D7-4)
	HMP1    = 6'h21,  // Write: horizontal motion player 1 (D7-4)
	HMM0    = 6'h22,  // Write: horizontal motion missle 0 (D7-4)
	HMM1    = 6'h23,  // Write: horizontal motion missle 1 (D7-4)
	HMBL    = 6'h24,  // Write: horizontal motion ball (D7-4)
	VDELP0  = 6'h25,  // Write: vertical delay player 0 (D0)
	VDELP1  = 6'h26,  // Write: vertical delay player 1 (D0)
	VDELBL  = 6'h27,  // Write: vertical delay ball (D0)
	RESMP0  = 6'h28,  // Write: reset missle 0 to player 0 (D1)
	RESMP1  = 6'h29,  // Write: reset missle 1 to player 1 (D1)
	HMOVE   = 6'h2a,  // Write: apply horizontal motion (strobe)
	HMCLR   = 6'h2b,  // Write: clear horizontal motion registers (strobe)
	CXCLR   = 6'h2c,  // Write: clear collision latches (strobe)
	ENBLO   = 6'h3D,  // Not a real register, used for ENABL OLD
	GRP0O   = 6'h3E,  // Not a real register, used for GRP0 storage
	GRP1O   = 6'h3F   // Not a real register, used for GRP1 storage
} write_registers;

typedef enum bit [3:0] {
	CXM0P   = 4'h0,  // Read collision: D7=(M0,P1); D6=(M0,P0)
	CXM1P   = 4'h1,  // Read collision: D7=(M1,P0); D6=(M1,P1)
	CXP0FB  = 4'h2,  // Read collision: D7=(P0,PF); D6=(P0,BL)
	CXP1FB  = 4'h3,  // Read collision: D7=(P1,PF); D6=(P1,BL)
	CXM0FB  = 4'h4,  // Read collision: D7=(M0,PF); D6=(M0,BL)
	CXM1FB  = 4'h5,  // Read collision: D7=(M1,PF); D6=(M1,BL)
	CXBLPF  = 4'h6,  // Read collision: D7=(BL,PF); D6=(unused)
	CXPPMM  = 4'h7,  // Read collision: D7=(P0,P1); D6=(M0,M1)
	INPT0   = 4'h8,  // Read pot port: D7
	INPT1   = 4'h9,  // Read pot port: D7
	INPT2   = 4'ha,  // Read pot port: D7
	INPT3   = 4'hb,  // Read pot port: D7
	INPT4   = 4'hc,  // Read P1 joystick trigger: D7
	INPT5   = 4'hd   // Read P2 joystick trigger: D7
} read_registers;

typedef struct packed {
	logic edge_p1;  // Clock falling edge for all clocks
	logic edge_p2;  // Clock rising edge for all clocks
	logic level_p1; // Phase 1 for ripple counters
	logic level_p2; // Phase 2 for ripple counters
	logic clock;    // Clock for symmetric clocks
} clock_t;

/////////////////////////////////////////////////////////////////////////////////////////

module lfsr_6
(
	input clk,
	input phi1,
	input phi2,
	input reset,
	input sys_reset,
	output logic [5:0] lfsr
);
	reg [5:0] lfsr_latch1, lfsr_next;

	assign lfsr = reset ? 6'd0 : (phi2 ? lfsr_next : lfsr_latch1);

	always @(posedge clk) begin

		if (phi1)
			lfsr_next <= {~((lfsr_latch1[1] && ~lfsr_latch1[0]) || ~(lfsr_latch1[1] || ~lfsr_latch1[0])), lfsr_latch1[5:1]};

		if (phi2)
			lfsr_latch1 <= lfsr;

		if (reset || sys_reset) begin
			lfsr_latch1 <= 0;
		end
	end

endmodule

module lfsr_6_instant
(
	input clk,
	input phi1,
	input phi2,
	input reset,
	input sys_reset,
	output logic [5:0] lfsr
);
	reg [5:0] lfsr_latch1;

	wire [5:0] lfsr_next = reset ? 6'd0 : {~((lfsr[1] && ~lfsr[0]) || ~(lfsr[1] || ~lfsr[0])), lfsr[5:1]};
	always @(posedge clk) begin
		if (phi1) begin
			lfsr_latch1 <= lfsr_next;
		end

		if (phi2)
			lfsr <= lfsr_latch1;

		if (sys_reset) begin
			lfsr_latch1 <= 0;
			lfsr <= 0;
		end
	end

endmodule

module sr_latch
(
	input clk,
	input reset,
	input r,
	input s,
	output logic q,
	output logic q_n
);

	wire i_val = r ? 1'd0 : (s ? 1'd1 : sr_val);
	logic sr_val, sr_val_n;
	assign q_n = (r & s) ? 1'd0 : ~q;
	assign q = i_val;

	always @(posedge clk) begin
		sr_val <= i_val;
		if (reset)
			sr_val <= 1'd0;
	end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module f_cell
(
	input  logic   clk,
	input  logic   reset,
	input  logic   tick,
	input  logic   r_n,
	input  logic   s_n,
	output logic   q_n,
	output logic   q
);
	logic q_in, qn_in;

	sr_latch in_sr
	(
		.clk        (clk),
		.reset      (reset),
		.r          (~(tick || s_n)),
		.s          (~(tick || r_n) || reset),
		.q          (q_in),
		.q_n        (qn_in)
	);

	sr_latch out_sr
	(
		.clk        (clk),
		.reset      (reset),
		.r          ((q_in && tick) || reset),
		.s          (qn_in && tick),
		.q          (q),
		.q_n        (q_n)
	);

endmodule

module f_counter_ll
(
	input  logic   clk,
	input  logic   reset,
	input  logic   sys_reset,
	input  logic   tick,
	output clock_t clock,
	output logic   f1_qn,
	output logic   f1_q_l
);

	logic q_left, q_left_n, q_right, q_right_n;
	logic f1_q_l_l;

	assign clock.clock = 0; // Edges and clock are unused for the ripple counter low level
	assign clock.edge_p1 = 0;
	assign clock.edge_p2 = 0;
	assign clock.level_p1 = ~(q_left || q_right);
	assign clock.level_p2 = ~(q_left_n || q_right_n);
	assign f1_qn = q_right_n;

	f_cell f_left
	(
		.clk        (clk),
		.reset      (reset || sys_reset),
		.tick       (tick),
		.s_n        (q_right),
		.r_n        (q_right_n),
		.q          (q_left),
		.q_n        (q_left_n)
	);

	f_cell f_right
	(
		.clk        (clk),
		.reset      (reset || sys_reset),
		.tick       (tick),
		.s_n        (q_left_n),
		.r_n        (q_left),
		.q          (q_right),
		.q_n        (q_right_n)
	);

	sr_latch q_1l
	(
		.clk        (clk),
		.reset      (sys_reset),
		.r          (~q_right_n),
		.s          (reset),
		.q          (f1_q_l),
		.q_n        ()
	);
endmodule

module d_cell
(
	input  logic   clk,
	input  logic   reset,
	input  logic   phi1,
	input  logic   phi2,
	input  logic   in,
	output logic   out
);
	logic out_next, out_latch;

	assign out = reset ? 1'd0 : (phi2 ? out_next : out_latch);

	always @(posedge clk) begin
		if (phi1)
			out_next <= in;

		if (phi2)
			out_latch <= out_next;

		if (reset) begin
			out_latch <= 0;
			out_next <= 0;
		end
	end
endmodule

module inverter_reg
(
	input clk,
	input reset,
	input set,
	input in,
	output out
);

	logic inv_latch = 0;
	// FIXME: I'm treating this as a gate delay since I am using a 14mhz clock for this design,
	// but with slower clocks, this may need to be continuous to work correctly.
	assign out = /*set ? in : */inv_latch;

	always @(posedge clk) begin
		if (set)
			inv_latch <= in;
		if (reset)
			inv_latch <= 0;
	end
endmodule


/////////////////////////////////////////////////////////////////////////////////////////
module f_counter
(
	input  logic   clk,
	input  logic   reset,
	input  logic   sys_reset,
	input  logic   tick,
	output clock_t clock,
	output logic   f1_qn,
	output logic   f1_qn_edge,
	output logic   f1_q_l
);

// This component re-occurs throughout the design multiple times and contains two
// F1 cells, effectively creating a counter that goes from 0 to 3 and then resets, flipping the
// clock on two of the four positions.

// This does not generate a symmetric clock. It is a four phase ripple counter, so PH1 and
// PH2 will only be high for one clock each out of four clocks total.

localparam EDGE_P1 = 3;
localparam LEVEL_P1 = 0;
localparam EDGE_P2 = 1;
localparam LEVEL_P2 = 2;

// Left      Right
// q   qn    q   qn
// 0    1    0    1
// 1    0    0    1
// 1    0    1    0
// 0    1    1    0

logic [1:0] f_count = 0;
logic old_tick, old_reset;
logic f1_qn_reg;

wire tick_edge = ~old_tick && tick;

assign clock.edge_p1 = tick_edge && ((f_count == EDGE_P1) || reset && ~clock.level_p1);
assign clock.edge_p2 = tick_edge && (f_count == EDGE_P2) && ~clock.level_p2 && ~reset;
assign clock.level_p1 = (f_count == LEVEL_P1) || reset && old_reset;
assign clock.level_p2 = (f_count == LEVEL_P2);
assign f1_qn_edge = tick_edge && f_count == 3;
assign f1_qn = (f_count == 0 || f_count == 1);
assign f1_q_l = reset ? 1'd1 : (~f1_qn ? 1'd0 : f1_qn_reg);
assign clock.clock = 0; // Clock is unused for ripple counters!!

always_ff @(posedge clk) begin
	old_tick <= tick;
	old_reset <= reset;

	if (tick_edge) begin
		f_count <= f_count + 1'd1;
	end

	if (reset || sys_reset) begin
		f_count <= reset ? 1'd1 : 2'd0;
		if (sys_reset) old_tick <= 0;
		if (reset)
			f1_qn_reg <= 1;
	end

	if (~f1_qn)
		f1_qn_reg <= 0;

end

endmodule

module cpuclk
(
	input         clk,
	input         reset,
	input clock_t oclk,
	input         resp0,
	output        phi0
);

	logic q_1, q_2, q_3, q_4;
	logic qn_1, qn_2, qn_3, qn_4;

	assign phi0 = (q_1 || q_4);

	wire q_3_nor = ~(q_4 || qn_2);

	sr_latch q_1l
	(
		.clk    (clk),
		.reset  (reset),
		.r      (~(oclk.clock || q_4)),
		.s      (~(oclk.clock || qn_4)),
		.q      (q_1),
		.q_n    (qn_1)
	);

	sr_latch q_2l
	(
		.clk    (clk),
		.reset  (reset),
		.r      (oclk.clock && q_1),
		.s      ((oclk.clock && qn_1) || resp0),
		.q      (q_2),
		.q_n    (qn_2)
	);

	sr_latch q_3l
	(
		.clk    (clk),
		.reset  (reset),
		.r      (~(oclk.clock || ~q_3_nor)),
		.s      (~(oclk.clock || q_3_nor)),
		.q      (q_3),
		.q_n    (qn_3)
	);

	sr_latch q_4l
	(
		.clk    (clk),
		.reset  (reset),
		.r      (oclk.clock && q_3),
		.s      ((oclk.clock && qn_3) || resp0),
		.q      (q_4),
		.q_n    (qn_4)
	);
endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module clockgen
(
	input  logic   clk,    // System clock
	input  logic   is_7800,
	input  logic   ce,     // clock enable. This is expected to be 7.159091 mhz, 2x the original atari oscillator
	input  logic   reset,  // reset signal
	input  logic   rsync,  // RSYNC register written to
	input  logic   rsynd,  // rsynd wire coming from the horizontal lfsr decoder
	input  logic   pext_1, // CPU clk Phi1 external (7800)
	input  logic   pext_2, // CPU clk Phi0/2 external
	output logic   rsynl,  // RSYNC latch
	output clock_t pclk, // CPU clock
	output clock_t hclk, // Horizontal clock
	output clock_t oclk,  // Oscillator Clock
	output logic   phi0_ll
);

parameter PHI2_EXT = 0;
// Fantastic Clocks and Where To Find Them
// system oscillator - every other CE, 3.1mhz
// motclk            - inverse of the system oscillator while not hblank
// clkp              - pixel clk, inverse of the system oscillator
// horizontal clk    - HP1 and HP2, every four clkp
// pclk              - phi0 = phi2, phi1 = ~phi0. cpu clk, every 3 system oscillator clks

logic oclk_tog;
logic [2:0] pclk_div;
logic pclock;
wire pclk_edge = (oclk.edge_p1 || oclk.edge_p2);
assign oclk.edge_p2 = oclk_tog && ce;
assign oclk.edge_p1 = ~oclk_tog && ce;
assign oclk.level_p1 = ~oclk.clock;
assign oclk.level_p2 = oclk.clock;

assign pclk.edge_p2 = ((is_7800 || PHI2_EXT) ? pext_2 : (pclk_div == 2) && pclk_edge) && ~pclk.clock; // Phi0 // 0
assign pclk.edge_p1 = (is_7800 ? pext_1 : (pclk_div == 5 || (resp0 && pclk_div == 0)) && pclk_edge) && pclk.clock; // Phi1 // 1
assign pclk.level_p1 = ~pclk.clock;
assign pclk.level_p2 = pclk.clock;

clock_t hclk_ll, hclk_hl;

f_counter hclk_counter
(
	.clk        (clk),
	.reset      (rsync),
	.sys_reset  (reset),
	.tick       (oclk.edge_p2),
	.clock      (hclk),
	.f1_qn      (),
	.f1_q_l     (rsynl)
);

wire resp0 = (hclk.level_p2 && rsynd) || reset;

// This is an original cpu clock divider purely for reference purposes. I left it in case
// anyone ever wanted to use it for research.

// cpuclk pclk_gen
// (
// 	.clk        (clk),
// 	.reset      (reset),
// 	.oclk       (oclk),
// 	.resp0      (resp0),
// 	.phi0       (phi0_ll)
// );
assign phi0_ll = 0;

always_ff @(posedge clk) begin : phi0_gen
	// Oscillator Clock
	if (ce) begin
		oclk_tog <= ~oclk_tog;
	end

	if (oclk.edge_p2) begin
		oclk.clock <= 1;
	end else if (oclk.edge_p1) begin
		oclk.clock <= 0;
	end

	// CPU Clock
	if (pclk_edge) begin
		pclk_div <= (pclk_div == 5) ? 3'd0 : pclk_div + 1'd1;
	end

	if (pclk.edge_p2)
		pclk.clock <= 1'b1;
	else if (pclk.edge_p1)
		pclk.clock <= 1'b0;

	if (hclk.edge_p2 && rsynd) begin
		pclk_div <= 3'd2;
	end

	if (reset) begin
		pclk_div <= 3'd4;
		oclk_tog <= 0;
		oclk.clock <= '0;
		pclk.clock  <= 0;
	end
end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module horiz_gen
(
	input logic clk,
	input logic rst,
	input clock_t hclk,
	input logic rsynl,
	input logic sec,
	output logic hsync,
	output logic CB,
	output logic cntd,
	output logic cnt,
	output logic hblank, // Hblank signal with proper delays for hmove
	output logic hgap, // Hblank signal without delay
	output logic aud0, // Audio clocks need to be high twice per line
	output logic aud1,
	output logic shb,
	output logic rhb,
	output logic rsynd
);

	logic [5:0] lfsr;
	logic sec_latch, sec_latch_n;
	
	logic err, rhs, rcb, shs, lrhb, ehb;
	logic aud1_l, aud2_l;
	logic rhs_d;
	logic hblank_n, hgap_n;
	
	assign aud0 = aud1_l;
	assign aud1 = aud2_l;
	wire eer = (ehb || rsynl || err);
	
	lfsr_6 timing_lfsr
	(
		.clk       (clk),
		.phi1      (hclk.level_p1),
		.phi2      (hclk.level_p2),
		.reset     (shb || rst),
		.sys_reset (rst),
		.lfsr      (lfsr)
	);

	always_comb begin
		{err, rhs, ehb, cnt, shs, lrhb, rhb, rcb} = '0;
		case (lfsr)
				6'b111111: err  = 1;    // Error
				6'b010100: ehb  = 1;    // End (Set Hblank)
				6'b110111: rhs  = 1;    // Reset HSync
				6'b101100: cnt  = 1;    // Center
				6'b001111: rcb  = 1;    // Reset Color Burst
				6'b111100: shs  = 1;    // Set Hsync
				6'b011100: rhb  = 1;    // Reset HBlank
				6'b010111: lrhb = 1;    // Late Reset Hblank
				default: ;
		endcase
	end

	sr_latch sec_l
	(
		.clk    (clk),
		.reset  (rst),
		.r      (sec),
		.s      (shb),
		.q      (sec_latch),
		.q_n    (sec_latch_n)
	);

	inverter_reg rsynd_ir(clk, rst, hclk.level_p1, eer, rsynd);
	inverter_reg shb_ir(clk, rst, hclk.level_p2, rsynd, shb);

	d_cell aud1_d
	(
		.clk        (clk),
		.reset      (rst),
		.phi1       (hclk.level_p1),
		.phi2       (hclk.level_p2),
		.in         (shb || lrhb),
		.out        (aud1_l)
	);

	d_cell aud2_d
	(
		.clk        (clk),
		.reset      (rst),
		.phi1       (hclk.level_p1),
		.phi2       (hclk.level_p2),
		.in         (rhs || cnt),
		.out        (aud2_l)
	);

	d_cell rhs_db
	(
		.clk        (clk),
		.reset      (rst),
		.phi1       (hclk.level_p1),
		.phi2       (hclk.level_p2),
		.in         (rhs),
		.out        (rhs_d)
	);

	d_cell hsync_dl
	(
		.clk        (clk),
		.reset      (rst || rhs_d),
		.phi1       (hclk.level_p1),
		.phi2       (hclk.level_p2),
		.in         (hsync || shs),
		.out        (hsync)
	);

	wire hb_1a = sec_latch && rhb;
	wire hb_1b = sec_latch_n && lrhb;

	d_cell hblank_dl
	(
		.clk        (clk),
		.reset      (rst || shb),
		.phi1       (hclk.level_p1),
		.phi2       (hclk.level_p2),
		.in         (hblank_n || hb_1a || hb_1b),
		.out        (hblank_n)
	);

	assign hblank = ~hblank_n;

	d_cell hgap_dl
	(
		.clk        (clk),
		.reset      (rst || shb),
		.phi1       (hclk.level_p1),
		.phi2       (hclk.level_p2),
		.in         (hgap_n || rhb),
		.out        (hgap_n)
	);

	assign hgap = ~hgap_n;

	d_cell cb_dl
	(
		.clk        (clk),
		.reset      (rst || rhs_d),
		.phi1       (hclk.level_p1),
		.phi2       (hclk.level_p2),
		.in         (CB || rcb),
		.out        (CB)
	);

	d_cell cnt_d
	(
		.clk        (clk),
		.reset      (rst),
		.phi1       (hclk.level_p1),
		.phi2       (hclk.level_p2),
		.in         (cnt),
		.out        (cntd)
	);

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module hmove_gen
(
	input  logic       clk,
	input  logic       reset,
	input  clock_t     hclk,
	input  clock_t     oclk,
	input  clock_t     pclk,
	input  logic       hmove,
	input  logic       hblank,
	input  logic [3:0] p0_m,
	input  logic [3:0] p1_m,
	input  logic [3:0] m0_m,
	input  logic [3:0] m1_m,
	input  logic [3:0] bl_m,
	output logic       sec,
	output logic       p0_mclk,
	output logic       p1_mclk,
	output logic       m0_mclk,
	output logic       m1_mclk,
	output logic       bl_mclk
);
	logic [1:0] p0ec, p1ec, m0ec, m1ec, blec;
	logic [3:0] hmove_cnt;
	logic sec_1, sec_0;
	logic hmove_latch;

	wire [3:0] hmc_uns = {~hmove_cnt[3], hmove_cnt[2:0]};

	assign p0_mclk = (p0ec[1] && hclk.level_p1);
	assign p1_mclk = (p1ec[1] && hclk.level_p1);
	assign m0_mclk = (m0ec[1] && hclk.level_p1);
	assign m1_mclk = (m1ec[1] && hclk.level_p1);
	assign bl_mclk = (blec[1] && hclk.level_p1);

	sr_latch hmove_l
	(
		.clk    (clk),
		.reset  (reset),
		.r      (sec_1),
		.s      (hmove),
		.q      (hmove_latch),
		.q_n    ()
	);

	inverter_reg s0_ir(clk, reset, hclk.level_p1, hmove_latch, sec_0);
	inverter_reg sec_ir(clk, reset, hclk.level_p2, sec_0, sec);
	inverter_reg sec1_ir(clk, reset, hclk.level_p1, sec, sec_1);

	always @(posedge clk) begin : hmove_block
		if (hclk.edge_p2) begin
			if (sec || |hmove_cnt)
				hmove_cnt <= hmove_cnt + 1'd1;
			{p0ec[1], p1ec[1], m0ec[1], m1ec[1], blec[1]} <= {p0ec[0], p1ec[0], m0ec[0], m1ec[0], blec[0]};
		end

		if (hclk.level_p1) begin
			if (sec)
				{p0ec[0], p1ec[0], m0ec[0], m1ec[0], blec[0]} <= 5'b11111;
			if (p0_m[3:0] == hmc_uns)
				p0ec[0] <= 0;
			if (p1_m[3:0] == hmc_uns)
				p1ec[0] <= 0;
			if (m0_m[3:0] == hmc_uns)
				m0ec[0] <= 0;
			if (m1_m[3:0] == hmc_uns)
				m1ec[0] <= 0;
			if (bl_m[3:0] == hmc_uns)
				blec[0] <= 0;
		end

		if (reset) begin
			{p0ec, p1ec, m0ec, m1ec, blec} <= 10'd0;
			hmove_cnt <= 0;
		end
	end

endmodule


/////////////////////////////////////////////////////////////////////////////////////////

module playfield
(
	input         clk,     // Master clock
	input         reset,   // System reset
	input logic   clkp,    // Pixel Clock
	input clock_t hclk,    // Horizontal clock phase 2
	input         reflect, // Control playfield, 1 makes right half mirror image
	input         cnt,     // center signal, high means right half
	input         rhb,     // Reset HBlank signal
	input [19:0]  pfc,     // Combined playfield registers
	output logic  pf       // Playfield graphics
);

	logic [4:0] pf_index, pf_next, pf_latch2, pf_latch1;
	logic pf_1, pf_2, pf_3;

	// Outputs in order PF0 4..7, PF1 7:0, PF2 0:7
	logic [4:0] index_lut[20];

	wire pf_reset = rhb || (cnt && ~reflect);
	wire pf_reflect = (cnt && reflect);

	assign index_lut = '{
		5'd00, 5'd01, 5'd02, 5'd03,                             // PF0
		5'd11, 5'd10, 5'd09, 5'd08, 5'd07, 5'd06, 5'd05, 5'd04, // PF1 in reverse
		5'd12, 5'd13, 5'd14, 5'd15, 5'd16, 5'd17, 5'd18, 5'd19  // PF2
	};

	logic [4:0] pf_latch;
	logic dir;

	assign pf_index = pf_reset ? 1'd0 : (hclk.level_p2 ? pf_latch1 : pf_latch2);
	assign pf_next = dir ? (|pf_index ? pf_index - 1'd1 : 5'd0) : (pf_index < 19 ? pf_index + 1'd1 : 5'd19);

	assign pf_1 = pfc[index_lut[pf_index]];

	f_cell pf_out
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (clkp),
		.s_n        (~pf_3),
		.r_n        (pf_3),
		.q          (pf),
		.q_n        ()
	);

	sr_latch dir_l
	(
		.clk        (clk),
		.reset      (reset),
		.r          (pf_reset),
		.s          (pf_reflect),
		.q          (dir),
		.q_n        ()
	);

	inverter_reg pf1_ir(clk, reset, hclk.level_p1, pf_1, pf_2);
	inverter_reg pf2_ir(clk, reset, hclk.level_p2, pf_2, pf_3);

	always @(posedge clk) begin : pf_block
		if (hclk.level_p1) begin
			pf_latch1 <= pf_next;
		end

		if (hclk.level_p2) begin
			pf_latch2 <= pf_latch1;
		end
	end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module object_tick
(
	input clk,
	input reset,
	input motck,
	input ec,
	output tick
);
	// The reason for signal this centers around an analog delay of around 21ns which causes an
	// extra clock edge to form if the hmove counter is glitched into remaining on during non-hblank
	// clocks. This was discovered by Crispy and is available in this topic here:
	// https://atariage.com/forums/topic/261596-cosmic-ark-star-field-revisited/
	logic old_motck, old_ec;

	wire edge_miss = (old_motck && ~motck) && (~old_ec && ec);
	assign tick = (motck || ec) && ~edge_miss;
	always @(posedge clk) begin
		old_motck <= motck;
		old_ec <= ec;
		if (reset) begin
			old_motck <= 0;
			old_ec <= 0;
		end
	end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////

module ball
(
	input       clk,         // Master Clock
	input       reset,       // System Reset
	input       clkp,        // Pixel Clock
	input       motck,       // Motion Clock (real clock)
	input       blec,        // Ball extra clock
	input       blre,        // Ball reset signal
	input       blen,        // Ball enable register
	input       blen_o,      // Ball enable register (last)
	input       blvd,        // Ball vdel
	input [1:0] blsiz,       // Ball size register
	output      bl           // Ball graphics output
);
	clock_t objclk;

	logic [1:0] d1l_1, d1l_2;
	logic [5:0] lfsr;
	logic fc1_qn;
	logic q_or_res;

	wire object_tick;
	wire object_reset = (lfsr == 6'b111111 || lfsr == 6'b101101 || q_or_res);

	object_tick bl_tick
	(
		.clk        (clk),
		.reset      (reset),
		.motck      (motck),
		.ec         (blec),
		.tick       (object_tick)
	);

	f_counter_ll object_counter
	(
		.clk        (clk),
		.reset      (blre),
		.sys_reset  (reset),
		.tick       (object_tick),
		.clock      (objclk),
		.f1_qn      (fc1_qn),
		.f1_q_l     (q_or_res)
	);

	lfsr_6 object_lfsr
	(
		.clk       (clk),
		.phi1      (objclk.level_p1),
		.phi2      (objclk.level_p2),
		.reset     (~d1l_1[1]),
		.sys_reset (reset),
		.lfsr      (lfsr)
	);

	wire gr1  = ~((~blvd && blen) || (blvd && blen_o));
	wire gr2a = ~(~blsiz[1] || ~blsiz[0] || d1l_2[1] || gr1);
	wire gr2b = ~(~blsiz[0] || fc1_qn);
	wire gr3  = ~(blsiz[1] || gr2b || objclk.level_p2);
	wire gr4  = ~(gr1 || gr3 || d1l_1[1]);
	wire gr5 = ~(gr2a || gr4);

	f_cell ball_out
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (clkp),
		.s_n        (gr5),
		.r_n        (~gr5),
		.q          (bl),
		.q_n        ()
	);

	d_cell obj_1
	(
		.clk        (clk),
		.reset      (reset),
		.phi1       (objclk.level_p1),
		.phi2       (objclk.level_p2),
		.in         (~object_reset),
		.out        (d1l_1[1])
	);

	d_cell obj_2
	(
		.clk        (clk),
		.reset      (reset),
		.phi1       (objclk.level_p1),
		.phi2       (objclk.level_p2),
		.in         (d1l_1[1]),
		.out        (d1l_2[1])
	);

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module missile
(
	input       clk,        // Master Clock
	input       reset,      // System Reset
	input       clkp,       // Pixel clock
	input       motck,      // Motion Clock (real clock)
	input       mec,        // Missile extra clock
	input       mre,        // Missile reset signal
	input       men,        // Missile enable register
	input [5:0] nusiz,      // Player/missile size
	output      m           // Missile graphics output
);

	clock_t objclk;

	logic [1:0] d1l_1, d1l_2;
	logic [5:0] lfsr;
	logic fc1_qn;
	logic or_d;

	wire object_tick;
	wire [1:0] m_size_n = ~nusiz[5:4];
	wire [2:0] ns_sel = nusiz[2:0];
	wire q_or_res;
	wire object_reset = (lfsr == 6'b111111 || lfsr == 6'b101101 || q_or_res);
	wire object_draw = (lfsr == 6'b101101) ||
		((lfsr == 6'b111000) && ((ns_sel == 3'b001) || (ns_sel == 3'b011))) ||
		((lfsr == 6'b101111) && ((ns_sel == 3'b011) || (ns_sel == 3'b010)   || (ns_sel == 3'b110))) ||
		((lfsr == 6'b111001) && ((ns_sel == 3'b100) || (ns_sel == 3'b110)));

	object_tick m_tick
	(
		.clk        (clk),
		.reset      (reset),
		.motck      (motck),
		.ec         (mec),
		.tick       (object_tick)
	);

	f_counter_ll object_counter
	(
		.clk        (clk),
		.reset      (mre),
		.sys_reset  (reset),
		.tick       (object_tick),
		.clock      (objclk),
		.f1_qn      (fc1_qn),
		.f1_q_l     (q_or_res)
	);

	lfsr_6 object_lfsr
	(
		.clk       (clk),
		.phi1      (objclk.level_p1),
		.phi2      (objclk.level_p2),
		.reset     (or_d),
		.sys_reset (reset),
		.lfsr      (lfsr)
	);

	wire mg1  = ~(fc1_qn || m_size_n[0]);
	wire mg2a = ~(mg1 || objclk.level_p2 || ~m_size_n[1]);
	wire mg2b = ~(~men || m_size_n[1] || d1l_2[1] || m_size_n[0]);
	wire mg3  = ~(mg2a || ~men || d1l_1[1]);
	wire mg4  = ~(mg3 || mg2b);

	f_cell mis_out
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (clkp),
		.s_n        (mg4),
		.r_n        (~mg4),
		.q          (m),
		.q_n        ()
	);

	d_cell obj_1
	(
		.clk        (clk),
		.reset      (reset),
		.phi1       (objclk.level_p1),
		.phi2       (objclk.level_p2),
		.in         (object_reset),
		.out        (or_d)
	);

	d_cell obj_2
	(
		.clk        (clk),
		.reset      (reset),
		.phi1       (objclk.level_p1),
		.phi2       (objclk.level_p2),
		.in         (~object_draw),
		.out        (d1l_1[1])
	);

	d_cell obj_3
	(
		.clk        (clk),
		.reset      (reset),
		.phi1       (objclk.level_p1),
		.phi2       (objclk.level_p2),
		.in         (d1l_1[1]),
		.out        (d1l_2[1])
	);

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module player
(
	input       clk,        // Master Clock
	input       reset,      // System Reset
	input       clkp,       // Pixel Clock
	input       motck,      // Motion Clock (real clock)
	input       pec,        // Player extra clock
	input       pre,        // Player reset signal
	input       pvdel,      // Player Vertical Delay
	input       m2pr,       // Missile To Player Reset Enabled
	input       pref,       // player reflect
	input [5:0] nusiz,      // Player size
	input [7:0] grpnew,     // Player graphic (new)
	input [7:0] grpold,     // Player graphic (delayed)
	output      msrst,      // Missile to player reset signal
	output      p           // Player graphics output
);
	clock_t objclk;

	logic [1:0] d1l_1, d1l_2;
	logic [5:0] lfsr;
	logic fstob;
	logic fc1_qn;
	logic ena_n;
	logic start_n;
	logic f_psc1_q, f_psc1_q_n, f_psc2_q, f_psc2_q_n, f_psc3_q, f_psc3_q_n;
	logic go_n;
	logic or_d;
	logic [2:0] gs;

	wire object_tick;
	wire [2:0] ns_sel = nusiz[2:0];
	wire q_or_res;
	wire object_reset = (lfsr == 6'b111111 || lfsr == 6'b101101 || q_or_res);
	wire object_fstob =
		((lfsr == 6'b111000) && ((ns_sel == 3'b001) || (ns_sel == 3'b011))) ||
		((lfsr == 6'b101111) && ((ns_sel == 3'b011) || (ns_sel == 3'b010)   || (ns_sel == 3'b110))) ||
		((lfsr == 6'b111001) && ((ns_sel == 3'b100) || (ns_sel == 3'b110)));

	wire object_draw = (lfsr == 6'b101101) || object_fstob;
	wire pns = ~(~nusiz[0] || ~nusiz[2]);
	wire pns2 = objclk.level_p1 && ~nusiz[1];
	wire count_n = ~(~pns || pns2 || objclk.level_p2);
	wire stop = ~(f_psc1_q_n || f_psc2_q_n || f_psc3_q_n);
	wire start_stop = ~(start_n && stop);
	wire newgrp = grpnew[gs];
	wire oldgrp = grpold[gs];

	assign msrst = ~(fstob || ena_n || object_tick || f_psc3_q || f_psc2_q || f_psc1_q_n || ~m2pr);
	assign gs[0] = ~((pref && f_psc1_q_n) || (~pref && f_psc1_q));
	assign gs[1] = ~((pref && f_psc2_q_n) || (~pref && f_psc2_q));
	assign gs[2] = ~((pref && f_psc3_q_n) || (~pref && f_psc3_q));

	object_tick p_tick
	(
		.clk        (clk),
		.reset      (reset),
		.motck      (motck),
		.ec         (pec),
		.tick       (object_tick)
	);

	f_counter_ll object_counter
	(
		.clk        (clk),
		.reset      (pre),
		.sys_reset  (reset),
		.tick       (object_tick),
		.clock      (objclk),
		.f1_qn      (fc1_qn),
		.f1_q_l     (q_or_res)
	);

	lfsr_6 object_lfsr
	(
		.clk       (clk),
		.phi1      (objclk.level_p1),
		.phi2      (objclk.level_p2),
		.reset     (or_d),
		.sys_reset (reset),
		.lfsr      (lfsr)
	);

	wire pl_1a = ~(go_n || ~oldgrp || ~pvdel);
	wire pl_1b = ~(go_n || ~newgrp || pvdel);
	wire pl_2 = ~(pl_1a || pl_1b);

	f_cell pl_out
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (clkp),
		.s_n        (pl_2),
		.r_n        (~pl_2),
		.q          (p),
		.q_n        ()
	);

	d_cell obj_reset
	(
		.clk        (clk),
		.reset      (reset),
		.phi1       (objclk.level_p1),
		.phi2       (objclk.level_p2),
		.in         (object_reset),
		.out        (or_d)
	);

	d_cell obj_start
	(
		.clk        (clk),
		.reset      (reset),
		.phi1       (objclk.level_p1),
		.phi2       (objclk.level_p2),
		.in         (~object_draw),
		.out        (start_n)
	);

	d_cell obj_fstob
	(
		.clk        (clk),
		.reset      (reset || or_d),
		.phi1       (objclk.level_p1),
		.phi2       (objclk.level_p2),
		.in         (fstob || object_fstob),
		.out        (fstob)
	);

	f_cell f_ena
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (object_tick),
		.s_n        (count_n),
		.r_n        (~count_n),
		.q          (),
		.q_n        (ena_n)
	);

	f_cell f_go
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (object_tick),
		.s_n        (ena_n || start_n),
		.r_n        (ena_n || start_stop),
		.q          (),
		.q_n        (go_n)
	);

	wire ena_n_or_go_n = (ena_n || go_n);

	f_cell f_psc1
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (object_tick),
		.s_n        (ena_n_or_go_n || f_psc1_q),
		.r_n        (ena_n_or_go_n || f_psc1_q_n),
		.q          (f_psc1_q),
		.q_n        (f_psc1_q_n)
	);

	wire ena_n_or_go_2 = (ena_n_or_go_n || f_psc1_q_n);

	f_cell f_psc2
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (object_tick),
		.s_n        (ena_n_or_go_2 || f_psc2_q),
		.r_n        (ena_n_or_go_2 || f_psc2_q_n),
		.q          (f_psc2_q),
		.q_n        (f_psc2_q_n)
	);

	wire ena_n_or_go_3 = (ena_n_or_go_2 || f_psc2_q_n);

	f_cell f_psc3
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (object_tick),
		.s_n        (ena_n_or_go_3 || f_psc3_q),
		.r_n        (ena_n_or_go_3 || f_psc3_q_n),
		.q          (f_psc3_q),
		.q_n        (f_psc3_q_n)
	);

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module priority_encoder
(
	input           clk,
	input           ce,
	input           p0,
	input           m0,
	input           p1,
	input           m1,
	input           pf,
	input           bl,
	input           blank,
	input           decomb,
	input           cntd,
	input           pfp,
	input           score,
	output [3:0]    col_select // {bk, pf, p1, p0}
);

	// Normal priority:
	// 0: P0, M0
	// 1: P1, M1
	// 2: PF, BL
	// 3: BK

	// PFP:
	// 0: PF, BL
	// 1: P0, M0
	// 2: P1, M1
	// 3: BK

	// When a one is written into the score control bit, the playfield is forced
	// to take the color-lum of player 0 in the left half of the screen and player
	// 1 in the right half of the screen.
	logic rs_q;
	logic rs_qn;

	sr_latch center_delayed
	(
		.clk    (clk),
		.reset  (),
		.r      (blank),
		.s      (cntd),
		.q      (rs_q),
		.q_n    (rs_qn)
	);

	wire score_n = ~score;
	wire pfp_n = ~pfp;

	wire pf_n = ~pf;
	wire pf_nor_bl = ~(pf || bl);
	wire pr_1a = ~(rs_q || pf_n || score_n);
	wire pr_1b = ~(pf_n || score_n || rs_qn);
	wire pr_2a = ~(p0 || m0 || pr_1a);
	wire pr_2b = ~(p1 || m1 || pr_1b);
	wire pr_2c = ~(pf_nor_bl || pfp_n);

	wire sel_p0 = ~(blank || pr_2a || pr_2c);
	wire sel_p1 = ~(blank || pr_2b || pr_2c || sel_p0);
	wire sel_pf = ~(blank || pf_nor_bl || sel_p1 || sel_p0);
	wire sel_bk = ~(blank || sel_pf || sel_p1 || sel_p0);

	assign col_select = {sel_bk, sel_pf, sel_p1, sel_p0};

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module audio_channel
(
	input           clk,
	input           reset,
	input           ce,
	input           aud0,
	input           aud1,
	input  [3:0]    volume,
	input  [4:0]    freq,
	input  [3:0]    audc,
	output [3:0]    audio
);

	// Audio is quite a lot of convoluted wide nors and odd shifting, so
	// I just got sick of trying to simplify it and did it at gate level.

	// Frequency divider area signals
	logic [4:0] freq_div, freq_latch, freq_next;
	logic freq_match, freq_div1, freq_div2;
	logic T1, T2;

	// Noise area signals
	logic [4:0] noise, noise_latch, noise_next;
	logic noise_wnor_1;
	logic noise_wnor_2;
	logic nor1, nor2, nor3, nor4, nor5, nor6, nor7, nor8;
	logic and1, and2;
	logic noise0_latch_n;
	logic nor2_latch;

	// Pulse area signals
	logic nor_a, nor_b, nor_c, nor_d, nor_e;
	logic pulse_bit;
	logic pulse_wnor_1;
	logic pulse_wnor_2;
	logic rnor1, rnor2, rnor3;
	logic rand1;
	logic pulse3_q, pulse2_q, pulse1_q, pulse0_q;
	logic pulse3_qn, pulse2_qn, pulse1_qn, pulse0_qn;

	// Frequency divider area logic
	assign freq_div = (aud1 ? (~freq_div2 ? 5'd0 : freq_next) : freq_latch);
	assign freq_match = (freq == freq_div);

	inverter_reg freq_div01(clk, reset, aud0, ~freq_match, freq_div1);
	inverter_reg freq_div02(clk, reset, aud1, freq_div1, freq_div2);

	assign T1 = ~|{~aud0, freq_div2};
	assign T2 = ~|{~aud1, freq_div1};

	// Noise area logic
	assign nor1 = ~|{~audc[1:0], noise0_latch_n};
	assign nor2 = ~|{nor1, ~audc[1], noise_wnor_1};
	assign nor3 = ~|{audc[1:0], pulse_wnor_1};
	assign nor4 = ~|audc[1:0];
	assign nor5 = ~|{~noise[2], nor4};
	assign nor6 = ~|{nor5, and1};
	assign nor7 = ~|{nor6, noise[0]};
	assign nor8 = ~|{nor_a, nor7, and2, noise_wnor_2};

	assign and1 = nor4 && pulse0_q;
	assign and2 = noise[0] && nor6;

	assign noise_wnor_1 = ~|{noise[4:2], ~noise[1], audc[0], ~audc[1]};
	assign noise_wnor_2 = ~|{noise, nor3};

	// Pulse area logic
	assign rnor1 = ~|{pulse_wnor_2, pulse1_q};
	assign rnor2 = ~|{pulse1_q, pulse0_q};
	assign rnor3 = ~|{pulse_wnor_1, rnor2, rand1};

	assign rand1 = pulse1_q && pulse0_q;

	assign nor_a = ~|audc;
	assign nor_b = ~|{audc[3:2], rnor3};
	assign nor_c = ~|{~audc[3:2], rnor1};
	assign nor_d = ~|{audc[3], ~audc[2], pulse3_qn};
	assign nor_e = ~|{~audc[3], audc[2], noise0_latch_n};

	assign pulse_bit = ~|{nor_a, nor_b, nor_c, nor_d, nor_e};

	assign pulse_wnor_1 = ~|{pulse3_qn, pulse2_q, pulse1_qn, pulse0_q};
	assign pulse_wnor_2 = ~|{pulse3_q, pulse2_q, pulse1_q};

	inverter_reg noise0_latch(clk, reset, T1, ~noise[0], noise0_latch_n);
	inverter_reg nor2_l(clk, reset, T1, nor2, nor2_latch);

	wire pulse_clock = ~|{~T2, nor2_latch};

	assign noise = T2 ? noise_next : noise_latch;

	f_cell pulse_3
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (pulse_clock),
		.s_n        (~pulse_bit),
		.r_n        (pulse_bit),
		.q          (pulse3_q),
		.q_n        (pulse3_qn)
	);
	f_cell pulse_2
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (pulse_clock),
		.s_n        (pulse3_q),
		.r_n        (pulse3_qn),
		.q          (pulse2_q),
		.q_n        (pulse2_qn)
	);
	f_cell pulse_1
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (pulse_clock),
		.s_n        (pulse2_q),
		.r_n        (pulse2_qn),
		.q          (pulse1_q),
		.q_n        (pulse1_qn)
	);
	f_cell pulse_0
	(
		.clk        (clk),
		.reset      (reset),
		.tick       (pulse_clock),
		.s_n        (pulse1_q),
		.r_n        (pulse1_qn),
		.q          (pulse0_q),
		.q_n        (pulse0_qn)
	);

	always_ff @(posedge clk) begin

		if (aud0)
			freq_next <= freq_div + 1'd1;
		if (aud1)
			freq_latch <= ~freq_div2 ? 5'd0 : freq_next;
		if (T1)
			noise_next <= {~nor8, noise_latch[4:1]};
		if (T2)
			noise_latch <= noise_next;

		if (reset) begin
			freq_next <= 0;
			freq_latch <= 0;
			noise_latch <= 0;
			noise_next <= 0;
		end

	end

	assign audio = ~pulse0_qn ? volume : 4'd0;

endmodule

module video_stabilize
(
	input           clk,        // system clock
	input           reset,      // System reset
	input clock_t   oclk,       // Oscillator clock aka pixel clock or color clock
	input [1:0]     mode,       // 00 = smart, 01 = fixed, 10 = none
	input           vsync_in,   // Unmodified vsync signal
	input           vblank_in,  // Umodified vblank signal
	input           hsync_in,   // Unmodified hsync signal
	input           hblank_in,  // Hblank signal with applicable system delays
	output          vsync,
	output          vblank,
	output          auto_pal,
	output          f1           // Indicates Odd field of interlaced video
);
	localparam ntsc_vb_end = 9'd19; // 19
	localparam pal_vb_end = 9'd23; // 23
	localparam ntsc_vb_start = 9'd240 + ntsc_vb_end; //9'd262;//9'd243;
	localparam pal_vb_start = 9'd288 + pal_vb_end; //9'd312;//9'd288;


	logic [8:0] v_count, total_lines, vsync_line, vsync_end_line;
	logic [7:0] h_count;
	logic old_hblank, old_vblank, old_hsync, old_vsync;
	logic vsync_en, vsync_set, vblank_en, midline_sync, vsync_override, set_end;
	logic [7:0] vsync_count, vblank_count, lines_from_vs;
	logic [7:0] dot_count = 0;
	logic vsync_emulate;

//	wire vblank_start = ~old_vblank && vblank_in;
//	wire vblank_end   = old_vblank && ~vblank_in;
	wire hblank_start = ~old_hblank && hblank_in;
	wire hblank_end   = old_hblank && ~hblank_in;
	wire vsync_start  = ~old_vsync && vsync_in;
//	wire vsync_end    = old_vsync && ~vsync_in;
//	wire hsync_start  = ~old_hsync && hsync_in;
//	wire hsync_end    = old_hsync && ~hsync_in;

	assign vblank = |mode ? vblank_in : vblank_en;
	assign vsync = |mode ? vsync_in : vsync_en;
	assign f1 = 1'b0; // |mode ? 1'b0 : midline_sync; // I could never make this work productively
	assign auto_pal = |mode ? 1'b0 : total_lines >= 290;

	always_ff @(posedge clk) begin
		old_hblank <= hblank_in;
		old_vsync <= vsync_in;
		if (&v_count) begin // Something is whack, emulate a signal
			total_lines <= 9'd262;
			vsync_override <= 1'd1;
			vsync_emulate <= 1'd1;
		end

		// Base new lines on the horizontal LFSR reset
		if (hblank_start) begin
			v_count <= v_count + 1'd1;
			if (v_count == (auto_pal ? pal_vb_end : ntsc_vb_end))
				vblank_en <= 0;
			if (v_count == (auto_pal ? pal_vb_start : ntsc_vb_start) || v_count == ((vsync_override ? vsync_line : total_lines) - 4'd4))
				vblank_en <= 1;

			if ((vsync_override && v_count == (vsync_line - 1'd1)) || vsync_set) begin
				if (vsync_emulate)
					v_count <= 0;
				vsync_en <= 1;
				vsync_set <= 0;
				vblank_en <= 1;
				if (~|vsync_count)
					vsync_count <= 3'd3;
			end
			if (|vsync_count) begin
				vsync_count <= vsync_count - 1'd1;
				if (vsync_count == 1)
					vsync_en <= 0;
			end
		end

		if (oclk.edge_p1)
			dot_count <= dot_count + 1'd1;
		if (hblank_end)
			dot_count <= 0;

		if (vsync_start) begin
			vsync_emulate <= 0;
			if (v_count != total_lines) begin
				vsync_set <= 1;
				if (total_lines - v_count < 3'd4) begin
					vsync_override <= 1;
					vsync_line <= v_count;
				end else if (v_count - total_lines < 3'd4) begin
					vsync_override <= 1;
					vsync_line <= total_lines;
				end else begin
					vsync_override <= 0;
				end
			end
			if (~vsync_override) begin
				vsync_set <= 1;
			end
			v_count <= 0;
			total_lines <= v_count;

			// if (dot_count > 15 && dot_count < 145) // Vsync outside of hblank can be considered invoking interlaced resolutions
			// 	midline_sync <= 1;
			// else
			// 	midline_sync <= 0;
		end

		if (reset) begin
			vsync_emulate <= 0;
			dot_count <= 0;
			vsync_set <= 0;
			vsync_line <= 0;
			vsync_override <= 0;
			total_lines <= 9'd262;
			v_count <= 0;
			vblank_en <= 1;
			vsync_en <= 0;
		end

	end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module TIA
(
	// Original Pins
	input           clk,
	output          phi0,
	input           phi2,
	output logic    phi1,
	input           RW_n,
	output logic    rdy,
	input  [5:0]    addr,
	input  [7:0]    d_in,
	output [7:0]    d_out,
	input  [3:0]    i,     // On real hardware, these would be ADC pins. i0..3
	output [3:0]    i_out,
	input           i4,
	input           i5,
	output [3:0]    aud0,
	output [3:0]    aud1,
	output [3:0]    col,
	output [2:0]    lum,
	output          BLK_n,
	output          sync,
	input           cs0_n,
	input           cs2_n,

	// Abstractions
	input           rst,
	input           ce,     // Clock enable for CLK generation only, should be 2x normal TIA clk
	output          video_ce,
	output          vblank,
	output          hblank,
	output          hgap,
	output          vsync,
	output          hsync,
	input           phi1_in,
	input [7:0]     open_bus,
	input           is_7800,
	input           decomb,
	output logic    cart_ce,
	output logic    [9:0] row,
	output logic    [9:0] column,
	output          is_pal,
	output          is_f1,
	input           stabilize,
	output  [3:0]   paddle_read // Helper to let us autodetect paddles
);

logic [7:0] wreg[64]; // Write registers. Only 44 are used.
logic [7:0] rreg[16]; // Read registers.

logic cs; // Chip Select (cs1 and 3 were NC)
logic wsync,rsync,resp0,resp1,resm0,resm1,resbl,hmove,hmclr,cxclr; // Strobe register signals
logic [3:0] color_select;
logic p0, p1, m0, m1, bl, pf; // Current object active flags
logic aclk0, aclk1, rhb, shb, cnt, cntd; // horizontal triggers
logic sec;
logic hblank_o, vblank_o, vsync_o, hgap_o; // Original video timing signals
logic msrst0, msrst1; // Missile/player reset signals
logic p0ec, p1ec, m0ec, m1ec, blec; // HMOVE Extra clock signals
logic rsynl, rsynd; // Reset synchronization signals
logic motck; // Motion Clock
logic clkp;  // Pixel Clock
logic hblank_d;
logic blank;
logic phi2_delay;

logic old_hblank, old_vsync;
logic [1:0] vsync_count;
logic hgap_1;

clock_t hclk;
clock_t pclk;
clock_t oclk;

assign phi0 = pclk.edge_p2;
assign phi1 = pclk.edge_p1;
assign cs = ~cs0_n && ~cs2_n;
assign video_ce = oclk.edge_p2;
assign BLK_n = blank;
assign sync = ~(hsync || vsync);
assign vsync_o = wreg[VSYNC][1];
assign vblank_o = wreg[VBLANK][1];
assign d_out[5:0] = open_bus[5:0];
assign cart_ce = oclk.edge_p2;
assign motck = ~oclk.clock & ~hblank_d;
assign clkp = ~oclk.clock;

f_cell hgap1_out
(
	.clk        (clk),
	.reset      (rst),
	.tick       (oclk.level_p1),
	.s_n        (~hgap_o),
	.r_n        (hgap_o),
	.q          (hgap_1),
	.q_n        ()
);

f_cell hgap_out
(
	.clk        (clk),
	.reset      (rst),
	.tick       (oclk.level_p1),
	.s_n        (~hgap_1),
	.r_n        (hgap_1),
	.q          (hgap),
	.q_n        ()
);

f_cell hblank_out
(
	.clk        (clk),
	.reset      (rst),
	.tick       (oclk.level_p1),
	.s_n        (~hblank_o),
	.r_n        (hblank_o),
	.q          (hblank),
	.q_n        ()
);

f_cell blank_out
(
	.clk        (clk),
	.reset      (rst),
	.tick       (oclk.level_p1),
	.s_n        (~(~hblank_o && ~vblank_o)),
	.r_n        ((~hblank_o && ~vblank_o)),
	.q          (),
	.q_n        (blank)
);

video_stabilize stab
(
	.clk        (clk),
	.reset      (rst),
	.oclk       (oclk),
	.mode       (stabilize),
	.vsync_in   (vsync_o),
	.vblank_in  (vblank_o),
	.hsync_in   (hsync),
	.hblank_in  (hgap),
	.vsync      (vsync),
	.vblank     (vblank),
	.auto_pal   (is_pal),
	.f1         (is_f1)
);


always_ff @(posedge clk) begin
	old_hblank <= hblank_o;
	old_vsync <= vsync_o;
	hblank_d <= hblank_o;
	if (oclk.edge_p1)
		column <= column + 1'd1;
	if (old_hblank && !hblank_o) begin
		column <= 0;
		row <= row + 1'd1;
	end
	if (old_vsync && !vsync_o)
		row <= 0;
end

// Reads and writes
// NOTE: A realistic attempt at bus stuffing might need the registers to be set in a combinational
// way, but otherwise using the clock enable signal keeps the timings valid.
always_ff @(posedge clk) begin
	phi2_delay <= pclk.level_p2; // Phi2 analog delay
	i_out <= {4{~wreg[VBLANK][7]}};
	if (pclk.edge_p2 || pclk.level_p2) begin
		if (cs && RW_n) begin
			if (addr[3:0] == INPT4 && ~wreg[VBLANK][6]) begin
				d_out[7:6] <= {i4, 1'b0};
			end else if (addr[3:0] == INPT5 && ~wreg[VBLANK][6]) begin
				d_out[7:6] <= {i5, 1'b0};
			end else if (~&addr[3:1]) begin
				d_out[7:6] <= rreg[addr[3:0]][7:6]; // reads only use the lower 4 bits of addr
			end else
				d_out[7:6] <= 2'd0;
		end
		if (cs && ~RW_n && addr <= 6'h2C) begin
			wreg[addr] <= d_in;

			if (addr == GRP0)
				wreg[GRP1O] <= wreg[GRP1];
			if (addr == GRP1) begin
				wreg[GRP0O] <= wreg[GRP0];
				wreg[ENBLO] <= wreg[ENABL];
			end
		end
	end

	// FIXME: Due to analog delays in the chip, it appears these signals need roughly a
	// 50ish nanosecond delay. This may need adaptation if you use a different speed clock.
	{hmclr, cxclr} <= '0;
	if (~RW_n && phi2_delay && cs) begin
		case(addr)
			HMCLR: hmclr <= 1;
			CXCLR: cxclr <= 1;
			default: ;
		endcase
	end

	if (hmclr) begin
		wreg[HMP0] <= 0;
		wreg[HMP1] <= 0;
		wreg[HMM0] <= 0;
		wreg[HMM1] <= 0;
		wreg[HMBL] <= 0;
	end

	if (rst) begin
		d_out[7:6] <= 0;
		wreg <= '{64{8'h00}};
		wreg[VBLANK][1] <= 1;
	end
end

// "Strobe" registers have an immediate effect
always_comb begin
	{wsync,rsync,resp0,resp1,resm0,resm1,resbl,hmove} = '0;
	if (~RW_n && pclk.level_p2 && cs) begin
		case(addr)
			WSYNC: wsync = 1;
			RSYNC: rsync = 1;
			RESP0: resp0 = 1;
			RESP1: resp1 = 1;
			RESM0: resm0 = 1;
			RESM1: resm1 = 1;
			RESBL: resbl = 1;
			HMOVE: hmove = 1;
			default: ;
		endcase
	end
	paddle_read = '0;
	if (RW_n && pclk.level_p2 && cs) begin
		paddle_read[0] = (addr[3:0] == INPT0);
		paddle_read[1] = (addr[3:0] == INPT1);
		paddle_read[2] = (addr[3:0] == INPT2);
		paddle_read[3] = (addr[3:0] == INPT3);
	end
end

// Submodules
clockgen clockgen
(
	.clk        (clk),
	.is_7800    (is_7800),
	.ce         (ce),
	.reset      (rst),
	.rsync      (rsync),
	.rsynd      (rsynd),
	.rsynl      (rsynl),
	.pext_1     (phi1_in),
	.pext_2     (phi2),
	.pclk       (pclk),
	.hclk       (hclk),
	.oclk       (oclk)
);

horiz_gen h_gen
(
	.clk        (clk),
	.rst        (rst),
	.hclk       (hclk),
	.rsynl      (rsynl),
	.rsynd      (rsynd),
	.sec        (sec),
	.hsync      (hsync),
	.hgap       (hgap_o),
	.hblank     (hblank_o),
	.cntd       (cntd),
	.cnt        (cnt),
	.aud0       (aclk0),
	.aud1       (aclk1),
	.shb        (shb),
	.rhb        (rhb)
);

playfield playfield
(
	.clk        (clk),
	.reset      (rst),
	.clkp       (clkp),
	.hclk       (hclk),
	.rhb        (rhb),
	.reflect    (wreg[CTRLPF][0]),
	.cnt        (cnt),
	.pfc        ({wreg[PF2], wreg[PF1], wreg[PF0][7:4]}),
	.pf         (pf)
);

hmove_gen hmv
(
	.clk        (clk),
	.reset      (rst),
	.sec        (sec),
	.hclk       (hclk),
	.oclk       (oclk),
	.pclk       (pclk),
	.hmove      (hmove),
	.hblank     (hblank_o),
	.p0_m       (hmclr ? 4'd0 : wreg[HMP0][7:4]),
	.p1_m       (hmclr ? 4'd0 : wreg[HMP1][7:4]),
	.m0_m       (hmclr ? 4'd0 : wreg[HMM0][7:4]),
	.m1_m       (hmclr ? 4'd0 : wreg[HMM1][7:4]),
	.bl_m       (hmclr ? 4'd0 : wreg[HMBL][7:4]),
	.p0_mclk    (p0ec),
	.p1_mclk    (p1ec),
	.m0_mclk    (m0ec),
	.m1_mclk    (m1ec),
	.bl_mclk    (blec)
);

player pl1 (
	.clk        (clk),
	.reset      (rst),
	.clkp       (clkp),
	.motck      (motck),
	.pec        (p0ec),
	.pre        (resp0),
	.pvdel      (wreg[VDELP0]),
	.m2pr       (wreg[RESMP0][1]),
	.pref       (wreg[REFP0][3]),
	.nusiz      (wreg[NUSIZ0][5:0]),
	.grpnew     (wreg[GRP0]),
	.grpold     (wreg[GRP0O]),
	.msrst      (msrst0),
	.p          (p0)
);

player pl2 (
	.clk        (clk),
	.reset      (rst),
	.clkp       (clkp),
	.motck      (motck),
	.pec        (p1ec),
	.pre        (resp1),
	.pvdel      (wreg[VDELP1]),
	.m2pr       (wreg[RESMP1][1]),
	.pref       (wreg[REFP1][3]),
	.nusiz      (wreg[NUSIZ1][5:0]),
	.grpnew     (wreg[GRP1]),
	.grpold     (wreg[GRP1O]),
	.msrst      (msrst1),
	.p          (p1)
);

missile mis0 (
	.clk        (clk),
	.reset      (rst),
	.clkp       (clkp),
	.motck      (motck),
	.mec        (m0ec),
	.mre        (resm0 || (wreg[RESMP0][1] && msrst0)),
	.men        (wreg[ENAM0][1] && ~wreg[RESMP0][1]),
	.nusiz      (wreg[NUSIZ0][5:0]),
	.m          (m0)
);

missile mis1 (
	.clk        (clk),
	.reset      (rst),
	.clkp       (clkp),
	.motck      (motck),
	.mec        (m1ec),
	.mre        (resm1 || (wreg[RESMP1][1] && msrst1)),
	.men        (wreg[ENAM1][1] && ~wreg[RESMP1][1]),
	.nusiz      (wreg[NUSIZ1][5:0]),
	.m          (m1)
);

ball bal (
	.clk        (clk),
	.reset      (rst),
	.clkp       (clkp),
	.motck      (motck),
	.blec       (blec),
	.blre       (resbl),
	.blen       (wreg[ENABL][1]),
	.blen_o     (wreg[ENBLO][1]),
	.blvd       (wreg[VDELBL]),
	.blsiz      (wreg[CTRLPF][5:4]),
	.bl         (bl)
);

priority_encoder prior
(
	.clk        (clk),
	.p0         (p0),
	.m0         (m0),
	.p1         (p1),
	.m1         (m1),
	.bl         (bl),
	.pf         (pf),
	.cntd       (cntd),
	.blank      (blank),
	.pfp        (wreg[CTRLPF][2]),
	.score      (wreg[CTRLPF][1]),
	.col_select (color_select)
);

audio_channel audio0
(
	.clk        (clk),
	.reset      (rst),
	.aud0       (aclk0),
	.aud1       (aclk1),
	.volume     (wreg[AUDV0]),
	.freq       (wreg[AUDF0]),
	.audc       (wreg[AUDC0]),
	.audio      (aud0)
);

audio_channel audio1
(
	.clk        (clk),
	.reset      (rst),
	.aud0       (aclk0),
	.aud1       (aclk1),
	.volume     (wreg[AUDV1]),
	.freq       (wreg[AUDF1]),
	.audc       (wreg[AUDC1]),
	.audio      (aud1)
);

// Select the correct output register
always_ff @(posedge clk) if (oclk.edge_p1) begin
	if ((hblank || vblank_o))
		{col, lum} <= decomb ? wreg[COLUBK][7:1] : 7'h0; // Blank non-visible areas
	else begin
		case (color_select)
			4'b0001: {col, lum} <= wreg[COLUP0][7:1];
			4'b0010: {col, lum} <= wreg[COLUP1][7:1];
			4'b0100: {col, lum} <= wreg[COLUPF][7:1];
			4'b1000: {col, lum} <= wreg[COLUBK][7:1];
			default: {col, lum} <= 7'd0;
		endcase
	end
end

// WSYNC register controls the RDY signal to the CPU. It is cleared at the start of hblank.
wire rdy_q;
assign rdy = ~rdy_q;
sr_latch in_sr
(
	.clk        (clk),
	.reset      (rst),
	.r          (shb),
	.s          (wsync),
	.q          (rdy_q),
	.q_n        ()
);

// Calculate the collisions

always_ff @(posedge clk) begin : read_reg_block
	if (cxclr) begin
		{rreg[CXM0P][7:6], rreg[CXM1P][7:6], rreg[CXP0FB][7:6],
			rreg[CXP1FB][7:6], rreg[CXM0FB][7:6], rreg[CXM1FB][7:6],
			rreg[CXBLPF][7:6], rreg[CXPPMM][7:6]} <= '0;
	end else if (oclk.level_p1 && ~vblank_o) begin
		rreg[CXM0P][7:6]  <= (rreg[CXM0P][7:6]  | {(m0 && p1), (m0 && p0)});
		rreg[CXM1P][7:6]  <= (rreg[CXM1P][7:6]  | {(m1 && p0), (m1 && p1)});
		rreg[CXP0FB][7:6] <= (rreg[CXP0FB][7:6] | {(p0 && pf), (p0 && bl)});
		rreg[CXP1FB][7:6] <= (rreg[CXP1FB][7:6] | {(p1 && pf), (p1 && bl)});
		rreg[CXM0FB][7:6] <= (rreg[CXM0FB][7:6] | {(m0 && pf), (m0 && bl)});
		rreg[CXM1FB][7:6] <= (rreg[CXM1FB][7:6] | {(m1 && pf), (m1 && bl)});
		rreg[CXBLPF][7:6] <= (rreg[CXBLPF][7:6] | {(bl && pf), 1'b0});
		rreg[CXPPMM][7:6] <= (rreg[CXPPMM][7:6] | {(p0 && p1), (m0 && m1)});
	end

	for (logic [2:0] x = 0; x < 4; x = x + 1'd1) begin
		rreg[{2'b10, x[1:0]}][7] <= wreg[VBLANK][7] ? 1'b0 : i[x[1:0]];
	end

	if (~wreg[VBLANK][6]) begin
		{rreg[INPT4][7], rreg[INPT5][7]} <= '1;
	end else begin
		if (~i4)
			rreg[INPT4][7] <= 0;
		if (~i5)
			rreg[INPT5][7] <= 0;
	end

	if (pclk.edge_p2 && cs && ~RW_n) begin
		if (addr[3:0] == VBLANK && d_in[6]) begin
			{rreg[INPT4][7], rreg[INPT5][7]} <= '1;
		end
	end

	if (rst) begin
		rreg <= '{16{8'h00}};
	end
end

endmodule

