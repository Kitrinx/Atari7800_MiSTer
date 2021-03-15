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
	input  logic        PCLKEDGE,
	input  logic        vblank,
	input  logic        vbe,
	input  logic        hbs,
	input  logic        lrc,
	input  logic        dma_en,
	input  logic        pclk1,
	output logic [15:0] AddrB,
	output logic        drive_AB,
	output logic        latch_byte,
	input  logic [7:0]  DataB,
	output logic        clear_hpos,
	output logic        HALT,
	output logic [7:0]  HPOS,
	output logic        DLI,
	output logic        WM,
	output logic [2:0]  PAL,
	input logic [15:0]  ZP,
	input logic         character_width,
	input logic [7:0]   char_base
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

always_ff @(posedge clk_sys) if (reset) begin
	state <= DMA_WAIT_ZP;
	substate <= 0;
	width_ovr <= 0;
	shutting_down <= 1;
	latch_byte <= 0;
	CHR_PTR <= 0;
	DL_PTR <= 0;
	PIX_PTR <= 0;
	ZONE_PTR <= 0;
	drive_AB <= 0;
	wrote_one <= 0;
	OFFSET <= 0;
	vbe_trigger <= 0;
	WM <= 0;
	A12en <= 0;
	A11en <= 0;
	HALT <= 0;
	DLI <= 0;
	PAL <= 0;
	clear_hpos <= 0;
end else if (mclk0) begin
	if (hbs) begin
		vbe_trigger <= 0;
		if (dma_en && ~vblank)
			HALT <= 1;
	end
	if (vbe) begin
		vbe_trigger <= 1;
		if (dma_en)
			HALT <= 1;
	end
	case (state)
		// Wait for starting condition
		DMA_WAIT_DP,
		DMA_WAIT_ZP: begin
			if (pclk1) begin
				if (HALT || ((vbe || (hbs & ~vblank)) & dma_en))
					halt_cnt <= halt_cnt + 1'd1;
				else
					halt_cnt <= 0;
				if (halt_cnt == 1) begin
					substate <= 0;
					drive_AB <= 1;
					DLI <= 0;

					if (vbe_trigger) begin
						vbe_trigger <= 0;
						ZONE_PTR <= ZP;
						AddrB <= ZP;
						shutting_down <= 1;
						state <= DMA_START_ZP;
					end else begin
						DL_PTR <= DP;
						AddrB <= DP;
						shutting_down <= 0;
						state <= DMA_START_DP;
					end

				end
			end
		end

		DMA_START_ZP:begin
			substate <= substate + 1'd1;
			if (substate >= 2) begin
				substate <= 0;
				state <= DMA_ZONE_END_0;
			end
		end

		DMA_START_DP:begin
			substate <= substate + 1'd1;
			if (substate >= 3) begin
				substate <= 0;
				state <= DMA_HEADER_0;
			end
		end

		DMA_HOLEY_COOLDOWN:begin
			substate <= substate + 1'd1;
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
					IND <= 0;
					width_ovr <= 0;
					PIX_PTR[7:0] <= DataB;
					DL_PTR <= DL_PTR + 1'd1;
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
					substate <= 0;
					// Maria apparently only checks 0x5F as a bit pattern
					// for end-of-zone markers, not for 0.
					if (~DataB[6] && ~|DataB[4:0]) begin// End of line
						state <= DMA_ZONE_END_0;
						if (OFFSET) begin
							if (pclk1) begin
								HALT <= 0;
								OFFSET <= OFFSET - 1'd1;
								state <= DMA_WAIT_DP;
								latch_byte <= 0;
								substate <= 0;
								drive_AB <= 0;
							end else
								state <= DMA_END;
						end
						shutting_down <= 1;
					end else if (~|DataB[4:0]) begin/// Long header
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
					HPOS <= DataB;
					if (~IND)
						WIDTH <= WIDTH + 1'd1;
					state <= IND ? DMA_INDIRECT_PTR : DMA_DIRECT;
					// Check for holey DMA
					if (((AHPO[3] & A11en) | (AHPO[4] & A12en)) & AHPO[7]) begin
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

		// Decrement offset and terminate DMA
		DMA_END: begin
			if (pclk1) begin
				HALT <= 0;
				OFFSET <= OFFSET - 1'd1;
				state <= DMA_WAIT_DP;
				latch_byte <= 0;
				substate <= 0;
				drive_AB <= 0;
			end
		end

		DMA_END_ZP: begin
			if (pclk1) begin
				HALT <= 0;
				state <= DMA_WAIT_DP;
				latch_byte <= 0;
				substate <= 0;
				drive_AB <= 0;
			end
		end

		// Fetch DL header
		DMA_ZONE_END_0: begin
			substate <= substate + 1'd1;
			case (substate)
				0: AddrB <= ZONE_PTR;
				1: begin
					ZONE_PTR <= ZONE_PTR + 1'd1;
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
					if (pclk1) begin
						HALT <= 0;
						state <= DMA_WAIT_DP;
						latch_byte <= 0;
						substate <= 0;
						drive_AB <= 0;
					end else
						state <= DMA_END_ZP;
				end
			endcase
		end

	endcase

	// If we reach the line ram swap point, terminate DMA. This is a convienience to
	// avoid a massive state machine surrounding this.
	if (lrc && dma_en && !shutting_down) begin
		state <= OFFSET ? DMA_END : DMA_ZONE_END_0;
		latch_byte <= 0;
		substate <= 0;
		clear_hpos <= 0;
		shutting_down <= 1;
	end
		

end

endmodule // dma_ctrl
