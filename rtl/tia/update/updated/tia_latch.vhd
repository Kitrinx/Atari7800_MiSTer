----------------------------------------------------------------------------------
--
--   File        : tia_latch.vhd
--
--   Author      : Ed Henciak
--
--   Date        : December 29, 2004.
--
--   Description : TIA -> Single "latch"
--                  
--                 This logic acts as a SR latch.  The faster clock
--                 registers a "set" request on both the edges.  The
--                 async. clear available on flops in FPGAs is used to clear
--                 the latch.  This keeps the design happy and SYNCHRONOUS! 
--                 Please, it's the best I can do without resorting to gated
--                 clocks and clock skew, and silly things that make your design 
--                 fail.
--
--   Update      : 1/20/2015 : Changed this to use synchronous clears.  This 
--                             might munge the behavior.  I might have to either
--                             run this clock faster OR use the opposite edge
--                             of the current clock ... simulations will reveal
--                             the solution.
--
--                             I'll probably add clock enables to this as well.
--
--
----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

entity tia_latch is
port
(

   -- Clock input (the x2 clock)
   clk    : in std_logic;

   -- Bits that set and clear
   set    : in std_logic;
   clear  : in std_logic;

   -- Our output bit...
   output : out std_logic

);
end tia_latch;

architecture synth of tia_latch is

    signal latch_rise, latch_fall : std_logic; 

begin

    -- Grab value on the rising edge
    process(clk)
    begin

        if rising_edge(clk) then

            if (clear = '1') then

                latch_rise <= '0';

            else

                if (set = '1') then
                   latch_rise <= '1';
                end if;

            end if;

        end if;

    end process;

    -- Grab value on the falling edge
    process(clk)
    begin

        if falling_edge(clk) then

            if (clear = '1') then

                latch_fall <= '0';

            else

                if (set = '1') then
                   latch_fall <= '1';
                end if;

            end if;

        end if;

    end process;

    -- Gate the outputs of the "DDR" flops to create
    -- the latch output...
    output <= latch_rise or latch_fall;

end synth;
