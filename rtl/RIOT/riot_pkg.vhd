-------------------------------------------------------------------------------
--
--   Copyright (C) 2005 Retrocircuits, LLC.
--
--   Title       : RIOT -> Package of useful things
--
--   Description : Useful stuff to make RIOT work
--
--   Author      : Ed Henciak
--
--   Date        : January 20, 2005
--
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

package riot_pkg is

   -- Here is RIOT
   component riot
   port
   (
      -- Clock and reset 
      clk          : in    std_logic; -- input core clock sclk
      reset        : in    std_logic; -- async. input reset
      go_clk       : in    std_logic;
      go_clk_180   : in    std_logic;

      -- IO Ports (Instantiate tristate @ higher level)
      port_a_in    : in  std_logic_vector(7 downto 0);
      port_a_out   : out std_logic_vector(7 downto 0);
      port_a_ctl   : out std_logic_vector(7 downto 0);

      port_b_in    : in  std_logic_vector(7 downto 0);
      port_b_out   : out std_logic_vector(7 downto 0);
      port_b_ctl   : out std_logic_vector(7 downto 0);

      -- Address and data bus (if you want bidir data,
      -- wrap this logic with the included wrapper).
      addr         : in    std_logic_vector(6 downto 0);
      din          : in    std_logic_vector(7 downto 0);
      dout         : out   std_logic_vector(7 downto 0);

      -- Read/write
      rwn          : in    std_logic;

      -- RAM select
      ramsel_n     : in    std_logic;

      -- Chip selects
      cs1          : in    std_logic;
      cs2n         : in    std_logic;

      -- Interrupt (active low...use wrapper for "open drain")
      irqn         : out   std_logic

   );
   end component;

   component xil_riot_ram
   port (

        A   : IN std_logic_VECTOR(6 downto 0);
        CLK : IN std_logic;
        D   : IN std_logic_VECTOR(7 downto 0);
        WE  : IN std_logic;
        I_CE : IN std_logic;
        SPO : OUT std_logic_VECTOR(7 downto 0)
   );
   end component;

   component spram
   generic (
      addr_width    : integer := 8;
      data_width    : integer := 8;
      mem_init_file : string := " ";
      mem_name      : string := "MEM" -- for InSystem Memory content editor.
   );
   port
   (
      clock   : in  STD_LOGIC;
      address : in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
      data    : in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
      enable  : in  STD_LOGIC := '1';
      wren    : in  STD_LOGIC := '0';
      q       : out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
      cs      : in  std_logic := '1'
   );
   end component;

   --------------------------------------------
   -- Useful RIOT stuff
   --------------------------------------------
   type     timer_div_t   is (DIV_1T, DIV_8T, DIV_64T, DIV_1024T);
   constant RESET_1T      : std_logic_vector(9 downto 0) := "0000000000";
   constant RESET_8T      : std_logic_vector(9 downto 0) := "0000000111";
   constant RESET_64T     : std_logic_vector(9 downto 0) := "0000111111";
   constant RESET_1024T   : std_logic_vector(9 downto 0) := "1111111111";


end riot_pkg;
