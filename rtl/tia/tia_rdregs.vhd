-------------------------------------------------------------------------------
--
--   Copyright (C) 2004 Retrocircuits, LLC.
--
--   Title       : TIA -> Read Registers
--
--   Description : This logic routes read requests back to the outside
--                 world.
--
--   Author      : Ed Henciak
--
--                 All constants, subtypes, tricks, trinkets and what-not
--                 are found in the TIA package.
--
--   Date        : December 18, 2004
--
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

library A2600;
    use A2600.tia_pkg.all;

-- Entity declaration

entity tia_rdregs is
port
(
   -- Address bus from the outside world
   addr         : in  std_logic_vector( 5 downto 0);

   -- Input data bus (i.e. float emulation)
   din          : in  std_logic_vector( 7 downto 0);

   -- Data output
   dout         : out std_logic_vector( 7 downto 0);

   -- Collision vector input
   cx_vector    : in  std_logic_vector(14 downto 0);
 
   -- Input latch/pot threshold registers
   input_lat    : in  std_logic_vector( 5 downto 0) 

);
end tia_rdregs;

architecture rtl of tia_rdregs is

begin

    -- This process is entirely combinational.  It muxes out
    -- read data based on the input address.
    process (addr, cx_vector, input_lat)
    begin

         -- DEfault
         dout <= (others => '0');

         -- Decode address and see what we should do
         case addr(3 downto 0) is

             -- First are the collision latches

             when CXM0P_A  => dout(7) <= cx_vector(COL_M0P1);
                              dout(6) <= cx_vector(COL_M0P0);
                              --dout(5 downto 0) <= din(5 downto 0);

             when CXM1P_A  => dout(7) <= cx_vector(COL_M1P0); 
                              dout(6) <= cx_vector(COL_M1P1);
                              --dout(5 downto 0) <= din(5 downto 0);
                              

             when CXP0FB_A => dout(7) <= cx_vector(COL_P0PF); 
                              dout(6) <= cx_vector(COL_P0BL);
                              --dout(5 downto 0) <= din(5 downto 0);

             when CXP1FB_A => dout(7) <= cx_vector(COL_P1PF); 
                              dout(6) <= cx_vector(COL_P1BL);
                              --dout(5 downto 0) <= din(5 downto 0);

             when CXM0FB_A => dout(7) <= cx_vector(COL_M0PF); 
                              dout(6) <= cx_vector(COL_M0BL);
                              --dout(5 downto 0) <= din(5 downto 0);

             when CXM1FB_A => dout(7) <= cx_vector(COL_M1PF); 
                              dout(6) <= cx_vector(COL_M1BL);
                              --dout(5 downto 0) <= din(5 downto 0);

             when CXBLPF_A => dout(7) <= cx_vector(COL_BLPF); 
                              --dout(6 downto 0) <= din(6 downto 0);

             when CXPPMM_A => dout(7) <= cx_vector(COL_P0P1); 
                              dout(6) <= cx_vector(COL_M0M1);
                              --dout(5 downto 0) <= din(5 downto 0);

             -- Next are the input latches!

             when INPT0_A  => dout(7) <= input_lat(0); 
                              --dout(6 downto 0) <= din(6 downto 0);
             when INPT1_A  => dout(7) <= input_lat(1); 
                              --dout(6 downto 0) <= din(6 downto 0);
             when INPT2_A  => dout(7) <= input_lat(2); 
                              --dout(6 downto 0) <= din(6 downto 0);
             when INPT3_A  => dout(7) <= input_lat(3); 
                              --dout(6 downto 0) <= din(6 downto 0);
             when INPT4_A  => dout(7) <= input_lat(4); 
                              --dout(6 downto 0) <= din(6 downto 0);
             when INPT5_A  => dout(7) <= input_lat(5); 
                              --dout(6 downto 0) <= din(6 downto 0);

             -- Default if a useless read address is registered.
             when others   => dout <= (others => '0');

         end case;


    end process;

end rtl;
