-------------------------------------------------------------------------------
--
--   Copyright (C) 2005
--
--   Title     : Atari TIA Horizontal motion simulation model
--
--   Author    : Ed Henciak 
--
--   Notes     : Use this to see a gate level sim of the horizontal
--               motion circuit...this circuit is very critical in proper
--               Atari 2600 hardware emulation in that there is a bug
--               that allows nice starfields in Cosmic Arc and Rabbit Transit.
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

library a2600;
    use a2600.tia_sim_comps.all;

entity tia_hmotion_sim is
port
(

   -- Clock and reset 
   h1_clk     : in  std_logic;
   h2_clk     : in  std_logic;
   reset      : in  std_logic;

   -- HMOVE input from registers logic
   hmove      : in  std_logic;
 
   -- Silly 4-bit vectors that represent motion values
   p0_vec     : in  std_logic_vector(3 downto 0);
   p1_vec     : in  std_logic_vector(3 downto 0);
   m0_vec     : in  std_logic_vector(3 downto 0);
   m1_vec     : in  std_logic_vector(3 downto 0);
   bl_vec     : in  std_logic_vector(3 downto 0);

   -- Output control signals which gate the
   -- motion clock.
   p0_ec_n    : out std_logic; -- Player 0 motion clock enable
   p1_ec_n    : out std_logic; -- Player 1 motion clock enable
   m0_ec_n    : out std_logic; -- Missile 0 motion clock enable
   m1_ec_n    : out std_logic; -- Missile 1 motion clock enable
   bl_ec_n    : out std_logic  -- heh heh Ball motion clock enable

);
end tia_hmotion_sim;

architecture behave of tia_hmotion_sim is

   signal cc_nor        : std_logic;
   signal nor_in        : std_logic;

   signal x1_out        : std_logic;
   signal x2_out        : std_logic;
   signal x3_out        : std_logic;
 
   signal ref_sec       : std_logic;

   signal ref_hmot_dcnt : std_logic_vector(3 downto 0);

   signal cmp_p0_vec    : std_logic_vector(3 downto 0);
   signal cmp_p1_vec    : std_logic_vector(3 downto 0);
   signal cmp_m0_vec    : std_logic_vector(3 downto 0);
   signal cmp_m1_vec    : std_logic_vector(3 downto 0);
   signal cmp_bl_vec    : std_logic_vector(3 downto 0);

   signal adv_p0        : std_logic;
   signal adv_p1        : std_logic;
   signal adv_m0        : std_logic;
   signal adv_m1        : std_logic;
   signal adv_bl        : std_logic;

   signal hmove_del     : std_logic;

begin

   hmove_del <= hmove after 0.1 ns;

   ------------------------------------------------------
   -- In the beginning, the motion vectors from the reg.
   -- file have their MSB inverted in this circuit .....
   ------------------------------------------------------
   cmp_p0_vec    <= not(p0_vec(3)) & p0_vec(2 downto 0);
   cmp_p1_vec    <= not(p1_vec(3)) & p1_vec(2 downto 0);
   cmp_m0_vec    <= not(m0_vec(3)) & m0_vec(2 downto 0);
   cmp_m1_vec    <= not(m1_vec(3)) & m1_vec(2 downto 0);
   cmp_bl_vec    <= not(bl_vec(3)) & bl_vec(2 downto 0);

   ------------------------------------------------------
   -- Now, this little bastard generates the SEC pulse...
   ------------------------------------------------------

   -- Cross coupled nors that enable the SEC pulse.
   -- This is basically a latch...
   cc_nor <= x3_out nor nor_in;
   nor_in <= hmove_del  nor cc_nor;

   -- WARNING!!!!! ---->
   -- 3 stage pass gate-latched chain in the next two processes
   -- ahead.  The circuit is some silly pulse generator that requires
   -- voodoo (oooga booga) to make work properly. Proceed with caution. 
   -- Watch for enemy fighters.

   process(h1_clk, reset, cc_nor, x2_out)
   begin

       if (reset = '1') then -- reset here to make simulations work
           x1_out <= '1';
           x3_out <= '1';
       elsif (h1_clk = '1') then -- Latch!
           x1_out <= cc_nor;
           x3_out <= not(x2_out);
       end if;

   end process;

   -- More oooga booga...
   process(h2_clk, x1_out)
   begin

       if (h2_clk = '1') then
           x2_out <= not(x1_out); -- A.K.A. SEC
       end if;
   end process;

   -- OOOGA BOOGA!
   ref_sec <= not(x2_out);

   ----------------------------------------------------------
   -- In all seriousness, this circuit is the four bit down 
   -- counter that is used as a reference to shut off the
   -- motion control outputs seen below.
   ----------------------------------------------------------
   sim_hmot_dcnt_0 : tia_hmotion_dcnt
   port map
   (

      -- Clock and reset 
      h1_clk     => h1_clk,
      h2_clk     => h2_clk,
      reset      => reset,

      -- SEC pulse from pulse generator
      sec        => ref_sec,

      -- Downcounter output
      dcnt_out   => ref_hmot_dcnt

   );

   -------------------------------------------------------------
   -- Next, compare the downcounter to the motion input vectors.
   -- This, in turn, generates the motion advance_n signal.
   -------------------------------------------------------------

   adv_p0 <= '0' when (not(ref_hmot_dcnt) /= cmp_p0_vec) else '1';
   adv_p1 <= '0' when (not(ref_hmot_dcnt) /= cmp_p1_vec) else '1';
   adv_m0 <= '0' when (not(ref_hmot_dcnt) /= cmp_m0_vec) else '1';
   adv_m1 <= '0' when (not(ref_hmot_dcnt) /= cmp_m1_vec) else '1';
   adv_bl <= '0' when (not(ref_hmot_dcnt) /= cmp_bl_vec) else '1';

   ----------------------------------------------------------------------
   -- Five motion control output registers sit here and drive 
   -- the signals that advance the object sequencers.
   ----------------------------------------------------------------------

   -- Note that "adv" should be "adv_n"....I'm too lazy to change it
   -- at this point.

   -- Sim player 0 motion
   p0_mot_out : tia_mot_out_flop
   port map
   (

      h1_clk     => h1_clk,
      h2_clk     => h2_clk,
      reset      => reset,
      sec        => ref_sec,
      adv        => adv_p0,
      out_ebl_n  => p0_ec_n

   );

   -- Sim player 1 motion
   p1_mot_out : tia_mot_out_flop
   port map
   (

      h1_clk     => h1_clk,
      h2_clk     => h2_clk,
      reset      => reset,
      sec        => ref_sec,
      adv        => adv_p1,
      out_ebl_n  => p1_ec_n

   );

   -- Sim missile 0 motion
   m0_mot_out : tia_mot_out_flop
   port map
   (

      h1_clk     => h1_clk,
      h2_clk     => h2_clk,
      reset      => reset,
      sec        => ref_sec,
      adv        => adv_m0,
      out_ebl_n  => m0_ec_n

   );

   -- Sim missile 1 motion
   m1_mot_out : tia_mot_out_flop
   port map
   (

      h1_clk     => h1_clk,
      h2_clk     => h2_clk,
      reset      => reset,
      sec        => ref_sec,
      adv        => adv_m1,
      out_ebl_n  => m1_ec_n

   );

   -- Sim ball motion....heh heh...ball
   bl_mot_out : tia_mot_out_flop
   port map
   (

      h1_clk     => h1_clk,
      h2_clk     => h2_clk,
      reset      => reset,
      sec        => ref_sec,
      adv        => adv_bl,
      out_ebl_n  => bl_ec_n

   );

end behave;



