// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.


module dma(
	input logic         clk_sys,
	input logic         reset,
	input  logic        mclk0,
	input  logic        mclk1,
	input  logic        vblank,
	input  logic        vbe,
	input  logic        hbs,
	input  logic        lrc,
	input  logic        pclk1,
	input  logic        pclk0,
	input logic [15:0]  ZP,
	input logic         char_width,
	input logic [7:0]   char_base,
	input logic         bypass_bios,
	input  logic [7:0]  d_in,
	input  logic [1:0]  DM,
	input  logic        PCLKEDGE,
	input  logic        pclk,

	output logic        noslow,
	output logic        latch_hpos,
	output logic        HALT,
	output logic        DLI,
	output logic        WM,
	output logic [2:0]  PAL,
	output logic [15:0] AB,
	output logic        ABEN,
	output logic        latch_byte,
	output logic        nmi_n,
	output logic   [14:0] sel_out
);

// 4 Byte Header format:
// byte 0: Address Low
// byte 1: PPPWWWWW where P is palette data and W is width of request. If byte is 0, DMA ends for the line. If Width is 0, it's 5 byte.
// byte 2: Address High
// byte 3: Horizontal Position

// 5 Byte Header Format:
// byte 0: Address Low
// byte 1: Mode - 1'bWM, 1'b1, 1'bINDIRECT, 5'b00000 -- This is checked agains the mask 0x5F for end of dma!
// byte 2: High Address
// byte 3: PPPWWWWW where P is palette data and W is width of request. If Width (or the byte) is 0, DMA ends for the line. In this mode width of zero is 32.
// byte 4: Horizontal Position

// DLL Format
// byte 0: 1'bDLI, 1'bHoley16, 1'bHoley8, 1'b0, 4'bOFFSET (added to Address High to make address)
// byte 1: High DL address
// byte 2: Low DL address

// Header and DLL byte reads are from RAM, and take 2 cycles each
// Graphics bytes are assumed to be in ROM, and take 3 cycles each

logic LONGHDR;

logic [7:0] addr_low, addr_high;

logic IND;

logic [3:0] OFFSET;
logic [4:0] WIDTH;
logic [15:0] DL;
logic [15:0] DL_PTR;
logic [15:0] PIX_PTR;
logic [15:0] CHR_PTR;
logic [15:0] ZONE_PTR;
logic A11en;
logic A12en;
logic wrote_one;
logic width_ovr;
logic shutting_down;
logic [3:0] halt_cnt;
logic vbe_trigger;

logic [6:0] sel, sel_last;
logic [4:0] cond;
logic [47:0] dmas;
logic [15:0] incremented_address;
logic vbe_halt, hbs_halt;

// The two RSS signals are the DMA's start and stop flags. They are governed by 3
// contributing signals each. One is the halt flip-flop for each of the vblank end and
// hblank start. The second is a "start" pulse that comes from a state machine which
// provides a delay and aligns with the CPU clock, to ensure a clean shutdown of the cpu.
// the last signal occurs on the leading edge of the border signal (after the line is drawn)
// and this signal serves to activate BOTH RSS signals, indicating the DMA should forcibly
// shut down. An RSS line will be active when both the halt and start pulse conditions are
// simultaniously active.

// RSS1 RSS0 (logic inverted)
// 0    0    = No action
// 1    0    = Start VBE DMA (fetch zone info)
// 0    1    = Start HBS DMA
// 1    1    = Abort DMA (on border edge)
logic RSS1, RSS0;


