--------------------------------------------------------------------------------
--     This file is owned and controlled by Xilinx and must be used           --
--     solely for design, simulation, implementation and creation of          --
--     design files limited to Xilinx devices or technologies. Use            --
--     with non-Xilinx devices or technologies is expressly prohibited        --
--     and immediately terminates your license.                               --
--                                                                            --
--     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"          --
--     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR                --
--     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION        --
--     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION            --
--     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS              --
--     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,                --
--     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE       --
--     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY               --
--     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE                --
--     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR         --
--     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF        --
--     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS        --
--     FOR A PARTICULAR PURPOSE.                                              --
--                                                                            --
--     Xilinx products are not intended for use in life support               --
--     appliances, devices, or systems. Use in such applications are          --
--     expressly prohibited.                                                  --
--                                                                            --
--     (c) Copyright 1995-2005 Xilinx, Inc.                                   --
--     All rights reserved.                                                   --
--------------------------------------------------------------------------------
-- You must compile the wrapper file xil_riot_ram.vhd when simulating
-- the core, xil_riot_ram. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".

-- The synopsys directives "translate_off/translate_on" specified
-- below are supported by XST, FPGA Compiler II, Mentor Graphics and Synplicity
-- synthesis tools. Ensure they are correct for your synthesis tool(s).

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- synopsys translate_off
Library XilinxCoreLib;
-- synopsys translate_on
ENTITY xil_riot_ram IS
	port (
	A: IN std_logic_VECTOR(6 downto 0);
	CLK: IN std_logic;
	D: IN std_logic_VECTOR(7 downto 0);
	WE: IN std_logic;
	I_CE: IN std_logic;
	SPO: OUT std_logic_VECTOR(7 downto 0));
END xil_riot_ram;

ARCHITECTURE xil_riot_ram_a OF xil_riot_ram IS
-- synopsys translate_off
component wrapped_xil_riot_ram
	port (
	A: IN std_logic_VECTOR(6 downto 0);
	CLK: IN std_logic;
	D: IN std_logic_VECTOR(7 downto 0);
	WE: IN std_logic;
	I_CE: IN std_logic;
	SPO: OUT std_logic_VECTOR(7 downto 0));
end component;

-- Configuration specification 
	for all : wrapped_xil_riot_ram use entity XilinxCoreLib.C_DIST_MEM_V7_1(behavioral)
		generic map(
			c_qualify_we => 1,
			c_mem_type => 1,
			c_has_qdpo_rst => 0,
			c_has_qspo => 0,
			c_has_qspo_rst => 0,
			c_has_dpo => 0,
			c_has_qdpo_clk => 0,
			c_has_d => 1,
			c_qce_joined => 0,
			c_width => 8,
			c_reg_a_d_inputs => 1,
			c_latency => 1,
			c_has_spo => 1,
			c_has_we => 1,
			c_depth => 128,
			c_has_i_ce => 1,
			c_default_data_radix => 1,
			c_default_data => "0",
			c_has_dpra => 0,
			c_has_clk => 1,
			c_enable_rlocs => 1,
			c_generate_mif => 1,
			c_has_qspo_ce => 0,
			c_addr_width => 7,
			c_has_qdpo_srst => 0,
			c_mux_type => 0,
			c_has_spra => 0,
			c_has_qdpo => 0,
			c_reg_dpra_input => 0,
			c_mem_init_file => "",
			c_has_qspo_srst => 0,
			c_has_rd_en => 0,
			c_read_mif => 0,
			c_sync_enable => 0,
			c_has_qdpo_ce => 0);
-- synopsys translate_on
BEGIN
-- synopsys translate_off
U0 : wrapped_xil_riot_ram
		port map (
			A => A,
			CLK => CLK,
			D => D,
			WE => WE,
			I_CE => I_CE,
			SPO => SPO);
-- synopsys translate_on

END xil_riot_ram_a;

