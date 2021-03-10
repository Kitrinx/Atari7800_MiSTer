-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  SR Flop Flop w. async. clear.
--
--   Author    :  Ed Henciak 
--
--   Notes     :  Dervied from the F1 flip flop found in the Atari TIA.
--                
-------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;

entity tia_f1_sr_flop is
port(

     clk : in std_logic;
     rst : in std_logic;

     s_n : in std_logic;
     r_n : in std_logic;

     q   : out std_logic;
     q_n : out std_logic
);
end tia_f1_sr_flop;


architecture gate of tia_f1_sr_flop is

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

    -- Flip flop created at the gate level.
    -- Synthesis tools will probably bitch about
    -- this being a latch / feedback circuit.
    -- Oh!  Cool...it's calling it a combinational 
    -- loop!  It's generally not a good idea to use
    -- anything but the D Flip Flops available "for
    -- free" in FPGAs unless you do proper timing 
    -- analysis yourself.

    -- I left this model in here so that one can
    -- see the operation of the TIA clock divider
    -- compared to the "abstract" one created from
    -- a simple two-bit counter.  The two-bit counter
    -- will probably require fewer logic elements!
    -- However, I want this to be the "definitive" 
    -- HDL version of TIA so I'll leave this in here
    -- for reference.  

    -- Two-input NORs at input of circuit.
    node_1 <= s_n nor clk;
    node_2 <= r_n nor clk;

    -- Cross coupled NORs in the "middle" of the circuit.
    node_3 <= node_1 nor node_4;
    node_4 <= not(node_3 or rst or node_2);

    -- AND gates near output of the circuit.
    and_1  <= clk and node_3;
    and_2  <= clk and node_4;

    -- Cross coupled NORs at output stage.
    q_i    <= not(and_1 or rst or q_n_i);
    q_n_i  <= and_2 nor q_i;

    -- Q and Qbar drivers.
    q   <= q_i;
    q_n <= q_n_i;

end gate;
