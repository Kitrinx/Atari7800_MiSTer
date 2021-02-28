// Princess TIAbeanie
// Copyright Jamie Dickson, 2019 - 2020
// Based on Stella Programmer's Guide and TIA schematics, and verified with Stella Emulator

// Enum ripped strait from Stella. Thanks man.
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
	CXCLR   = 6'h2c   // Write: clear collision latches (strobe)
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
module lfsr6_gen (
	input clk,
	input ce,
	input reset,
	output reg [5:0] lfsr
);

// Linear feedback shift register used by almost all components of TIA as a poor-man's
// counter.

always @(posedge clk) begin
	if (ce) begin
		if (reset || &lfsr)
			lfsr <= 0;
		else
			lfsr <= {~((lfsr[1] & ~lfsr[0]) | ~(lfsr[1] | ~lfsr[0])), lfsr[5:1]};
	end
end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////

module playfield
(
	input clk,
	input reset,
	input HP2, // Horizontal clock phase 2
	input hblank,
	input reflect, // Control playfield, 1 makes right half mirror image
	input cnt,   // center signal, high means right half
	input [19:0] pfc, // Combined playfield registers
	output pf
);

reg [4:0] pf_index;

// Outputs in order PF0 4..7, PF1 7:0, PF2 0:7
wire [4:0] index_lut[20] = '{
	5'd00, 5'd01, 5'd02, 5'd03,                             // PF0
	5'd11, 5'd10, 5'd09, 5'd08, 5'd07, 5'd06, 5'd05, 5'd04, // PF1 in reverse
	5'd12, 5'd13, 5'd14, 5'd15, 5'd16, 5'd17, 5'd18, 5'd19  // PF2
};

assign pf = hblank ? 0 : pfc[index_lut[pf_index]];

// ((cnt & ~mirror) | rhb)
// ~(~cnt | ~mirror)

always @(posedge clk) if (reset) begin
	pf_index <= 0;
end else begin
	// The first half of the screen should draw from left to right in a strange order:
	// PF0[7:4], PF1[0:7], PF2[7:0] Note that PF1 is drawn backwards.
	// PF0     PF1         PF2
	// 4567 <- 76543210 <- 01234567
	if (HP2) begin
		if (~hblank) begin
			if (reflect & cnt) begin
				if (pf_index > 0)
					pf_index <= pf_index - 5'd1;
			end else begin
				if (pf_index < 19)
					pf_index <= pf_index + 5'd1;
				else if (~reflect)
					pf_index <= 0;
			end
		end else begin
			pf_index <= 0;
		end
	end
end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////

module player_o
(
	input clk,
	input motck,
	input cc, // Color Clock (original oscillator frequency)
	input enable,
	input resp,
	input reset,
	input hmove,
	input hmclr,
	input signed [3:0] hmp,
	input [7:0] grp,
	input refp, // Player reflect
	input [2:0] size,
	output p
);



reg [5:0] lfsr;
reg start;

reg PP0, PP1; // Player clocks
reg [1:0] player_div;
reg [2:0] scan_div;
reg fstob;

wire ce = cc & enable;

always_ff @(posedge clk) begin
	{PP0, PP1} <= 0;
	if (ce) begin
		player_div <= player_div + 2'd1;
		scan_div <= scan_div + 3'd1;
		if (player_div == 3)
			PP0 <= 1;
		if (player_div <= 1)
			PP1 <= 1;
		if (scan_div >= 2)
			scan_div <= 0;
	end

	if (PP1) begin
		lfsr <= {~(~(lfsr[1] | lfsr[0]) | (~lfsr[0] & lfsr[1])), lfsr[5:1]};
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

	if (resp) begin
		lfsr <= 0;
	end
end


endmodule

/////////////////////////////////////////////////////////////////////////////////////////

module missile_o
(
	input clk,
	input ce,
	input resm,
	input resmp,
	input hmove,
	input hmclr,
	input enam,
	input signed [3:0] hmm,
	input [1:0] size,
	output m
);

endmodule

/////////////////////////////////////////////////////////////////////////////////////////

module ball_o
(
	input clk,
	input cc,
	input hmove,
	input hmclr,
	input signed [3:0] hmbl,
	input enabl, // Enaball, get it ena..ball.. It was funnier in the 70s.
	input resbl,
	input hblank,
	input [1:0] size,
	output bl
);

// reg [5:0] lfsr_bl;

