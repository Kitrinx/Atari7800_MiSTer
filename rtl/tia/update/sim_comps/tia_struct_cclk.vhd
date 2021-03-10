-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  CPU clock generator created from SR flops.
--
--   Author    :  Ed Henciak 
--
--   Notes     :  This circuit takes the input clock and divides it by 3.
--                Use this only for simulation as synthesis tools generally
--                loathe the combinational loops introduced by the SR flops.
--                
-------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;

entity tia_struct_cclk is
port(

     clk  : in  std_logic;
     rst  : in  std_logic;

     cclk : out std_logic
);
end tia_struct_cclk;


architecture struct of tia_struct_cclk is

component tia_cclk_sr_flop
port(

     clk : in  std_logic;
     rst : in  std_logic;

     s_n : in  std_logic;
     r_n : in  std_logic;

     mp  : out std_logic;

     q   : out std_logic;
     q_n : out std_logic
);
end component;

signal tap_flop_0   : std_logic;
signal out_flop_0_n : std_logic;
signal out_flop_1   : std_logic;
signal out_flop_1_n : std_logic;
signal gate_node    : std_logic;
signal gate_node_n  : std_logic;


begin

flop_0 : tia_cclk_sr_flop
port map(

     clk => clk,
     rst => rst,

     s_n => out_flop_1,
     r_n => out_flop_1_n,

     mp  => tap_flop_0,

     q   => open,
     q_n => out_flop_0_n 
);

-- Some silly logic for the secondary flop...
gate_node   <= out_flop_0_n nor out_flop_1;
gate_node_n <= not(gate_node);

flop_1 : tia_cclk_sr_flop
port map(

     clk => clk,
     rst => rst,

     s_n => gate_node_n,
     r_n => gate_node,

     mp  => open,

     q   => out_flop_1,
     q_n => out_flop_1_n 
);

-- Clock output driver
cclk <= out_flop_1 nor tap_flop_0;

end struct;
