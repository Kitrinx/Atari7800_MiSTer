// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.

// Based on Stella Programmer's Guide, TIA Schematics, and Decapped TIA.

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
	GRP0O   = 6'h3E,  // Not a real register, used for GPR0 storage
	GRP1O   = 6'h3F   // Not a real register, used for GPR1 storage
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


/////////////////////////////////////////////////////////////////////////////////////////
module horiz_gen
(
	input clk,
	input rst,
	input HP1,
	input HP2,
	input rsync,
	input hmove,
	output hsync,
	output logic cntd,
	output logic cnt,
	output logic res0d,
	output logic hblank, // Hblank signal with proper delays for hmove
	output logic hgap, // Hblank signal without delay
	output aud0, // Audio clocks need to be high twice per line
	output aud1,
	output logic shb,
	output logic rhb,
	output logic wsr,
	output logic shbd
);

// Horizontal Phase Clock Timing
//
// HP0 X--XX--XX--XX--XX--XX--XX--XX--X
// HP1 -XX--XX--XX--XX--XX--XX--XX--XX-

// 75 - 144 = 69
// 109 - 185 = 76
// starts 34 early, ends 41 early
// 00
// 10 - H1
// 11
// 01 - H0


// 000000 err77 0  Error
// 010100 end12 43 End
// 110111 rhs73 8  Reset H Sync
// 101100 cnt15 19 Center
// 001111 rcb74    Reset Color Burst
// 111100 shs17    Set H Sync
// 010111 lrhb72   Late Reset H Blank
// 011100 rhb16    Reset H Blank

localparam hsync_start = 26; // sync and burst 16 counts
localparam hsync_end = hsync_start + 16;
localparam hblank_start = 0; // Blank 68 counts
localparam hblank_end = 67; // Blank 68 counts

logic [5:0] lfsr;
logic hsync_1, hblank_1;
logic hmove_latch;

logic err, rhs, rcb, shs, lrhb, ehb;

assign aud0 = (HP2 && (shb || lrhb));
assign aud1 = (HP2 && (rhs || cnt));

assign res0d = err || shb;
// RHS Delayed twice for hsync, delayed once for audclk0
// CNT delayed once for audc0, delayed 0 for playfield.
always_comb begin
	{err, wsr, rhs, ehb, cnt, shs, lrhb, rhb} = '0;
	case (lfsr)
			6'b000000: wsr = 1;
			6'b111111: err = 1;    // Error
			6'b010100: ehb = 1;    // End (Set Hblank)
			6'b110111: rhs = 1;    // Reset HSync
			6'b101100: cnt = 1;    // Center // 101001?
//			6'b001111: rcb = 1;    // Reset Color Burst
			6'b111100: shs = 1;    // Set Hsync
			6'b011100: rhb = 1;    // Reset HBlank
			6'b010111: lrhb = 1;   // Late Reset Hblank
			default: ;
	endcase

// 	if (rsync)111011 000100
// 		shb = 1;
end

// always_latch begin
// 	if (cnt)
// 		cntd = 1;
// 	if (err | shb)
// 		cntd = 0;
// end

logic shb_1;
always_ff @(posedge clk) if (rst) begin
	lfsr <= 0;
	hmove_latch <= 0;
	hsync <= 0;
	hblank <= 0;
	hgap <= 0;
	shb <= 0;
	hsync_1 <= 0;
	hblank_1 <= 0;
	cntd <= 0;
	shbd <= 0;
end else begin
	if (hmove)
		hmove_latch <= 1;

	if (HP2) begin
		shb <= ehb || rsync || err;
	end

	if (HP1) begin
		lfsr <= shb ? 6'd0 : {~((lfsr[1] && ~lfsr[0]) || ~(lfsr[1] || ~lfsr[0])), lfsr[5:1]};
		cntd <= cnt;
		hsync <= hsync_1;
		//hblank <= hblank_1;

		if (shb) begin
			hblank <= 1;
			hmove_latch <= 0;
			hgap <= 1;
			lfsr <= 6'd0;
		end

		if (rhs) begin
			hsync_1 <= 0;
		end

		if (shs) begin
			hsync_1 <= 1;
		end
		if (rhb) begin
			hblank <= hmove_latch;
			hgap <= 0;
		end

		if (lrhb) begin
			hblank <= 0;
		end
	end
end


endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module clockgen
(
	input clk,
	input ce,
	input reset,
	input rsync,
	input logic res0d,
	output logic rsync_d,
	output logic phi0,
	output logic phi1,
	output logic phi2_gen,
	output logic phase,
	output logic HP1,
	output logic HP2,
	output logic CC
);

