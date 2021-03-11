
// Atari 7800 cart mapper support
// (c) Jamie Blanks, 2021
// For MiSTer use only

// Covers the bank switching, ram, and audio hardware from carts
module cart
(
	input  logic        clk_sys,
	input  logic        pclk0,
	input  logic        pclk1,
	input  logic [15:0] address_in,
	input  logic [7:0]  din,
	input  logic        halt_n,
	input  logic [7:0]  rom_din,
	input  logic [15:0] cart_flags,
	input  logic [31:0] cart_size,
	input  logic [7:0]  cart_save,
	input  logic        cart_cs,
	input  logic        dma_read,
	input  logic        rw, // Write low
	input  logic        reset,
	input  logic        hsc_en,
	input  logic  [7:0] cart_xm,

	output logic [7:0]  dout,
	output logic        cart_read,
	output logic [15:0] pokey_audio,
	output logic [15:0] ym_audio_r,
	output logic [15:0] ym_audio_l,
	output logic [24:0] rom_address
);

logic [7:0] bank_reg;
logic [7:0] ram_dout;
logic [7:0] ym_dout;
logic [7:0] hsc_rom_dout;
logic [7:0] hsc_ram_dout;

logic rom_cs, ram_cs, pokey_cs, ym_cs;
logic [2:0] hardware_map[8];
logic [7:0] bank_map[8];
logic [2:0] bank_type; // 00 = Supergame, 01 = Activision, 02 = none 03 = absolute
logic [31:0] address_offset;
logic [2:0] cart_cs_reg, cart_cs_reg_m;
logic [7:0] bank_mask;
logic [13:0] ram_mask;
logic [7:0] XCTRL1, XCTRL2, XCTRL3, XCTRL4, XCTRL5; // 2-5 currently unused
logic [24:0] old_rom_address;
logic souper_ram_cs;
logic [24:0] souper_addr;
wire souper_en = cart_flags[12];
logic [11:0] souper_bank;

