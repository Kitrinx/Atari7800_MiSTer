// (C) Jamie Blanks, 2021

// For MiSTer use only.

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

module dma_ctrl(
	input logic         clk_sys, 
	input logic         reset,
	input  logic        mclk0,
	input  logic        mclk1,
	input  logic        vblank,
	input  logic        vbe,
	input  logic        hbs,
	input  logic        lrc,
	input  logic        dma_en,
	input  logic        pclk1,
	input  logic        pclk0,
	output logic [15:0] AddrB,
	output logic        drive_AB,
	output logic        latch_byte,
	input  logic [7:0]  DataB,
	output logic        clear_hpos,
	output logic        HALT,
	output logic [7:0]  HPOS,
	output logic        DLI,
	output logic        WM,
	input  logic [1:0]  DM,
	output logic [2:0]  PAL,
	input logic [15:0]  ZP,
	input logic         character_width,
	input logic [7:0]   char_base,
	input logic         bypass_bios,
	output logic [6:0]  sel_out,
	output logic        nmi_n,
	output logic [19:0] dm_test,
	output logic [19:0] dm_test2,
	output logic rss0_t,
	output logic rss1_t,
	output [47:0] dmas
);

typedef enum logic [4:0] {
	DMA_HEADER_0,
	DMA_HEADER_1,
	DMA_HEADER_2,
	DMA_HEADER_3,
	DMA_HEADER_4,
	DMA_DIRECT,
	DMA_INDIRECT_PTR,
	DMA_INDIRECT_BYTE,
	DMA_END,
	DMA_ZONE_END_0,
	DMA_ZONE_END_1,
	DMA_ZONE_END_2,
	DMA_ZP,
	DMA_WAIT_ZP,
	DMA_WAIT_DP,
	DMA_START_ZP,
	DMA_START_DP,
	DMA_HOLEY_COOLDOWN,
	DMA_END_ZP
} DMA_STATE;



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

logic [4:0] substate;
logic [3:0] OFFSET; // Added an extra bit so we can use 0 as done rather than -1;

DMA_STATE state;

logic [15:0] DP;

logic [7:0] addr_low, addr_high;

logic IND;

logic [4:0] WIDTH;
logic [7:0] AHPO;
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

// Note that Karateka inappropriately uses ROM space for it's DL list, which is not supposed
// to be accessible in two cycles. For this reason I assert the addresses a cycle earlier to
// deal with the situation.
logic [6:0] sel, sel_last;
logic [4:0] cond;

// This arcane block of comparisons is a direct implementation of the state machine
// that starts and stops DMA and controls NMI. In effect it waits for the first
// falling edge of phi2 (aka phi1) with halt active, and then starts DMA.
// Halt takes 1 phi1 tick to start, so ultimately it takes 2 cpu cycles to
// start up.
// Halt is actually asserted on the falling edge of vblank, or the rising edge of
// (vblank & hblank), effectively making it happen at the end of every visible line.
// If DMA is disabled, I believe halt is held in a continously reset state, so even
// though the blanks attempt to asset it, it fails because of haltrst.

// RSS0, RSS1
// 0     1    = ZP DMA
// 1     0    = DP DMA
// 0     0    = No action
// 1     1    = Abort DMA
// DMA is disabled when HALTRST takes place, which occurs when RSS is 00 or DMA ends

assign cond = {pclk1, HALT, DLI, |sel_last[5:1], |sel_last[2:1]};
assign sel[6] = cond ==? 5'b1xx11;
assign sel[5] = cond ==? 5'b11x00;
assign sel[4] = cond ==? 5'bx1x10;
assign sel[3] = cond ==? 5'b0x110;
assign sel[2] = cond ==? 5'b10110;
assign sel[1] = cond ==? 5'b0xx11;
assign sel[0] = cond ==? 5'b1xx00;

assign sel_out = sel;

logic sel5_next;
logic nmi_set;
logic is_zp;
logic RSS1, RSS0;

logic [3:0] z_start, d_start, z_end, d_end;
logic is_zp_dma;
logic vbe_halt, hbs_halt;

// Probes probe (
// 	.source ({z_start, d_start, z_end, d_end}),
// 	.probe (0)
// );

