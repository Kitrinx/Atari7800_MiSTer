-------------------------------------------------------------------------------
--
--   File        : tia_ball_obj.vhd 
--
--   Author      : Ed Henciak 
--
--   Date        : January 29, 2005
--
--   Description : Atari 2600 TIA heh heh Ball Object Logic 
--
--                 The "heh heh" is a tribute to that brilliant duo
--                 Beavis and Butthead....sorry if they never made it to
--                 your part of the world...take solice in the fact that 
--                 "you're" IQ probably didn't suffer as a result of watching
--                 it.  I guess that's a good thing.
--
--                 HEh heh....thing.....
--
--                 They would have loved this logic.
--
--   Update      : 1-20-2015 ... Wow, we're in the future!
--                               Made all resets synchronous ... better for 
--                               modern FPGAs.  Probably want to add clk_2x 
--                               clock enables here ...
--
--                               Also, Beavis and Butthead made a return to
--                               MTV in 2011 I think it was ... it wasn't that
--                               good.  They wouldn't have loved this logic.
--                
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

library a2600;
    use a2600.tia_pkg.all;

entity tia_ball_obj is
port
(

   -- Clock and reset.
   clk            : in  std_logic; -- FPGA System clock
   reset          : in  std_logic; -- System reset

   -- Pixel clock rising edge reference.
   pix_clk_re     : in  std_logic; -- Pixel clock

   -- Simulation signals...

   -- synthesis translate_off
   sim_motclk     : in  std_logic; -- Motion clock
   sim_ball_mot_n : in  std_logic; -- Enable motion
   -- synthesis translate_on

   -- These are the synthesizable enables synchronized
   -- to clk...
   ball_mot       : in  std_logic; -- Enable motion
   adv_obj        : in  std_logic; -- Enable counter.
   
   -- Enable ball graphics bit...from the 
   -- write registers (gating between it 
   -- and the delay info are already taken into
   -- account).
   enabl_n        : in  std_logic;

   -- Reset the ball counter strobe
   -- from the write register file...
   resbl          : in  std_logic;

   -- Ball size (HEH HEHEEH H HEEHEHEH)
   pf_bsize       : in  std_logic_vector(1 downto 0);

   -- Serialized ball graphic bit...
   g_bl           : out std_logic

);
end tia_ball_obj;

architecture synth of tia_ball_obj is

   -- Resets the ball logic...all together...
   -- "Resets the ball logic"
   signal reset_ball_ctr : std_logic;

   -- Tap output of ball counter...turn right and cough.
   signal ball_tap       : std_logic; -- Another wrong sounding signal name

   -- Indicates that the ball counter should be
   -- cleared immediately...
   signal clear_ball     : std_logic;

   -- Even worse, the output of the ball end flip flops.
   -- These would make Beavis and Butthead go to the bathroom.
   signal ball_flop_1    : std_logic;
   signal ball_flop_2    : std_logic;

   -- B1 and B2 clocks used for reference...
   signal b1_clk         : std_logic;
   signal b2_clk         : std_logic;

   -- Ball pos. counter from the count logic...
   signal cur_ball_cnt   : seq_int;

   -- Signal to clear the current ball counter
   signal clear_ball_cnt : std_logic;

   -- Signal that enables the ball counter
   signal enable_ballctr : std_logic;

   -- Ball counter indicates END OF LINE :)!
   signal end_i          : std_logic;

   -- These are all gates that are used to determine 
   -- ball pixel enabling...
   signal bsize_1        : std_logic;
   signal lo_g1          : std_logic;
   signal lo_g2          : std_logic;
   signal bsize_2        : std_logic;
   signal ball_pix       : std_logic;

   -- synthesis translate_off
   signal sim_ball_clk   : std_logic; -- Used for reference...
   -- synthesis translate_on

begin

    -- synthesis translate_off
    -- Ball clock generation for reference
    sim_ball_clk       <= sim_motclk or not(sim_ball_mot_n);
    -- synthesis translate_on

    -- Generate the reset for this section of TIA
    reset_ball_ctr <= resbl or reset;

    -- This circuit generates the enables for
    -- advancing the sequencer...
    bl_ena_0 : tia_enabler
    port map
    (

       clk        => clk,
       reset      => reset,
       noblank    => adv_obj,
       hmotion    => ball_mot,
       obj_enable => enable_ballctr

    );

    -- Instantiate the sequencer circuit that
    -- mimics the LFSR...
    ball_seq_0 : tia_sequencer
    port map
    (

       -- synthesis translate_off
       sim_clk   => sim_ball_clk,
       -- synthesis translate_on
       clk       => clk,
       reset     => reset,
       enable    => enable_ballctr,
       reset_ctr => clear_ball_cnt, 
       rlat_in   => reset_ball_ctr, 
       p1_clk    => b1_clk,
       p2_clk    => b2_clk,
       p1_ena    => open,
       p2_ena    => open,
       cnt_out   => cur_ball_cnt,
       rlat_out  => clear_ball,
       tap_out   => ball_tap

    );
 
    -- This process decodes the current ball counter
    -- so that we can take corrective action based on the
    -- current value!  Unlike others, this one only needs
    -- to decode one critical count
    process(cur_ball_cnt, clear_ball)
    begin

          if (cur_ball_cnt = RESET_BALL_COUNTER) or
             (clear_ball   = '1')               then
              end_i <= '0';
          else
              end_i <= '1';
          end if;

    end process;

    -- Now we need a pair of flip-flops to feed some information
    -- to the serializer...these are clocked on B1 and B2 clocks
    ball_dff_1 : tia_d_flop
    generic map(
       flop_style   => REGULAR_D
    )
    port map
    (

       clk         => clk,
       reset       => reset,
       reset_gate  => '0', 
       p1_clk      => b1_clk,
       p2_clk      => b2_clk,
       data_in     => end_i, 
       p1_out      => open,
       p2_out      => ball_flop_1

    );

    -- The inversion of the first ball flop is
    -- what resets the ball sequencer...
    clear_ball_cnt <= not(ball_flop_1);

    -- The second flip flop 
    ball_dff_2 : tia_d_flop
    generic map(
       flop_style   => REGULAR_D
    )
    port map
    (

       clk         => clk,
       reset       => reset,
       reset_gate  => '0', 
       p1_clk      => b1_clk,
       p2_clk      => b2_clk,
       data_in     => ball_flop_1, 
       p1_out      => open,
       p2_out      => ball_flop_2

    );

    -- Okay, we have a lot of combinational logic to implement @ the serializer...

    -- "Upper" ball size logic
    bsize_1  <= not(pf_bsize(1)) or not(pf_bsize(0)) or ball_flop_2 or enabl_n;

    -- "Lower" ball size logic
    lo_g1    <= ball_tap          or not(pf_bsize(0));
    lo_g2    <= not(pf_bsize(1)) and lo_g1            and not(b2_clk);
    bsize_2  <= enabl_n           or lo_g2             or ball_flop_1;

    -- Ball pixel pre output flip flop.
    ball_pix <= not(bsize_1 and bsize_2);

    -- Output ball pixel
    process(clk)
    begin

        if rising_edge(clk) then

            if (reset = '1') then

               g_bl <= '0';

            else

               if (pix_clk_re = '1') then
                   g_bl <= ball_pix; 
               end if;

            end if;

        end if;
    
    end process;

end synth;
