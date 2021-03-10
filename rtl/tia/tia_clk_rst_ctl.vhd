-------------------------------------------------------------------------------
--
--   Copyright (C) 2005
--
--   Title     :  Atari 2600 TIA Clock and Reset Generation circuit
--
--   Author    :  Ed Henciak 
--
--   Notes     :  This circuit takes an input clock that is twice the
--                typical oscillator clock frequency used by the Atari
--                2600 (for NTSC, this is roughly 3.58MHz X 2, PAL is slightly
--                faster).
--
--                From here, reference signals are derived so that the
--                entire design can be cloked by this single source.
--
--                Moreover, this block of logic generates the reset 
--                signal that the entire system uses.
--
--                Finally, reference signals are used so that simulation
--                primitives can be observed  (i.e. "real" TIA behavior).
--                
--   Date      :  February 17, 2005
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_unsigned.all;
    use IEEE.std_logic_arith.all;

library A2600;
    use A2600.tia_pkg.all;

entity tia_clk_rst_ctl is
port
(

   -- Master Clock and Master Reset 
   clk            : in  std_logic; -- Main FPGA/ASIC system clock 
   master_reset   : in  std_logic; -- Master system reset (i.e. POR)

   -- synthesis translate_off
   -- Reference "real" clocks for simulation purposes
   ref_sys_clk    : out std_logic;
   ref_pix_clk    : out std_logic;
   -- synthesis translate_on

   cpu_p0_ref     : out std_logic; -- CPU P0 reference
   cpu_p0_ref_180 : out std_logic; -- CPU P0 reference (180 deg. oop)

   -- System reset (deasserted once clocks are stable)
   system_reset   : out std_logic;

   -- These signals provide reference to both
   -- the rising and falling edge of the main
   -- oscillator input...
   ena_sys        : out std_logic; -- System clock rising edge
   ena_pix        : out std_logic; -- System clock 180 oop 

   -- CPU clock I/O 
   ctl_rst_cpu    : in  std_logic; -- TIA control to sync CPU
   cpu_clk        : out std_logic  -- Main CPU clock output

);
end tia_clk_rst_ctl;

architecture struct of tia_clk_rst_ctl is

    -- Synchronous reset pipeline
    signal r1, r2, master_reset_sync : std_logic;

    -- Internal master reset
    signal master_reset_i            : std_logic;

    -- Clocking reference signals
    signal pix_clk_ref_i : std_logic;
    signal sys_clk_ref_i : std_logic;
    signal go_clocks     : std_logic;

    -- Resync CPU clock
    signal reset_cpu_clk : std_logic;

    -- Signals used to generate a system reset.
    signal system_reset_i : std_logic;
    signal sys_rst_cnt    : std_logic_vector(3 downto 0);

    -- Controls clocks
    signal clk_reset_i    : std_logic;
    signal clk_rst_cnt    : std_logic_vector(3 downto 0);

    signal mrst_del1      : std_logic;
    signal mrst_del2      : std_logic;

    -- Signals used for simulation only
    -- synthesis translate_off
    signal ref_sys_clk_i  : std_logic;
    signal ref_pix_clk_i  : std_logic;
    -- synthesis translate_on

begin

   -------------------------------------
   -- This logic allows master reset to
   -- assert asynchronously and deassert 
   -- synchronously.
   -------------------------------------
   process(clk)
   begin

       if(clk'event and clk = '1') then
          r1                <= master_reset;
          r2                <= r1;
          master_reset_sync <= r2;
       end if;

   end process;

   master_reset_i <= master_reset_sync or master_reset;

   ----------------------------------------------------------
   -- This logic generates the system clock reference as well
   -- as the pixel clock reference from the "x2" clock source
   ----------------------------------------------------------
   process(master_reset_i, clk)
   begin

       if (master_reset_i = '1') then

           pix_clk_ref_i <= '0';
           sys_clk_ref_i <= '0';
           go_clocks     <= '0';

       elsif(clk'event and clk = '1') then

           -- Enable clocks
           go_clocks     <= '1';

           -- Divide system clock by two WRT clk_2x
           sys_clk_ref_i <= not(sys_clk_ref_i);

           -- Divide system clock by two!
           if (go_clocks = '1') then
               pix_clk_ref_i <= not(pix_clk_ref_i);
           end if;

       end if;

   end process;

   -- Delay CPU clock reset for 2 cycles after master reset
   process(clk, master_reset_i)
   begin 

       if (master_reset_i = '1') then

           mrst_del1 <= '1';
           mrst_del2 <= '1';

       elsif (clk'event and clk = '1') then

           mrst_del1 <= master_reset_i;
           mrst_del2 <= mrst_del1;

       end if;

   end process;

   -------------------------------------------------------------
   -- This component generates the CPU clock and references
   -------------------------------------------------------------

   -- First, create the signal that will disable the CPU clock
   -- generator...
   reset_cpu_clk <= mrst_del2 or ctl_rst_cpu;
   
   -- Next, this component generates the CPU clock... 
   cpu_clk_gen_0 : tia_cpu_clk_gen
   port map
   (
      -- synthesis translate_off
      ref_clk    => ref_sys_clk_i,
      -- synthesis translate_on
      clk        => clk,
      reset      => reset_cpu_clk,
      ena        => sys_clk_ref_i,
      ena_180    => pix_clk_ref_i,
      p0_ref     => cpu_p0_ref,
      p0_ref_180 => cpu_p0_ref_180,
      clk_out    => cpu_clk

   );

   -- Concurrent signal assignments to drive out
   -- useful signals across TIA...
   ena_sys      <= sys_clk_ref_i;
   ena_pix      <= pix_clk_ref_i;
   system_reset <= master_reset_i;


   -- Simulation only below...

   -- This creates the reference clocks used by simulation
   -- primitives throughout the design...

   -- synthesis translate_off
   ref_pix_clk_i <= sys_clk_ref_i;
   ref_sys_clk_i <= pix_clk_ref_i;
   ref_pix_clk   <= ref_pix_clk_i;
   ref_sys_clk   <= ref_sys_clk_i;
   -- synthesis translate_on


end struct;
