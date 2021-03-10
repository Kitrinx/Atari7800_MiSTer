-------------------------------------------------------------------------------------
--
--   File        :  tia_audio.vhd
--
--   Author      :  Eric Crabill (original Verilog description)
--                  Ed Henciak (ported to VHDL)
--
--   Date        :  3-16-2005
--
--   Description :  TIA audio circuit.
--
--                  Ported Eric Crabill's design TIA audio design to VHDL.  While the 
--                  circuit isn't a precise recreation of the TIA audio circuit, it is 
--                  most certainly accurate in virtually all ways.  I've included
--                  all of Eric's commentary as it shall easily guide one through
--                  this design.  Eric's comments are the C++ style comments 
--                  wrapped with a VHDL comment so that the compiler doesn't get 
--                  mad and fling monkey poop at me for using foreign comment syntax.
--
--                  As you will see, the circuit is pretty much a copy of the TIA 
--                  audio logic in the schematics ... the only difference is that a
--                  "regular" downcounter is used for the audio clock as oppose to
--                  that LFSR based counter + decoder you see all over the place on 
--                  TIA.  The circuits are functionally identical.
--
--   Update      :  1-20-2015 ... Yeah, it's been a while.  
--
--                              Changed async. resets to synchronous (better for 
--                              Spartan 6 & beyond).
--
--                              Got rid of std_logic_arith and std_logic_unsigned ...
--                              using numeric_std like a good VHDL designer should.
--                             
-------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity tia_audio is
port
(

    -- Clock input (2X osc clk) & reset
    clk         : in  std_logic;
    reset       : in  std_logic;

    -- CPU clock rising edge reference (runs @ 1.19MHz)
    cpu_clk_re  : in  std_logic;

    -- Audio frequency, volume, and control inputs
    audf        : in  unsigned(4 downto 0);
    audc        : in  unsigned(3 downto 0);
    audv        : in  unsigned(3 downto 0);

    -- Audio output (4 bit vector)
    aout        : out unsigned(3 downto 0) 


);
end tia_audio;

architecture synth of tia_audio is

    -- Frequency divide counter
    signal counter        : unsigned(11 downto 0);
    signal clken          : std_logic;

    -- Polynomial counter (that's an LFSR for those of you
    -- in Rio Linda).
    signal polyfive_state : std_logic_vector(5 downto 1);
    signal polyfive       : std_logic_vector(5 downto 1);
    signal polyfive_fb    : std_logic;
    signal x0, x1, x2     : std_logic;    
    signal net0, net1     : std_logic;    
    signal net2, net3     : std_logic;    
    signal net4, net5     : std_logic;    
    signal net6, net7     : std_logic;    
    signal net8, net9     : std_logic;    
    signal net10, net11   : std_logic;
    signal clken_next     : std_logic;    

    -- Four bit control poly for audio
    signal polyfour_state : std_logic_vector(9 downto 6);
    signal polyfour       : std_logic_vector(9 downto 6);
    signal polyfour_fb    : std_logic;
    signal one_bit_signal : std_logic;
    signal pt0, pt1, pt2  : std_logic;
    signal pt3, pt4, pt5  : std_logic;
    signal pt6            : std_logic;
    signal net12, net13   : std_logic;
    signal net14, net15   : std_logic;