logic PLA0;     // Programmable Logic Array Index aka "State"
logic PLA1;     // Programmable Logic Array Index
logic PLA2;     // Programmable Logic Array Index
logic PLA3;     // Programmable Logic Array Index
logic PLA4;     // Programmable Logic Array Index
logic ABENF;    // Address Bus Enable (active low)
logic ELRWA;    // Instructs line ram to latch the incoming data bus as a new cell and increment its pos
logic ALATCON;  // Address Latch On? means to latch the address currently selected by XEN
logic DSEL;     // Data Select. This signal means to write the data bus to register selected by the "reload" selection.
logic INTENBL;  // Occurs on last byte of zone ends. If the DLI bit has been recorded, this signal enables the DLI signal.
logic ASEL;     // Adds OFFSET to the currently selected address for latching
logic RLD0;     // "Reload" selector lines
logic RLD1;     // "Reload" selector lines
logic RDL2;     // "Reload" selector lines
logic RLD3;     // "Reload" selector lines
logic XEN0;     // "Enable" selector lines
logic XEN1;     // "Enable" selector lines
logic XEN2;     // "Enable" selector lines
logic LRICLD;   // Signal to make line ram latch the horizontal position of the upcoming graphics
logic HALTRST;  // Pulse to end HALT

// "Reload" outcomes. These signals cause pointers to increment or decrement appropriately, or if
// DSEL is high, become the target of the data bus being written to them instead.
logic TLD;      // Char pointer increment
logic DPPHLD;   // DP High Increment
logic DPPLLD;   // DP Low Increment (both incremented as one if together)
logic DPRLLD;   // ZP Low Increment
logic DPRHLD;   // ZP High Increment
logic DPHLD;    // DP Register High Load (base, not pointer)
logic DPLLD;    // DP Register Low Load
logic PPLLD;    // PP High Increment
logic PPHLD;    // PP Low Increment
logic OFFLD;    // Offset Decrement
logic WLATLDF;  // Width latch/Increment
logic DLILDF;   // DLI Bit load (also holey)
logic WLD1F;    // Header byte 1 load

// "Enable" outcomes (Value 0 has no outcome). This instructs Maria to put the selected register
// onto the internal bus. If ALATCON is selected, the internal bus is latched to the address bus
// until the next ALATCON overwrites it. If ASEL is high, OFFSET is added to the internal bus
// before being placed on the address bus.
logic DPPREN;   // Present base Zone Address and reload pointer
logic CBTEN;    // Present Character Byte Pointer
logic DPPEN;    // Present incremented Zone Pointer
logic DPREN;    // Present base DP Address and reload pointer
logic DPEN;     // Present incremented DP Pointer
logic PPEN;     // Present P Pointer
logic WEN;      // Width enable

//logic [47:0] dmas;
wire [3:0] rldcmp = ({RLD3, RDL2, RLD1, RLD0});

logic [2:0] XEN;
logic data_en;
logic add_sel;
logic [15:0] selected_address;
logic DLI_flag;
logic addr_latch;
logic holey;

// This arcane block of comparisons is a direct implementation of the state machine
// that starts and stops DMA and controls NMI. In effect it waits for the first
// falling edge of phi2 (aka phi1) with halt active, and then starts DMA.
// Halt takes 1 phi1 tick to start, so ultimately it takes 2 cpu cycles to
// start up.
// Halt is actually asserted on the falling edge of vblank, or the rising edge of
// hblank, effectively making it happen at the end of every visible line.
// If DMA is disabled, halt is held in a continously reset state, so even
// though the blanks attempt to assert it, it fails because of HALTRST.

assign sel[6] = cond ==? 5'b0xx00; //  1xx11
assign sel[5] = cond ==? 5'b00x11; //  11x00
assign sel[4] = cond ==? 5'bx0x01; //  x1x10
assign sel[3] = cond ==? 5'b1x001; //  0x110
assign sel[2] = cond ==? 5'b01001; //  10110
assign sel[1] = cond ==? 5'b1xx00; //  0xx11
assign sel[0] = cond ==? 5'b0xx11; //  1xx00

assign latch_hpos = LRICLD;

assign cond[4] = PCLKEDGE;



