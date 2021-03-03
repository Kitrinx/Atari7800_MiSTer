-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  Cross coupled NOR latch found everywhere in TIA.  This does
--                not have the silly inverter found at the input of the 
--                reset input.
--
--   Author    :  Ed Henciak 
--
-------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;

entity tia_nor_lat is
port(

     set    : in std_logic;
     rst    : in std_logic;

     output : out std_logic 
);
end tia_nor_lat;


architecture gate of tia_nor_lat is

    signal node_1 : std_logic;
    signal node_2 : std_logic;

begin

    -- Happy cross couple...
    node_1 <= rst nor node_2;
    node_2 <= set nor node_1;

    -- Silly concurrent signal assignment
    output <= node_1;

end gate;
