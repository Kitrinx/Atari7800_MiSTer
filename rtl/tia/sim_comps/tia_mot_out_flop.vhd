-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     : TIA horizontal motion circuit output flop
--
--   Author    : Ed Henciak 
--
--   Notes     : This simulates the output flip flop circuit of the
--               TIA motion logic.  This should be used in simulation 
--               only!
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

-- Entity declaration

entity tia_mot_out_flop is
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
end tia_mot_out_flop;

architecture rtl of tia_mot_out_flop is

    signal upper_node  : std_logic;
    signal lower_node  : std_logic;
    signal up_rslt_h2  : std_logic;
    signal lo_rslt_h2  : std_logic;
    signal up_nor_out  : std_logic;
    signal low_inv_out : std_logic;
    signal rst0        : std_logic;
    signal rst1        : std_logic;
    signal rst2        : std_logic;

begin

   -- We need to delay the deassertion of reset by a few
   -- cycles since it's going to be in a don't care state
   process(h2_clk, reset)
   begin

       if (reset = '1') then

           rst0 <= '1';
           rst1 <= '1';
           rst2 <= '1';

       elsif (h2_clk'event and h2_clk = '1') then

           rst0 <= reset;
           rst1 <= rst0;
	   rst2 <= rst1;

       end if;

   end process; 

            
          

   -- This is all the nonsense clocked by the H1 clock
   process(h1_clk, rst2)
   begin

       if (rst2 = '1') then

           upper_node <= '1';
           lower_node <= '1';

       elsif (h1_clk'event and h1_clk = '1') then

           upper_node <= sec nor up_nor_out;
           lower_node <= not(adv);
   
       end if;

   end process;

   -- More nonsense clocked by the H2 clock
   process(h2_clk, rst2)
   begin

       if (reset = '1') then

           up_rslt_h2 <= '1';
           lo_rslt_h2 <= '0';

       elsif (h2_clk'event and h2_clk = '1') then

           up_rslt_h2 <= upper_node;
           lo_rslt_h2 <= lower_node;

       end if;

   end process;

   -- Invert H2 clock lower output
   low_inv_out <= not(lo_rslt_h2);

   -- Drive H2 results into the NOR gate
   up_nor_out <=  low_inv_out nor up_rslt_h2;

   -- Output NAND gate...DONE! HA HA
   out_ebl_n <= h1_clk nand up_nor_out;


end rtl;





 