// always @(posedge clk) if (resbl) begin
// end else begin
// 	lfsr_bl <= {~(~(lfsr_bl[1] | lfsr_bl[0]) | (lfsr_bl[0] & lfsr_bl[1])), lfsr_bl[5:1]};
// end

reg [5:0] lfsr;
reg start, start_last;

reg P0, P1; // Ball clocks
reg [1:0] div;

assign bl = (start && (size[1] | P1 | (div == 2 && size == 3))) || (start_last && size == 3);

always_ff @(posedge clk) begin
	{P0, P1} <= 0;

	if (cc & enabl) begin
		div <= div + 2'd1;
		if (div == 3)
			P0 <= 1;
		if (div <= 1)
			P1 <= 1;
	end

	if (P1) begin
		lfsr <= {~(~(lfsr[1] | lfsr[0]) | (~lfsr[0] & lfsr[1])), lfsr[5:1]};
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

// The original hardware for the sound is quite convoluted using two shift registers and a
// series of logic matching to manipulate the wave form. This recreation uses the condensed
// logic found in the Stella emulator.

reg [4:0] freq_div;
reg [3:0] pulse_sr; // Pulse generator
reg [4:0] noise_sr; // Noise generator
reg noise;

reg noise_en;

wire pulse_en;
reg pulse_hold;

reg noise4_latch;

assign audio = pulse_sr[0] ? volume : 4'h0;

reg audio_clk;

