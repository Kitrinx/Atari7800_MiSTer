-------------------------------------------------------------------------------
--
--   File        : tia_sequencer.vhd
--
--   Author      : Ed Henciak 
--
--   Date        : December 29, 2004
--
--   Description : Atari 2600 TIA Sequencing circuit
--
--                 This component represents the divide by four clock,
--                 reset latch, and LFSR found in all TIA object components.
-- 
--                 Simulation primitives are instantiated so that "real" 
--                 functionality can be compared to that which is synthesized.
--
--   Update      : 1/20/2015 : Wow! 10 years!  Damn!  Anyway, only update was
--                             a move to numeric_std and change to synchronous
--                             resets.
--
--                             I probably should add a pix_clk_2x_re clock 
--                             enable input ... also need pix_clk_2x_fe for
--                             a falling edge reference!!!
--
--                             There are piss poor design decisions I made in
--                             this thing.  Mainly, it was quick hacks I made
--                             to a couple of circuits to get up and running
--                             quickly.  That was stupid seeing that I forget
--                             a lot of details.  I will list what I changed 
--                             here though that I find disturbing :
-- 
--                             Check the behavior of the two flops related 
--                             to master_rlat ... there might be issues there.
--                             It'll be best to fire up the simulation 
--                             primitives and compare against those.
--                
-------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library a2600;
    use a2600.tia_pkg.all;

    -- synthesis translate_off
    use a2600.tia_sim_comps.all;
    -- synthesis translate_on

entity tia_sequencer is
port
(

   -- First, this clock is a "simulation"
   -- clock...it's used for comparing "real"
   -- TIA operation against my silly mess...

   -- synthesis translate_off
   sim_clk   : in  std_logic;
   -- synthesis translate_on

   -- The rest of these signals are what
   -- we need to synthesize the design.

   -- Clock and reset inputs
   clk       : in  std_logic;
   reset     : in  std_logic;

   -- Enable input...this allows the internal
   -- logic to advance.
   enable    : in  std_logic;

   -- This reset clears the counter.
   -- This is generally driven by the 
   -- TIA logic.
   reset_ctr : in  std_logic;

   -- This reset sets the sequencer
   -- reset latch...
   rlat_in   : in  std_logic;

   -- Divided clock outputs
   -- These enable nice thigs to occur
   -- on the main clock edge
   p1_clk    : out std_logic;
   p2_clk    : out std_logic;

   -- Currently, only the main control logic uses
   -- these (only for the playfield)...it'd be nice to
   -- eventually remove them.
   p1_ena    : out std_logic;
   p2_ena    : out std_logic;

   -- Output of the sequence counter
   cnt_out   : out seq_int; 

   -- Output of the reset latch...
   rlat_out  : out std_logic;

   -- Finally, the "tap" output used
   -- by the missile and ball sequencer
   tap_out   : out std_logic

);
end tia_sequencer;

architecture synth of tia_sequencer is

    -- Signals used to divide the inbound clock and
    -- generate clock enables
    signal tick_cnt        : unsigned(1 downto 0);
    signal p1_clk_i        : std_logic;
    signal p2_clk_i        : std_logic;
    signal clk_tap         : std_logic;
    signal inv_clk_tap     : std_logic;
  
    -- Internal reset
    signal counter_reset   : std_logic;
    signal counter_reset_s : std_logic;

    -- Signals used to generate an output sequence
    -- value....these replace the values generated
    -- by the LFSR.
 
    -- Current counter output
    signal cnt_out_i       : seq_int;

    -- Phase one logic
    signal cnt_out_p1_c    : seq_int; -- "Combinational"
    signal cnt_out_p1_s    : seq_int; -- "Sequential"
    signal cnt_out_p1      : seq_int; -- "Latch output"
 
    -- Phase two logic
    signal cnt_out_p2_c    : seq_int; -- "Combinational"
    signal cnt_out_p2_s    : seq_int; -- "Sequential"
    signal cnt_out_p2      : seq_int; -- "Latch Output"

    -- Signals used to create "synchronous" rlat_in
    signal rlat_in_fe      : std_logic;
    signal master_rlat_in  : std_logic;
    signal rlat_out_s      : std_logic;
    signal rlat_out_a      : std_logic;

    -- synthesis translate_off

    -- These signals are used for simulation purposes
    -- only.  They are not synthesized!
    signal ref_tap         : std_logic;
    signal ref_inv_tap     : std_logic;
    signal ref_p1_clk      : std_logic;
    signal ref_p2_clk      : std_logic;
    signal ref_rlat_out    : std_logic;
    signal ref_lfsr_vec    : std_logic_vector(5 downto 0);
    -- synthesis translate_on

