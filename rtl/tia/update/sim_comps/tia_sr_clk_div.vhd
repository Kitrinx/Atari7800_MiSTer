-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  TIA SR Flop Flop based clock divider with async.
--                reset.
--
--   Author    :  Ed Henciak 
--
--   Notes     :  Taken directly from the schematics!  This is used 
--                everywhere in TIA for driving object counters.  
--                
-------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;

entity tia_sr_clk_div is
port(

     clk    : in  std_logic;
     rst    : in  std_logic;

     tap    : out std_logic;

     p1_clk : out std_logic;
     p2_clk : out std_logic 

);
end tia_sr_clk_div;

architecture struct of tia_sr_clk_div is

    -- Declare the SR flip flop component.
    component tia_f1_sr_flop
    port(

         clk : in std_logic;
         rst : in std_logic;

         s_n : in std_logic;
         r_n : in std_logic;

         q   : out std_logic;
         q_n : out std_logic
    );
    end component;

    -- Some component interconnect

    signal q_flop1  : std_logic;
    signal qb_flop1 : std_logic;

    signal q_flop2  : std_logic;
    signal qb_flop2 : std_logic;

begin

-- Flip flop number 1
sr_flop_0 : tia_f1_sr_flop
port map(

     clk => clk,
     rst => rst,

     s_n => q_flop2,
     r_n => qb_flop2,

     q   => q_flop1,
     q_n => qb_flop1
);

-- Flip flop number 2
sr_flop_1 : tia_f1_sr_flop
port map(

     clk => clk,
     rst => rst,

     s_n => qb_flop1,
     r_n => q_flop1,

     q   => q_flop2,
     q_n => qb_flop2
);

-- Drive output clocks...
p1_clk <= q_flop2  nor q_flop1;
p2_clk <= qb_flop2 nor qb_flop1;

-- Drive the "tap" for both the 
-- missile counter as well as the
-- local reset latch
tap    <= qb_flop2;


end struct;