always_comb begin
	case (audc[3:2])
		0: pulse_en = ((pulse_sr[1] ? 1 : 0) ^ pulse_sr[0]) && (pulse_sr != 4'hA) && |audc[1:0];
		1: pulse_en = ~pulse_sr[3];
		2: pulse_en = ~noise4_latch;
		3: pulse_en = ~(pulse_sr[1] || ~|pulse_sr[3:1]);
	endcase
end

always_ff @(posedge clk) begin

	// The audio ctrl register controls various dividers for the
	// noise generator.
	if (aud0) begin
		freq_div <= freq_div + 1'd1;
		audio_clk <= 0;

		if (freq_div >= freq) begin
			freq_div <= 0;
			audio_clk <= 1;
		end

		if (~|audc[1:0]) begin
			noise_en <= ((pulse_sr[0] ^ noise_sr[0]) ||
				!(|noise_sr || (pulse_sr != 4'b1010)) || ~|audc[3:2]);
		end else begin
			noise_en <= (((noise_sr[2] ? 1 : 0) ^ noise_sr[0]) || ~|noise_sr);
		end

		if (audio_clk) begin
			noise4_latch <= noise_sr[0];

			case (audc[1:0])
				0,1: pulse_hold <= 0;
				2: pulse_hold <= (noise_sr[4:1] != 4'b0001);
				3: pulse_hold <= ~noise_sr[0];
			endcase
		end
	end

	if (aud1 & audio_clk) begin
		noise_sr <= {noise_en, noise_sr[4:1]};
		if (~pulse_hold)
			pulse_sr <= {pulse_en, ~pulse_sr[3:1]};
	end

	if (reset) begin
		{freq_div, audio_clk, noise4_latch, noise_en, noise_sr, pulse_sr, pulse_hold} <= '0;
	end
end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module horiz_gen
(
	input clk,
	input ce,
	input rst,
	input HP1,
	input HP2,
	input rsync,
	input hmove,
	output hsync,
	output reg cntd,
	output reg hblank, // Hblank signal with proper delays for hmove
	output reg hgap, // Hblank signal without delay
	output aud0, // Audio clocks need to be high twice per line
	output aud1,
	output reg shb,
	output reg rhb,
	output reg wsr
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

reg [5:0] lfsr;
reg hmove_latch;

reg err, rhs, cnt, rcb, shs, lrhb;

assign aud0 = (HP2 & (err | shb | lrhb));
assign aud1 = (HP2 & (rhs | cnt));

// always_comb begin
// 	{err, wsr, shb, rhs, cnt, rcb, shs, lrhb, rhb} = 0;
// 	case (lfsr)
// 			6'b000000: wsr = 1;
// 			6'b111111: err = 1;    // Error
// 			6'b010100: shb = 1;    // End (Set Hblank)
// 			6'b110111: rhs = 1;    // Reset HSync
// 			6'b101100: cnt = 1;    // Center
// 			6'b001111: rcb = 1;    // Reset Color Burst
// 			6'b111100: shs = 1;    // Set Hsync
// 			6'b011100: rhb = 1;    // Reset HBlank
// 			6'b010111: lrhb = 1;   // Late Reset Hblank
// 			default: {err, wsr, shb, rhs, cnt, rcb, shs, lrhb, rhb} = 0;
// 	endcase

// 	if (rsync)
// 		shb = 1;
// end

// always_latch begin
// 	if (cnt)
// 		cntd = 1;
// 	if (err | shb)
// 		cntd = 0;
// end

always_ff @(posedge clk) if (rst) begin
	lfsr <= 6'd0;
end else begin

	if (HP1) begin // clocked by HP1;
		{err, wsr, shb, rhs, cnt, rcb, shs, lrhb, rhb} <= 0;
		case (lfsr)
				6'b000000: wsr <= 1;
				6'b111111: err <= 1;    // Error
				6'b010100: shb <= 1;    // End (Set Hblank)
				6'b110111: rhs <= 1;    // Reset HSync
				6'b101100: cnt <= 1;    // Center
				6'b001111: rcb <= 1;    // Reset Color Burst
				6'b111100: shs <= 1;    // Set Hsync
				6'b011100: rhb <= 1;    // Reset HBlank
				6'b010111: lrhb <= 1;   // Late Reset Hblank
				default: {err, wsr, shb, rhs, cnt, rcb, shs, lrhb, rhb} <= 0;
		endcase

		if (hmove)
			hmove_latch <= 1;
	end

	if (HP2) begin
		lfsr <= {~((lfsr[1] & ~lfsr[0]) | ~(lfsr[1] | ~lfsr[0])), lfsr[5:1]};

		if (err | shb | rsync) begin
			hblank <= 1;
			hgap <= 1;
			cntd <= 0;
			lfsr <= 6'd0;
		end

		if (rhs) begin
			hsync <= 0;
			hmove_latch <= 0;
		end

		if (cnt) begin
			cntd <= 1;
		end

		if (shs)
			hsync <= 1;

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
// module object_clk
// (
// 	input clk,
// 	input cc,
// 	input reset,
// 	input signed [3:0] move_cnt,
// 	input hmove,
// 	input hbs,
// 	input hbr,
// 	output reg OC1,
// 	output reg OC2
// );

// reg [1:0] o_div;
// reg in_blank;
// reg [3:0] extra_cnt, supp_cnt;

// always_ff @(posedge clk) begin :oclk
// 	reg old_hmove;
// 	old_hmove <= hmove;
// 	OC1 <= 0;
// 	OC2 <= 0;
// 	if (cc) begin
// 		if (reset) begin
// 			extra_cnt <= 0;
// 			supp_cnt <= 0;
// 			o_div <= 0;
// 		end else begin
// 			o_div <= o_div + 2'd1;
// 			if ()
// 			if (hbs) in_blank <= 1;
// 			if (hbr) in_blank <= 0;

// 			if ((o_div == 1 && ~|supp_cnt))

// 			if (hmove) begin //
// 				if (move_cnt > 0) begin
// 					extra_cnt <= move_cnt;
// 				end else if (move_cnt < 0)
// 					supp_cnt <= (~move_cnt) + 4'd1;
// 				end
// 			end
// 		end
// 	end
// end

// endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module clockgen
(
	input clk,
	input ce,
	input reset,
	input rsync,
	output reg phi0,
	output reg phi2_gen,
	output reg phase,
	output reg HP1,
	output reg HP2,
	output reg CC
);

// Generation of Phi0. One phi0 clock is 3x hardware clocks, but we will allow for CE so we can use a single PLL.
// In this implementation, our 6507 does not generate phi2, so we will add here as an extra port which can
// be fed immediately back into the chip to satisfy the phi2 signal.

// It's important to note that in this context, CE represents the crystal or "color clock",
// Phi0 represents the generated clock that drives the 6507, and Phi2 should be the same as Phi1, but one
// "color clock" delayed, and it drives RIOT and parts of TIA. The actual "clk" port is any PLL.

assign CC = ce;

always_ff @(posedge clk) begin : phi0_gen
	reg [1:0] phi_div;
	reg [1:0] hp_cnt;
	phi0 <= 0;
	phi2_gen <= 0;
	HP1 <= 0;
	HP2 <= 0;

	if (reset) begin
		phi_div <= 0;
		hp_cnt <= 0;
		phi2_gen <= 0;
	end else if (ce) begin
		phi_div <= phi_div + 1'd1;
		hp_cnt <= hp_cnt + 1'd1;
		if (rsync) begin
			hp_cnt <= 0;
			HP1 <= 1;
		end
		if (hp_cnt == 0)
			HP1 <= 1;
		if (hp_cnt == 2)
			HP2 <= 1;

		if (phi_div >= 2) begin
			phi_div <= 0;
		end

		if (phi_div == 2) begin
			phi0 <= 1;
			phase <= 0;
		end

		if (phi_div == 0) begin
			phi2_gen <= 1;
			phase <= 1;
		end
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

always_comb begin
	casex ({pfp, (pf | bl), (p1 | m1), (p0 | m0)})
		4'bX_001: col_select = 4'b0001;
		4'bX_010: col_select = 4'b0010;
		4'bX_011: col_select = 4'b0001;
		4'bX_100: col_select = 4'b0100;
		4'b0_101: col_select = 4'b0001;
		4'b0_110: col_select = 4'b0010;
		4'b0_111: col_select = 4'b0001;
		4'b1_101: col_select = score ? (cntd ? 4'b0010 : 4'b0001) : 4'b0100;
		4'b1_110: col_select = score ? (cntd ? 4'b0010 : 4'b0001) : 4'b0100;
		4'b1_111: col_select = score ? (cntd ? 4'b0010 : 4'b0001) : 4'b0100;
		default: col_select = 4'b1000;
	endcase
end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////
module TIA2
(
	// Original Pins
	input        clk,
	output       phi0,
	input        phi2,
	input        RW_n,
	output reg   rdy,
	input  [5:0] addr,
	input  [7:0] d_in,
	output logic [7:0] d_out,
	input  [3:0][7:0] i,     // On real hardware, these would be ADC pins. i0..3
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
	input        video_ce,
	output       vblank,
	output       hblank,
	output       vsync,
	output       hsync,
	output       phi2_gen
);

reg [7:0] wreg[64]; // Write registers. Only 44 are used.
reg [7:0] rreg[16]; // Read registers.
reg rdy_latch; // buffer for the rdy signal
reg [14:0] collision;

wire [7:0] read_val;
wire cs = ~cs0_n & ~cs2_n; // Chip Select (cs1 and 3 were NC)
wire phase; // 0 = phi0, 1 = phi2
wire wsync,rsync,resp0,resp1,resm0,resm1,resbl,hmove,hmclr,cxclr; // Strobe register signals
wire [3:0] color_select;
wire p0, p1, m0, m1, bl, pf; // Current object active flags
wire aclk0, aclk1, cntd;
wire HP1, HP2; // Horizontal phase clocks
wire cc; // Color Clock (original oscillator speed)
wire rhb, shb, wsr; // Hblank triggers

assign d_out[5:0] = 6'h00;
assign BLK_n = ~(hblank | vblank);
assign sync = ~(hsync | vsync);
assign vsync = wreg[VSYNC][1];
assign vblank = wreg[VBLANK][1];

// Address Decoder
// Register writes happen when Phi2 falls, or in our context, when Phi0 rises.
// Register reads happen when Phi2 is high. This is relevant in particular to RIOT which is clocked on Phi2.

// always_comb begin
// 	d_out[7:6] = 2'b11;
// 	if (cs & RW_n) begin
// 		if (addr[3:0] == INPT4 && ~wreg[VSYNC][6])
// 			d_out[7:6] = {i4, 1'b1};
// 		else if (addr[3:0] == INPT5 && ~wreg[VSYNC][6])
// 			d_out[7:6] = {i5, 1'b1};
// 		else
// 			d_out[7:6] = rreg[addr[3:0]][7:6]; // reads only use the lower 4 bits of addr
// 	end
// end

always @(posedge clk) if (rst) begin
	d_out[7:6] <= 2'd0;
	wreg <= '{64{8'h00}};
end else if (phi2 & cs & ~RW_n) begin
	wreg[addr] <= d_in;
end else if (phi2 & cs & RW_n) begin
	if (addr[3:0] == INPT4 && ~wreg[VBLANK][6])
		d_out[7:6] <= {i4, 1'b0};
	else if (addr[3:0] == INPT5 && ~wreg[VBLANK][6])
		d_out[7:6] <= {i5, 1'b0};
	else
		d_out[7:6] <= rreg[addr[3:0]][7:6]; // reads only use the lower 4 bits of addr
end

// "Strobe" registers have an immediate effect
always_comb begin
	{wsync,rsync,resp0,resp1,resm0,resm1,resbl,hmove,hmclr,cxclr} = '0;
	if (~RW_n && cs && phi2) begin
		case(addr)
			WSYNC: wsync = 1;
			RSYNC: rsync = 1;
			RESP0: resp0 = 1;
			RESP1: resp1 = 1;
			RESM0: resm0 = 1;
			RESM1: resm1 = 1;
			RESBL: resbl = 1;
			HMOVE: hmove = 1;
			HMCLR: hmclr = 1;
			CXCLR: cxclr = 1;
			default: {wsync,rsync,resp0,resp1,resm0,resm1,resbl,hmove,hmclr,cxclr} = '0;
		endcase
	end
end

// Unaccount for:
// VDELP0

// Submodules

wire [7:0] uv_gen;
wire vs_gen, vb_gen, hs_gen, hb_gen;

// frame_gen frame
// (
// 	.clk       (clk),
// 	.rst       (rst),
// 	.cc        (cc),
// 	.enable    (1),
// 	.hbs       (shb),
// 	.hbr       (rhb),
// 	.vblank_in (wreg[VBLANK][1]),
// 	.vsync_in  (wreg[VSYNC][1]),
// 	.uv_in     ({col, lum}),
// 	.uv_out    (uv_gen)

// );

clockgen clockgen
(
	.clk      (clk),
	.ce       (ce),
	.CC       (cc),
	.phi0     (phi0),
	.phi2_gen (phi2_gen),
	.rsync    (rsync | rst),
	.HP1      (HP1),
	.HP2      (HP2),
	.phase    (phase)
);

horiz_gen h_gen
(
	.clk    (clk),
	.ce     (ce),
	.HP1    (HP1),
	.HP2    (HP2),
	.rsync  (rsync | rst),
	.hmove  (hmove),
	.hsync  (hsync),
	.hblank (hblank),
	.cntd   (cntd),
	.aud0   (aclk0),
	.aud1   (aclk1),
	.shb    (shb),
	.rhb    (rhb),
	.wsr    (wsr)
);

playfield playfield
(
	.clk(clk),
	.reset(rst),
	.HP2(HP2),
	.hblank(hblank),
	.reflect(wreg[CTRLPF][0]),
	.cnt(cntd),
	.pfc({wreg[PF2], wreg[PF1], wreg[PF0][7:4]}),
	.pf(pf)
);

player_o player0
(
	.clk(clk),
	.cc(cc),
	.resp(resp0),
	.reset(rst),
	.hmove(hmove),
	.hmclr(hmclr),
	.hmp(wreg[HMP0][7:4]),
	.grp(wreg[GRP0]),
	.refp(wreg[REFP0][3]),
	.size(wreg[NUSIZ0][2:0]),
	.p(p0)
);

player_o player1
(
	.resp(resp1),
	.hmove(hmove),
	.hmclr(hmclr),
	.hmp(wreg[HMP1][7:4]),
	.grp(wreg[GRP1]),
	.refp(wreg[REFP1][3]),
	.size(wreg[NUSIZ1][2:0]),
	.p(p1)
);

missile_o missile0
(
	.resm(resm0),
	.resmp(wreg[RESMP0][1]),
	.hmove(hmove),
	.hmclr(hmclr),
	.enam(wreg[ENAM0][1]),
	.hmm(wreg[HMM0][7:4]),
	.size(wreg[NUSIZ0][5:4]),
	.m(m0)
);

missile_o missile1
(
	.resm(resm1),
	.resmp(wreg[RESMP1][1]),
	.hmove(hmove),
	.hmclr(hmclr),
	.enam(wreg[ENAM1][1]),
	.hmm(wreg[HMM1][7:4]),
	.size(wreg[NUSIZ1][5:4]),
	.m(m1)
);

ball_o ball
(
	.clk(clk),
	.resbl(resbl),
	.hmove(hmove),
	.hmclr(hmclr),
	.enabl(wreg[ENABL][1]),
	.hmbl(wreg[HMBL][7:4]),
	.size(wreg[CTRLPF][5:4]),
	.bl(bl)
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
	if (hblank | vblank)
		{col, lum} = 7'd0; // My own innovation for modern displays, not part of the chip
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
	if (rst) begin
		rdy <= 1;
	end else if (cc) begin
		if (wsync)
			rdy <= 0;

		if (wsr)
			rdy <= 1;
	end
end

// Calculate the collisions
reg hsync_clock;

always_ff @(posedge clk) begin : read_reg_block
	reg old_hsync;
	reg [8:0] x;
	reg [7:0] icount;

	hsync_clock <= 0;
	old_hsync <= hsync;
	if (~old_hsync & hsync)
		hsync_clock <= 1;

	if (rst) begin
		rreg <= '{16{8'h00}};

	end else if (phi0) begin
		if (cxclr) begin
			{rreg[CXM0P][7:6], rreg[CXM1P][7:6], rreg[CXP0FB][7:6],
				rreg[CXP1FB][7:6], rreg[CXM0FB][7:6], rreg[CXM1FB][7:6],
				rreg[CXBLPF][7:6], rreg[CXPPMM][7:6]} <= '0;
		end else begin
			rreg[CXM0P][7:6]  <= (rreg[CXM0P][7:6] | {(m0 & p1), (m0 & m0)});
			rreg[CXM1P][7:6]  <= (rreg[CXM1P][7:6] | {(m1 & p0), (m1 & p1)});
			rreg[CXP0FB][7:6] <= (rreg[CXM1P][7:6] | {(p0 & pf), (p0 & bl)});
			rreg[CXP1FB][7:6] <= (rreg[CXP1FB][7:6]| {(p1 & pf), (p1 & bl)});
			rreg[CXM0FB][7:6] <= (rreg[CXM0FB][7:6]| {(m0 & pf), (m0 & bl)});
			rreg[CXM1FB][7:6] <= (rreg[CXM1FB][7:6]| {(m1 & pf), (m1 & bl)});
			rreg[CXBLPF][7:6] <= (rreg[CXBLPF][7:6]| {(bl & pf), 1'b0});
			rreg[CXPPMM][7:6] <= (rreg[CXPPMM][7:6]| {(p0 & p1), (m0 & m1)});
		end

		// So analog input requires simulating the capacitor recharge of the paddle
		// circuit. This generally takes 1 hsync per (196 - (value / 2)) of the given input port.
		for (x = 0; x < 4; x = x + 1'd1) begin
			rreg[{2'b10, x[1:0]}][7] <= ((8'd196 - i[x[1:0]][7:1]) <= icount);
		end
	end

	if (~wreg[VBLANK][6]) begin
		{rreg[INPT4][7], rreg[INPT5][7]} <= '1;
	end else begin
		if (~i4)
			rreg[INPT4][7] <= 0;
		if (~i5)
			rreg[INPT5][7] <= 0;
	end

	if (phi2 & cs & ~RW_n) begin
		if (addr[3:0] == VBLANK && d_in[6]) begin
			{rreg[INPT4][7], rreg[INPT5][7]} <= '1;
		end
	end

	if (wreg[VSYNC][7]) begin
		icount <= 0;
	end else if (hsync_clock && icount < 255) begin
		icount <= icount + 1'd1;
	end
end

// Audio output is non-linear, and this table represents the proper compressed values of
// audv0 + audv1.
// Generated based on the info here: https://atariage.com/forums/topic/271920-tia-sound-abnormalities/

reg [15:0] audio_lut[32] = '{
	16'h0000, 16'h0842, 16'h0FFF, 16'h1745, 16'h1E1D, 16'h2492, 16'h2AAA, 16'h306E,
	16'h35E4, 16'h3B13, 16'h3FFF, 16'h44AE, 16'h4924, 16'h4D64, 16'h5173, 16'h5554,
	16'h590A, 16'h5C97, 16'h5FFF, 16'h6343, 16'h6665, 16'h6968, 16'h6C4D, 16'h6F17,
	16'h71C6, 16'h745C, 16'h76DA, 16'h7942, 16'h7B95, 16'h7DD3, 16'h7FFF, 16'hFFFF
};

reg [15:0] audio_lut_single[16] = '{
	16'h0000, 16'h0C63, 16'h17FF, 16'h22E8, 16'h2D2C, 16'h36DB, 16'h3FFF, 16'h48A5,
	16'h50D6, 16'h589C, 16'h5FFF, 16'h6705, 16'h6DB6, 16'h7416, 16'h7A2D, 16'h7FFF
};

endmodule

