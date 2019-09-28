
// Atari 7800 cart mapper support by Kitrinx, 2019.
// GPL3 Licence.

// Covers the bank switching, ram, and audio hardware from carts
module cart
(
	input  logic        clock, clock100, pclk_2,
	input  logic [15:0] address_in,
	input  logic [7:0]  din,
	input  logic [7:0]  rom_din,
	input  logic [9:0]  cart_flags,
	input  logic [31:0] cart_size,
	input  logic        cart_cs,
	input  logic        rw, // Write low
	input  logic        reset,

	output logic [7:0]  dout,
	output logic [3:0]  pokey_audio,
	output logic [17:0] rom_address
);

logic [3:0] bank_reg;
reg [7:0] ram_dout;

logic rom_cs, ram_cs, pokey_cs;
logic [2:0] hardware_map[8];
logic [3:0] bank_map[8];
logic [2:0] bank_type; // 00 = Supergame, 01 = Activision, 02 = none
logic [31:0] address_offset;
logic [2:0] cart_cs_reg;
logic [3:0] bank_mask;

always_ff @(negedge clock) begin
	hardware_map <= '{3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0};
	bank_map <= '{4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0};
	bank_type <= 3'b000;
	address_offset <= 32'd0;
	bank_mask <= 4'b1111;

	// Banking mode selector
	if (cart_flags[8]) begin                                   // Activision
		hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
		bank_map <= '{4'd0, 4'd0, 4'd13, 4'd12, 4'd15, 4'd0, 4'd0, 4'd14};
		bank_map[5] <= {bank_reg[2:0], 1'b0};
		bank_map[6] <= {bank_reg[2:0], 1'b1};
		bank_type <= 3'd1;
	end else if (cart_flags[9]) begin                           // Absolute
		hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
		bank_map <= '{4'd0, 4'd0, 4'd0, 4'd0, 4'd2, 4'd2, 4'd3, 4'd3};
		bank_map[2] <= {3'b000, |bank_reg[1:0]};
		bank_map[3] <= {3'b000, |bank_reg[1:0]};
		bank_type <= 3'd0;
	end else if (cart_flags[3] || cart_size > 32'h20000) begin  // SuperGame 9 bank
		hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
		bank_map <= '{4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd8, 4'd8};
		bank_map[4] <= bank_reg[3:0] + 1'b1;
		bank_map[5] <= bank_reg[3:0] + 1'b1;
		bank_type <= 3'd0;
	end else if (cart_flags[1] || cart_size >= 32'h10000) begin // SuperGame
		hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
		bank_map <= '{4'd0, 4'd0, 4'd6, 4'd6, 4'd0, 4'd0, 4'd7, 4'd7};
		bank_map[4] <= bank_reg[3:0];
		bank_map[5] <= bank_reg[3:0];
		bank_mask <= (cart_size == 32'h10000) ? 4'b0011 : 4'b0111; // 64k carts have 4 banks mirrored
		bank_type <= 3'd0;
	end else begin                                     // Not banked
		if (cart_size <= 32'h2000) // A7808
			hardware_map <= '{3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd1};
		else if (cart_size <= 32'h4000) // A7816
			hardware_map <= '{3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd1, 3'd1};
		else if (cart_size <= 32'h8000) // A7832
			hardware_map <= '{3'd0, 3'd0, 3'd0, 3'd0, 3'd1, 3'd1, 3'd1, 3'd1};
		else if (cart_size <= 32'hC000) // A7848
			hardware_map <= '{3'd0, 3'd0, 3'd0, 3'd1, 3'd1, 3'd1, 3'd1, 3'd1};
		address_offset <= (cart_size - 1'd1) <= 32'hFFFF ? 32'hFFFF - (cart_size - 1'd1) : 32'd0;
		bank_type <= 3'd2;
	end

	// 450 POKEY
	if (cart_flags[6]) begin // POKEY at $450
		hardware_map[0] <= 3'd2;
	end

	// Alternative hardware at $4k selector
	if (cart_flags[0]) begin // POKEY at $4k
		hardware_map[2] <= 3'd2;
		hardware_map[3] <= 3'd2;
	end else if (cart_flags[2]) begin // Supergame RAM at $4k
		hardware_map[2] <= 3'd3;
		hardware_map[3] <= 3'd3;
	end else if (cart_flags[5]) begin // Banked RAM at $4k
		hardware_map[2] <= 3'd3;
		hardware_map[3] <= 3'd3;
	end else if (cart_flags[7]) begin // Mirror RAM at $4k
		hardware_map[2] <= 3'd3;
		hardware_map[3] <= 3'd3;
	end /*else if (cart_flags[4]) begin // Bank 6 at $4k
		hardware_map[2] = 3'd4;
		hardware_map[3] = 3'd4;
		bank_map[2] = 4'd6;
		bank_map[3] = 4'd6;
	end*/
end

logic [2:0] address_index;
assign address_index = address_in[15:13];

// Address translation
always_comb begin
	pokey_cs = 0;
	ram_cs = 0;
	rom_address = 17'd0;
	if (cart_cs) case (hardware_map[address_index])
		3'd1: begin           // ROM Data
			rom_address = {1'b0, address_in - address_offset[15:0]};
		end
		3'd2: pokey_cs = 1'b1;// POKEY
		3'd3: ram_cs = 1'b1;  // RAM
		3'd4: begin           // Banked ROM
			case (bank_type)
				3'd0: // SuperGame
					rom_address = {(bank_map[address_index] & bank_mask), address_in[13:0]};
				3'd1: // Activision
					rom_address = {1'b0, bank_map[address_index], address_in[12:0]};
				3'd2: // No banking
					rom_address = {2'b00, address_in - address_offset[15:0]};
			endcase
		end
		//default: // High impedance
	endcase
end

//CS Type:
//00 - high impedance
//01 - ROM Data
//02 - POKEY
//03 - RAM
//04 - Banked ROM
//m_bank_mask = (size / 0x4000) - 1
//m_base_rom = 0x10000 - size;

always_ff @(posedge clock) begin
	if (reset) begin
		bank_reg <= 4'd0;
	end else if (~rw & cart_cs) begin
		if (bank_type == 3'd0 && (hardware_map[address_index] == 3'd4)) //supergame bank
			bank_reg <= din[3:0];
		else if (bank_type == 3'd1 && (address_in[15:4]) == 12'hFF8) // activision bank
			bank_reg <= address_in[3:0];
	end
end

spram #(.addr_width(14)) cart_ram
(
	.clock(clock),
	.address(address_in[13:0]),
	.data(din),
	.wren(~rw),
	.q(ram_dout),
	.cs(ram_cs)
);

always_ff @(posedge clock) if (cart_cs) cart_cs_reg <= hardware_map[address_index];

//CS Type:
//00 - high impedance
//01 - ROM Data
//02 - POKEY
//03 - RAM
//04 - Banked ROM
always_comb begin
	case(cart_cs_reg)
		3'd0: dout = 8'bZZZZZZZZ;   // High Impedance
		3'd1: dout = rom_din;       // ROM Data
		3'd2: dout = pokey4k_dout;  // POKEY
		3'd3: dout = ram_dout;      // RAM Data
		default: dout = 8'bZZZZZZZZ;
	endcase
end

logic pokey4k_dout;
logic pokey4k_aud;
logic pokey4k_audio;

// POKEY pokey4k
// (
// 	.Din(din),
// 	.Dout(pokey4k_dout),
// 	.A(address_in[3:0]), //4 bits
// 	.P(8'd0), //pot?
// 	.phi2(pclk_2), //pclk_2
// 	.rw(rw), //write low
// 	.cs0Bar(~pokey_cs),
// 	.aud(pokey4k_aud), //producing audio
// 	.audio(pokey4k_audio)
// 	.clk(clk100) //100mhz
// );

endmodule: cart

/*
0		A7808,        // Atari7800 non-bankswitched 8KB cart
1		A7816,        // Atari7800 non-bankswitched 16KB cart
2		A7832,        // Atari7800 non-bankswitched 32KB cart
		A7832P,       // Atari7800 non-bankswitched 32KB cart w/Pokey
3		A7848,        // Atari7800 non-bankswitched 48KB cart
4		A78SG,        // Atari7800 SuperGame cart
		A78SGP,       // Atari7800 SuperGame cart w/Pokey
5		A78SGR,       // Atari7800 SuperGame cart w/RAM
6		A78S9,        // Atari7800 SuperGame cart, nine banks
7		A78S4,        // Atari7800 SuperGame cart, four banks
8		A78S4R,       // Atari7800 SuperGame cart, four banks, w/RAM
9		A78AB,        // F18 Hornet cart (Absolute)
10		A78AC,        // Double dragon cart (Activision)
*/

// Cart Info:
// bit 0 - pokey at $4000
// bit 1 - supergame bank switched
// bit 2 - supergame ram at $4000
// bit 3 - rom at $4000
// bit 4 - Bank 6 mapped at $4k
// bit 5 - supergame banked ram
// bit 6 - pokey at $450
// bit 7 - Mirror RAM at $4000 
// bit 8 - activision
// bit 9 - Absolute
// 10-15 - ???/unused
// Manage addresses in 8k chunks

//  bit 0 [0x01] - POKEY at $4000
//  bit 1 [0x02] - SuperCart bank switched
//  bit 2 [0x04] - SuperCart RAM at $4000
//  bit 3 [0x08] - bank 0 of 144K ROM at $4000
//  bit 4 [0x10] - bank 6 at $4000
//  bit 5 [0x20] - banked RAM at $4000
//  bit 6 [0x40] - POKEY at $0450
//  bit 7 [0x80] - Mirror RAM at $4000
// bit 8 - Absolute
// bit 9 - activision


// cart_type1:

// 0000_0000: (by size)
// if (size <= 0x2000) A7808;
// if (size <= 0x4000) A7816;
// if (size <= 0x8000) (w/pokey) A7832P else A7832;
// if (size <= 0xC000) A7848;
// if (size > 131072) A78S9

// 0000_0001:
// 	if (size <= 0x8000) (w/pokey) A7832P
// 0000_0010: A78SG 
// 0000_0011: A78SGP

// 0000_0100:
// 0000_0101:
// 0000_0110:
// 0000_0111: A78S4R

// 0000_1000:
// 0000_1001:
// 0000_1010:
// 0000_1011: A78S4
// 1_0000_0000: A78AB // The appear to be reversed in the atari forum romset
// 10_0000_0000: A78AC

