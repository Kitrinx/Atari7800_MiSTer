-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  Package of useful things for simulating TIA.
--                This should never be synthesized.  If you do,
--                a giant hedgehog searching for Dinsdale will 
--                get you!  Yes, YOU!
--
--   Author    :  Ed Henciak 
--
-------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;

package tia_sim_comps is

   -- Here are the component decalrations...have a nice day...

   -- CPU clock SR Flop...
   component tia_cclk_sr_flop
   port(

        clk : in  std_logic;
        rst : in  std_logic;

        s_n : in  std_logic;
        r_n : in  std_logic;

        mp  : out std_logic;

        q   : out std_logic;
        q_n : out std_logic
   );
   end component;

   -- The TIA "F1" SR flop...
   component tia_f1_sr_flop
   port(

        clk : in std_logic;
        rst : in std_logic;

        s_n : in std_logic;
        r_n : in std_logic;

        q   : out std_logic;
        q_n : out std_logic
   );
   end component;

   -- The TIA "F3" SR flop...
   component tia_f3_sr_flop
   port(

        clk  : in std_logic;
        rst  : in std_logic;

        s_n  : in std_logic;
        s1_n : in std_logic;
        r_n  : in std_logic;
        r1_n : in std_logic;

        q    : out std_logic;
        q_n  : out std_logic
   );
   end component;

   -- TIA LFSR counter...
   component tia_lfsr
   port(

      p1_clk   : in std_logic;
      p2_clk   : in std_logic;
      reset    : in std_logic;

      lfsr_out : out std_logic_vector(5 downto 0)
   );
   end component;

   -- TIA NOR based SR latch...
   component tia_nor_lat
   port(

        set    : in std_logic;
        rst    : in std_logic;

        output : out std_logic 
   );
   end component;

   -- TIA SR clock divide by four circuit...
   component tia_sr_clk_div
   port(

        clk    : in  std_logic;
        rst    : in  std_logic;

        tap    : out std_logic;

        p1_clk : out std_logic;
        p2_clk : out std_logic

   );
   end component;

   -- TIA CPU clock generation circuit...
   component tia_struct_cclk
   port(

        clk  : in  std_logic;
        rst  : in  std_logic;

        cclk : out std_logic
   );
   end component;

   -- TIA "NOR" based FF used in the horizontal 
   -- motion logic.
   component tia_mot_nor_flop
   port
   (

      -- Clock and reset 
      h1_clk     : in  std_logic;
      h2_clk     : in  std_logic;
      reset      : in  std_logic;

      -- "Chain" input signal
      input_sig  : in  std_logic;

      -- Output signals
      out_data   : out std_logic;
      out_signal : out std_logic;
      out_chain  : out std_logic

   );
   end component;

   -- Horizontal motion reference downcounter
   component tia_hmotion_dcnt
   port
   (

      -- Clock and reset 
      h1_clk     : in  std_logic;
      h2_clk     : in  std_logic;
      reset      : in  std_logic;

      -- SEC pulse from pulse generator
      sec        : in  std_logic;

      -- Downcounter output
      dcnt_out   : out std_logic_vector(3 downto 0)

   );
   end component;

   -- This component is the whole horizontal motion
   -- circuit for "gate level simulations".
   component tia_hmotion_sim 
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
   end component;

   component tia_mot_out_flop
   port
   (

      -- Clock and reset 
      h1_clk     : in  std_logic;
      h2_clk     : in  std_logic;
      reset      : in  std_logic;

      -- Start motion signal
      sec        : in  std_logic;

      -- Advance pulse from the control circuit
      adv        : in  std_logic;

      -- Output enable signal
      out_ebl_n  : out std_logic

   );
   end component;

   component tia_pcnt_sim
   port
   (

      -- Clock and reset 
      pl_clk     : in  std_logic;
      reset_sys  : in  std_logic;

      -- Control signals from player logic
      enable_n   : in  std_logic;
      start_n    : in  std_logic;

      -- Counter output
      pcnt       : out std_logic_vector(2 downto 0)


   );
   end component;


end tia_sim_comps;