begin

    --  //******************************************************************//
    --  // Generate the clock enable for the audio circuit.  The original   //
    --  // schematics have a two phase audio clock generated from the       //
    --  // horizontal position counter.  The audio clock goes through two   //
    --  // cycles for every horizontal line, so each audio clock cycle is   //
    --  // 38 processor clock cycles -- yielding a frequency near 30 KHz.   //
    --  // This two phase clock is then further divided using the contents  //
    --  // of the audio frequency divider register.  Here, I have combined  //
    --  // everything to generate an audio clock enable.  This is just a    //
    --  // programmable down counter.  My goal in doing it this way is to   //
    --  // make the audio logic independent of the video logic.             //
    --  //******************************************************************//
    process(clk)
    begin

        if rising_edge(clk) then

            if (reset = '1') then

                counter <= (others => '0');

            else

                -- When we're on a 1.19MHz cycle AND we can latch
                -- a new value....
                if (cpu_clk_re = '1') 

                    if (clken = '1') then

                        -- This multiplier is VERY small...however, if you're
                        -- ever doing high-speed designs and embedded mults are
                        -- not available, pay attention to seemlessly harmless stuff
                        -- like this or you're going to zinz up your whole design.
                        counter <= (38 * audf) + 37;

                    else

                        -- Decrement counter.
                        counter <= counter - 1;

                    end if;

                end if;

            end if;

        end if;

    end process;

    -- Assert audio clock enable signal (i.e. frequency synthesis)
    clken <= '1' when (counter = x"000") else '0';

    -- //******************************************************************//
    -- // Implementation of the 5-bit lfsr "polynomial counter".  This is  //
    -- // derived from the schematic diagram.                              //
    -- //******************************************************************//
    process (clk)
    begin

        if rising_edge(clk) then

            if (reset = '1') then 

                  polyfive_state <= (others => '0');

            else

                if (cpu_clk_re = '1') then

                    if (clken = '1') then

                        polyfive_state(5) <= polyfive(4);
                        polyfive_state(4) <= polyfive(3);
                        polyfive_state(3) <= polyfive(2);
                        polyfive_state(2) <= polyfive(1);
                        polyfive_state(1) <= polyfive_fb;

                    end if;

                end if;

            end if;

        end if;

    end process;
    
    -- Feedback circuit and other malarky.
    polyfive    <= polyfive_state;
    x2          <= not(polyfive(5));
    net0        <= not(audc(0) or audc(1));
    net1        <= not(net0 or not(polyfive(3)));
    net2        <= x0 and net0;
    net3        <= not(net1 or net2);
    net4        <= not(net3 or polyfive(5));
    net5        <= net3 and polyfive(5);
    net6        <= not(audc(0) or audc(1) or x1);
    net7        <= '1' when ((polyfive = "00000") and (net6 = '0')) else '0';
    net8        <= '1' when (audc = "0000") else '0'; 

    polyfive_fb <= net8 or net4 or net5 or net7;

    -- // This stuff here is for a clock
    -- // enable to the 4-bit lfsr...

    net9        <=  '1' when ((polyfive(4 downto 1) = "1000") and (audc(0) = '0') and (audc(1) = '1')) else '0';
    net10       <= not( not(audc(1)) or not(audc(0)) or not(polyfive(5)) ); 
    net11       <= net9 or net10 or not(audc(1));
    clken_next  <= net11 and clken; 
 
    -- THe 4 bit polynomial counter.
    process(clk)
    begin

        if rising_edge(clk) then

            if (reset = '1') then

                polyfour_state <= (others => '0');

            else

                if (cpu_clk_re = '1') then

                    if (clken_next = '1') then
            
                        polyfour_state(9) <= polyfour(8);
                        polyfour_state(8) <= polyfour(7);
                        polyfour_state(7) <= polyfour(6);
                        polyfour_state(6) <= polyfour_fb;

                    end if;

                end if;

            end if;

        end if;
      
    end process;

    -- More feedback circuitry
    polyfour       <= polyfour_state;
    one_bit_signal <= not(polyfour(9));
    x0             <= polyfour(9);
    x1             <= '1' when (polyfour = "0000") else '0';
    
    polyfour_fb    <= not(pt0);
    pt0            <= not(pt1 or pt2 or pt3 or pt4 or pt5);
    
    pt1            <= '1' when (audc = "0000") else '0';
    pt2            <= not(audc(3) or audc(2) or net13);
    pt3            <= audc(3) and audc(2) and not(net12);
    pt4            <= not(audc(3)) and audc(2) and not(polyfour(6));
    pt5            <= audc(3) and not(audc(2)) and not(x2);
    pt6            <= polyfour(6) and not(polyfour(7)) and polyfour(8);
    
    net12          <= not(pt6 or not(polyfour(8)));
    net13          <= not(x1 or net14 or net15);
    net14          <= not(polyfour(9) or not(polyfour(8)) );
    net15          <= polyfour(9) and not(polyfour(8));

    -- //******************************************************************//
    -- // While I'm getting the easy stuff out of the way, generate the    //
    -- // unsigned output from this module.  The original circuit has what //
    -- // appears to be a one bit audio signal, which then is used to      //
    -- // turn on (or off) a programmable pull down network attached to    //
    -- // a chip pad.  The pull strength is set by the volume register.    //
    -- // The programmable pull down is used with a fixed pull up outside  //
    -- // the chip, to generate a voltage waveform that is capacitively    //
    -- // coupled to the modulator.                                        //
    -- //******************************************************************//
    process (clk)
    begin 

       if rising_edge(clk) then

           if (reset = '1') then 
                aout <= (others => '0');
           else

               -- If we're on a "CPU cycle"
               if (cpu_clk_re = '1') then

                   -- and the one bit signal is asserted
                   if (one_bit_signal = '1') then
                       -- output the volume vector
                       aout <= (others => '0');
                   else
                       -- no volume
                       aout <= audv;
                   end if;

               end if;

           end if;

       end if;

    end process;

    -- That's All Folks!!!!!

    -- Doo Doo Dee Doo Doot Doo Doooo....or however the hell you're supposed to sing
    -- that in text....

end synth;
