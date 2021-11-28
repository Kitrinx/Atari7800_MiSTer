// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.

module mapper_none
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	assign rom_a = {4'd0, a_in[11:0]};

endmodule

module mapper_F8
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic bank;

	always @(posedge clk) begin
		if (a_change) begin
			case (a_in)
				13'h1FF8: bank <= 0;
				13'h1FF9: bank <= 1;
				default: ;
			endcase
		end
		if (reset)
			bank <= 1;
	end

	assign rom_a = {3'd0, bank, a_in[11:0]};

endmodule

module mapper_F6
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic [1:0] bank;

	always @(posedge clk) begin
		if (a_change) begin
			case (a_in)
				13'h1FF6: bank <= 2'd0;
				13'h1FF7: bank <= 2'd1;
				13'h1FF8: bank <= 2'd2;
				13'h1FF9: bank <= 2'd3;
				default: ;
			endcase
		end
		if (reset)
			bank <= 0;
	end

	assign rom_a = {2'd0, bank, a_in[11:0]};

endmodule

module mapper_FE // SCABS
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a,
	// Special
	input           ce
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic bank;
	logic latch_next;

	always @(posedge clk) begin
		if (ce) begin
			if (a_in == 13'h1FE)
				latch_next <= 1;
			else
				latch_next <= 0;

			if (latch_next)
				bank <= ~d_in[5];
		end

		if (reset) begin
			bank <= 0;
			latch_next <= 0;
		end
	end

	assign rom_a = {3'd0, bank, a_in[11:0]};

endmodule

module mapper_E0
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic [2:0] banks[3];
	logic [2:0] current_bank;

	always @(posedge clk) begin
		if (a_change) begin
			case (a_in[12:3])
				{9'h1FE, 1'b0}: banks[0] <= a_in[2:0];
				{9'h1FE, 1'b1}: banks[1] <= a_in[2:0];
				{9'h1FF, 1'b0}: banks[2] <= a_in[2:0];
				default: ;
			endcase
		end
		if (reset)
			banks <= '{3'd0, 3'd0, 3'd0};
	end

	always_comb begin
		case (a_in[11:10])
			0: current_bank = banks[0];
			1: current_bank = banks[1];
			2: current_bank = banks[2];
			3: current_bank = 3'b111;
		endcase
	end

	assign rom_a = {3'd0, current_bank, a_in[9:0]};

endmodule

module mapper_3F
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic [7:0] bank;
	wire [7:0] current_bank = ~a_in[11] ? bank : 8'hFF;

	always @(posedge clk) begin
		if (a_in == 13'h3F)
			bank <= d_in;

		if (reset)
			bank <= '0;
	end

	assign rom_a = {current_bank, a_in[10:0]};

endmodule

module mapper_F4
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic [2:0] bank;

	always @(posedge clk) begin
		if (a_change) begin
			case (a_in)
				13'h1FF4: bank <= 3'd0;
				13'h1FF5: bank <= 3'd1;
				13'h1FF6: bank <= 3'd2;
				13'h1FF7: bank <= 3'd3;
				13'h1FF8: bank <= 3'd4;
				13'h1FF9: bank <= 3'd5;
				13'h1FFA: bank <= 3'd6;
				13'h1FFB: bank <= 3'd7;
				default: ;
			endcase
		end
		if (reset)
			bank <= 0;
	end

	assign rom_a = {1'd0, bank, a_in[11:0]};

endmodule

module mapper_P2
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a,
	// Special
	input           ce
);
	logic direct_en, rom_en, and_do_en, music_en;
	logic bank;
	logic [10:0] counters[8];
	logic [2:0] music_modes;
	logic [7:0] tops[8];
	logic [7:0] bottoms[8];
	logic [7:0] flags[8];
	logic [7:0] rand_val;
	logic dpc_oe;
	logic [9:0] music_div;
	logic [15:0] music_clock;
	logic [15:0] rom_a_next;

	wire [7:0] amplitude_lut[8] = '{8'h0F, 8'h0B, 8'h0A, 8'h06, 8'h09, 8'h05, 8'h04, 8'h00};
	wire [7:0] rom_do_i = ~|dpc_addr ? (~music_en ? rand_val : amplitude_lut[music_amp_index]) :
		((dpc_addr == 3'd7 || dpc_addr == 3'd2) ? flags[index] : 8'd0);

	assign flags_out = {13'd0, dpc_oe && and_do_en, dpc_oe && direct_en};
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : (dpc_oe ? 8'hFF : 8'h00)) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;
	assign d_out = rom_do_i;

	wire [2:0] index = a_in[2:0];
	wire is_dpc = ~|a_in[11:7];
	wire dpc_rw = ~a_in[6];
	wire [2:0] dpc_addr = a_in[5:3];
	wire [2:0] ain_minus_5 = (index - 3'd5);
	wire [2:0] music_amp_index = {
		music_modes[2] & flags[7][0],
		music_modes[1] & flags[6][0],
		music_modes[0] & flags[5][0]
	};

	assign rom_en = is_dpc && dpc_rw && dpc_addr == 3'd1;
	assign and_do_en = is_dpc && dpc_rw && dpc_addr == 3'd2;
	assign direct_en = is_dpc && dpc_rw && ~(rom_en || and_do_en);
	assign music_en = is_dpc && dpc_addr == 3'b000 && a_in[2];

	assign dpc_oe = ~is_dpc || (is_dpc && dpc_rw);
	assign rom_a = rom_a_next;

	always @(posedge clk) begin
		if (a_change) begin
			rom_a_next <= (is_dpc && (dpc_addr == 1 || dpc_addr == 2)) ? {5'b00100, ~counters[index]} : {3'd0, bank, a_in[11:0]};
			if (a_in[12]) begin
				rand_val <= {rand_val[6:0], ~(rand_val[7] ^ rand_val[5] ^ rand_val[4] ^ rand_val[3])};
				if (is_dpc) begin
					if (dpc_rw) begin // read
						if (index < 5 || (index >= 5 && music_modes[ain_minus_5])) begin
							counters[index] <= counters[index] - 1'd1;
						end

						if (counters[index][7:0] == tops[index]) begin
							flags[index] <= 8'hFF;
						end else if (counters[index][7:0] == bottoms[index]) begin
							flags[index] <= 8'h00;
						end
					end else begin // Write
						case (dpc_addr)
							3'h0: begin
								tops[index] <= d_in;
								if (counters[index][7:0] == d_in)
									flags[index] <= 8'hFF;
								else
									flags[index] <= 8'h00;
							end
							3'h1: bottoms[index] <= d_in;
							3'h2: counters[index][7:0] <= d_in;
							3'h3: begin
								counters[index][10:8] <= d_in[2:0];
								if (index >= 3'd5)
									music_modes[ain_minus_5] <= d_in[4];
							end
							3'h6: rand_val <= 8'h01;
							default: ;
						endcase
					end
				end else begin // F8 banking if it's not a DPC address
					case (a_in)
						13'h1FF8: bank <= 0;
						13'h1FF9: bank <= 1;
						default: ;
					endcase
				end
			end
		end

		if (ce) begin
			music_div <= music_div + 1'd1;
			if (music_div == 178) begin // Divide down to 15-20khz (180 == 19.88khz, 170 = 21khz)
				music_div <= 10'd0;
				music_clock <= music_clock + 1'd1;
				if (music_clock % (tops[5] + 1'd1) > bottoms[5])
					flags[5] <= 8'hFF;
				else
					flags[5] <= 8'h00;

				if (music_clock % (tops[6] + 1'd1) > bottoms[6])
					flags[6] <= 8'hFF;
				else
					flags[6] <= 8'h00;

				if (music_clock % (tops[7] + 1'd1) > bottoms[7])
					flags[7] <= 8'hFF;
				else
					flags[7] <= 8'h00;
			end
		end
		if (reset) begin
			bank <= 0;
			rand_val <= 8'h01;
			bottoms <= '{8{8'd0}};
			tops <= '{8{8'd0}};
			counters <= '{8{11'd0}};
			flags <= '{8{8'd0}};
			music_modes <= '0;
			music_clock <= '0;
			music_div <= '0;
		end
	end

endmodule

module mapper_FA
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : (a_in[12:9] == 4'b1000);
	assign ram_a = sc ? {4'd0, a_in[6:0]} : {3'd0, a_in[7:0]};
	assign ram_rw = sc ? a_in[7] : a_in[8];

	logic [1:0] bank;

	always @(posedge clk) begin
		if (a_change) begin
			case (a_in)
				13'h1FF8: bank <= 2'd0;
				13'h1FF9: bank <= 2'd1;
				13'h1FFA: bank <= 2'd2;
				default: ;
			endcase
		end
		if (reset)
			bank <= 0;
	end

	assign rom_a = {2'd0, bank, a_in[11:0]};

endmodule

module mapper_CV
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : (a_in[12:11] == 2'b10);
	assign ram_a = sc ? {4'd0, a_in[6:0]} : {1'd0, a_in[9:0]};
	assign ram_rw = sc ? a_in[7] : ~a_in[10];

	assign rom_a = {4'd0, a_in[10:0]};
endmodule

module mapper_2K
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	assign rom_a = {4'd0, a_in[10:0]};

endmodule

module mapper_UA
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a,
	// special
	input           swapped // Swapped flag for the UASW mapper (Mickey)
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic bank;

	always @(posedge clk) begin
		if (a_change) begin
			case (a_in & 13'h1260)
				13'h0220: bank <= swapped;
				13'h0240: bank <= ~swapped;
				default: ;
			endcase
		end
		if (reset)
			bank <= 0;
	end

	assign rom_a = {3'd0, bank, a_in[11:0]};

endmodule

module mapper_E7
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  logic [15:0]  rom_a
);
	logic [2:0] bank;
	logic [1:0] ram_bank;

	// FIXME: Add upper ram bank?
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = (((a_in[12:11] == 2'b10) && &bank) || a_in[12:9] == 4'b1100);
	assign ram_a = (a_in[12:11] == 2'b10 ? {1'b0, a_in[9:0]} : {1'b1, ram_bank, a_in[7:0]});
	assign ram_rw = (a_in[12:11] == 2'b10 ? (a_in[10] || ~&bank) : a_in[8]);

	always_comb begin
		rom_a = {4'b0000, a_in[11:0]};
		if (a_in[12:11] == 2'b10) begin
			rom_a = {1'b0, bank, a_in[10:0]};
		end else if ((a_in[12:11] == 2'b11) || (a_in[12:10] == 3'b101)) begin
			rom_a = {5'b01111, a_in[10:0]};
		end
	end

	always @(posedge clk) begin
		if (a_change) begin
			if (a_in[12:4] == 9'h1FE) begin
				if (~a_in[3])
					bank <= a_in[2:0];
				else if (~a_in[2])
					ram_bank <= a_in[1:0];
			end
		end
		if (reset)
			bank <= 0;
	end

endmodule

module mapper_F0
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic [3:0] bank;

	always @(posedge clk) begin
		if (a_change) begin
			if (a_in == 13'h1FF0)
				bank <= bank + 1'd1;
		end
		if (reset) begin
			bank <= 0;
		end
	end
	assign rom_a = {bank, a_in[11:0]};

endmodule

module mapper_32
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a,
	// Special
	input           cold_reset
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic [4:0] bank;
	logic old_reset;

	always @(posedge clk) begin
		old_reset <= reset;
		if (~old_reset && reset)
			bank <= bank + 1'd1;
		if (cold_reset)
			bank <= 0;
	end
	assign rom_a = {bank, a_in[10:0]};

endmodule

module mapper_AR
(
	input           clk,
	input           reset,
	input           cold_reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [12:0]  ram_a,
	output  [18:0]  rom_a,
	// Special
	input           ce, // 3.579 mhz
	output          ar_read,
	input   [7:0]   rom_do,
	input   [1:0]   tape_in,
	output  logic   audio_data,
	input   [18:0]  rom_size
);
	// These numbers represent ONE HALF the cycles
	// needed to achieve 340us for a 1 bit, and 227us for a 0 bit.
	// Thus the numbers are about 170us and 113.5us respectively.
	// Below we're calculating these numbers based on the same 3.579mhz
	// clock as the DPC mapper above.
	localparam CYCLES_PER_HALF_1        = 12'd608;
	localparam CYCLES_PER_HALF_0        = 12'd405;
	localparam PREAMBLE_CYCLES_PER_HALF = 12'd2384;
	localparam COOLDOWN_PERIOD          = 16'hFFF;
	
	typedef enum logic[3:0] {
		AR_START,
		AR_FETCH,
		AR_EQ_TONE,
		AR_PREAMBLE,
		AR_HEADER,
		AR_PREBANK,
		AR_BANK,
		AR_POSTAMBLE,
		AR_END
	} ar_load_state;

	logic [2:0] bank;
	logic [5:0] we_cycle;
	logic [7:0] bios_data;
	logic ram_we;
	logic [7:0] we_byte;
	logic rom_en;
	logic [18:0] preload_a;
	logic [7:0] header_a;
	logic [7:0] bank_a;
	ar_load_state state, state_next;
	logic [11:0] audio_timer;
	logic [3:0] bit_position;
	logic [7:0] page_position;
	logic header_toggle;
	logic  [7:0] page_count;
	logic [10:0] state_count;
	logic [16:0] tape_offset;
	logic fetch_byte;
	logic playback;
	logic current_bit;
	logic [7:0] audio_buffer;
	logic [15:0] cooldown;
	logic [1:0] bank_lut[8][2];
	logic [1:0] tape_num;
	logic eq_tone;

	// Banks 0-2 are the ram chip selects, bank 3 is the boot rom
	assign bank_lut[0] = '{2'd2, 2'd3};
	assign bank_lut[1] = '{2'd0, 2'd3};
	assign bank_lut[2] = '{2'd2, 2'd0};
	assign bank_lut[3] = '{2'd0, 2'd2};
	assign bank_lut[4] = '{2'd2, 2'd3};
	assign bank_lut[5] = '{2'd1, 2'd3};
	assign bank_lut[6] = '{2'd2, 2'd1};
	assign bank_lut[7] = '{2'd1, 2'd2};

	wire adata_select = a_in == 13'h1FF9;
	wire is_control_reg = a_in == 13'h1FF8;
	wire [3:0] bit_pos_minus_1 = bit_position - 1'd1;
	wire rom_bank = &current_bank;
	wire [1:0] current_bank = ~a_in[11] ? bank_lut[bank][0] : bank_lut[bank][1];
	wire adc_load = tape_in[1];

	//wire eq_tone = state == AR_EQ_TONE;
	assign flags_out = {15'd0, rom_bank || ~ram_rw || adata_select};
	assign oe = a_in[12] ? 8'hFF : 8'h00;
	assign ram_sel = a_in[12] && ~rom_bank;
	assign ram_a = {current_bank, a_in[10:0]};
	assign ram_rw = ~(a_in[12] && ram_we && we_cycle[5] && ~a_change && ~is_control_reg && ~rom_bank);
	assign rom_a = preload_a + tape_offset;
	assign ar_read = ce;
	assign d_out = ~ram_rw ? we_byte : (adata_select ? {7'd0, audio_data} : bios_data);

	// Supercharger
	spram #(.addr_width(11), .mem_init_file("ar.mif")) ar_rom
	(
		.clock      (clk),
		.address    (a_in[10:0]),
		.enable     (1),
		.q          (bios_data)
	);
	
	always_comb begin
		case (state_next)
			AR_HEADER: preload_a = {6'b100000, header_a};
			AR_PREBANK: preload_a = {6'b100000, page_position + (header_toggle ? 8'h40 : 8'h10)};
			AR_BANK: preload_a = {3'd0, page_position, bank_a};
			default: preload_a = 19'd0;
		endcase
		case (tape_num)
			0: tape_offset = 17'h0;
			1: tape_offset = 17'h2100;
			2: tape_offset = 17'h4200;
			3: tape_offset = 17'h6300;
			default: tape_offset = 17'h0;
		endcase
	end

	always @(posedge clk) begin
		if (adc_load)
			audio_data <= tape_in[0];

		if (ce) begin // Timed with a 3.579mhz clock (2600 oscillator freq)
			fetch_byte <= 0;
			if (playback) begin
				audio_timer <= audio_timer + 1'd1;
				if (eq_tone && audio_timer == PREAMBLE_CYCLES_PER_HALF) begin
					audio_timer <= 0;
					audio_data <= ~audio_data;
					state_count <= state_count + 1'd1;
					if (&state_count[10:0]) begin
						fetch_byte <= 1;
						eq_tone <= 0;
					end
				end else if (~eq_tone && audio_timer == (current_bit ? CYCLES_PER_HALF_1 : CYCLES_PER_HALF_0)) begin
					audio_timer <= 0;
					bit_position <= bit_pos_minus_1;
					audio_data <= bit_position[0];
					current_bit <= audio_buffer[bit_pos_minus_1[3:1]];
					fetch_byte <= bit_position == 1;
				end
			end

			case (state)
				AR_START: begin
					header_a <= 0;
					fetch_byte <= 0;
					bit_position <= 0;
					page_position <= 0;
					eq_tone <= 0;
					state_count <= 0;
					bank_a <= 0;
					state <= AR_PREAMBLE;
					state_next <= AR_PREAMBLE;
					if (tape_offset >= rom_size)
						tape_num <= 0;
				end
				AR_EQ_TONE: begin // The calibration tone isn't really needed here
					playback <= 1;
					if (fetch_byte) begin
						state <= AR_PREAMBLE;
						state_next <= AR_PREAMBLE;
					end
				end
				AR_FETCH: begin
					if (fetch_byte) begin
						state <= state_next;
					end
				end
				AR_PREAMBLE: begin
					playback <= 1;
					audio_buffer <= &state_count[8:0] ? 8'h54 : 8'h55;
					state_count <= state_count + 1'd1;
					state_next <= &state_count[8:0] ? AR_HEADER : AR_PREAMBLE;
					state <= AR_FETCH;
				end
				AR_HEADER: begin
					audio_buffer <= rom_do;
					if (header_a == 3)
						page_count <= rom_do;
					if (header_a < 7) begin
						header_a <= header_a + 1'd1;
						state_next <= AR_HEADER;
					end else begin
						header_a <= 0;
						state_next <= AR_PREBANK;
					end
					state <= AR_FETCH;
				end
				AR_PREBANK: begin
					audio_buffer <= rom_do;
					header_toggle <= ~header_toggle;
					if (header_toggle) begin
						state_next <= AR_BANK;
					end else begin
						state_next <= AR_PREBANK;
					end
					state <= AR_FETCH;
				end
				AR_BANK: begin
					audio_buffer <= rom_do;
					if (&bank_a) begin
						page_position <= page_position + 1'd1;
						state_next <= (page_position == (page_count - 1'd1)) || (page_position == 23) ?
							AR_POSTAMBLE : AR_PREBANK;
					end else
						state_next <= AR_BANK;
					bank_a <= bank_a + 1'd1;
					state <= AR_FETCH;
				end
				AR_POSTAMBLE: begin
					audio_buffer <= 8'd0;
					state_count <= state_count + 1'd1;
					state <= AR_FETCH;
					state_next <= &state_count[8:0] ? AR_END : AR_POSTAMBLE;
					if (&state_count[8:0]) begin
						cooldown <= COOLDOWN_PERIOD;
						tape_num <= tape_num + 1'd1;
					end
				end
				AR_END: begin
					playback <= 0;
					audio_buffer <= 0;
					audio_data <= 0;
				end
			endcase
		end

		if (a_change) begin
			we_cycle <= {we_cycle[4:0], 1'b0};
			
			if (adata_select && ~playback) begin
				if (|cooldown)
					cooldown <= cooldown - 1'd1;
				else if (~adc_load)
					state <= AR_START;
			end

			if (a_in == 13'h1FF8) begin // Control Register
				bank <= we_byte[4:2];
				ram_we <= we_byte[1];
				//rom_en <= we_byte[0];
				we_cycle <= '0;
			end

			if (a_in[12] && ~|a_in[11:8] && (~|we_cycle[4:0] || ~ram_we)) begin
				we_cycle <= 5'd1;
				we_byte <= a_in[7:0];
			end
		end

		if (reset) begin
			tape_num <= 0;
			cooldown <= COOLDOWN_PERIOD;
			audio_data <= 0;
			state <= AR_END;
			state_next <= AR_END;
			bank <= 0;
			ram_we <= 0;
			we_cycle <= '0;
			//rom_en <= 1;
		end
	end

endmodule

module mapper_WD
(
	input           clk,
	input           reset,
	input           cold_reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	logic [2:0] bank_config;
	logic [3:0] pending_switch;
	logic [2:0] banks[4];
	
	// Four 1k bank slots with preset configurations as follows, indexed by hotspot addr
	logic [2:0] bank_lut[8][4];
	assign bank_lut[0] = '{3'd0, 3'd0, 3'd1, 3'd3};
	assign bank_lut[1] = '{3'd0, 3'd1, 3'd2, 3'd3};
	assign bank_lut[2] = '{3'd4, 3'd5, 3'd6, 3'd7};
	assign bank_lut[3] = '{3'd7, 3'd4, 3'd2, 3'd3};
	assign bank_lut[4] = '{3'd0, 3'd0, 3'd6, 3'd7};
	assign bank_lut[5] = '{3'd0, 3'd1, 3'd7, 3'd6};
	assign bank_lut[6] = '{3'd2, 3'd3, 3'd4, 3'd5};
	assign bank_lut[7] = '{3'd6, 3'd0, 3'd5, 3'd1};
	
	logic [2:0] bank_out;
	assign bank_out = banks[a_in[11:10]];
	
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = a_in[12] && ~|a_in[11:7];
	assign ram_a = {5'd0, a_in[5:0]};
	assign ram_rw = ~a_in[6] || ~ram_sel;
	assign rom_a = {6'd0, bank_out, a_in[9:0]};

	// Bankswitching is delayed by at least three cpu clocks, and is triggered by
	// address 0x30 through 0x3F. The bank is the bottom three bits.
	always @(posedge clk) begin
		if (a_change) begin
			pending_switch <= {pending_switch[2:0], 1'b0};
			if (pending_switch[3]) begin
				banks <= bank_lut[bank_config];
			end
			if (a_in[12:4] == 9'h003) begin
				pending_switch <= 3'd1;
				bank_config <= a_in[2:0];
			end
		end

		if (reset) begin
			bank_config <= 0;
			pending_switch <= 0;
			banks <= bank_lut[0];
		end
	end
endmodule

module mapper_3E
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [17:0]  ram_a,
	output  [18:0]  rom_a,
	// special
	input   [18:0]  rom_size
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = a_in[12] && ~a_in[11] && ram_en;
	assign ram_a = {ram_bank, a_in[9:0]};
	assign ram_rw = ~a_in[10] || ~ram_en || a_change;

	logic [7:0] bank;
	logic [4:0] ram_bank;
	logic ram_en;
	wire [7:0] highest_bank = rom_size[18:11] - 1'd1;

	wire [7:0] current_bank = ~a_in[11] ? bank : highest_bank;

	always @(posedge clk) begin
		case (a_in)
			13'h003F: begin
				bank <= d_in[7:0];
				ram_en <= 0;
			end
			13'h003E: begin
				ram_en <= 1;
				ram_bank <= d_in[4:0];
			end
		endcase

		if (reset) begin
			bank <= 4'd0;
			ram_bank <= 4'd0;
			ram_en <= 0;
		end
	end

	assign rom_a = {current_bank, a_in[10:0]};

endmodule

module mapper_SB
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic [6:0] bank;

	always @(posedge clk) begin
		if (a_change) begin
			if (a_in[12:11] == 2'b01)
				bank <= a_in[6:0];
		end

		if (reset)
			bank <= 3'd0;
	end

	assign rom_a = {bank, a_in[11:0]};

endmodule

module mapper_EF
(
	input           clk,
	input           reset,
	input           a_change,
	input           sc,
	input   [12:0]  a_in,
	input   [7:0]   d_in,
	output  [7:0]   d_out,
	output  [15:0]  flags_out,
	output  [7:0]   oe,
	output          ram_sel,
	output          ram_rw,
	output  [10:0]  ram_a,
	output  [18:0]  rom_a
);
	assign flags_out = 16'd0;
	assign d_out = 8'd0;
	assign oe = a_in[12] ? (~ram_rw && ram_sel ? 8'h00 : 8'hFF) : 8'h00;
	assign ram_sel = sc ? (a_in[12:8] == 5'b10000) : 1'd0;
	assign ram_a = sc ? {4'd0, a_in[6:0]} : 11'd0;
	assign ram_rw = sc ? a_in[7] : 1'd1;

	logic [3:0] bank;

	always @(posedge clk) begin
		if (a_change) begin
			if (a_in[12:4] == 9'h1FE)
				bank <= a_in[3:0];
		end

		if (reset)
			bank <= 0;
	end

	assign rom_a = {bank, a_in[11:0]};

endmodule

	// AR File Format
	// 3 2KB banks, each broken into 8 256 byte pages, for a total of 6KB.
	// 1 Useless empty 2KB bank that has no purpose, as a placeholder for ROM space I guess.
	// 256 bytes of header data that is organized as follows:
	// Byte 0: start address of tape code, lower byte
	// Byte 1: start address of tape code, upper byte
	// Byte 2: initial control register value
	// byte 3: total page count of game
	// Byte 4: checksum of header
	// Byte 5: index number for multi-load games (0 for first or single games)
	// Byte 6: progress counter of load LSB
	// Byte 7: progress counter of load MSB
	// Byte 8-15: reserved space
	// Byte 16-31: an array of 8 bit-packed values for the first 2kb, specifying the memory
	//  destination of the data, it follows the format: XXXPPPBB, X = useless P = page address, B =
	//  ram chip (bank) number.
	// Byte 32-63: same as previous except for the second 2kb
	// Byte 64-95: same as previous except for the third 2kb
	// Byte 96-103: padding
	// Byte 104-127: 24 bytes of checksums for each page of the 6kb of data.
	// The rest is padding.