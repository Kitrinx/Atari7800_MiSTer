-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     : Horizontal motion reference downcounter.
--
--   Author    : Ed Henciak 
--
--   Notes     : This is the downcounter to the right of the motion 
--               registers when looking at the schematics of the TIA.
--               
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

library a2600;
    use a2600.tia_sim_comps.all;

-- Entity declaration

entity tia_hmotion_dcnt is
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
end tia_hmotion_dcnt;

architecture sim of tia_hmotion_dcnt is

    signal mot_pd       : std_logic_vector(3 downto 0);
    signal mot_pull_sig : std_logic;

    signal mot_in       : std_logic;
    signal motd         : std_logic_vector(3 downto 0);
    signal chain        : std_logic_vector(3 downto 0); 

begin

    -- This simulates the freaky NMOS pulldown transistor
    -- happiness that acts as a way rad feedback
    -- comparitor to see if we should stop counting.
    process(mot_pd)
    begin

        if (mot_pd = "0000") then
            mot_pull_sig <= '1';
        else
            mot_pull_sig <= '0';
        end if;

    end process;

    -- NAND gate that drives the counter control signal
    mot_in <= not(sec) nand mot_pull_sig;

    -- Here we instantiate the four "nor" flops that
    -- are chained together to form the downcounter.

    mot_nor_0 : tia_mot_nor_flop
    port map
    (

       h1_clk     => h1_clk,
       h2_clk     => h2_clk,
       input_sig  => mot_in,
       reset      => reset,
       out_data   => motd(0),
       out_signal => mot_pd(0),
       out_chain  => chain(0)

    );

    mot_nor_1 : tia_mot_nor_flop
    port map
    (

       h1_clk     => h1_clk,
       h2_clk     => h2_clk,
       input_sig  => chain(0),
       reset      => reset,
       out_data   => motd(1),
       out_signal => mot_pd(1),
       out_chain  => chain(1)

    );

    mot_nor_2 : tia_mot_nor_flop
    port map
    (

       h1_clk     => h1_clk,
       h2_clk     => h2_clk,
       input_sig  => chain(1),
       reset      => reset,
       out_data   => motd(2),
       out_signal => mot_pd(2),
       out_chain  => chain(2)

    );

    mot_nor_3 : tia_mot_nor_flop
    port map
    (

       h1_clk     => h1_clk,
       h2_clk     => h2_clk,
       input_sig  => chain(2),
       reset      => reset,
       out_data   => motd(3),
       out_signal => mot_pd(3),
       out_chain  => chain(3)

    );

    -- Send the down counter value out the door...
    dcnt_out <= motd;

end sim;
