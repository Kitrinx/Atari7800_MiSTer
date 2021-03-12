//------------------------------------------------------------------------------
// souper.v
// Memory Bastard for Atari 7800.
//------------------------------------------------------------------------------
// This mapper provides banking for 512KB of ROM, 32KB of RAM, optional graphic
// enhancement functionality, and an 8-Bit clocked output port.
//------------------------------------------------------------------------------
// Version 1.0, March 30th, 2015
// Copyright (C) 2015 Osman Celimli
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//------------------------------------------------------------------------------
module souper(
	clk,
	pclk1,
	reset,

	halt_n,
	data,
	rw,

	addr_15,
	addr_14,
	addr_13,
	addr_12,
	addr_11,
	addr_10,
	addr_9,
	addr_8,
	addr_7,
	addr_2,
	addr_1,
	addr_0,

	romSel_n,
	ramSel_n,
	oe_n,
	wr_n,

	mapAddr_7p,

	audCom,
	audReq_n
);
	// System Clocks and Reset
	//------------------------------
	input			clk;
	input			pclk1;
	input			reset;

	// Bits of a Bus
	//------------------------------
	input			halt_n;
	input			rw;

	input[7:0]		data;
	input			addr_15;
	input			addr_14;
	input			addr_13;
	input			addr_12;
	input			addr_11;
	input			addr_10;
	input			addr_9;
	input			addr_8;
	input			addr_7;
	input			addr_2;
	input			addr_1;
	input			addr_0;

	// Memory Selects
	//------------------------------
	output			romSel_n;
	output			ramSel_n;
	output			oe_n;
	output			wr_n;

	// Memory Banks (Connect to A7+ on attached ROM + RAM)
	//------------------------------
	output[11:0]	mapAddr_7p;

	// Audio Expansion Interface
	//------------------------------
	output[7:0]		audCom;
	output			audReq_n;


//******************************************************************************
// !!!!----                BUSSING AND ADDRESS DECODING                 ----!!!!
//******************************************************************************
// As if the 6502 and 6800 weren't similar enough, rw and phi2 must be used to
// generate the usual oe_n and wr_n required for most memory.
//
// The 6502 will be READING while rw and phi2 are high, and WRITING if rw is
// low and phi2 is high. Basically, use PHI2 as the replacement for E compared
// to the 6800.
//
// Maria can take the bus whenever she pleases in order to fetch display lists
// and graphic data. Fortunately the 6502 is actually a special Atari variant
// (Sally) which can be single cycle halted + tri-stated with a special dance
// and Maria ONLY reads.
//
// My assumption is that Maria has the bus TWO falling edges of PHI2 after
// HALTn lowers. There shouldn't be any special requirements for completing
// multi-cycle RMW instructions ala stopping execution through the use of the
// RDYn pin.
//                        |
//                        V
//          __    __    __    __        __
// PHI2  __|  |__|  |__|  |__|  |__ ...   |___
//       ______                             __
// HALTn       |___________________ ... ___|
//
//------------------------------------------------------------------------------
	reg				haltDelA_ir,
					haltDelB_ir;
	wire			marRead_i;

assign oe_n = ~((rw) | marRead_i);
assign wr_n = ~(~rw);

assign marRead_i = ~halt_n & haltDelB_ir;

always@(posedge clk) begin
	if(reset) begin
		haltDelA_ir <= 1'b0;
		haltDelB_ir <= 1'b0;
	end
	else if (pclk1) begin
		if(~halt_n) begin
			haltDelA_ir <= ~halt_n;
			haltDelB_ir <= haltDelA_ir;
		end
		else begin
			haltDelA_ir <= 1'b0;
			haltDelB_ir <= 1'b0;
		end
	end
end


// On reset, the 48KB area from $4000 - $FFFF available to cartridges is
// arranged as follows :
//
// $4000 - $7FFF : 16KB Extended RAM
// $8000 - $BFFF : 16KB Selectable ROM Bank
// $C000 - $FFFF : 16KB Fixed ROM Bank
//
// This is mostly compatible with the Atari SuperCart layout if RAM Banking
// is disabled. However, once RAM Banking is enabled by setting Souper Mode
// Bit 2 ($8003,2), the 16KB RAM region is repartitioned :
//
// $4000 - $5FFF : 8KB Fixed Extended RAM
// $6000 - $6FFF : 4KB Selectable V-Extended RAM
// $7000 - $7FFF : 4KB Selectable D-Extended RAM
//
// Enabling both SOUPER Mode and Character Remapping through Souper Mode
// Bits 0 & 1 ($8003,1 & 0), will allow additional Maria fetch trapping :
//
// - Fetches from $0000-$7FFF are unchanged
// - Fetches from $8000-$9FFF are routed to the Fixed ROM Bank
// - Fetches from $A000-$BFFF are routed to the Character A/B Bank Select
// - Fetches from $C000-$FFFF are routed to EXRAM
//------------------------------------------------------------------------------
	reg 			soupMode_ir;

assign romSel_n = (marRead_i & soupMode_ir)
	? ~(addr_15 & ~addr_14)
	: ~(addr_15);
assign ramSel_n = (marRead_i & soupMode_ir)
	? ~(addr_14)
	: ~(~addr_15 & addr_14);


