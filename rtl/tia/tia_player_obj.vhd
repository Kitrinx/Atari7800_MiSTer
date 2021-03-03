-------------------------------------------------------------------------------
--
--   Copyright (C) 2005
--
--   Title     :  Atari 2600 TIA Player Object Logic
--
--   Author    :  Ed Henciak 
--
--   Notes     :  Mimics the player sprite logic accurately!
--
--   Date      :  February 1, 2005
--                
-------------------------------------------------------------------------------

-- synthesis library tia

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_unsigned.all;
    use IEEE.std_logic_arith.all;

library A2600;
    use A2600.tia_pkg.all;

    -- synthesis translate_off
    use A2600.tia_sim_comps.all;
    -- synthesis translate_on

entity tia_player_obj is
port
(

   -- Clocks and resets
   clk           : in  std_logic; -- System clock (x2)
   pix_clk       : in  std_logic; -- Pixel clock reference
   reset_sys     : in  std_logic; -- System reset

   -- synthesis translate_off
   -- These are for simulation reference only
   motclk        : in  std_logic;
   pl_mot_n      : in  std_logic;
   -- synthesis translate_on

   -- These signals move the object counter
   -- for synthesis applications ;)
   pl_mot        : in  std_logic;
   adv_obj       : in  std_logic;

   -- Player number/size info
   nusiz         : in  std_logic_vector(2 downto 0);

   -- Player reflect & vdelay bit.
   pl_refl       : in  std_logic;
   pl_vdel       : in  std_logic;

   -- Player sprite registers
   play_new      : in  std_logic_vector(7 downto 0);
   play_old      : in  std_logic_vector(7 downto 0);
   
   -- Reset the player counter strobe
   respl         : in  std_logic;

   -- Missile to player reset
   m2p_reset     : out std_logic;

   -- Serialized player graphic bit...
   g_pl          : out std_logic

);
end tia_player_obj;


architecture struct of tia_player_obj is

   -- Resets the player counter
   signal reset_pl_ctr : std_logic;

   -- Indicates that the player counter should be
   -- cleared immediately...
   signal clear_pl, 
          clear_pl_cnt_i : std_logic;

   -- Enable the player object counter
   signal enable_plctr : std_logic;

   -- P1 and P2 clocks used for reference...
   signal p1_clk : std_logic;
   signal p2_clk : std_logic;

   -- Player pos. counter from the count logic...
   signal cur_pl_cnt : seq_int;

   -- Used to indicate motion
   signal fstob     : std_logic;

   -- Signal to clear the current player counter
   signal clear_pl_cnt : std_logic;

   -- Start and end counter signals (pre flip flop)
   signal start_i   : std_logic;
   signal start_n_i : std_logic;
   signal start_n   : std_logic;
   signal end_i     : std_logic;

   -- Signals used to control and generate the player sprite
   -- counter
   signal n1, n2         : std_logic;
   signal count_n        : std_logic;
   signal enable_n       : std_logic;
   signal start_ctr      : std_logic;
   signal stop_ctr       : std_logic;
   signal plr_pix_ctr    : std_logic_vector(2 downto 0);
   signal enable_pix_ctr : std_logic;

   -- Signals used to both mux player sprites
   -- and reflect player sprites.
   signal old            : std_logic;
   signal oldr           : std_logic;
   signal new_p          : std_logic;
   signal new_pr         : std_logic;

   -- Current selected pixel
   signal pl_pix         : std_logic;

   -- Player clock reference for the missile to player
   -- reset pulse...
   signal int_clock      : std_logic;
   signal m2p_clk        : std_logic;
   signal m2p_motion     : std_logic_vector(1 downto 0);

   -- Logical 0 for those of you in Rio Linda
   signal gnd             : std_logic;

   -- synthesis translate_off
   signal pl_clk          : std_logic; -- For simulation only...
   signal ref_plr_pix_cnt : std_logic_vector(2 downto 0);
   signal bitsel          : std_logic_vector(2 downto 0);
   -- synthesis translate_on