// Generation of Phi0. One phi0 clock is 3x hardware clocks, but we will allow for CE so we can use a single PLL.
// In this implementation, our 6507 does not generate phi2, so we will add here as an extra port which can
// be fed immediately back into the chip to satisfy the phi2 signal.

// It's important to note that in this context, CE represents the crystal or "color clock",
// Phi0 represents the generated clock that drives the 6507, and Phi2 should be the same as Phi1, but one
// "color clock" delayed, and it drives RIOT and parts of TIA. The actual "clk" port is any PLL.

// Using 2x the native oscillator we can set up clocks like this

//     0123456789ABCDEF123456789
// CC  X-X-X-X-X-X-X-X-X-X-X-X-X
// H01 X-------X-------X-------X
// H02 ----X-------X-------X----
// PH0 X-----X-----X-----X-----X
// PH1 -X-----X-----X-----X-----
// PH1 ----X-----X-----X-----X--

//assign CC = ce;
logic [2:0] phi_div;
logic [2:0] hp_cnt;
logic rsync_latch;
logic phi_clear;
logic cc_tog;
logic hp_tog;

assign HP1 = hp_cnt == 1 && ~hp_tog && CC;
assign HP2 = hp_cnt == 1 && hp_tog && CC;

assign phi0 = phi_div == 1 && ce;
assign phi1 = phi_div == 4 && ce;
assign phase = phi_div > 2;
assign CC = cc_tog && ce;

always_ff @(posedge clk) begin : phi0_gen
	phi2_gen <= phi0;
	if (ce) begin
		cc_tog <= ~cc_tog;
		phi_div <= phi_div + 1'd1;

		if (phi_div == 5)
			phi_div <= 0;
	end

	if (CC) begin
		hp_cnt <= hp_cnt + 1'd1;
		if (hp_cnt == 1) begin
			hp_cnt <= 0;
			hp_tog <= ~hp_tog;
		end
	end


	if (rsync)
		rsync_latch <= 1;

	if ((rsync || rsync_latch) && phi_div == 0 && (ce && ~CC)) begin
		rsync_latch <= 0;
		rsync_d <= 1;
		hp_cnt <= 0;
		hp_tog <= 0;
		phi_clear <= 1;
	end

	if ((res0d || phi_clear) && HP1) begin
		phi_div <= 1;
		phi_clear <= 0;
	end


	if (reset) begin
		rsync_latch <= 0;
		cc_tog <= 0;
		rsync_d <= 0;
		phi_clear <= 0;
		phi2_gen <= 0;
		phi_div <= 0;
		hp_cnt <= 0;
	end
end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module hmove_gen
(
	input  logic       clk,
	input  logic       cc,
	input  logic       reset,
	input  logic       HP1,
	input  logic       HP2,
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
	logic p0ec, p1ec, m0ec, m1ec, blec;

	assign p0_mclk = (~hblank || p0ec && HP1) && cc;
	assign p1_mclk = (~hblank || p1ec && HP1) && cc;
	assign m0_mclk = (~hblank || m0ec && HP1) && cc;
	assign m1_mclk = (~hblank || m1ec && HP1) && cc;
	assign bl_mclk = (~hblank || blec && HP1) && cc;

	logic [3:0] hmove_cnt;
	logic sec_1;

	wire [3:0] hmc_uns = {~hmove_cnt[3], hmove_cnt[2:0]};

	always @(posedge clk) begin : hmove_block
		// Hmove latches when set, then progresses through 
		// HP1 gate, HP2 gate, then HP1 gate before it goes to the
		// memory to take action at HP2
		if (hmove)
			sec_1 <= 1;
		else if (sec)
			sec_1 <= 0;

		if (HP2) begin
			sec <= sec_1;
		end

		if (HP1) begin
			if (sec)
				{p0ec, p1ec, m0ec, m1ec, blec} <= 5'b11111;

			if (sec || |hmove_cnt)
				hmove_cnt <= hmove_cnt + 1'd1;

			if (p0_m[3:0] == hmc_uns)
				p0ec <= 0;
			if (p1_m[3:0] == hmc_uns)
				p1ec <= 0;
			if (m0_m[3:0] == hmc_uns)
				m0ec <= 0;
			if (m1_m[3:0] == hmc_uns)
				m1ec <= 0;
			if (bl_m[3:0] == hmc_uns)
				blec <= 0;
		end
	end

endmodule


/////////////////////////////////////////////////////////////////////////////////////////

module playfield
(
	input clk,
	input reset,
	input HP1,
	input HP2, // Horizontal clock phase 2
	input cc,
	input reflect, // Control playfield, 1 makes right half mirror image
	input cnt,   // center signal, high means right half
	input rhb,
	input [19:0] pfc, // Combined playfield registers
	output logic pf
);

logic [4:0] pf_index;

// Outputs in order PF0 4..7, PF1 7:0, PF2 0:7
logic [4:0] index_lut[20];
assign index_lut = '{
	5'd00, 5'd01, 5'd02, 5'd03,                             // PF0
	5'd11, 5'd10, 5'd09, 5'd08, 5'd07, 5'd06, 5'd05, 5'd04, // PF1 in reverse
	5'd12, 5'd13, 5'd14, 5'd15, 5'd16, 5'd17, 5'd18, 5'd19  // PF2
};

