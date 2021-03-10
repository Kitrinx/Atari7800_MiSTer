-------------------------------------------------------------------------------
--
--   File        : tia_missile_obj.vhd
--
--   Author      : Ed Henciak 
--
--   Description : Atari 2600 TIA Missile Object Logic
--
--                 Mimics the missile logic!
--
--   Date        : February 13, 2005
--
--   Updates     : 1/21/2015 (the future) : Migrated to numeric_std
--                                          Switched from async. to sync resets.
--                
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

library a2600;
    use a2600.tia_pkg.all;

entity tia_missile_obj is
port
(

   -- Clocks and resets
   clk           : in  std_logic; -- System clock (x2)
   pix_clk       : in  std_logic; -- Pixel clock
   reset         : in  std_logic; -- System reset

   -- synthesis translate_off
   -- These are for simulation reference only
   motclk        : in  std_logic;
   mis_mot_n     : in  std_logic;
   -- synthesis translate_on

   -- These signals move the object counter
   -- for synthesis applications ;)
   mis_mot       : in  std_logic;
   adv_obj       : in  std_logic;

   -- Missile number/size info
   mis_num       : in  std_logic_vector(2 downto 0);
   mis_siz       : in  std_logic_vector(1 downto 0);

   -- Missile enable
   mis_ena       : in  std_logic;

   -- Player to missile reset enable
   m2p_ena       : in  std_logic;

   -- Reset the missile strobe
   resmis        : in  std_logic;

   -- Missile to player reset strobe
   m2p_reset     : in std_logic;

   -- Serialized missile graphic bit...
   g_mis         : out std_logic

);
end tia_missile_obj;

architecture synth of tia_missile_obj is

   -- Resets the missile counter
   signal reset_mis_ctr   : std_logic;

   -- Indicates that the missile counter should be
   -- cleared immediately...
   signal clear_mis, 
          clear_mis_cnt_i : std_logic;

   -- Enable the missile object counter
   signal enable_misctr   : std_logic;

   -- M1 and M2 clocks used for reference...
   signal m1_clk          : std_logic;
   signal m2_clk          : std_logic;

   -- Player pos. counter from the count logic...
   signal cur_mis_cnt     : seq_int;

   -- Signal to clear the current missile counter
   signal clear_mis_cnt   : std_logic;

   -- Tap of missile clock divider...
   signal mis_tap         : std_logic;

   -- Signals used to indicate start and end graphics...
   signal start_i         : std_logic;
   signal end_i           : std_logic;

   -- Start signals delayed by missile clock pairs
   signal start_del_1, 
          start_del_2     : std_logic;

   -- Group of gates that shape the missile
   signal go_missile      : std_logic;
   signal mis_tapper      : std_logic;
   signal mis_resize      : std_logic;
   signal mis_size_2      : std_logic;
   signal mis_size_1      : std_logic;
   signal mis_bit         : std_logic;

   -- synthesis translate_off
   signal mis_clk         : std_logic; -- For simulation only...
   -- synthesis translate_on