begin

   -- Ground!
   gnd <= '0';

   -- synthesis translate_off
   -- "Real" player clock.
   pl_clk <= motclk or not(pl_mot_n);
   -- synthesis translate_on

   -- Generate the reset for this section of TIA
   reset_pl_ctr <= respl or reset_sys;

   -- This component shall govern the operation
   -- of this player object with respect to the
   -- system clock multiplied and phase aligned
   -- to the main osicllator clock...
   pl_ena_0 : tia_enabler
   port map
   (

      clk        => clk,
      reset      => reset_sys,
      noblank    => adv_obj,
      hmotion    => pl_mot,
      obj_enable => enable_plctr

   );

   -- Instantiate the sequencer circuit that
   -- mimics the LFSR...
   player_seq : tia_sequencer
   port map
   (

      -- synthesis translate_off
      sim_clk   => pl_clk,
      -- synthesis translate_on
      clk       => clk,
      reset_sys => reset_sys,
      enable    => enable_plctr,
      reset_ctr => clear_pl_cnt, 
      rlat_in   => reset_pl_ctr, 
      p1_clk    => p1_clk,
      p2_clk    => p2_clk,
      p1_ena    => open,
      p2_ena    => open,
      cnt_out   => cur_pl_cnt,
      rlat_out  => clear_pl,
      tap_out   => open

   );

   -- Decode counter and take number of players into
   -- account.  We'll size them using gates below... 
   process(cur_pl_cnt, nusiz)
   begin

         -- Keep these guys low by default...
         start_i <= '0';
         end_i   <= '0';

         case cur_pl_cnt is

             -- Only one or start of three
             when PLAYER_START_1 => if (nusiz = DUO_C) or
                                       (nusiz = TRIO_C) then
                                        start_i <= '1';
                                    end if;

             -- Start of 2 or continue 3
             when PLAYER_START_2 => if (nusiz = TRIO_C) or
                                       (nusiz = DUO_M)  or
                                       (nusiz = TRIO_M) then
                                        start_i <= '1';
                                    end if;

             -- Wide two or number three
             when PLAYER_START_3 => if (nusiz = DUO_W) or
                                       (nusiz = TRIO_M) then
                                        start_i <= '1';
                                    end if; 

             when PLAYER_END     => end_i   <= '1';

             when others         => start_i <= '0';
                                    end_i   <= '0';

         end case;

   end process;

   -- Either of these starts to clear the LFSR.
   clear_pl_cnt_i <= end_i or clear_pl;

   -- Generate the clear signal
   play_end_0 : tia_d_flop
   generic map(
      flop_style   => REGULAR_D
   )
   port map
   (

      clk         => clk,
      reset       => reset_sys,
      reset_gate  => gnd, 
      p1_clk      => p1_clk,
      p2_clk      => p2_clk,
      data_in     => clear_pl_cnt_i, 
      p1_out      => open,
      p2_out      => clear_pl_cnt

   );

   -- This flop stores the FSTOB signal
   fstob_0 : tia_d_flop
   generic map(
      flop_style   => FEEDBK_RST
   )
   port map
   (

      clk         => clk,
      reset       => reset_sys,
      reset_gate  => clear_pl_cnt, 
      p1_clk      => p1_clk,
      p2_clk      => p2_clk,
      data_in     => start_i, 
      p1_out      => open,
      p2_out      => fstob

   );

   -- This flop delays start_n by a P1 P2 duo
   start_n_i <= start_i nor end_i;

   play_start_0 : tia_d_flop
   generic map(
      flop_style   => REGULAR_D
   )
   port map
   (

      clk         => clk,
      reset       => reset_sys,
      reset_gate  => gnd, 
      p1_clk      => p1_clk,
      p2_clk      => p2_clk,
      data_in     => start_n_i, 
      p1_out      => open,
      p2_out      => start_n

   );

   -- These gates generate the count_n signal (kick the player
   -- pixel counter).  They're useful for sprite stretching...
   n1      <= p1_clk  and not(nusiz(1));
   n2      <= not(nusiz(2) and nusiz(0)); 
   count_n <= not(n1 or n2 or p2_clk);

   -- This flop stores the count_n signal and
   -- generates ena_n as a result.
   process(reset_sys, clk)
   begin

       if (reset_sys = '1') then
           enable_n <= '1';
       elsif(clk'event and clk = '1') then
           if (enable_plctr = '1') then
              enable_n <= count_n;
           end if;
       end if;

   end process;

   -- All of this lovely logic controls the player pixel counter.
   start_ctr   <= not(start_n)  and not(enable_n);

   stop_ctr    <= not(enable_n) and (start_n and (plr_pix_ctr(0) and 
                                                  plr_pix_ctr(1) and
                                                  plr_pix_ctr(2)));
   -- Our silly player sprite counter...
   process(reset_sys, clk)
   begin

       if (reset_sys = '1') then

           plr_pix_ctr    <= "000";
           enable_pix_ctr <= '0';

       elsif(clk'event and clk = '1') then

           if (enable_plctr = '1') then

              -- Advance counter when enabled...
              if (enable_pix_ctr = '1') and (enable_n = '0') then
                  plr_pix_ctr <= plr_pix_ctr + 1;
              end if;

              -- Enable the counter
              if (start_ctr = '1') then
                  enable_pix_ctr <= '1';
              end if;

              -- Disable the counter
              if (stop_ctr = '1') then
                  enable_pix_ctr <= '0';
              end if;

           end if;

       end if;

   end process;

   -- And our subsequent silly simulation model
   -- synthesis translate_off
--   sim_cnt_0 : tia_pcnt_sim
--   port map
--   (
--
--      pl_clk     => pl_clk,
--      reset_sys  => reset_sys,
--      enable_n   => enable_n,
--      start_n    => start_n,
--      pcnt       => ref_plr_pix_cnt
--
--
--   );
--
--   bitsel(2) <= not((ref_plr_pix_cnt(2) and not(pl_refl)) or (not(ref_plr_pix_cnt(2)) and pl_refl));
--   bitsel(1) <= not((ref_plr_pix_cnt(1) and not(pl_refl)) or (not(ref_plr_pix_cnt(1)) and pl_refl));
--   bitsel(0) <= not((ref_plr_pix_cnt(0) and not(pl_refl)) or (not(ref_plr_pix_cnt(0)) and pl_refl));
--
--
   -- synthesis translate_on

   -- Determines the proper pixel to output...
   process(plr_pix_ctr, play_old, play_new)
   begin

        case plr_pix_ctr is

           when "000"  => old    <= play_old(7);
                          oldr   <= play_old(0);
                          new_p  <= play_new(7);
                          new_pr <= play_new(0);

           when "001"  => old    <= play_old(6);
                          oldr   <= play_old(1);
                          new_p  <= play_new(6);
                          new_pr <= play_new(1);

           when "010"  => old    <= play_old(5);
                          oldr   <= play_old(2);
                          new_p  <= play_new(5);
                          new_pr <= play_new(2);

           when "011"  => old    <= play_old(4);
                          oldr   <= play_old(3);
                          new_p  <= play_new(4);
                          new_pr <= play_new(3);

           when "100"  => old    <= play_old(3);
                          oldr   <= play_old(4);
                          new_p  <= play_new(3);
                          new_pr <= play_new(4);

           when "101"  => old    <= play_old(2);
                          oldr   <= play_old(5);
                          new_p  <= play_new(2);
                          new_pr <= play_new(5);

           when "110"  => old    <= play_old(1);
                          oldr   <= play_old(6);
                          new_p  <= play_new(1);
                          new_pr <= play_new(6);

           when others => old    <= play_old(0);
                          oldr   <= play_old(7);
                          new_p  <= play_new(0);
                          new_pr <= play_new(7);


        end case;

   end process;

   -- This determines the pixel to output when we're enabled.
   process(enable_pix_ctr, 
           pl_vdel, pl_refl, 
           oldr,    old,
           new_pr,  new_p)
   begin

       -- If the pixel counter is enabled, then
       -- we're going to drive a valid pixel!
       if (enable_pix_ctr = '1') then

           -- If we're driving the "old" player
           -- sprite, we fall to here...
           if (pl_vdel = '1') then

               -- Do we drive the reflected sprite?
               if (pl_refl = '1') then
                   pl_pix <= oldr;
               else
                   pl_pix <= old;
               end if;

           -- Drive the "current" sprite...
           else
                 
               -- Should we drive a reflected sprite? 
               if (pl_refl = '1') then
                   pl_pix <= new_pr;
               else
                   pl_pix <= new_p;
               end if;

           end if;

       else

           -- Else, output nothing...
           pl_pix <= '0';

       end if;

   end process;

   process(reset_sys, clk)
   begin

       if (reset_sys = '1') then

           g_pl <= '0';

       elsif (clk'event and clk = '1') then

           if (pix_clk = '1') then
              g_pl <= pl_pix;
           end if;

       end if;

   end process;

   -- And finally, we need to generate the missile to player
   -- reset signal...you'd think this would be SOOOOOOOOOO easy,
   -- but it isn't "that" simple...
   
   -- First, we have to generate a signal that represents the
   -- player clock that TIA generates via gating.  Yes, I have
   -- this signal for simulation purposes, but I cannot use it
   -- since we'd be gating the clock in the FPGA...so, to avoid
   -- a zinz of epic proportions, we must do the following...

   -- This process simply latches the value of enable_plctr
   -- on the rising edge of the clock...this will give us
   -- a player clock reference....mostly...
   -- Clock pulses generated by motion are two cycles long...
   process(clk)
   begin

       if (clk'event and clk = '1') then

           -- int_clock simply gets enable_plctr...
           int_clock <= enable_plctr;

           -- Most of the time, motion_1 will be low...
           m2p_motion(0)  <= '0';

           -- ...unless we see motion enabled!
           if (enable_plctr = '1') and (pl_mot = '1') then
              m2p_motion(0)  <= '1';
           end if;

           -- Pipe the motion bit...
           m2p_motion(1)  <= m2p_motion(0);

       end if;

   end process;

   -- Our silly missile to player reference clock...
   m2p_clk <= int_clock or m2p_motion(1);

   -- And, finally, the logic which generates the missile
   -- to player reset signal....this is gated with the 
   -- enable signal in the missile logic...
   process(m2p_clk, enable_n, fstob, plr_pix_ctr)
   begin

         if (m2p_clk     = '0')   and
            (enable_n    = '0')   and
            (fstob       = '0')   and
            (plr_pix_ctr = "100") then 

             m2p_reset <= '1';

         else

             m2p_reset <= '0';

         end if;

   end process;

end struct;

