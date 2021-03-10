-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  Atari 2600 TIA LFSR
--
--   Author    :  Ed Henciak 
--
--   Notes     :  This counter is the one found throughout TIA.
--                I left it in the archive so that functionality
--                of the counter can be simulated if one wants to
--                see what the TIA did...in the TIA implementation,
--                the LFSR is replaced with a more "readable" counter.
--                The more "readable" counter will consume a little 
--                more area, so one may want to use this with decode
--                logic if they're targeting smaller devices. Do not
--                expect much of a savings though...if any! Enjoy!
--
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

entity tia_lfsr is
port(

   p1_clk    : in std_logic;
   p2_clk    : in std_logic;
   reset     : in std_logic;

   lfsr_out  : out std_logic_vector(5 downto 0)  
);
end tia_lfsr;

architecture struct of tia_lfsr is

  signal lfsr_vec    : std_logic_vector(5 downto 0) := "000000";
  signal next_vec    : std_logic_vector(5 downto 0) := "000000";
  signal next_vec_p1 : std_logic_vector(5 downto 0) := "000000";
  signal node2       : std_logic;
  signal node1       : std_logic;
  signal gate_in     : std_logic;
  signal lfsr_out_i  : std_logic_vector(5 downto 0) := "000000";

begin

   -- Silly feedback logic for lfsr
   node2   <= not(lfsr_out_i(0)) nor lfsr_out_i(1);
   node1   <= not(lfsr_out_i(0)) and lfsr_out_i(1);
   gate_in <= node1 nor node2;

   -- This process calculates the "next" value 
   -- to latch (combinational logic at output of
   -- the phase two clock)
   process(gate_in, lfsr_out_i)
   begin

       next_vec(5) <= gate_in;
       next_vec(4) <= lfsr_out_i(5);
       next_vec(3) <= lfsr_out_i(4);
       next_vec(2) <= lfsr_out_i(3);
       next_vec(1) <= lfsr_out_i(2);
       next_vec(0) <= lfsr_out_i(1);

   end process;

   -- First the latch structure for the phase 1 clock
   -- (silly inverting eliminated since it is useless
   --  for our purposes!)
   process(p1_clk, next_vec)
   begin

        if(p1_clk = '1') then
           next_vec_p1 <= next_vec;
        end if;

   end process;

   -- Silly LFSR shift register.
   process(p2_clk, next_vec_p1)
   begin

        if(p2_clk = '1') then
            lfsr_vec <= next_vec_p1;
        end if;

   end process;

   lfsr_out_i(5)   <= lfsr_vec(5) and not(reset);
   lfsr_out_i(4)   <= lfsr_vec(4) and not(reset);
   lfsr_out_i(3)   <= lfsr_vec(3) and not(reset);
   lfsr_out_i(2)   <= lfsr_vec(2) and not(reset);
   lfsr_out_i(1)   <= lfsr_vec(1) and not(reset);
   lfsr_out_i(0)   <= lfsr_vec(0) and not(reset);

   lfsr_out        <= lfsr_out_i;

end struct;

