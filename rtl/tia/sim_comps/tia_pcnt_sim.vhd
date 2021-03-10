-------------------------------------------------------------------------------
--
--   Copyright (C) 2005
--
--   Title     : Atari TIA Horizontal motion simulation model
--
--   Author    : Ed Henciak 
--
--   Notes     : Use this to see a gate level sim of the horizontal
--               motion circuit...this circuit is very critical in proper
--               Atari 2600 hardware emulation in that there is a bug
--               that allows nice starfields in Cosmic Arc and Rabbit Transit.
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

library a2600;
    use a2600.tia_sim_comps.all;

entity tia_pcnt_sim is
port
(

   -- Clock and reset 
   pl_clk     : in  std_logic;
   reset_sys  : in  std_logic;

   -- Control signals from player logic
   enable_n   : in  std_logic;
   start_n    : in  std_logic;

   -- Counter output
   pcnt       : out std_logic_vector(2 downto 0)


);
end tia_pcnt_sim;

architecture behave of tia_pcnt_sim is

   -- Signals for the simulation model...
   signal to_f1,   to_f2,   to_f3   : std_logic;
   signal out_0,   out_1,   out_2   : std_logic;
   signal out_0_n, out_1_n, out_2_n : std_logic;
   signal stop_gate                 : std_logic;
   signal go_n                      : std_logic;

   signal start_n_del, enable_n_del : std_logic;

begin

-- Nand gate that appears to stop the counter.
stop_gate <= not((out_0 and out_1 and out_2) and start_n);

-- Insert a little delay on input control signals
start_n_del  <= start_n  after 0.1 ns;
enable_n_del <= enable_n after 0.1 ns;

-- This appears to be the flop that controls
-- the counter circuit...
f1_0 : tia_f3_sr_flop
port map(

     clk  => pl_clk,
     rst  => reset_sys,

     s_n  => start_n_del,
     s1_n => enable_n_del,
     r_n  => enable_n_del,
     r1_n => stop_gate,

     q    => open,
     q_n  => go_n
);

to_f1 <= enable_n_del or go_n;

f1_1 : tia_f3_sr_flop
port map(

     clk  => pl_clk,
     rst  => reset_sys,

     s_n  => out_0,
     s1_n => to_f1,
     r_n  => to_f1,
     r1_n => out_0_n,

     q    => out_0,
     q_n  => out_0_n
);

to_f2 <= to_f1 or out_0_n;

f1_2 : tia_f3_sr_flop
port map(

     clk  => pl_clk,
     rst  => reset_sys,

     s_n  => out_1,
     s1_n => to_f2,
     r_n  => to_f2,
     r1_n => out_1_n,

     q    => out_1,
     q_n  => out_1_n
);

to_f3 <= to_f2 or out_1_n;

f1_3 : tia_f3_sr_flop
port map(

     clk  => pl_clk,
     rst  => reset_sys,

     s_n  => out_2,
     s1_n => to_f3,
     r_n  => to_f3,
     r1_n => out_2_n,

     q    => out_2,
     q_n  => out_2_n
);

-- Output counter value.
pcnt <= out_2 & out_1 & out_0;

end behave;