always @(posedge clk) begin : pf_block
	logic dir;
	// The first half of the screen should draw from left to right in a strange order:
	// PF0[7:4], PF1[0:7], PF2[7:0] Note that PF1 is drawn backwards.
	// PF0     PF1         PF2
	// 4567 <- 76543210 <- 01234567

	if (cc)
		pf <= pfc[index_lut[pf_index]];

	if (HP2) begin
		if (dir && |pf_index)
			pf_index <= pf_index - 5'd1;
		else if (~dir && pf_index < 19)
			pf_index <= pf_index + 5'd1;

		if (cnt && reflect)
			dir <= 1;

		if (rhb || (cnt && ~reflect)) begin
			dir <= 0;
			pf_index <= 0;
		end
	end

	if (reset) begin
		dir <= 0;
		pf_index <= 0;
		pf <= 0;
	end
end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module player_o
(
	input clk,
	input motck,
	input enable,
	input resp,
	input reset,
	input delay,
	input [7:0] grp,
	input [7:0] grpo,
	input refp, // Player reflect
	input [2:0] size,
	output m_rst,
	output p
);

logic [5:0] lfsr;
logic start;

logic PP0, PP1, PP1_edge; // Player clocks
logic scan_clk;
logic [1:0] player_div;
logic fstob;
logic [2:0] scan_out;

logic ce;
logic scan_en;
assign PP0 = player_div == 0;
assign PP1_edge = player_div == 2;
assign PP1 = player_div == 3;
assign ce = motck && enable;
assign m_rst = fstob && scan_out == 1;