always_ff @(posedge clk_sys) if (reset) begin
	// A few things reset differently if bios is disbled, so we can
	// skip it without consequence.
	DP <= bypass_bios ? 16'h1FFC : 16'd0;
	DL_PTR <= bypass_bios ? 16'h1FFC : 16'd0;
	ZONE_PTR <= bypass_bios ? 16'h1F84 : 16'd0;
	OFFSET <= bypass_bios ? 4'hA : 4'd0;
	state <= DMA_WAIT_ZP;
	substate <= 0;
	width_ovr <= 0;
	shutting_down <= 1;
	latch_byte <= 0;
	{z_start, d_start, z_end, d_end} <= 16'h2223;
	CHR_PTR <= 0;
	PIX_PTR <= 0;
	drive_AB <= 0;
	wrote_one <= 0;
	vbe_trigger <= 0;
	WM <= 0;
	A12en <= 0;
	A11en <= 0;
	vbe_halt <= 0;
	hbs_halt <= 0;
	HALT <= 0;
	is_zp <= 0;
	nmi_n <= 1;
	is_zp_dma <= 0;
	DLI <= 0;
	PAL <= 0;
	sel_last <= 0;
	nmi_set <= 0;
	clear_hpos <= 0;
end else if (mclk0) begin
	if (sel[6]) begin
		nmi_n <= 0;
		nmi_set <= 1;
	end
	if (sel[0]) begin
		if (nmi_set) // Extend the NMI one extra tick so the 6502 sees it.
			nmi_set <= 0;
		else
			nmi_n <= 1;
	end 

	sel_last <= sel;

	if (hbs) begin // This starts on the rising edge of "blank" which stays true if either blank is true.
		vbe_trigger <= 0;
		if (~vblank)
			hbs_halt <= 1;
		if (dma_en && ~vblank)
			HALT <= 1;
	end
	if (vbe) begin
		vbe_trigger <= 1;
		vbe_halt <= 1;
		if (dma_en)
			HALT <= 1;
	end
	if (HALTRST) begin
		vbe_halt <= 0;
		hbs_halt <= 0;
	end

	case (state)
		// Wait for starting condition
		DMA_WAIT_DP,
		DMA_WAIT_ZP: begin

			if (sel[5]) begin
				substate <= 0;
				DLI <= 0;
				is_zp <= 0;

				if (vbe_trigger) begin // + 4 idle cycles
					vbe_trigger <= 0;
					ZONE_PTR <= ZP;
					is_zp_dma <= 1;
					AddrB <= ZP;
					shutting_down <= 1;
					state <= DMA_START_ZP;
				end else begin         // + 8 idle cycles
					DL_PTR <= DP;
					AddrB <= DP;
					is_zp_dma <= 0;
					shutting_down <= 0;
					state <= DMA_START_DP;
				end
			end
		end

		// Maria simply waits for the bus to be released
		DMA_START_ZP:begin
			substate <= substate + 1'd1;
			if (substate >= z_start - 1'd1) begin
				substate <= 0;
				drive_AB <= 1;
				state <= DMA_ZONE_END_0;
			end
		end

		DMA_START_DP:begin
			substate <= substate + 1'd1;
			if (substate >= d_start - 1'd1) begin
				substate <= 0;
				drive_AB <= 1;
				state <= DMA_HEADER_0;
			end
		end

		DMA_HOLEY_COOLDOWN:begin // Holey dma aborts on the first pixel fetch (not the char ptr fetch)
			substate <= substate + 1'd1;
			AddrB <= DL_PTR;
			case (substate)
				2: if (!IND) begin
					substate <= 0;
					state <= DMA_HEADER_0;
				end
				5: begin
					substate <= 0;
					state <= DMA_HEADER_0;
				end
			endcase
		end

		// Fetch Address Low byte
		DMA_HEADER_0: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= DL_PTR;
				1: begin
					PIX_PTR[7:0] <= DataB;
					DL_PTR <= DL_PTR + 1'd1;
					AddrB <= DL_PTR + 1'd1;
					state <= DMA_HEADER_1;
					substate <= 0;
				end
			endcase
		end

		// Fetch byte 1 which varies;
		DMA_HEADER_1: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= DL_PTR;
				1: begin
					DL_PTR <= DL_PTR + 1'd1;
					WIDTH <= DataB[4:0];
					LONGHDR <= 0;
					IND <= 0;
					width_ovr <= 0;
					substate <= 0;
					// Maria apparently only checks 0x5F as a bit pattern
					// for end-of-zone markers, not for 0.
					if (~DataB[6] && ~|DataB[4:0]) begin// End of line
						state <= DMA_ZONE_END_0;
						AddrB <= ZONE_PTR;
						if (OFFSET) begin
							state <= DMA_END;
						end
						shutting_down <= 1;
					end else if (~|DataB[4:0]) begin // Long header
						LONGHDR <= 1;
						WM <= DataB[7];
						IND <= DataB[5];
						state <= DMA_HEADER_2;
					end else begin // four byte header
						LONGHDR <= 0;
						{PAL, WIDTH} <= DataB;
						state <= DMA_HEADER_2;
					end
				end
			endcase
		end

		// Fetch High Address
		DMA_HEADER_2: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= DL_PTR;
				1: begin
					PIX_PTR[15:8] <= IND ? DataB : DataB + OFFSET;
					if (IND)
						AHPO <= char_base + OFFSET;
					else
						AHPO <= DataB + OFFSET;
					DL_PTR <= DL_PTR + 1'd1;
					AddrB <= DL_PTR + 1'd1;
					state <= LONGHDR ? DMA_HEADER_3 : DMA_HEADER_4;
					substate <= 0;
				end
			endcase
		end

		// Fetch 5-byte width and palette
		DMA_HEADER_3: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= DL_PTR;
				1: begin
					DL_PTR <= DL_PTR + 1'd1;
					AddrB <= DL_PTR + 1'd1;
					{PAL, WIDTH} <= DataB;
					state <= DMA_HEADER_4;
					substate <= 0;
				end
			endcase
		end

		// Fetch line ram address (horizontal position)
		DMA_HEADER_4: begin
			substate <= substate + 1'd1;
			case (substate)
				0: begin AddrB <= DL_PTR; clear_hpos <= 1; end
				1: begin
					clear_hpos <= 0;
					DL_PTR <= DL_PTR + 1'd1;
					AddrB <= DL_PTR + 1'd1;
					HPOS <= DataB;
					if (~IND)
						WIDTH <= WIDTH + 1'd1;
					state <= IND ? DMA_INDIRECT_PTR : DMA_DIRECT;
					// Check for holey DMA
					if (((AHPO[3] & A11en) | (AHPO[4] & A12en)) & AHPO[7]) begin
						width_ovr <= 1;
						WIDTH <= 0;
						state <= DMA_HOLEY_COOLDOWN;
					end
					substate <= 0;
				end
			endcase
		end

		// Fetch the low address for indirect read
		DMA_INDIRECT_PTR: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= PIX_PTR;
				1: PIX_PTR <= PIX_PTR + 1'd1;
				2: begin
					wrote_one <= 0;
					CHR_PTR <= {AHPO, DataB};
					// 0 width means value 32, so we have to catch overflow
					{width_ovr, WIDTH} <= {1'b0, WIDTH} + 1'd1; 
					state <= DMA_INDIRECT_BYTE;
					substate <= 0;
				end
			endcase
		end

		// Fetch one or two char bytes
		DMA_INDIRECT_BYTE: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= CHR_PTR;
				1: begin
					latch_byte <= 1;
				end
				2: begin
					latch_byte <= 0;
					wrote_one <= 1;
					if (~wrote_one & character_width) begin
						state <= DMA_INDIRECT_BYTE;
						CHR_PTR <= CHR_PTR + 1'd1;
					end else if (width_ovr) begin
						state <= DMA_HEADER_0;
					end else begin
						state <= DMA_INDIRECT_PTR;
					end
					substate <= 0;
				end
			endcase
		end

		// Fetch direct bytes
		DMA_DIRECT: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= PIX_PTR;
				1: latch_byte <= 1;
				2: begin
					latch_byte <= 0;
					PIX_PTR <= PIX_PTR + 1'd1;
					if (~|WIDTH) begin
						state <= DMA_HEADER_0;
					end else begin
						WIDTH <= WIDTH + 1'd1;
						state <= DMA_DIRECT;
					end
					substate <= 0;
				end
			endcase
		end

		// Fetch DL header
		DMA_ZONE_END_0: begin
			is_zp <= 1;
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= ZONE_PTR;
				1: begin
					ZONE_PTR <= ZONE_PTR + 1'd1;
					AddrB <= ZONE_PTR + 1'd1;
					{DLI, A12en, A11en} <= DataB[7:5];
					OFFSET <= DataB[3:0];
					state <= DMA_ZONE_END_1;
					substate <= 0;
				end
			endcase
		end

		// Fetch DL address upper byte
		DMA_ZONE_END_1: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= ZONE_PTR;
				1: begin
					AddrB <= ZONE_PTR + 1'd1;
					ZONE_PTR <= ZONE_PTR + 1'd1;
					DP[15:8] <= DataB;
					state <= DMA_ZONE_END_2;
					substate <= 0;
				end
			endcase
		end

		// Fetch DL address lower byte and terminate DMA
		DMA_ZONE_END_2: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= ZONE_PTR;
				1: begin
					ZONE_PTR <= ZONE_PTR + 1'd1;
					DP[7:0] <= DataB;
					substate <= 0;
					is_zp <= 1;
					state <= is_zp_dma ? DMA_END_ZP : DMA_END;
				end
			endcase
		end

		// Maria waits to release the bus, then un-halts
		DMA_END: begin
			drive_AB <= 0;
			substate <= substate + 1'd1;
			if (substate >= d_end) begin
				HALT <= 0;
				if (~is_zp)
					OFFSET <= OFFSET - 1'd1;
				is_zp <= 0;
				state <= DMA_WAIT_DP;
				latch_byte <= 0;
				substate <= 0;
			end
		end

		DMA_END_ZP: begin
			drive_AB <= 0;
			substate <= substate + 1'd1;
			if (substate >= z_end) begin
				HALT <= 0;
				is_zp <= 0;
				is_zp_dma <= 0;
				state <= DMA_WAIT_DP;
				latch_byte <= 0;
				substate <= 0;
			end
		end

	endcase

	// If we reach the line ram swap point, aka the leading edge of border, terminate DMA. This is a
	// convienience to avoid a massive state machine surrounding this.
	if (lrc && dma_en && !shutting_down) begin
		state <= OFFSET ? DMA_END : DMA_ZONE_END_0;
		latch_byte <= 0;
		substate <= 0;
		clear_hpos <= 0;
		shutting_down <= 1;
	end

end

assign dm_test = {PLA0, PLA1, PLA2, PLA3, PLA4, ABENF, ELRWA, ALATCON, DSEL, INTENBL,
	ASEL, RLD0, XEN0, RLD1, XEN1, RDL2, XEN2, RLD3, LRICLD, HALTRST};

assign rss1_t = RSS1;
assign rss0_t = RSS0;

logic PLA0, PLA1, PLA2, PLA3, PLA4, ABENF, ELRWA, ALATCON, DSEL, INTENBL,
	ASEL, RLD0, XEN0, RLD1, XEN1, RDL2, XEN2, RLD3, LRICLD, HALTRST;

logic TLD, DPPHLD, DPPLLD, DPRLLD, DPRHLD, DPHLD, DPLLD, PPLLD, PPHLD, OFFLD, WLATLDF, DLILDF, WLD1F;
logic DPPREN, CBTEN, DPPEN, DPREN, DPEN, PPEN, WEN;

//logic [47:0] dmas;
wire [3:0] rldcmp = ({RLD3, RDL2, RLD1, RLD0});

wire [13:0] cond2 = {PLA0, PLA1, PLA2, PLA3, PLA4, character_width, DM[1], DM[0], LONGHDR,
	IND, OFFSET == 0, WIDTH == 0 || width_ovr, ~RSS1, ~RSS0};
// NOTE: The indexing of this is the opposite of the schematic
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
assign dm_test2 = {7'd0, TLD, DPPHLD, DPPLLD, DPRLLD, DPRHLD, DPHLD, DPLLD, PPLLD, PPHLD, OFFLD, WLATLDF, DLILDF, WLD1F};
logic data_en;

always @(posedge clk_sys) begin

	if (mclk0) begin
		RSS1 <= (vbe_halt && sel[5]);
		RSS0 <= (hbs_halt && sel[5]);



	end else if (mclk1) begin
		{DPPREN, CBTEN, DPPEN, DPREN, DPEN, PPEN, WEN} <= '0;

		// case ({XEN2, XEN1, XEN0})
		// 	3'b101: DPPREN <= 1'b1;
		// 	3'b100: CBTEN <= 1'b1;
		// 	3'b011: DPPEN <= 1'b1;
		// 	3'b010: DPREN <= 1'b1;
		// 	3'b001: DPEN <= 1'b1;
		// 	3'b000: PPEN <= 1'b1;
		// 	3'b110: WEN <= 1'b1;
		// endcase

		case ({XEN2, XEN1, XEN0})
			3'b010: DPPREN <= 1'b1;
			3'b011: CBTEN <= 1'b1;
			3'b100: DPPEN <= 1'b1;
			3'b101: DPREN <= 1'b1;
			3'b110: DPEN <= 1'b1;
			3'b111: PPEN <= 1'b1;
			3'b001: WEN <= 1'b1;
		endcase

		TLD     <= rldcmp ==? 4'b0010; //1101;
		DPPHLD  <= rldcmp ==? 4'b010X; //101x;
		DPPLLD  <= rldcmp ==? 4'b010X; //101x;
		DPRLLD  <= rldcmp ==? 4'b0110; //1001;
		DPRHLD  <= rldcmp ==? 4'b0111; //1000;
		DPHLD   <= rldcmp ==? 4'b0011; //1100;
		DPLLD   <= rldcmp ==? 4'b0011; //1100;
		PPLLD   <= rldcmp ==? 4'b10x1; //01x0;
		PPHLD   <= rldcmp ==? 4'b101X; //010x;
		OFFLD   <= rldcmp ==? 4'b111X; //000x;
		WLATLDF <= rldcmp ==? 4'b110X; //001x;
		DLILDF  <= rldcmp ==? 4'b1110; //0001;
		WLD1F   <= rldcmp ==? 4'b1100; //0011;

		DSEL <= data_en;

		PLA0    <= ~(dmas ==? 48'b000xxx0x0x0x0x00xx0000xxx00xx0x0x00xxx0x0x0xxxxx);
		PLA1    <= ~(dmas ==? 48'bxxx0000xx00xx000xxxxxx00000xxx00xxx0000xx00xxxxx);
		PLA2    <= ~(dmas ==? 48'bxxxxxxx0000xxxxx00000000000xxxxx00xxxxx0000xxxxx);
		PLA3    <= ~(dmas ==? 48'b00000000000xxxxxxxxxxxxxxxx0000000xxxxxxxxx00000);
		PLA4    <= ~(dmas ==? 48'bxxxxxxxxxxx00000000000000000000000xxxxxxxxxxxxxx);
		ABENF   <= ~(dmas ==? 48'b000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0xx00);
		ELRWA   <= ~(dmas ==? 48'bxxxxx0xxxxxxxxxxxxxxxxxxx00xxxxxx0xxxxxxxxxxxxxx);
		ALATCON <= ~(dmas ==? 48'bxxx000x0x0x0x0xx00xxxxx0x00xxx0xx0x000x0x0xxxxxx);
		data_en <= ~(dmas ==? 48'b000xxxx0x0x0x0xxxxxxxxxxxxxxx0xxxxxxxxx0x0x0x000);
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
	end

	if (lrc) begin
		RSS1 <= 1;
		RSS0 <= 1;
	end
end

// XEN:
// 0 Hold value
// 1 Write color byte
// 2 ZP Reload
// 3 Char Byte
// 4 ZP Enable
// 5 DP Reload
// 6 DP Enable
// 7 PP Enable

// RLD:
// 0: pp address assert

// 2: zp byte 2
// 3: dma byte 1

// 5: theend// 5: dma byte 2
// 6: zone end 3
// 7: zone end 1

// 9:dma byte 0

// 11: dma byte 3// 11: dma byte 4 pp address?
// 12: nothing/incpp?
// 13: pp byte write?
// 14: zone end 2
// 15: unhalt

// 4/5: DPPH LD
// 4/5: DPPL LD
// 6: DPRL LD
// 7: DPRH LD
// 3: DPL LD
// 9/11: PPL LD
// 11/12: PPH LD
// 14/15: OFF LD

// 12/13: WLATLDF
// 14: DLILDF
// 12: WLD1F

endmodule // dma_ctrl
