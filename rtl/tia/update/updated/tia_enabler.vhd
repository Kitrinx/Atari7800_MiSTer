-----------------------------------------------------------------------------------
--
--   File        : tia_enabler.vhd
--
--   Author      : Ed Henciak 
--
--   Date        : February 11, 2005 (very, very AM) I need to work tomorrow,
--                 but layoffs are comming and seeing that I am a contractor
--                 and have quit on my current employer twice, I doubt I'll be
--                 at work very long tomorrow.  I plan on smelling like sour 
--                 milk soon.
--
--   Description : Atari 2600 TIA Enable Sequencing Circuit 
--
--                 This component is used by all object counters.
--                 It uses a x2 system clock to generate enable signals
--                 that advance the counters.
--
--                 This circuit does not appear in TIA.  It is used to
--                 maintain synchronicity for FPGA applications.  
--
--                 Purists may bitch about this.  I agree, it's not "pure".
--                 However, non-working FPGA/ASICs are typically fancy random
--                 number generators that typically lead to designer depression.
--                 So, if you desire a garbage zinz to make TIA work, simply
--                 translate the schematics directly to VHDL and drive the
--                 clock from gated logic.  I perfer to do it the right way,
--                 get the EXACT same functionality, and smile as the design
--                 works in any process, any FPGA, and any device you'd want 
--                 to migrate this thing to.  Again, this avoids zinzing the
--                 friggin TIA circuit up...
--
--                 Moreover, I think I figured out why a "bug" was left in
--                 TIA that allows one to stuff the extra clock cycles to
--                 object counters...more on that later.  I think it is a 
--                 conspiracy of epic proportions...
-- 
--   Update      : January 20, 2015 (11:10PM) Wow, it's been a long long time.
--                 I didn't get the axe!!!  Actually, I got decent contracts with
--                 both Netronome and Novocell throughout 2005 and 2006 and quit
--                 that employer in May of 2005!  Like a complete wuss, I bailed 
--                 on contracting once those were finished and took a full time
--                 job.  That was silly as I could have had more work not a week
--                 later ... lesson learned! :-) 
--
--                 Next, I totally forget what the "conspiracy of epic proportions"
--                 was exactly ... I'll figure it out though ...
--
--                 Anyway, all I did here was change the resets to synchronous
--                 ones.  I also moved to numeric_std from that Synopsys jive.
--
--                 I think I should make a "pix_clk_2x_re" clock enable for this 
--                 logic ... that way we can drive any multiple of the pixel clock
--                 into this with the proper enables ... but I'll tackle that once
--                 I get it back up and running.
--                
-----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library a2600;
    use a2600.tia_pkg.all;

entity tia_enabler is
port
(

   -- System wide clock and reset.
   clk        : in  std_logic;
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


architecture synth of tia_enabler is

   -- Divide by four counter...
   signal tick_cnt : unsigned(1 downto 0);
 
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
    process(clk)
    begin

        if rising_edge(clk) then

            if (reset = '1') then

                tick_cnt <= "00";
                ena_div  <= '0';

            else

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

        end if;

    end process;

    -- This process triggers advances in the event a motion
    -- request arrives...we do this on the rising edge!
    process(clk)
    begin

        if rising_edge(clk) then

            if (reset = '1') then

                mot_adv <= '0';

            else

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

        end if;

    end process;

    -- NOTE TO SELF (1/20/2015) ... I think this should be "OR", 
    -- not XOR.  10 years ago, I was pissing around trying to figure 
    -- out that Cosmic Ark bug ... I recall making this change, but 
    -- don't know if it was a guess or was a bug fix.  Anyway, I'll
    -- resolve that later assuming I do not die.

    -- Drive out the enable signal which shall allow the 
    -- counter to advance on a system_clk_x2 rising edge!
    obj_enable <= ena_div xor mot_adv;
    --obj_enable <= ena_div or mot_adv;

 
end synth;
