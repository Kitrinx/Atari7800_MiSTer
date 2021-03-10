-------------------------------------------------------------------------------
--
--   Copyright (C) 2005
--
--   Title     :  Atari 2600 TIA Enable Sequencing Circuit
--
--   Author    :  Ed Henciak 
--
--   Notes     :  This component is used by all object counters.
--                It uses a x2 system clock to generate enable signals
--                that advance the counters.
--
--                This circuit does not appear in TIA.  It is used to
--                maintain synchronicity for FPGA applications.  
--
--                Purists may bitch about this.  I agree, it's not "pure".
--                However, non-working FPGA/ASICs are typically fancy random
--                number generators that typically lead to designer depression.
--                So, if you desire a garbage zinz to make TIA work, simply
--                translate the schematics directly to VHDL and drive the
--                clock from gated logic.  I perfer to do it the right way,
--                get the EXACT same functionality, and smile as the design
--                works in any process, any FPGA, and any device you'd want 
--                to migrate this thing to.  Again, this avoids zinzing the
--                friggin TIA circuit up...
--
--                Moreover, I think I figured out why a "bug" was left in
--                TIA that allows one to stuff the extra clock cycles to
--                object counters...more on that later.  I think it is a 
--                conspiracy of epic proportions...
-- 
--   Date      :  February 11, 2005 (very, very AM) I need to work tomorrow,
--                but layoffs are comming and seeing that I am a contractor
--                and have quit on my current employer twice, I doubt I'll be
--                at work very long tomorrow.  I plan on smelling like sour 
--                milk soon.
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_arith.all;
    use IEEE.std_logic_unsigned.all;

library A2600;
    use A2600.tia_pkg.all;

entity tia_enabler is
port
(

   -- Clock input (main oscillator clock x2)
   clk        : in  std_logic;

   -- Resets this logic...this should be tied to system
   -- reset only....
   reset      : in  std_logic;

   -- This signal states that we are driving a visible
   -- scanline.  As a result, we better move the counter
   -- or else we won't see stuff.
   noblank    : in  std_logic;

   -- Motion logic enable input...we use this to determine
   -- when to advance a counter with respect to the
   -- system_clk x2.  This is part of the TIA conspiracy...
   hmotion    : in  std_logic;

   -- Main "enable counter" signal....this advances the counter
   -- with respect to the x2 clock.
   obj_enable : out std_logic 

);
end tia_enabler;


architecture rtl of tia_enabler is

   -- Divide by four counter...
   signal tick_cnt : std_logic_vector(1 downto 0);
 
   -- Enable object based on counter ticks elapsed.
   signal ena_div  : std_logic;

   -- Advance based on motion pulse
   signal mot_adv  : std_logic;

begin

    -- OK, first we are going to focus on advancing during
    -- a normal non-blank interval...this guy simply counts
    -- to three, flips to zero, and counts to three again.
    -- If it counts to four, well, that is plain silly seeing
    -- that we're only using two bits.  Five is out of the 
    -- question.  Three.  Two is too few, four is too many.
    -- Three.  In effect, we're merely diving the inbound
    -- clock by four.
    process(clk, reset)
    begin

        if (reset = '1') then

            tick_cnt <= "00";
            ena_div  <= '0';

        elsif(clk'event and clk = '0') then

            -- By default, these are low unless we're
            -- under the control of the blank....
            ena_div  <= '0';
            tick_cnt <= "00";

            -- When we're not blanked...
            if (noblank = '1') then

                -- Decode the current tick counter and enable
                -- when necessary.
                case tick_cnt is
                   when "00" | "10" => ena_div <= '1';
                   when others      => ena_div <= '0';
                end case;

                -- Advance the tick counter
                tick_cnt <= tick_cnt + 1;

            end if;

        end if;

    end process;

    -- This process triggers advances in the event a motion
    -- request arrives...we do this on the rising edge!
    process(clk, reset)
    begin

        if (reset = '1') then

            mot_adv <= '0';

        elsif(clk'event and clk = '1') then

            -- By default, no motion advance
            mot_adv <= '0';

            -- If we see the hmotion signal arrive, then
            -- enable the advance signal....however, we
            -- only generate one of these pulses per
            -- hmotion assertion, not each cycle hmotion
            -- is high during the clk_2x pulse....
            if (hmotion = '1') and (mot_adv = '0') then
                mot_adv <= '1';
            end if;

        end if;

    end process;

    -- Drive out the enable signal which shall allow the 
    -- counter to advance on a system_clk_x2 rising edge!
    obj_enable <= ena_div xor mot_adv;
    --obj_enable <= ena_div or mot_adv;

 
end rtl;
