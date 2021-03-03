-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     : TIA motion control NOR flip flop
--
--   Author    : Ed Henciak 
--
--   Notes     : These are the NOR based flops found in the TIA
--               horizontal motion control downcounter logic.
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

-- Entity declaration

entity tia_mot_nor_flop is
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
end tia_mot_nor_flop;

architecture rtl of tia_mot_nor_flop is

   signal node1            : std_logic;
   signal node2            : std_logic;
   signal feedback_din     : std_logic;
   signal out_data_i       : std_logic;

   signal rst0, rst1, rst2 : std_logic;

begin

   -- Here the reset is delayed a little to allow the
   -- signals to propigate thru the SEC generation 
   -- logic...
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


   -- This process is the "input" process...
   process(h1_clk, rst2)
   begin

       if (rst2 = '1') then
           node1 <= '0';
           node2 <= '0';
       elsif (h1_clk'event and h1_clk = '1') then
           node1 <= input_sig      nor feedback_din;
           node2 <= not(input_sig) nor out_data_i;
       end if;

   end process;

   -- This process latches the output of the nor
   -- and inverts
   process(h2_clk, rst2)
   begin
 
       if (rst2 = '1') then
           out_data_i <= '0';
       elsif(h2_clk'event and h2_clk = '1') then
           out_data_i <= node1 or node2;
       end if;

   end process;

   -- Drive feedback and output
   feedback_din <= not(out_data_i);
   out_signal   <= feedback_din;
   out_data     <= out_data_i;
   out_chain    <= not(input_sig) nor (out_data_i);

end rtl;





 