always_comb begin
	selected_address = '0;
	case (XEN)
		3'b010: selected_address = ZP;
		3'b011: selected_address = CHR_PTR;
		3'b100: selected_address = ZONE_PTR;
		3'b101: selected_address = DL;
		3'b110: selected_address = DL_PTR;
		3'b111: selected_address = PIX_PTR;
		3'b001: selected_address = WIDTH;
		default: ;
	endcase
	incremented_address = selected_address + (add_sel ? {OFFSET, 8'd0} : 16'd0);
end
logic [3:0] start_sr;
logic sel_5;
logic old_halt;

// Here we have the DMA state machine. It consists of a 48 part condition check, and then
// produces results for several signals using wide NORs. The PLA latches serve as a 5
// bit state variable to tell this mechanism what phase of operation it is in. The major
// start and stop conditions are the two RSS signals discussed above.
// NOTE: The indexing of this is the opposite of the schematic for comparison purposes
logic [13:0] cond2;
// Input gated by phi2
assign dmas[47] = cond2 ==? 14'b10010x10xxxx00;
assign dmas[46] = cond2 ==? 14'b10010x10xxxx11;
assign dmas[45] = cond2 ==? 14'b00010x10xxxxxx;
assign dmas[44] = cond2 ==? 14'b10010x10xxxx10;
assign dmas[43] = cond2 ==? 14'b10010x01xxxxxx;
assign dmas[42] = cond2 ==? 14'b01101xxxxxx111;
assign dmas[41] = cond2 ==? 14'b01010xxxxxxx11;
assign dmas[40] = cond2 ==? 14'b11010xxxxxxx11;
assign dmas[39] = cond2 ==? 14'b00110xxxxxxx11;
assign dmas[38] = cond2 ==? 14'b10110xxxxxxx11;
assign dmas[37] = cond2 ==? 14'b01110xxxxxxx11;
assign dmas[36] = cond2 ==? 14'b11110xxxxxxx11;
assign dmas[35] = cond2 ==? 14'b00001xxx1xx111;
assign dmas[34] = cond2 ==? 14'b10001xxxxxxx11;
assign dmas[33] = cond2 ==? 14'b00001xxxxxx011;
assign dmas[32] = cond2 ==? 14'b01001xxxxxxx11;
assign dmas[31] = cond2 ==? 14'b11001xxxx1xx11;
assign dmas[30] = cond2 ==? 14'b11001xxxx0xx11; // ???
assign dmas[29] = cond2 ==? 14'b00101xxxx0xx11;
assign dmas[28] = cond2 ==? 14'b11101xxxx0xx11;
assign dmas[27] = cond2 ==? 14'b010110xxxxxx11;
assign dmas[26] = cond2 ==? 14'b10111xxxxxxx11;
assign dmas[25] = cond2 ==? 14'b10101x10x1xx11;
assign dmas[24] = cond2 ==? 14'b10101x01x1xx11;
assign dmas[23] = cond2 ==? 14'b10101xxxx0xx11;
assign dmas[22] = cond2 ==? 14'b01101xxxx1x011;
assign dmas[21] = cond2 ==? 14'b01101xxxx0x011;
assign dmas[20] = cond2 ==? 14'b00101xxxx1xx11;
assign dmas[19] = cond2 ==? 14'b11101xxxx1xx11;
assign dmas[18] = cond2 ==? 14'b00011xxxxxxx11;
assign dmas[17] = cond2 ==? 14'b10011xxxxxxx11;
assign dmas[16] = cond2 ==? 14'b010111xxxxxx11;
assign dmas[15] = cond2 ==? 14'b11011xxxxxxx11;
assign dmas[14] = cond2 ==? 14'b00111xxxxxxx11;
assign dmas[13] = cond2 ==? 14'b00000xxxxxxxxx;
assign dmas[12] = cond2 ==? 14'b10010x10xxxx01;
assign dmas[11] = cond2 ==? 14'b10010x00xxxxxx;
assign dmas[10] = cond2 ==? 14'b10000xxxxx1xxx;
assign dmas[9 ] = cond2 ==? 14'b01000xxxxxxxxx; // ???
assign dmas[8 ] = cond2 ==? 14'b11000xxxxxxxxx;
assign dmas[7 ] = cond2 ==? 14'b00100xxxxxxxxx;
assign dmas[6 ] = cond2 ==? 14'b10100xxxxxxxxx;
assign dmas[5 ] = cond2 ==? 14'b01100xxxxxxxxx;
assign dmas[4 ] = cond2 ==? 14'b10010x11xxxxxx;
assign dmas[3 ] = cond2 ==? 14'b10000xxxxx0xxx;
assign dmas[2 ] = cond2 ==? 14'b11100xxxxxxxxx;
assign dmas[1 ] = cond2 ==? 14'b00010x11xxxxxx;
assign dmas[0 ] = cond2 ==? 14'b00010x0xxxxxxx;

logic [2:0] end_sr;
logic sel5_1, sel5_2;
logic [2:0] sel5_cnt;
logic old_halt2;
logic nmi_en;
logic halt_en;

assign sel_5 = sel5_cnt == 1'd1;

assign sel_out = sel_last;
assign ABEN = ~ABENF; // Gated by phi1
assign HALT = ~pclk ? halt_en : old_halt2; // gated by phi1

assign cond2[3:2] = {~|OFFSET, ~|WIDTH};


always_ff @(posedge clk_sys) begin
	if (~pclk)
		old_halt2 <= halt_en;

	if (pclk1) begin
		end_sr <= {end_sr[1:0], old_halt && ~HALT};
		start_sr <= {start_sr[2:0], ~old_halt && HALT};
		old_halt <= HALT;
		if (~old_halt && HALT) begin
			sel5_cnt <= 3'd3;
			noslow <= 1;
		end else if (old_halt && ~HALT) begin
			noslow <= 0;
		end
	end

	if (mclk0) begin
		if (sel5_cnt)
			sel5_cnt <= sel5_cnt - 1'd1;
		sel_last <= sel;
		// if (sel[6]) begin
		// 	nmi_en <= 0;
		// end
		// if (sel[0]) begin
		// 		nmi_en <= 1;
		// end
		nmi_n <= ~(|end_sr[2:1] && DLI);
		sel5_2 <= sel5_1;

	end else if (mclk1) begin
		sel5_1 <= sel_last[5];
		cond[3:0] <= {~(vbe_halt || hbs_halt), ~DLI, ~|sel_last[5:1], ~|sel_last[2:1]}; // gated by phi1
	end

	if (mclk1) begin
		data_en <= DSEL; // Gated by phi2, then phi1
		XEN <= {XEN2, XEN1, XEN0}; // Gated by phi2, then phi1
		addr_latch <= ALATCON; // gated by phi2, then phi1
		add_sel <= ASEL; // Gated by phi2, then phi1
		latch_byte <= ELRWA && ~holey; // gated by phi2, then phi1
		halt_en <= vbe_halt || hbs_halt;

		// Gated by phi2, then phi1
		TLD     <= rldcmp ==? 4'b0010;
		DPPHLD  <= rldcmp ==? 4'b010X;
		DPPLLD  <= rldcmp ==? 4'b010X;
		DPRLLD  <= rldcmp ==? 4'b0110;
		DPRHLD  <= rldcmp ==? 4'b0111;
		DPHLD   <= rldcmp ==? 4'b0011;
		DPLLD   <= rldcmp ==? 4'b0011;
		PPLLD   <= rldcmp ==? 4'b10x1;
		PPHLD   <= rldcmp ==? 4'b101X;
		OFFLD   <= rldcmp ==? 4'b111X;
		WLATLDF <= rldcmp ==? 4'b110X;
		DLILDF  <= rldcmp ==? 4'b1110;
		WLD1F   <= rldcmp ==? 4'b1100;

		// Outputs on phi1
		PLA0    <= ~(dmas ==? 48'b000xxx0x0x0x0x00xx0000xxx00xx0x0x00xxx0x0x0xxxxx);
		PLA1    <= ~(dmas ==? 48'bxxx0000xx00xx000xxxxxx00000xxx00xxx0000xx00xxxxx);
		PLA2    <= ~(dmas ==? 48'bxxxxxxx0000xxxxx00000000000xxxxx00xxxxx0000xxxxx);
		PLA3    <= ~(dmas ==? 48'b00000000000xxxxxxxxxxxxxxxx0000000xxxxxxxxx00000);
		PLA4    <= ~(dmas ==? 48'bxxxxxxxxxxx00000000000000000000000xxxxxxxxxxxxxx);
		ABENF   <= ~(dmas ==? 48'b000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0xx00);
		ELRWA   <= ~(dmas ==? 48'bxxxxx0xxxxxxxxxxxxxxxxxxx00xxxxxx0xxxxxxxxxxxxxx);
		ALATCON <= ~(dmas ==? 48'bxxx000x0x0x0x0xx00xxxxx0x00xxx0xx0x000x0x0xxxxxx);
		DSEL    <= ~(dmas ==? 48'b000xxxx0x0x0x0xxxxxxxxxxxxxxx0xxxxxxxxx0x0x0x000);
		INTENBL <= ~(dmas ==? 48'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0xxxxx);
		ASEL    <= ~(dmas ==? 48'bxxxxxxxxxxxxxxxxx0xxxxxxxx0xxx0xx00xxxxxxxxxxxxx);
		RLD0    <= ~(dmas ==? 48'bxxxxxx000x0x000000xxxxxx00000xxxxxxxxxxxx0xx0xxx);
		XEN0    <= ~(dmas ==? 48'bxxx00xxxxxxxxx000000xx00000xxx00x0xxxxxxxxxxxxxx);
		RLD1    <= ~(dmas ==? 48'bxxxxxx0x0x000x00xxxxxxxx0xx000xx0xxxxxx0x0xx00xx);
		XEN1    <= ~(dmas ==? 48'bxxxxx0x0x0x0x0xx0000xxxxx00xxx00x0x00xxxxxxxxxxx);
		RDL2    <= ~(dmas ==? 48'bxxxxxxxxx0xxx0xx00xxxxxxx00xxxxxxxxxxx00000x00xx);
		XEN2    <= ~(dmas ==? 48'bxxx000x0x0x0x0xx0000xxxxx00xxxxxxxxxx0x0x0xxxxxx); //???
		RLD3    <= ~(dmas ==? 48'bxxxxxxx0x0x0x0xx00xxxxxx00000xxxxxxxxxx0xxxx0xxx);
		LRICLD  <= ~(dmas ==? 48'bxxxxxxxxxxxxxxxxxx0xxxxxxxx0xxxxxxxxxxxxxxxxxxxx);
		HALTRST <= ~(dmas ==? 48'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00000);

		if (addr_latch)
			AB <= incremented_address;

		if (add_sel) begin
			if (((incremented_address[11] & A11en) || (incremented_address[12] & A12en))
				&& incremented_address[15]) begin
				holey <= 1;
				WIDTH <= 0;
			end
		end

		RSS0 <= (hbs_halt && sel_5); // gated by phi1
		RSS1 <= (vbe_halt && sel_5);

		if (lrc) begin // gated by phi2, then phi1
			RSS1 <= 1;
			RSS0 <= 1;
		end

	end else if (mclk0) begin
		// gated at phi2
		cond2[1:0] <= {~RSS1, ~RSS0};
		cond2[13:4] <= {PLA0, PLA1, PLA2, PLA3, PLA4, char_width, DM[1:0], LONGHDR, IND};

		if (DLI_flag && INTENBL)
			DLI <= 1;

		// gated by phi2
		if (hbs) begin // This starts on the rising edge of "blank" which stays true if either blank is true.
			if (~vblank)
				hbs_halt <= 1;
		end

		// gated by phi2
		if (vbe)
			vbe_halt <= 1;
		
		// Gated by phi2
		if (HALTRST) begin 
			vbe_halt <= 0;
			hbs_halt <= 0;
		end

		if (sel_5 && hbs_halt) begin
			DLI <= 0;
			DLI_flag <= 0;
		end

		case (XEN)
			3'b010: ZONE_PTR <= ZP;
			3'b101: DL_PTR <= DL;
			default: ;
		endcase

		// Reloads: All these pretty much happen on phi2, gated by the RLD line PLA
		if (TLD) begin
			if (data_en)
				CHR_PTR <= {char_base, d_in};
			else
				CHR_PTR <= CHR_PTR + 1'd1;
		end

		if (DPPHLD) begin
			if (data_en)
				ZONE_PTR[15:8] <= d_in;
		end

		if (DPPLLD) begin
			if (~data_en)
				ZONE_PTR <= ZONE_PTR + 1'd1;
		end

		if (DPRLLD) begin
			if (data_en)
				DL[7:0] <= d_in;
		end

		if (DPRHLD) begin
			if (data_en)
				DL[15:8] <= d_in;
		end

		if (DPHLD) begin
			if (data_en)
				DL_PTR[15:8] <= d_in;
		end

		if (DPLLD) begin
			holey <= 0;
			DL_PTR <= DL_PTR + 1'd1;
		end

		if (PPLLD) begin
			if (data_en)
				PIX_PTR[7:0] <= d_in;
			else
				PIX_PTR <= PIX_PTR + 1'd1;
		end

		if (PPHLD) begin
			if (data_en)
				PIX_PTR[15:8] <= d_in;
		end

		if (OFFLD) begin
			if (data_en)
				OFFSET <= d_in[3:0];
			else
				OFFSET <= OFFSET - 1'd1;
		end

		if (WLATLDF) begin
			if (data_en) begin
				WIDTH <= d_in[4:0];
				if (LONGHDR || |d_in[4:0])
					PAL <= d_in[7:5];
			end else
				WIDTH <= WIDTH + 1'd1;
		end

		if (DLILDF) begin
			if (data_en) begin
				DLI_flag <= d_in[7];
				A12en <= d_in[6];
				A11en <= d_in[5];
			end
		end

		if (WLD1F) begin
			LONGHDR <= 0;
			IND <= 0;

			if (d_in[6] && ~|d_in[4:0]) begin
				LONGHDR <= 1;
				IND <= d_in[5];
				WM <= d_in[7];
			end
		end
	end
	if (reset) begin
		DL <= bypass_bios ? 16'h1FFC : 16'd0;
		DL_PTR <= bypass_bios ? 16'h1FFC : 16'd0;
		ZONE_PTR <= bypass_bios ? 16'h1F84 : 16'd0;
		OFFSET <= bypass_bios ? 4'hA : 4'd0;
		CHR_PTR <= 0;
		PIX_PTR <= 0;
		WIDTH <= 0;
		//dmas <= 48'h400000000000;
		WM <= 0;
		DLI <= 0;
		RSS0 <= 0;
		RSS1 <= 0;
		{PLA1, PLA2, PLA4, ELRWA, ALATCON, DSEL, INTENBL,
		ASEL, RLD0, XEN0, RLD1, XEN1, RDL2, XEN2, RLD3, LRICLD, HALTRST} <= '0;
		{TLD, DPPHLD, DPPLLD, DPRLLD, DPRHLD, DPHLD, DPLLD, PPLLD, PPHLD, OFFLD,
		WLATLDF, DLILDF, WLD1F} <= '0;
		PLA3 <= bypass_bios ? 1'b1 : 1'b0;
		PLA0 <= bypass_bios ? 1'b1 : 1'b0; // 0x8 after reset init
		AB <= 0;
		PAL <= 0;
		XEN <= 0;
		ABENF <= 1;
		cond2[13:4] <= bypass_bios ? 10'b1001001100 : 10'd0;
		cond2[1:0] <= bypass_bios ? 2'b11 : 2'd0; // 0x05f7 after reset init
		//cond2[3:2] <= 2'b00;
		DLI_flag <= 0;
		add_sel <= 0;
		cond[3:0] <= 0;
		data_en <= 0;
		holey <= 0;
		latch_byte <= 0;
		addr_latch <= 0;
		data_en <= 0;
		A12en <= 0;
		A11en <= 0;
		vbe_halt <= 0;
		hbs_halt <= 0;
		nmi_n <= 1;
		PAL <= 0;
		sel_last <= 0;
	end
end

endmodule // dma_ctrl