begin

   -- Grab 'rlat' on the falling edge of the clock...this is
   -- our "synced" clearing signal...we're basically insuring
   -- that rlat_in gets the hold time that it needs...in effect,
   -- we're doing a virtual asynchronous assert, synchronous deassert
   -- style of reset.
   -- 
   -- NOTE : (1/20/15) This was a very stupid design decision.  Made 
   --        this synchronous (see original file).  The asynchronous
   --        clearing of rlat_in_fe means that timing from master_rlat_in
   --        to other destinations could be munged if reset is asserted.
   process(clk)
   begin
  
       if falling_edge(clk) then

           if (reset = '1') then
               rlat_in_fe <= '0';
           else
               rlat_in_fe <= rlat_in;
           end if;

       end if;

   end process;

   -- Create the "master" rlat_in signal...
   master_rlat_in <= rlat_in or rlat_in_fe;
   --master_rlat_in <= rlat_in_fe;  -- <--- Don't know why I did this
 
   -----------------------------------------------------
   -- This sequential process provids the counter to 
   -- divide the inbound clock...
   -----------------------------------------------------
   -- NOTE : 1/20/2015 : I changed this to a synchronous reset.  I think
   --                    I need to see how the rlat signal is related to
   --                    clk ... if enable and master_rlat are asserted
   --                    at the same time, we could have a nice problem!
   process(clk)
   begin

       if rising_edge(clk) then

           if (master_rlat_in = '1') then

               tick_cnt <= "11";

           else

               -- Advance counter when enabled ...
               if (enable = '1') then
                   tick_cnt <= tick_cnt + 1;
               end if;

           end if;

       end if;

   end process; 

   -----------------------------------------------------
   -- This combinational process decodes the current
   -- counter value and asserts the proper reference 
   -- signal...
   -----------------------------------------------------
   process(master_rlat_in, tick_cnt)
   begin

       if (master_rlat_in = '1') then

           p1_clk_i <= '1';
           p2_clk_i <= '0';
           p1_ena   <= '0';
           p2_ena   <= '0';
           clk_tap  <= '1';

       else

           -- By default, all control signals are
           -- low...
           p1_clk_i <= '0';
           p2_clk_i <= '0';
           p1_ena   <= '0';
           p2_ena   <= '0';
           clk_tap  <= '0';

           -- Decode the tick counter & see which
           -- control signal to advance.
           case tick_cnt is

              when "00"   => p2_clk_i <= '1';

              when "01"   => p1_ena   <= '1';

              when "10"   => clk_tap  <= '1';
                             p1_clk_i <= '1';

              when others => clk_tap  <= '1'; -- The "11" case
                             p2_ena   <= '1';

           end case;

       end if;

    end process;
       
   -----------------------------------------------------
   -- The following processes drive the count value to 
   -- the component.  It is used to sequence various 
   -- events in the logic.  It generally replaces the 
   -- LFSR in the TIA that achieves the same objective.
   -----------------------------------------------------

   -- First, generate the counter reset
   counter_reset <= reset_ctr or reset;

   process(clk)
   begin
 
        if rising_edge(clk) then
            counter_reset_s <= counter_reset;
        end if;

   end process;

   ----------------
   -- Phase one!!!
   ----------------

   -- Generate the "combinational" portion of the
   -- P1 logic...this is pretty much the output
   -- incremented...
   cnt_out_p1_c <= cnt_out_i + 1;

   -- Here we register this value when the P1 clock
   -- is done being active. 
   process(clk)
   begin

       if rising_edge(clk) then

           -- Snag this value when P1 is active
           if (p1_clk_i = '1') then
               cnt_out_p1_s <= cnt_out_p1_c;
           end if;

       end if;

   end process;

   -- Output of phase 1 latch
   cnt_out_p1 <= cnt_out_p1_c when (p1_clk_i = '1') else cnt_out_p1_s;

   ----------------
   -- Phase two!!!!
   ----------------

   -- Combinational component of the P2 latch...
   -- For all intents and purposes this is always the 
   -- sequential output of P1 since the two phase clock
   -- generator will never turn on both pass gates 
   -- simultaneously.
   cnt_out_p2_c <= cnt_out_p1_s;

   -- Sequential component of the P2 latch.
   process(clk)
   begin

       -- Snag the value...
       if rising_edge(clk) then

           -- Only if we're enabled...
           if (p2_clk_i = '1') then
               cnt_out_p2_s <= cnt_out_p2_c;
           end if;

       end if;

   end process;

   -- Determine the internal count value to output
   cnt_out_p2 <= (cnt_out_p2_c) when (p2_clk_i = '1') else cnt_out_p2_s;

   -- The combinational logic used to either clear
   -- the current count or present the "next" count.  If
   -- you look at the schematic for the TIA LFSR, you'll 
   -- see that the output of the "flop" is NOR gated.  
   process(cnt_out_p2, counter_reset_s)
   begin

       -- Mux out the proper value based on the 
       -- state of reset.
       if (counter_reset_s = '1') then
           cnt_out_i <= 0;
       else
           cnt_out_i <= cnt_out_p2;
       end if;

   end process;

   -- And now, send the current count out of this component
   cnt_out <= cnt_out_i;

   -----------------------------------------------------------
   -- Finally, the TIA reset latch is instantiated here.  This
   -- latch is used to sync the counter described above to the
   -- reset pulse received from the TIA write registers...
   -----------------------------------------------------------

   -- First, invert the "tap" for the latch...
   inv_clk_tap <= not(clk_tap);

   -- Next, instantiate the latch component.
   -- This indicates to external logic that a 
   -- reset of the sequencer is pending...
   reset_latch_0 : tia_latch
   port map
   (

      clk    => clk,
      set    => master_rlat_in,
      clear  => inv_clk_tap,
      output => rlat_out_a

   );

   -- Sync up the rlat out!
   process(clk, reset)
   begin

       if rising_edge(clk) then

           if (reset = '1') then
               rlat_out_s <= '0';
           else
               rlat_out_s <= rlat_out_a;
           end if;

       end if;

   end process;

   -- ehenciak
   --rlat_out <= rlat_out_s or rlat_out_a; -- <- Again, no fucking clue why I did that!
   rlat_out <= rlat_out_s;

   -----------------------------------------------
   -- Concurrent signal assignments to drive stuff
   -- outta here that other circuits may want.
   -----------------------------------------------
   p1_clk  <= p1_clk_i;
   p2_clk  <= p2_clk_i;
   tap_out <= clk_tap;

   ---------------------------------------------------
   -- And now for something completely different...
   ---------------------------------------------------

   -- Turn the synthesizer off! We don't want it to
   -- synthesize the following simulation related stuff.

   -- synthesis translate_off

   -- Here we are going to instantiate the "real" logic 
   -- found in TIA to insure that timing and the like
   -- are all correct...these components should not be
   -- synthesized since they contain a lot of constructs
   -- synthesis tools generally do not like... 

   -- First is the divide by four clock...this also gives
   -- us the "tap" used by the missile counter as well as
   -- the "all clear" signal used by the reset latch...
   sim_sr_clk_div_0 : tia_sr_clk_div
   port map(
 
     clk    => sim_clk, 
     rst    => rlat_in,
     tap    => ref_tap,
     p1_clk => ref_p1_clk,
     p2_clk => ref_p2_clk
 
   );
 
   -- Invert the "tap" signal for the SR latch...
   ref_inv_tap <= not(ref_tap);
 
   -- Here we instantiate a nice LFSR so that we can see that our
   -- integer value matches the one output by the TIA LFSR
   -- on the current p2 cycle.
   sim_lfsr_0 : tia_lfsr
   port map(
 
     p1_clk   => ref_p1_clk,
     p2_clk   => ref_p2_clk,
     reset    => reset_ctr,
     lfsr_out => ref_lfsr_vec
 
   );
 
   -- Finally, here's a gate level model of the SR latch
   -- used in this circuit.  The one used in the TIA emulation
   -- is more of a D Flip flop with its input tied to Vdd
   -- and async. clear used to reset the latch.
   sim_latch_0 : tia_nor_lat
   port map(
 
     set    => rlat_in,       -- Yep, set reset with a reset...hmmm
     rst    => ref_inv_tap,
     output => ref_rlat_out
 
   );

   -- synthesis translate_on

end synth;