wire XCTRL1_cs = (cart_xm[0] && address_in[15:4] == 8'h47) && cart_cs;
always @(posedge clk_sys) begin
	old_rom_address <= rom_address;
	cart_read <= rw && cart_cs;
	if (reset) begin
		{XCTRL1, XCTRL2, XCTRL3, XCTRL4, XCTRL5} <= 0;
	end else if (pclk0) begin
		if (XCTRL1_cs && ~rw)
		case (address_in[3:0]) // FIXME: ATM there seems not much reason to support anything more than ctrl1
			4'h0: XCTRL1 <= din;
			// 4'h8: XCTRL2 <= din;
			// 4'hC: XCTRL3 <= din;
			// 4'h1: XCTRL4 <= din;
			// 4'h2: XCTRL5 <= din;
		endcase
	end
end


wire is_9b = cart_flags[3];
wire [7:0] highest_bank = (8'hFF & bank_mask) + is_9b;
wire [7:0] second_highest_bank = is_9b ? 8'd0 : (8'hFE & bank_mask);
wire [7:0] sg_bank = (bank_reg & bank_mask) + is_9b;
always_ff @(posedge clk_sys) if (pclk1) begin
	hardware_map <= '{3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0};
	bank_map <= '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
	bank_type <= 3'd0;
	address_offset <= 32'd0;
	bank_mask <= 8'b11111111;
	ram_mask <= '1;

	// Banking mode selector
	if (cart_flags[8]) begin                                   // Activision
		hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
		bank_map <= '{8'd0, 8'd0, 8'd13, 8'd12, 8'd15, 8'd0, 8'd0, 8'd14};
		bank_map[5] <= {bank_reg[2:0], 1'b0};
		bank_map[6] <= {bank_reg[2:0], 1'b1};
		bank_type <= 3'd1;
	end else if (cart_flags[9]) begin                           // Absolute
		hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
		bank_map <= '{8'd0, 8'd0, 8'd0, 8'd0, 8'd2, 8'd2, 8'd3, 8'd3};
		bank_map[2] <= {3'b000, bank_reg[1]};
		bank_map[3] <= {3'b000, bank_reg[1]};
		bank_type <= 3'd3;
	end else if (cart_flags[12]) begin                           // Souper
		hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
		//bank_map <= '{4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd4};
		bank_type <= 3'd4;
	end else if (cart_flags[1] || cart_size >= 32'h10000) begin // SuperGame
		hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
		bank_map <= '{8'd0, 8'd0, second_highest_bank, second_highest_bank, 8'd0, 8'd0, highest_bank, highest_bank};
		bank_map[4] <= sg_bank;
		bank_map[5] <= sg_bank;
		if (cart_size[22])
			bank_mask <= 8'b11111111;
		else if (cart_size[21])
			bank_mask <= 8'b01111111;
		else if (cart_size[20])
			bank_mask <= 8'b00111111;
		else if (cart_size[19])
			bank_mask <= 8'b00011111;
		else if (cart_size[18])
			bank_mask <= 8'b00001111;
		else if (cart_size[17])
			bank_mask <= 8'b00000111;
		else
			bank_mask <= 8'b00000011;
		bank_type <= 3'd0;
	end else begin                                     // Not banked
		if (cart_size <= 32'h2000) // A7808
			hardware_map <= '{3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd1};
		else if (cart_size <= 32'h4000) // A7816
			hardware_map <= '{3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd1, 3'd1};
		else if (cart_size <= 32'h8000) // A7832
			hardware_map <= '{3'd0, 3'd0, 3'd0, 3'd0, 3'd1, 3'd1, 3'd1, 3'd1};
		else if (cart_size <= 32'hC000) // A7848
			hardware_map <= '{3'd0, 3'd0, 3'd1, 3'd1, 3'd1, 3'd1, 3'd1, 3'd1};
		address_offset <= (cart_size - 1'd1) <= 32'hFFFF ? 32'hFFFF - (cart_size - 1'd1) : 32'd0;
		bank_type <= 3'd2;
	end

	// Alternative hardware at $4k selector
	/*if (cart_flags[0]) begin // POKEY at $4k
		hardware_map[2] <= 3'd2;
		hardware_map[3] <= 3'd2;
	end else */
	if (cart_flags[2]) begin // Supergame RAM at $4k
		hardware_map[2] <= 3'd3;
		hardware_map[3] <= 3'd3;
	end else if (cart_flags[5]) begin // Supergame 8kb RAM at $6k
		hardware_map[3] <= 3'd3;
		hardware_map[4] <= 3'd3;
		ram_mask[13] <= 0;
	end else if (cart_flags[7]) begin // Mirror RAM at $4k // FIXME: Rescue at fractalis crazy mapping
		hardware_map[2] <= 3'd3;
		hardware_map[3] <= 3'd3;
		ram_mask[8] <= 0;
		ram_mask[13:12] <= 2'b00;
	end else if (cart_flags[4]) begin // Bank 6 at $4k
		hardware_map[2] <= 3'd4;
		hardware_map[3] <= 3'd4;
		bank_map[2] <= 4'd6;
		bank_map[3] <= 4'd6;
	end

	if (XCTRL1[5]) // FIXME: This is technically banked ram, but I dont want to waste the bram...
		hardware_map[2] <= 3'd3;
	if (XCTRL1[6])
		hardware_map[3] <= 3'd3;

end

wire is_pokey_450 = (((cart_flags[6] || XCTRL1[4]) && address_in[15:4] == 8'h45) && cart_cs);
wire is_pokey_440 = ((cart_flags[10] && address_in[15:4] == 8'h44) && cart_cs);
wire is_pokey_4k = ((cart_flags[0] && address_in[15:14] == 2'b01) && cart_cs);
wire pokey4k_wo = cart_flags[0] && cart_flags[3];

wire is_ym = (((cart_flags[11] || XCTRL1[7]) && address_in[15:1] == 15'h230) && cart_cs);
	// end else if (cart_flags[3] /*|| cart_size == 32'h24000*/) begin  // SuperGame 9 bank
	// 	hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
	// 	bank_map <= '{4'd0, 4'd0, 4'd0, 4'd0, 4'd1, 4'd1, 4'd8, 4'd8};
	// 	bank_map[4] <= bank_reg[3:0] + 1'd1;
	// 	bank_map[5] <= bank_reg[3:0] + 1'd1;
	// 	bank_type <= 3'd0;
	// end else if (cart_flags[1] || cart_size >= 32'h10000) begin // SuperGame
	// 	hardware_map <= '{3'd0, 3'd0, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4, 3'd4};
	// 	bank_map <= '{4'd0, 4'd0, 4'd6, 4'd6, 4'd0, 4'd0, 4'd7, 4'd7};
	// 	bank_map[4] <= bank_reg[3:0];
	// 	bank_map[5] <= bank_reg[3:0];
	// 	bank_mask <= (cart_size == 32'h10000) ? 4'b0011 : 4'b0111; // 64k carts have 4 banks mirrored
	// 	bank_type <= 3'd0;
	// end else begin                                     // Not banked
logic [2:0] address_index;
assign address_index = address_in[15:13];

// Address translation
always_comb begin
	pokey_cs = 0;
	ram_cs = 0;
	ym_cs = 0;
	rom_address = 25'd0;
	if (is_pokey_450)
		pokey_cs = 1;
	else if (is_pokey_440)
		pokey_cs = 1;
	else if (is_pokey_4k && (~pokey4k_wo || ~rw))
		pokey_cs = 1;
	else if (is_ym)
		ym_cs = 1;
	else if (cart_cs) case (hardware_map[address_index])
		3'd1: begin           // ROM Data
			rom_address = {1'b0, address_in - address_offset[15:0]};
		end
		3'd2: pokey_cs = 1'b1;// POKEY
		3'd3: ram_cs = 1'b1;  // RAM
		3'd4: begin           // Banked ROM
			case (bank_type)
				3'd0: // SuperGame
					rom_address = {bank_map[address_index], address_in[13:0]};
				3'd1: // Activision
					rom_address = {1'b0, bank_map[address_index], address_in[12:0]};
				3'd2: // No banking
					rom_address = {3'b000, address_in - address_offset[15:0]};
				3'd3: // Absolute
					rom_address = {bank_map[address_index], address_in[13:0]};
				3'd4: // souper
					rom_address = souper_addr;
				default: ;
		endcase
		end
		default: ;
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

always_ff @(posedge clk_sys) begin
	if (reset) begin
		bank_reg <= 8'd0;
	end else if (~rw & cart_cs & pclk0) begin
		if (bank_type == 3'd0 && address_in[15:14] == 2'b10) //supergame bank
			bank_reg <= din;
		else if (bank_type == 3'd1 && (address_in[15:4]) == 12'hFF8) // activision bank
			bank_reg <= address_in[3:0];
		else if (bank_type == 3'd3 && address_in[15]) // Absolute
			bank_reg <= din[1:0];
	end
end

spram #(.addr_width(14)) cart_ram
(
	.clock   (clk_sys),
	.address (souper_en ? souper_addr : (address_in[13:0] & ram_mask)),
	.data    (din),
	.wren    ((~rw & ram_cs & pclk0) || (souper_ram_cs && souper_en && ~super_wr)),
	.q       (ram_dout),
	.cs      (1)
);

//CS Type:
//00 - high impedance
//01 - ROM Data
//02 - POKEY
//03 - RAM
//04 - Banked ROM
always_comb begin
	case(hardware_map[address_index])
		3'd0: dout = 'Z;            // High Impedance
		3'd1, 3'd4: dout = rom_din; // ROM Data
		3'd2: dout = pokey4k_dout;  // POKEY
		3'd3: dout = ram_dout;      // RAM Data
		default: dout = 'Z;
	endcase
	if (is_pokey_450 | is_pokey_440 | (is_pokey_4k && ~pokey4k_wo))
		dout = pokey4k_dout;
	else if (is_ym)
		dout = ym_dout;
	if (hsc_rom_cs)
		dout = hsc_rom_dout;
	if (hsc_ram_cs)
		dout = hsc_ram_dout;
	if (XCTRL1_cs && rw)
		dout = XCTRL1;
	if (souper_en) begin
		if (souper_ram_cs)
			dout = ram_dout;
		else
			dout = rom_din;
	end

end

logic pokey4k_dout;


logic [3:0] ch0, ch1, ch2, ch3;
logic [5:0] pokey_mux;
logic [3:0] pokey_ce;

always @(posedge clk_sys) begin
	pokey_ce <= pokey_ce + 1'd1;
	pokey_mux <= ch0 + ch1 + ch2 + ch3;
end

assign pokey_audio = (cart_flags[0] || cart_flags[6] || cart_flags[10]) ? {pokey_mux, 10'd0} : 16'd0;
pokey the_penguin (
	.CLK                  (clk_sys),
	.ENABLE_179           (!pokey_ce[2:0]),
	.ADDR                 (address_in[3:0]),
	.DATA_IN              (din),
	.WR_EN                (~rw & pokey_cs),
	.RESET_N              (~reset),
	.keyboard_scan_enable (),
	.keyboard_scan        (),
	.keyboard_response    (),

	.POT_IN               (),
	.SIO_IN1              (),
	.SIO_IN2              (),
	.SIO_IN3              (),
	.DATA_OUT             (pokey4k_dout),
	.CHANNEL_0_OUT        (ch0),
	.CHANNEL_1_OUT        (ch1),
	.CHANNEL_2_OUT        (ch2),
	.CHANNEL_3_OUT        (ch3),

	.IRQ_N_OUT            (),
	.SIO_OUT1             (),
	.SIO_OUT2             (),
	.SIO_OUT3             (),
	.SIO_CLOCKIN_IN       (),
	.SIO_CLOCKIN_OUT      (),
	.SIO_CLOCKIN_OE       (),
	.SIO_CLOCKOUT         (),
	.POT_RESET            ()
);

wire [15:0] ym_audio_lo, ym_audio_ro;

jt51 ym2151 (
	.rst      (reset),
	.clk      (clk_sys),
	.cen      (!pokey_ce[1:0]),
	.cen_p1   (!pokey_ce[2:0]), 
	.cs_n     (~ym_cs),
	.wr_n     (rw),
	.a0       (address_in[0]),
	.din      (din),
	.dout     (ym_dout),
	.ct1      (),
	.ct2      (),
	.irq_n    (),
	.sample   (),
	.left     (),
	.right    (),
	// High res
	.xleft    (),
	.xright   (),
	// Full res
	.dacleft  (ym_audio_lo),
	.dacright (ym_audio_ro)
);

always @(posedge clk_sys) begin
	if (cart_flags[11]) begin
		ym_audio_r <= ym_audio_ro;
		ym_audio_l <= ym_audio_lo;
	end else begin
		ym_audio_r <= 0;
		ym_audio_l <= 0;
	end
end

wire hsc_ram_cs = address_in[15:11] == 5'd2 && hsc_en;
wire hsc_rom_cs = address_in[15:12] == 4'd3 && hsc_en;

spram #(.addr_width(12), .mem_name("HSC"), .mem_init_file("mem4.mif")) hsc_rom
(
	.address (address_in[11:0]),
	.clock   (clk_sys),
	.q       (hsc_rom_dout)
);

spram #(.addr_width(11), .mem_name("HSCR")) hsc_ram
(
	.address (address_in[10:0]),
	.clock   (clk_sys),
	.data    (din),
	.wren    (~rw & hsc_ram_cs & pclk0),
	.q       (hsc_ram_dout)
);

logic souper_rom_cs;
logic souper_wr;
assign souper_addr = {souper_bank, address_in[6:0]};

souper soup_soup (
	.clk_phi2(pclk0), // FIXME create ce's
	.reset_n(~reset),
	.halt_n(halt_n),
	.data(din),
	.rw(rw),
	.addr_15(address_in[15]),
	.addr_14(address_in[14]),
	.addr_13(address_in[13]),
	.addr_12(address_in[12]),
	.addr_11(address_in[11]),
	.addr_10(address_in[10]),
	.addr_9(address_in[9]),
	.addr_8(address_in[8]),
	.addr_7(address_in[7]),
	.addr_2(address_in[2]),
	.addr_1(address_in[1]),
	.addr_0(address_in[0]),
	.romSel_n(souper_rom_cs),
	.ramSel_n(souper_ram_cs),
	.oe_n(),
	.wr_n(souper_wr),
	.mapAddr_7p(souper_bank),
	.audCom(),
	.audReq_n()
);

endmodule: cart


// cart type word details::
//   bit 0    = pokey at $4000
//   bit 1    = supergame bank switched
//   bit 2    = supergame ram at $4000
//   bit 3    = rom at $4000
//   bit 4    = bank 6 at $4000
//   bit 5    = supergame banked ram
//   bit 6    = pokey at $450
//   bit 7    = mirror ram at $4000
//   bit 8    = activision banking
//   bit 9    = absolute banking
//   bit 10   = pokey at $440
//   bit 11   = ym2151 at $460/$461
//   bit 12-15 = special

// controller type byte details:
//   0 = none
//   1 = 7800 joystick
//   2 = lightgun
//   3 = paddle
//   4 = trakball
//   5 = 2600 joystick
//   6 = 2600 driving
//   7 = 2600 keypad
//   8 = ST mouse
//   9 = Amiga mouse

// TV type details:
//   0 = NTSC
//   1 = PAL

// save device details:
//   bit 1    = HSC
//   bit 2    = SaveKey/AtariVox

// expansion module details:
//   bit 1    = XM

// XM registers:
// cntrl1	$470
// 	d0 rof lo on
// 	d1 rof hi on
// 	d2 0=bios,1=top slot
// 	d3 1=hsc on
// 	d4 1=pokey on
// 	d5 1=bank0 on 4000-5fff
// 	d6 1=bank1 on 6000-7fff
// 	d7 1=ym2151 on

// cntrl2	$478  - SALLY RAM bank 8K page multiplexer.
// 	d0-d3 sally ram page 0 a0-a3
// 	d4-d7 sally ram page 1 a0-a3

// cntrl3	$47c  - MARIA RAM bank 8K page multiplexer.
// 	d0-d3 maria ram page 0 a0-a3
// 	d4-d7 maria ram page 1 a0-a3

// cntrl4	$471
// 	d0 1=pia on
// 	d1-d3 flash bank lo a1-a3
// 	d4-d6 flash bank hi a1-a3
// 	d7 1=top slot lock

// cntrl5 	$472
// 	d0 1=48k ram enable
// 	d1 1=ram we# disabled
// 	d2 1=bios enabled (in test mode)
// 	d3 1=POKEY enable/disable locked
// 	d4 1=HSC enable/disable locked - cannot disable after enable
// 	d5 1=PAL HSC enabled, 0=NTSC HSC enabled - cannot disable after enable