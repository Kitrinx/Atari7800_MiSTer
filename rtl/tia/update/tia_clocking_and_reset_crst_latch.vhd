-----------------------------------------------------------------------------------------------
--
--   File        : tia_clocking_and_reset_crst_latch.vhd
--
--   Author      : Ed Henciak 
--
--   Date        : January 27, 2015
--
--   Description : This circuit waits for a rising edge on the cpu clock's reset signal.
--                 It is latched using a D flip flop.  The 'latch' is held high until the
--                 next rising edge of 'clk' (this is done so that CCLK generation logic 
--                 sees the reset request).  The latch is then cleared.
--
--                 The latch output is ORed with the regular cpu clock reset signal.
--
--                 This circuit assumes that "clk" is running at 4x the rate of the TIA
--                 main system clock ('clk' on the schematics).
--
--                 We need this exotic behavior so that the TIA CPU clock generator circuit
--                 is emulated accurately.  Any high going pulse of a minimum pulse width
--                 will cause a reset of the SR latches that generate CCLK.  My original TIA
--                 description did not do this accurately.  It might have explained a few
--                 strange issues I saw in games like Ghostbusters, but I am not 100% sure 
--                 about that.  I can certainly re-verify after I get this up and running.
--
-----------------------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;

entity tia_clocking_and_reset_crst_latch is
port
(

    -- Master Clock and Master Reset 
    clk                : in  std_logic;
    clk_ena            : in  std_logic; -- The rate limit clock enable if > x4 TIA 'clk'
    reset              : in  std_logic; 
                                    
    -- TIA reset control to sync CPU
    ctl_rst_cclk       : in  std_logic;

    -- The 'latched' reset that resync's the CPU clock logic.
    cclk_latched_reset : out std_logic 

);

    -- We need some attributes to insure synthesis doesn't go
    -- treating 'ctl_rst_cclk' like a genuine "clock" in the 
    -- FPGA.  Altera should have similar attributes.
    attribute clock_signal       : string;
    attribute clock_signal of ctl_rst_cclk : signal is "yes";
    attribute buffer_type        : string;
    attribute buffer_type of ctl_rst_cclk : signal is "none";

end tia_clocking_and_reset_crst_latch;

architecture struct of tia_clocking_and_reset_crst_latch is

    -- Flip flops that capture the "sclk_re" input on the 
    -- rising and falling edges of the input clock "clk".
    signal clk_re_det : std_logic;
    signal clk_fe_det : std_logic; 

    -- Signal that clears the cclk reset latch.
    signal clear_cclk_rst_latch_i : std_logic;
    signal clear_latch_n          : std_logic;

    -- The cclk reset latch output.
    signal cclk_latched_reset_i : std_logic;

begin

    -- Create the latch clear signal
    clear_latch_n <= '0' when (clear_cclk_rst_latch_i = '1') or (reset = '1') else '1';

    -- First up is the latching process.  We set the latch when we
    -- have a rising edge on the ctl_rst_cclk signal.  The latch is
    -- cleared asynchronously during the time when sclk_re is active
    -- and "clk" is high.
    process(ctl_rst_cclk, clear_latch_n)
    begin

        if (clear_latch_n = '0') then
            cclk_latched_reset_i <= '0';
        elsif rising_edge(ctl_rst_cclk) then
            cclk_latched_reset_i <= '1';
        end if;

    end process;

    -- Next, we need a means of SAFELY detecting when the "clk" 
    -- input is high AND we have an active sclk_re signal ...
    -- What we need to do is register sclk_re on both the rising
    -- and falling edge of "clk" ...

    -- Clock on the rising edge.
    process(clk)
    begin
        if rising_edge(clk) then
            if (reset = '1') then
                clk_re_det <= '0';
            else
                if (clk_ena = '1') then
                    clk_re_det <= cclk_latched_reset_i;
                end if;
            end if;
        end if;
    end process;

    -- Clock on the falling edge.
    process(clk)
    begin
        if falling_edge(clk) then

            if (reset = '1') then
                clk_fe_det <= '0';
            else
                if (clk_ena = '1') then
                    clk_fe_det <= clk_re_det;
                end if;
            end if;
        end if;
    end process;

    -- Clear out the CPU clock reset latch ...
    clear_cclk_rst_latch_i <= '1' when ((clk_re_det = '1') and (clk_fe_det = '0')) else '0';

    -- Concurrent output ...
    cclk_latched_reset <= cclk_latched_reset_i or ctl_rst_cclk;

end struct;
