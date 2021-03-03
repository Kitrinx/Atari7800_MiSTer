-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  SR Flop Flop w. async. clear used to generate the
--                CPU clock in the Atari TIA ASIC.
--
--   Author    :  Ed Henciak 
--
--   Notes     :  Dervied from the CPU clock generator in TIA.  Do not
--                synthesize this unless you feel like making synthesis tools
--                work overtime.
--                
-------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;

entity tia_cclk_sr_flop is
port(

     clk : in  std_logic;
     rst : in  std_logic;

     s_n : in  std_logic;
     r_n : in  std_logic;

     mp  : out std_logic;

     q   : out std_logic;
     q_n : out std_logic
);
end tia_cclk_sr_flop;


architecture gate of tia_cclk_sr_flop is

    -- Various nodes of the circuit.
    signal node_1 : std_logic;
    signal node_2 : std_logic;

    signal node_3 : std_logic;
    signal node_4 : std_logic;

    signal and_1  : std_logic;
    signal and_2  : std_logic;

    signal q_i    : std_logic;
    signal q_n_i  : std_logic;


begin

    -- This model was left in the archive in the event
    -- someone wants to compare the original gate-level
    -- design to the HDL implementation.  Be aware that
    -- synthesis of logic such as this (latch/sequential)
    -- generally results in the synthesis tools whining.

    -- Two-input NORs at input of circuit.
    node_1 <= s_n nor clk;
    node_2 <= r_n nor clk;

    -- Cross coupled NORs in the "middle" of the circuit.
    node_3 <= node_1 nor node_4;
    node_4 <= node_2 nor node_3;

    -- AND gates near output of the circuit.
    and_1  <= clk and node_3;
    and_2  <= clk and node_4;

    -- Cross coupled NORs at output stage.
    -- This is where this circuit differs from 
    -- the other SR flop...
    q_i    <= and_1 nor q_n_i;
    q_n_i  <= not(and_2 or rst or q_i);

    -- Output drivers.
    mp  <= node_3; 
    q   <= q_i;
    q_n <= q_n_i;

end gate;