//******************************************************************************
// !!!!----               REGISTERS & EXPANSION INTERFACE               ----!!!!
//******************************************************************************
// A total of SIX mapping registers are available in the memory bastard, which
// are accessed by writing to $8000 - $FFFF and repeat over an 8-Byte range.
//
// Software should access these registers only using $8000 - $8007 in case newer
// variants of the mapper are developed with additional features.
//
// $0 = $8000 - $BFFF Bank Select, %xxxBBBBB
// $1 = Character A Graphic Select, %BBBBBBBS
// $2 = Character B Graphic Select, %BBBBBBBS
// $3 = Souper Mode Enable, %xxxxxECS
// $4 = $6000 - $6FFF EXRAM V-Bank Select, %xxxxxBBB
// $5 = $7000 - $7FFF EXRAM D-Bank Select, %xxxxxBBB
//------------------------------------------------------------------------------
	reg				chrMode_ir;
	reg				exMode_ir;

	reg[4:0]		bankSel_ir;
	reg[7:0]		chrSelA_ir,
					chrSelB_ir;
	reg[2:0]		exSelV_ir,
					exSelD_ir;

always@(posedge clk) begin
	if(reset) begin
		chrMode_ir <= 0;
		exMode_ir <= 0;
		soupMode_ir <= 0;

		chrSelA_ir <= 0;
		chrSelB_ir <= 0;
		exSelV_ir <= 0;
		exSelD_ir <= 0;
		bankSel_ir <= 0;
	end else if (pclk1) begin
		if(addr_15 & ~rw) begin
			case({addr_2, addr_1, addr_0})
				3'd0 : bankSel_ir <= data[4:0];
				3'd1 : chrSelA_ir <= data[7:0];
				3'd2 : chrSelB_ir <= data[7:0];
				3'd3 : begin
					soupMode_ir <= data[0];
					chrMode_ir <= data[1];
					exMode_ir <= data[2];
				end
				3'd4 : exSelV_ir <= data[2:0];
				3'd5 : exSelD_ir <= data[2:0];
			endcase
		end
	end
end


// There is a SEVENTH register which is a special case, it is used to alter the
// state of the audio expansion communication port.
//
// Writing to $7 will alter the state of audCom and invert audReq_n to let the
// audio processor know it has a command to read.
//
// Note that audReq_n is set up as an open drain output to simplify interfacing
// with a 3.3V device if one is used as the audio expansion processor.
//------------------------------------------------------------------------------
	reg[7:0]		audData_ir;
	reg				audReq_ir;

always@(posedge clk) begin
	if(reset) begin
		audData_ir <= 0;
		audReq_ir <= 1'b1;
	end
	else if (pclk1) begin
		if(addr_15 & ~rw) begin
			if(addr_2 & addr_1 & addr_0) begin
				audData_ir <= data;
				audReq_ir <= ~audReq_ir;
			end
		end
	end
end

assign audCom = audData_ir;
assign audReq_n = audReq_ir ? 1'bZ : 1'b0;


//******************************************************************************
// !!!!----                      ROM & RAM MAPPING                      ----!!!!
//******************************************************************************
assign mapAddr_7p = ramSel_n
	// ---- ROM SELECT (DEFAULT) ----
	//------------------------------
	// If it was Maria and in $8000 - $9FFF, reroute the access to our FIXED
	// ROM BANK at $C000 - $FFFF which is the END of ROM (all address bits SET).
	//
	// If it was Maria and in $A000 - $BFFF, our address will be generated based
	// upon our character bank select register and Maria's current read address
	// in the format: %00000BBB BBBBHHHH SLLLLLLL. This effectively splits the
	// region into two 2KB graphic data viewports which can be anywhere in ROM.
	//
	//
	// If it was the 6502, $C000 - $FFFF are routed to the FIXED ROM BANK (last)
	// while $8000 - $BFFF are routed to the currently selected 16KB bank.
	//------------------------------
	? ((marRead_i & chrMode_ir)
		? (addr_13
			? (addr_7
				? {chrSelB_ir[7:1],
					addr_11, addr_10, addr_9, addr_8,
					chrSelB_ir[0]}
				: {chrSelA_ir[7:1],
					addr_11, addr_10, addr_9, addr_8,
					chrSelA_ir[0]})
			: {5'b11111, addr_13, addr_12,
				addr_11, addr_10, addr_9, addr_8,
				addr_7})


		: (addr_14
			? {5'b11111, addr_13, addr_12,
				addr_11, addr_10, addr_9, addr_8,
				addr_7}
			: {bankSel_ir, addr_13, addr_12,
				addr_11, addr_10, addr_9, addr_8,
				addr_7}))
	// ---- RAM SELECT ----
	//------------------------------
	// If it was Maria OR the 6502, see whether they were looking at the UPPER
	// or LOWER 8KB of the EXRAM region and if extended RAM banking is enabled.
	//
	// The LOWER 8KB is always fixed, but the two upper 4KB banks are
	// selectable in EXMODE.
	//------------------------------
	: ((addr_13 & exMode_ir)
		? (addr_12
			? {4'd0, exSelD_ir,
				addr_11, addr_10, addr_9,
				addr_8, addr_7}
			: {4'd0, exSelV_ir,
				addr_11, addr_10, addr_9,
				addr_8, addr_7})
		: {5'd0,
			addr_13, addr_12,
			addr_11, addr_10, addr_9, addr_8,
			addr_7});
endmodule

