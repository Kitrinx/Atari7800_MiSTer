-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  TIA CPU clock generation
--
--   Author    :  Ed Henciak 
--
--   Notes     :  This component generates the clock for the CPU.
--                A gate level model is also included so that one can
--                see that the two are functionally equivalent.
--
--   Date      :  December 21, 2004
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_unsigned.all;
    use IEEE.std_logic_arith.all;

-- This library allows us to use the simulation
-- components so that we know TIA is behaving as expected.
-- We don't want to synthesize this though...

-- synthesis translate_off
library A2600;
    use A2600.tia_sim_comps.all;
-- synthesis translate_on 

entity tia_cpu_clk_gen is
port
(
   -- Clock and reset 
   -- synthesis translate_off
   ref_clk    : in  std_logic; -- Main oscillator
   -- synthesis translate_on
  
   clk        : in  std_logic; -- Main clock x2
   reset      : in  std_logic; -- async. input reset

   ena        : in  std_logic; -- System clk ref.
   ena_180    : in  std_logic; -- System clk ref (180 deg. oop)

   p0_ref     : out std_logic; -- CPU P0 reference
   p0_ref_180 : out std_logic; -- CPU P0 reference (180 deg. oop)

   clk_out    : out std_logic  -- Used by some logic in the design

);
end tia_cpu_clk_gen;


architecture behave of tia_cpu_clk_gen is

   -- These four signals are actually pos. edge /
   -- neg. edge flip flops...
   signal flop_d1 : std_logic;
   signal flop_d2 : std_logic;
   signal flop_d3 : std_logic;
   signal flop_d4 : std_logic;

   -- Signals used to generate the reference
   -- pulse for the CPU
   signal cnt         : std_logic_vector(2 downto 0);
   signal d0, d1, d2  : std_logic;
   signal p0_ref_i    : std_logic;

   -- This signal is for simulation only!
   -- synthesis translate_off
   signal ref_cpu_clk : std_logic;
   -- synthesis translate_on

begin

   -- Positive edge detect flops
   process(clk, reset)
   begin

       if (reset = '1') then

          flop_d2 <= '0';
          flop_d3 <= '0';

       elsif(clk'event and clk = '1') then

          if (ena = '1') then
             flop_d2 <= flop_d1;
             flop_d3 <= flop_d2;
          end if;

       end if;

   end process;

   -- Neg edge detect flops
   process(clk, reset)
   begin

       if (reset = '1') then

          flop_d1 <= '0';
          --flop_d4 <= '0';

       elsif(clk'event and clk = '1') then

          if (ena_180 = '1') then
             flop_d1 <= flop_d2 nor flop_d3;
             --flop_d4 <= flop_d3;
          end if;

       end if;

   end process;


   -- Gate the counters to see when the clock
   -- should be high...this clock is used as a 
   -- "real" reference for some logic in the main
   -- controller.
   clk_out <= flop_d1 or flop_d2;

   -- Here I'm generating a clock enable signal for the
   -- CPU so that the entire design is synchronous.

   -- This first process generates the reference counter
   process(clk, reset)
   begin

       if (reset = '1') then

           cnt <= "000";

       elsif (clk'event and clk = '1') then

           -- Increment reference counter
           cnt <= cnt + 1;

           -- If the counter is at five, clear it!
           if (cnt = "101") then
               cnt <= (others => '0');
           end if;
 
       end if;

   end process;

   -- This gate generates the CPU enable signal for the 
   -- rising edge of the Phi0 clock...
   p0_ref_i <= '1' when (cnt = "000" and reset = '0') else '0';
   p0_ref   <= p0_ref_i;

   -- Now we pipe this for three clock cycles to
   -- get the falling edge of the CPU clock reference...
   process(clk, reset)
   begin

       if (reset = '1') then

           d0 <= '0';
           d1 <= '0';
           d2 <= '0';

       elsif(clk'event and clk = '1') then

           d0 <= p0_ref_i;
           d1 <= d0;
           d2 <= d1;

       end if;

   end process;

   -- Drive out the falling edge reference
   p0_ref_180 <= d2;

   ---------------------------------------------------
   -- And now for something completely different...
   ---------------------------------------------------

   -- Turn the synthesizer off! We don't want it to
   -- see this!

   -- synthesis translate_off

   ---------------------------------------------------
   -- This component here is a gate level description
   -- of the TIA's CPU clock generator.  I made this
   -- so that the above "abstract" description can be
   -- compared against the real design...this is not
   -- synthesized at all...it is here for simulation
   -- reference...be aware that if the clk and reset
   -- lines switch states at the exact same simulation
   -- times, the simulation will halt due to a race
   -- condition error.
   ---------------------------------------------------
   
 --  ref_cpu_clk_0 : tia_struct_cclk
 --  port map(

 --       clk  => ref_clk,
 --       rst  => reset,

 --       cclk => ref_cpu_clk
 --  );

   -- synthesis translate_on

   -- Synthesizer is back on!


end behave;