always_ff @(posedge clk) begin
	if (ce) begin
		//{PP0, PP1} <= 0;
		player_div <= player_div + 2'd1;

		scan_clk <=
			(~(size == 3'b111) && ~(size == 3'b101)) ||
			(PP1 && ((size == 3'b111) || (size == 3'b101))) ||
			(PP0 && (size == 3'b101));

		if (PP1_edge) begin
			lfsr <= {~((lfsr[1] && ~lfsr[0]) || ~(lfsr[1] || ~lfsr[0])), lfsr[5:1]};
			if (lfsr == 6'b111111 || lfsr == 6'b101101)
				lfsr <= 0;
			if  ((lfsr == 6'b101101) ||
				((lfsr == 6'b111000) && ((size == 3'b001) || (size == 3'b011))) ||
				((lfsr == 6'b101111) && ((size == 3'b011) || (size == 3'b010) || (size == 3'b110))) ||
				((lfsr == 6'b111001) && ((size == 3'b100) || (size == 3'b110)))) begin
				start <= 1;
				if (lfsr == 6'b101101)
					fstob <= 1;
				else
					fstob <= 0;
			end else begin
				start <= 0;
			end
		end

		if (scan_clk) begin
			if (start)
				scan_en <= 1;
			else if (scan_out == 3'b111)
				scan_en <= 0;

			if (scan_en)
				scan_out <= scan_out + 1'b1;
		end
end

	if (resp || reset) begin
		lfsr <= 0;
		player_div <= 0;
	end
end

logic [2:0] scan_adr;
logic [1:0] pix_sel;

assign scan_adr = refp ? scan_out : ~scan_out;
//assign scan_cnt = scan_en & scan_clk & count;
assign pix_sel = {scan_en, delay};
assign p = pix_sel == 2'b10 ? grp[scan_adr] : pix_sel == 2'b11 ? grpo[scan_adr] : 1'b0;



endmodule

/////////////////////////////////////////////////////////////////////////////////////////

module missile_o
(
	input clk,
	input ce,
	input resm,
	input resmp,
	input hmove,
	input enam,
	input [1:0] size,
	output m
);

// logic [5:0] lfsr;
// logic start;

// logic PP0, PP1, PP1_edge; // Player clocks
// logic scan_clk;
// logic [1:0] player_div;
// logic fstob;
// logic [2:0] scan_out;

// logic ce;
// logic scan_en;
// assign PP0 = player_div == 1;
// assign PP1_edge = player_div == 2;
// assign PP1 = player_div == 3;
// assign ce = motck & enable;

// always_ff @(posedge clk) begin
// 	if (ce) begin
// 		player_div <= player_div + 2'd1;

// 		if (PP1_edge) begin
// 			lfsr <= {~((lfsr[1] & ~lfsr[0]) | ~(lfsr[1] | ~lfsr[0])), lfsr[5:1]};
// 			if (lfsr == 6'b111111 || lfsr == 6'b101101)
// 				lfsr <= 0;
// 			if  ((lfsr == 6'b101101) ||
// 				((lfsr == 6'b111000) && ((size == 3'b001) || (size == 3'b011))) ||
// 				((lfsr == 6'b101111) && ((size == 3'b011) || (size == 3'b010) || (size == 3'b110))) ||
// 				((lfsr == 6'b111001) && ((size == 3'b100) || (size == 3'b110)))) begin
// 				start <= 1;
// 				if (lfsr == 6'b101101)
// 					fstob <= 1;
// 				else
// 					fstob <= 0;
// 			end else begin
// 				start <= 0;
// 			end
// 		end
// 	end
// end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////

module ball_o
(
	input clk,
	input cc,
	input delay,
	input enabl, // Enaball, get it ena..ball.. It was funnier in the 70s.
	input resbl,
	input hblank,
	input [1:0] size,
	output bl
);

// logic [5:0] lfsr_bl;

// always @(posedge clk) if (resbl) begin
// end else begin
// 	lfsr_bl <= {~(~(lfsr_bl[1] | lfsr_bl[0]) | (lfsr_bl[0] & lfsr_bl[1])), lfsr_bl[5:1]};
// end

logic [5:0] lfsr;
logic start, start_last;

logic P0, P1; // Ball clocks
logic [1:0] div;

assign bl = 0;//(start && (size[1] | P1 | (div == 2 && size == 3))) || (start_last && size == 3);

always_ff @(posedge clk) begin
	{P0, P1} <= 0;

	if (cc && enabl) begin
		div <= div + 2'd1;
		if (div == 3)
			P0 <= 1;
		if (div <= 1)
			P1 <= 1;
	end

	if (P1) begin
		lfsr <= {~(~(lfsr[1] || lfsr[0]) || (~lfsr[0] && lfsr[1])), lfsr[5:1]};
		start_last <= start;
		if (lfsr == 6'b111111) // Error
			lfsr <= 0;

		if (lfsr == 6'b101101) begin
			lfsr <= 0;
			start <= 1;
		end else begin
			start <= 0;
		end
	end

	if (resbl) begin
		lfsr <= 0;
	end
end

endmodule



/////////////////////////////////////////////////////////////////////////////////////////
module priority_encoder
(
	input clk,
	input ce,
	input p0,
	input m0,
	input p1,
	input m1,
	input pf,
	input bl,
	input blank,
	input cntd, // 0 = left half, 1 = right half
	input pfp,
	input score,
	output [3:0] col_select // {bk, pf, p1, p0}
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
logic right_side;

always @(posedge clk) begin
	if (cntd)
		right_side <= 1;
	else if (blank)
		right_side <= 0;
end

always_comb begin
	casex ({pfp, (pf || bl), (p1 || m1), (p0 || m0)})
		4'bX_001: col_select = 4'b0001;
		4'bX_010: col_select = 4'b0010;
		4'bX_011: col_select = 4'b0001;
		4'bX_100: col_select = score ? (right_side ? 4'b0010 : 4'b0001) : 4'b0100;
		4'b0_101: col_select = 4'b0001;
		4'b0_110: col_select = 4'b0010;
		4'b0_111: col_select = 4'b0001;
		4'b1_101: col_select = score ? (right_side ? 4'b0010 : 4'b0001) : 4'b0100;
		4'b1_110: col_select = score ? (right_side ? 4'b0010 : 4'b0001) : 4'b0100;
		4'b1_111: col_select = score ? (right_side ? 4'b0010 : 4'b0001) : 4'b0100;
		default: col_select = 4'b1000;
	endcase
end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module audio_channel
(
	input clk,
	input reset,
	input ce,
	input aud0,
	input aud1,
	input [3:0] volume,
	input [4:0] freq,
	input [3:0] audc,
	output [3:0] audio
);

// Audio is quite a lot of convoluted wide nors and odd shifting, so
// I just did it at gate level.

// Frequency divider area signals
logic freq_clk;
logic [4:0] freq_div;
logic T1, T2;

// Noise area signals
logic [4:0] noise;
logic noise_wnor_1;
logic noise_wnor_2;
logic nor1, nor2, nor3, nor4, nor5, nor6, nor7, nor8;
logic and1, and2;
logic noise0_latch_n;
logic nor2_latch;

// Pulse area signals
logic [3:0] pulse;
logic nor_a, nor_b, nor_c, nor_d, nor_e;
logic pulse_bit;
logic pulse_wnor_1;
logic pulse_wnor_2;
logic rnor1, rnor2, rnor3;
logic rand1;

// Frequency divider area logic
assign T1 = aud0 && freq_clk;
assign T2 = aud1 && freq_clk;

// Noise area logic
assign nor1 = ~|{~audc[1:0], noise0_latch_n};
assign nor2 = ~|{nor1, ~audc[1], noise_wnor_1};
assign nor3 = ~|{audc[1:0], pulse_wnor_1};
assign nor4 = ~|audc[1:0];
assign nor5 = ~|{~noise[2], nor4};
assign nor6 = ~|{nor5, and1};
assign nor7 = ~|{nor6, noise[0]};
assign nor8 = ~|{nor_a, nor7, and2, noise_wnor_2};

assign and1 = nor4 && pulse[0];
assign and2 = noise[0] && nor6;

assign noise_wnor_1 = ~|{noise[4:2], ~noise[1], audc[0], ~audc[1]};
assign noise_wnor_2 = ~|{noise, nor3};

// Pulse area logic
assign rnor1 = ~|{pulse_wnor_2, pulse[1]};
assign rnor2 = ~|{pulse[1], pulse[0]};
assign rnor3 = ~|{pulse_wnor_1, rnor2, rand1};

assign rand1 = pulse[1] && pulse[0];

assign nor_a = ~|audc;
assign nor_b = ~|{audc[3:2], rnor3};
assign nor_c = ~|{~audc[3:2], rnor1};
assign nor_d = ~|{audc[3], ~audc[2], ~pulse[3]};
assign nor_e = ~|{~audc[3], audc[2], noise0_latch_n};

assign pulse_bit = ~|{nor_a, nor_b, nor_c, nor_d, nor_e};

assign pulse_wnor_1 = ~|{~pulse[3], pulse[2], ~pulse[1], pulse[0]};
assign pulse_wnor_2 = ~|pulse[3:1];

// Clocked registers
always_ff @(posedge clk) begin

	if (aud0) begin
		freq_clk <= 0;
		freq_div <= freq_div + 1'd1;
		if (freq_div >= freq) begin
			freq_div <= 0;
			freq_clk <= 1;
		end
	end

	if (T1) begin // aud0
		noise0_latch_n <= ~noise[0];
		nor2_latch <= nor2;
	end

	if (T2) begin // aud1
		noise <= {~nor8, noise[4:1]};
		if (~nor2_latch)
			pulse <= {pulse_bit, ~pulse[3:1]};
	end

	if (reset) begin
		noise0_latch_n <= 0;
		nor2_latch <= 0;
		noise <= 0;
		pulse <= 0;
	end

end

assign audio = pulse[0] ? volume : 4'd0;

endmodule



/////////////////////////////////////////////////////////////////////////////////////////
module TIA2
(
	// Original Pins
	input        clk,
	output       phi0,
	input        phi2,
	output logic phi1,
	input        RW_n,
	output logic rdy,
	input  [5:0] addr,
	input  [7:0] d_in,
	output [7:0] d_out,
	input  [3:0] i,     // On real hardware, these would be ADC pins. i0..3
	output [3:0] i_out,
	input        i4,
	input        i5,
	output [3:0] aud0,
	output [3:0] aud1,
	output [3:0] col,
	output [2:0] lum,
	output       BLK_n,
	output       sync,
	input        cs0_n,
	input        cs2_n,

	// Abstractions
	input        rst,
	input        ce,     // Clock enable for CLK generation only
	output       video_ce,
	output       vblank,
	output       hblank,
	output       hgap,
	output       vsync,
	output       hsync,
	output       phi2_gen,
	input        phi1_in,
	input [7:0]  open_bus,
	input        decomb
);

logic [7:0] wreg[64]; // Write registers. Only 44 are used.
logic [7:0] rreg[16]; // Read registers.
logic rdy_latch; // buffer for the rdy signal
logic [14:0] collision;

logic [7:0] read_val;
logic cs;  // Chip Select (cs1 and 3 were NC)
logic phase; // 0 = phi0, 1 = phi2
logic wsync,rsync,resp0,resp1,resm0,resm1,resbl,hmove,hmclr,cxclr; // Strobe register signals
logic [3:0] color_select;
logic p0, p1, m0, m1, bl, pf; // Current object active flags
logic aclk0, aclk1, cntd, cnt;
logic HP1, HP2; // Horizontal phase clocks
logic cc; // Color Clock (original oscillator speed)
logic rhb, shb, wsr, shbd; // Hblank triggers
logic sec;

assign cs = ~cs0_n && ~cs2_n;
assign video_ce = cc;

//assign d_out[5:0] = 6'h00;
assign BLK_n = ~(hblank || vblank);
assign sync = ~(hsync || vsync);
assign vsync = wreg[VSYNC][1];
assign vblank = wreg[VBLANK][1];

// Address Decoder
// Register writes happen when Phi2 falls, or in our context, when Phi0 rises.
// Register reads happen when Phi2 is high. This is relevant in particular to RIOT which is clocked on Phi2.

logic [7:0] last_bus_value;

// Read port masks
logic [1:0] rpm [16];
assign rpm = '{
	2'b11, 2'b11, 2'b11, 2'b11, 2'b11, 2'b11,
	2'b10,
	2'b11,
	2'b10, 2'b10, 2'b10, 2'b10, 2'b10, 2'b10,
	2'b00, 2'b00
};

assign d_out[5:0] = open_bus[5:0];

always_ff @(posedge clk) begin
	if (phi1_in)
		phase <= 0;
	if (phi2)
		phase <= 1;
end

always @(posedge clk) begin
	i_out <= {4{~wreg[VBLANK][7]}};
	if (phase) begin
		if (cs && RW_n) begin
			if (addr[3:0] == INPT4 && ~wreg[VBLANK][6]) begin
				d_out[7:6] <= {i4, 1'b0} | (open_bus[7:6] & ~rpm[addr[3:0]]);
			end else if (addr[3:0] == INPT5 && ~wreg[VBLANK][6]) begin
				d_out[7:6] <= {i5, 1'b0} | (open_bus[7:6] & ~rpm[addr[3:0]]);
			end else if (~&addr[3:1]) begin
				d_out[7:6] <= rreg[addr[3:0]][7:6] | (open_bus[7:6] & ~rpm[addr[3:0]]); // reads only use the lower 4 bits of addr
			end else
				d_out[7:6] <= open_bus[7:6];
		end
	end
	if (rst)
		d_out[7:6] <= 0;

	if (cs && ~RW_n && addr <= 6'h2C) begin
		if (phase)
			wreg[addr] <= d_in;

		if (phi2) begin
			if (addr == GRP0)
				wreg[GRP0O] <= wreg[GRP0];
			if (addr == GRP1)
				wreg[GRP1O] <= wreg[GRP1];
			if (addr == ENABL)
				wreg[ENBLO] <= wreg[ENABL];
		end

	end

	if (hmclr) begin
		wreg[HMP0] <= 0;
		wreg[HMP1] <= 0;
		wreg[HMM0] <= 0;
		wreg[HMM1] <= 0;
		wreg[HMBL] <= 0;
	end

	if (rst)
		wreg <= '{64{8'h00}};
end

// "Strobe" registers have an immediate effect
always @(posedge clk) begin
	{wsync,rsync,resp0,resp1,resm0,resm1,resbl,hmove,hmclr,cxclr} <= '0;
	if (~RW_n && phase && cs) begin
		case(addr)
			WSYNC: wsync <= 1;
			RSYNC: rsync <= 1;
			RESP0: resp0 <= 1;
			RESP1: resp1 <= 1;
			RESM0: resm0 <= 1;
			RESM1: resm1 <= 1;
			RESBL: resbl <= 1;
			HMOVE: hmove <= 1;
			HMCLR: hmclr <= 1;
			CXCLR: cxclr <= 1;
			default: ;
		endcase
	end
end


// Submodules

logic [7:0] uv_gen;
logic vs_gen, vb_gen, hs_gen, hb_gen;
logic p0ec, p1ec, m0ec, m1ec, blec;
logic res0d;

clockgen clockgen
(
	.clk      (clk),
	.ce       (ce),
	.CC       (cc),
	.res0d    (res0d),
	.phi0     (phi0),
	.phi1     (phi1),
	.phi2_gen (phi2_gen),
	.rsync    (rsync),
	.HP1      (HP1),
	.HP2      (HP2),
	.reset    (rst),
	.phase    ()
);

horiz_gen h_gen
(
	.clk    (clk),
	.rst    (rst),
	.HP1    (HP1),
	.HP2    (HP2),
	.rsync  (rsync),
	.hmove  (sec),
	.hsync  (hsync),
	.res0d  (res0d),
	.hgap   (hgap),
	.hblank (hblank),
	.cntd   (cntd),
	.cnt    (cnt),
	.aud0   (aclk0),
	.aud1   (aclk1),
	.shb    (shb),
	.rhb    (rhb),
	.shbd   (shbd),
	.wsr    (wsr)
);

playfield playfield
(
	.clk(clk),
	.reset(rst),
	.HP1(HP1),
	.HP2(HP2),
	.cc (cc),
	.rhb(rhb),
	.reflect(wreg[CTRLPF][0]),
	.cnt(cnt),
	.pfc({wreg[PF2], wreg[PF1], wreg[PF0][7:4]}),
	.pf(pf)
);

hmove_gen hmv
(
	.clk     (clk),
	.cc      (cc),
	.reset   (rst),
	.sec     (sec),
	.HP1     (HP1),
	.HP2     (HP2),
	.hmove   (hmove),
	.hblank  (hblank),
	.p0_m    (wreg[HMP0][7:4] & (hmclr ? 4'b0000 : 4'b111)),
	.p1_m    (wreg[HMP1][7:4] & (hmclr ? 4'b0000 : 4'b111)),
	.m0_m    (wreg[HMM0][7:4] & (hmclr ? 4'b0000 : 4'b111)),
	.m1_m    (wreg[HMM1][7:4] & (hmclr ? 4'b0000 : 4'b111)),
	.bl_m    (wreg[HMBL][7:4] & (hmclr ? 4'b0000 : 4'b111)),
	.p0_mclk (p0ec),
	.p1_mclk (p1ec),
	.m0_mclk (m0ec),
	.m1_mclk (m1ec),
	.bl_mclk (blec)
);
// -- 	p0: work.player
// -- 		port map(clk, p0_rst, p0_count, p0_nusiz, p0_reflect,
// -- 					p0_grpnew, p0_grpold, p0_vdel, p0_mrst, p0_pix);
logic msrst0, msrst1;

// player_o player0
// (
// 	.clk     (clk),
// 	.motck   (cc),
// 	.enable  (p0ec),
// 	.resp    (resp0),
// 	.reset   (rst),
// 	.delay   (wreg[VDELP0]),
// 	.grp     (wreg[GRP0]),
// 	.grpo    (wreg[GRP0O]),
// 	.refp    (wreg[REFP0][3]),
// 	.size    (wreg[NUSIZ0][2:0]),
// 	.m_rst   (msrst0),
// 	.p       (p0)
// );

// player_o player1
// (
// 	.clk     (clk),
// 	.motck   (cc),
// 	.enable  (p1ec),
// 	.resp    (resp1),
// 	.reset   (rst),
// 	.delay   (wreg[VDELP1]),
// 	.grp     (wreg[GRP1]),
// 	.grpo    (wreg[GRP1O]),
// 	.refp    (wreg[REFP1][3]),
// 	.size    (wreg[NUSIZ1][2:0]),
// 	.m_rst   (msrst1),
// 	.p       (p1)
// );


player play1 (
	.clk     (clk),
	.prst    (resp0),
	.count   (p0ec),
	.nusiz   (wreg[NUSIZ0][2:0]),
	.reflect (wreg[REFP0][3]),
	.grpnew  (wreg[GRP0]),
	.grpold  (wreg[GRP0O]),
	.vdel    (wreg[VDELP0]),
	.mrst    (msrst0),
	.pix     (p0)
);

player play2 (
	.clk     (clk),
	.prst    (resp1),
	.count   (p1ec),
	.nusiz   (wreg[NUSIZ1][2:0]),
	.reflect (wreg[REFP1][3]),
	.grpnew  (wreg[GRP1]),
	.grpold  (wreg[GRP1O]),
	.vdel    (wreg[VDELP1]),
	.mrst    (msrst1),
	.pix     (p1)
);

missile mis1 (
	.clk    (clk),
	.prst   (resm0 || (wreg[RESMP0][1] && msrst0)),
	.count  (m0ec),
	.enable (wreg[ENAM0][1]),
	.nusiz  (wreg[NUSIZ0][2:0]),
	.size   (wreg[NUSIZ0][5:4]),
	.pix    (m0)
);

missile mis2 (
	.clk    (clk),
	.prst   (resm1 || (wreg[RESMP1][1] && msrst1)),
	.count  (m1ec),
	.enable (wreg[ENAM1][1]),
	.nusiz  (wreg[NUSIZ1][2:0]),
	.size   (wreg[NUSIZ1][5:4]),
	.pix    (m1)
);

ball bal (
	.clk   (clk),
	.prst  (resbl),
	.count (blec),
	.ennew (wreg[ENABL][1]),
	.enold (wreg[ENBLO][1]),
	.vdel  (wreg[VDELBL]),
	.size  (wreg[CTRLPF][5:4]),
	.pix   (bl)
);

priority_encoder prior
(
	.p0     (p0),
	.m0     (m0),
	.p1     (p1),
	.m1     (m1),
	.bl     (bl),
	.pf     (pf),
	.cntd   (cntd),
	.blank  (hblank || vblank),
	.pfp    (wreg[CTRLPF][2]),
	.score  (wreg[CTRLPF][1]),
	.col_select (color_select)
);

audio_channel audio0
(
	.clk    (clk),
	.reset  (rst),
	.aud0   (aclk0),
	.aud1   (aclk1),
	.volume (wreg[AUDV0]),
	.freq   (wreg[AUDF0]),
	.audc   (wreg[AUDC0]),
	.audio  (aud0)
);

audio_channel audio1
(
	.clk    (clk),
	.reset  (rst),
	.aud0   (aclk0),
	.aud1   (aclk1),
	.volume (wreg[AUDV1]),
	.freq   (wreg[AUDF1]),
	.audc   (wreg[AUDC1]),
	.audio  (aud1)
);


// Select the correct output register
always_comb begin
	if (hblank || vblank)
		{col, lum} = decomb ? wreg[COLUBK][7:1] : 7'd0; // My own innovation for modern displays, not part of the chip
	else begin
		case (color_select)
			4'b0001: {col, lum} = wreg[COLUP0][7:1];
			4'b0010: {col, lum} = wreg[COLUP1][7:1];
			4'b0100: {col, lum} = wreg[COLUPF][7:1];
			4'b1000: {col, lum} = wreg[COLUBK][7:1];
			default: {col, lum} = 7'd0;
		endcase
	end
end

// WSYNC register controls the RDY signal to the CPU. It is cleared at the start of hblank.
always_ff @(posedge clk) begin
	if (wsync && cc)
		rdy <= 0;

	if (shb)
		rdy <= 1;

	if (rst)
		rdy <= 1;
end

// Calculate the collisions

always_ff @(posedge clk) begin : read_reg_block
	logic [8:0] x;

	if (cc) begin // FIXME: this should always be implicitly opposite phi2 for reads.
		if (cxclr) begin
			{rreg[CXM0P][7:6], rreg[CXM1P][7:6], rreg[CXP0FB][7:6],
				rreg[CXP1FB][7:6], rreg[CXM0FB][7:6], rreg[CXM1FB][7:6],
				rreg[CXBLPF][7:6], rreg[CXPPMM][7:6]} <= '0;
		end else begin
			rreg[CXM0P][7:6]  <= (rreg[CXM0P][7:6]  | {(m0 && p1), (m0 && p0)});
			rreg[CXM1P][7:6]  <= (rreg[CXM1P][7:6]  | {(m1 && p0), (m1 && p1)});
			rreg[CXP0FB][7:6] <= (rreg[CXM1P][7:6]  | {(p0 && pf), (p0 && bl)});
			rreg[CXP1FB][7:6] <= (rreg[CXP1FB][7:6] | {(p1 && pf), (p1 && bl)});
			rreg[CXM0FB][7:6] <= (rreg[CXM0FB][7:6] | {(m0 && pf), (m0 && bl)});
			rreg[CXM1FB][7:6] <= (rreg[CXM1FB][7:6] | {(m1 && pf), (m1 && bl)});
			rreg[CXBLPF][7:6] <= (rreg[CXBLPF][7:6] | {(bl && pf), 1'b0});
			rreg[CXPPMM][7:6] <= (rreg[CXPPMM][7:6] | {(p0 && p1), (m0 && m1)});
		end

		for (x = 0; x < 4; x = x + 1'd1) begin
			rreg[{2'b10, x[1:0]}][7] <= wreg[VBLANK][7] ? 1'b0 : i[x[1:0]];
		end
	end

	// TODO: Is this the case?
	// if (phi2 && ~RW_n && cs && addr == VBLANK && d_in[6])
	// 	{rreg[INPT4][7], rreg[INPT5][7]} <= '1;

	if (~wreg[VBLANK][6]) begin
		{rreg[INPT4][7], rreg[INPT5][7]} <= '1;
	end else begin
		if (~i4)
			rreg[INPT4][7] <= 0;
		if (~i5)
			rreg[INPT5][7] <= 0;
	end

	if (phase && cs && ~RW_n) begin
		if (addr[3:0] == VBLANK && d_in[6]) begin
			{rreg[INPT4][7], rreg[INPT5][7]} <= '1;
		end
	end

	if (rst)
		rreg <= '{16{8'h00}};
end

endmodule