begin

   -- synthesis translate_off
   -- "Real" missile clock.
   mis_clk       <= motclk or not(mis_mot_n);
   -- synthesis translate_on

   -- Generate the reset for this section of TIA
   reset_mis_ctr <= resmis or reset or (m2p_ena and m2p_reset);

   -- This component shall govern the operation
   -- of this missile object with respect to the
   -- system clock multiplied and phase aligned
   -- to the main osicllator clock...
   pl_ena_0 : tia_enabler
   port map
   (

      clk        => clk,
      reset      => reset,
      noblank    => adv_obj,
      hmotion    => mis_mot,
      obj_enable => enable_misctr

   );

   -- Instantiate the sequencer circuit that
   -- mimics the LFSR...
   missile_seq : tia_sequencer
   port map
   (

      -- synthesis translate_off
      sim_clk   => mis_clk,
      -- synthesis translate_on
      clk       => clk,
      reset     => reset,
      enable    => enable_misctr,
      reset_ctr => clear_mis_cnt, 
      rlat_in   => reset_mis_ctr, 
      p1_clk    => m1_clk,
      p2_clk    => m2_clk,
      p1_ena    => open,
      p2_ena    => open,
      cnt_out   => cur_mis_cnt,
      rlat_out  => clear_mis,
      tap_out   => mis_tap

   );

   -- Decode counter and take number of players into
   -- account.  We'll size them using gates below... 
   process(cur_mis_cnt, mis_num)
   begin

         -- By default, keep these guys off
         start_i <= '0';
         end_i   <= '0';

         case cur_mis_cnt is

             -- Only one or start of three
             when MISSILE_START_1 => if (mis_num = DUO_C) or
                                        (mis_num = TRIO_C) then
                                         start_i <= '1';
                                     end if;

             -- Start of 2 or continue 3
             when MISSILE_START_2 => if (mis_num = TRIO_C) or
                                        (mis_num = DUO_M)  or
                                        (mis_num = TRIO_M) then
                                         start_i <= '1';
                                     end if;

             -- Wide two or number three
             when MISSILE_START_3 => if (mis_num = DUO_W) or
                                        (mis_num = TRIO_M) then
                                         start_i <= '1';
                                     end if; 

             -- A start signal is fired at the end of  
             -- the missile count as well as an end_i
             -- signal...cute, huh?
             when MISSILE_END     => end_i   <= '1';
                                     start_i <= '1';

             when others          => start_i <= '0';
                                     end_i   <= '0';

         end case;

   end process;

   -- Either of these starts to clear the LFSR.
   clear_mis_cnt_i <= end_i or clear_mis;

   -- Generate the clear signal
   mis_end_0 : tia_d_flop
   generic map(
      flop_style   => REGULAR_D
   )
   port map
   (

       clk         => clk,
       reset       => reset,
       reset_gate  => '0', 
       p1_clk      => m1_clk,
       p2_clk      => m2_clk,
       data_in     => clear_mis_cnt_i, 
       p1_out      => open,
       p2_out      => clear_mis_cnt

   );

   -- Start signal delayed by one pair of missile clocks
   mis_del_1 : tia_d_flop
   generic map(
      flop_style   => REGULAR_D
   )
   port map
   (

       clk         => clk,
       reset       => reset,
       reset_gate  => '0', 
       p1_clk      => m1_clk,
       p2_clk      => m2_clk,
       data_in     => start_i,
       p1_out      => open,
       p2_out      => start_del_1

   );

   -- Start signal delayed by two pairs of missile clocks.
   mis_del_2 : tia_d_flop
   generic map(
      flop_style   => REGULAR_D
   )
   port map
   (

       clk         => clk,
       reset       => reset,
       reset_gate  => '0', 
       p1_clk      => m1_clk,
       p2_clk      => m2_clk,
       data_in     => start_del_1, 
       p1_out      => open,
       p2_out      => start_del_2

   );

   -- Enables a missile bit...
   go_missile <= not(m2p_ena) and mis_ena;

   -- Size gate based on missile clock tapper
   mis_tapper <= not(mis_tap) and mis_siz(0); 

   -- Missile bit resizer based on m2 clock
   mis_resize <= m2_clk or mis_siz(1) or mis_tapper;

   -- Another missile resize gate...
   mis_size_2 <= start_del_1 and go_missile and mis_resize;

   -- Double missile gate....
   mis_size_1 <= go_missile and mis_siz(0) and start_del_2 and mis_siz(1);

   -- Final missile bit...
   mis_bit    <= mis_size_1 or mis_size_2;

   -- The output bit registered on the pixel clock
   process(clk)
   begin

       if rising_edge(clk) then

           if (reset = '1') then

              g_mis <= '0';

           else

              if (pix_clk = '1') then
                 g_mis <= mis_bit;
              end if;

           end if;

       end if;

   end process;

end synth;

