-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  Atari 2600 TIA Sequencing circuit
--
--   Author    :  Ed Henciak 
--
--   Notes     :  This component represents the divide by four clock,
--                reset latch, and LFSR found in all TIA object components.
-- 
--                Simulation primitives are instantiated so that "real" 
--                functionality can be compared to that which is synthesized.
--
--   Date      :  December 29, 2004
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_arith.all;
    use IEEE.std_logic_unsigned.all;

library A2600;
    use A2600.tia_pkg.all;

    -- synthesis translate_off
    use A2600.tia_sim_comps.all;
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

   -- Clock input (main oscillator clock)
   clk       : in  std_logic;

   -- System reset (power-on reset)
   reset_sys : in  std_logic;

   -- Enable input...this allows the internal
   -- logic to advance.
   enable    : in  std_logic;

   -- This reset clears the counter.
   -- This is generally used by the 
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


architecture behave of tia_sequencer is

    -- Signals used to divide the inbound clock and
    -- generate clock enables
    signal tick_cnt       : std_logic_vector(1 downto 0) := "11";
    signal p1_clk_i       : std_logic;
    signal p2_clk_i       : std_logic;
    signal clk_tap        : std_logic;
    signal inv_clk_tap    : std_logic;
  
    -- Internal reset
    signal counter_reset  : std_logic;
    signal counter_reset_s : std_logic := '1';

    -- Signals used to generate an output sequence
    -- value....these replace the values generated
    -- by the LFSR.
 
    -- Current counter output
    signal cnt_out_i      : seq_int;

    -- Phase one logic
    signal cnt_out_p1_c   : seq_int; -- "Combinational"
    signal cnt_out_p1_s   : seq_int; -- "Sequential"
    signal cnt_out_p1     : seq_int; -- "Latch output"
 
    -- Phase two logic
    signal cnt_out_p2_c   : seq_int; -- "Combinational"
    signal cnt_out_p2_s   : seq_int; -- "Sequential"
    signal cnt_out_p2     : seq_int; -- "Latch Output"

    -- Signals used to create "synchronous" rlat_in
    signal rlat_in_fe     : std_logic;
    signal master_rlat_in : std_logic;
    signal rlat_out_s     : std_logic;
    signal rlat_out_a     : std_logic;

    -- synthesis translate_off

    -- These signals are used for simulation purposes
    -- only.  They will never make it into the FPGA
    signal ref_tap      : std_logic;
    signal ref_inv_tap  : std_logic;
    signal ref_p1_clk   : std_logic;
    signal ref_p2_clk   : std_logic;
    signal ref_rlat_out : std_logic;
    signal ref_lfsr_vec : std_logic_vector(5 downto 0);

    -- synthesis translate_on

begin

   -- Grab Rlat on the falling edge of the clock...this is
   -- our "synced" clearing signal...we're basically insuring
   -- that rlat_in gets the hold time that it needs...in effect,
   -- we're doing a virtual asynchronous assert, synchronous deassert
   -- style of reset.
   process(reset_sys, clk)
   begin
  
       if (reset_sys = '1') then
           rlat_in_fe <= '0';
       elsif(clk'event and clk = '0') then
           rlat_in_fe <= rlat_in;
       end if;

   end process;

   -- Create the "master" rlat_in signal...
   master_rlat_in <= rlat_in or rlat_in_fe;
   --master_rlat_in <= rlat_in_fe;
 
   -----------------------------------------------------
   -- This sequential process provids the counter to 
   -- divide the inbound clock...
   -----------------------------------------------------
   process(master_rlat_in, clk)
   begin

       if (master_rlat_in = '1') then

           tick_cnt <= "11"; -- Was 11

       elsif(clk'event and clk = '1') then

           if (enable = '1') then
               tick_cnt <= tick_cnt + 1;
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

              when "11"   => clk_tap  <= '1';
                             p2_ena   <= '1';

              when others => null;

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
   counter_reset <= reset_ctr or reset_sys;

   process(clk)
   begin
 
        if (clk'event and clk = '1') then
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

       if(clk'event and clk = '1') then

           -- Snag this value when P1 is active
           if (p1_clk_i = '1') then
               cnt_out_p1_s <= cnt_out_p1_c;
           end if;

       end if;

   end process;

   -- Output of phase 1 latch
 --  cnt_out_p1 <= cnt_out_p1_c when (p1_clk_i = '1') else cnt_out_p1_s;

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
       if(clk'event and clk = '1') then

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
   process(clk, reset_sys)
   begin

       if (reset_sys = '1') then
           rlat_out_s <= '0';
       elsif(clk'event and clk = '0') then
           rlat_out_s <= rlat_out_a;
       end if;

   end process;

   -- ehenciak
   --rlat_out <= rlat_out_s or rlat_out_a;
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
   --
   -- IT'S ...
   ---------------------------------------------------

   -- Turn the synthesizer off! We don't want it to
   -- see this silly nonsense!

   -- synthesis translate_off

   -- Here we are going to instantiate the real logic 
   -- found in TIA to insure that timing and the like
   -- are all correct...these components should not be
   -- synthesized since they contain a lot of constructs
   -- synthesis tools generally do not like... 

   -- First is the divide by four clock...this also gives
   -- us the "tap" used by the missile counter as well as
   -- the "all clear" signal used by the reset latch...
   ----sim_sr_clk_div_0 : tia_sr_clk_div
   ----port map(
 
   ----  clk    => sim_clk, 
   ----  rst    => rlat_in,
   ----  tap    => ref_tap,
   ----  p1_clk => ref_p1_clk,
   ----  p2_clk => ref_p2_clk
 
   ----);
 
   ------ Invert the "tap" signal for the SR latch...
   ----ref_inv_tap <= not(ref_tap);
 
   ------ Here we put a nice LFSR so that we can see that our
   ------ integer value matches the one output by the TIA LFSR
   ------ on the current p2 cycle.
   ----sim_lfsr_0 : tia_lfsr
   ----port map(
 
   ----  p1_clk   => ref_p1_clk,
   ----  p2_clk   => ref_p2_clk,
   ----  reset    => reset_ctr,
   ----  lfsr_out => ref_lfsr_vec
 
   ----);
 
   ------ Finally, here's a gate level model of the SR latch
   ------ used in this circuit.  The one used in the TIA emulation
   ------ is more of a D Flip flop with its input tied to Vdd
   ------ and async. clear used to reset the latch.
   ----sim_latch_0 : tia_nor_lat
   ----port map(
 
   ----  set    => rlat_in,       -- Yep, set reset with a reset...hmmm
   ----  rst    => ref_inv_tap,
   ----  output => ref_rlat_out
 
   ----);

   -- And now we can get back to our regularly scheduled 
   -- program. If you're in England, then its your regularly
   -- scheduled programme.  On BBC 1, there is the "Evening News",
   -- on BBC 2, there is "Not the Evening News"...

   -- synthesis translate_on

end behave;
