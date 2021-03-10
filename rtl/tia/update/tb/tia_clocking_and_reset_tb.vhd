-------------------------------------------------------------------------------------------------
--
--   Filename      : tia_clk_rst_ctl_tb.vhd
--
--   Author        : Ed Henciak
--
--   Date          : December 25 2014
--
--   Description   : Tests TIA's clocking component.
--
-------------------------------------------------------------------------------------------------
library shared_sim_components;
    use shared_sim_components.shared_sim_components_pkg.all;
    use shared_sim_components.shared_sim_textio_utils_pkg.all;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library a2600;
    use a2600.tia_pkg.all;

entity tia_clocking_and_reset_tb is
end tia_clocking_and_reset_tb;

architecture test of tia_clocking_and_reset_tb is

    -- Clock for stimulus driving.
    signal clk            : std_logic;
    signal reset          : std_logic;

    -- Reference "real" clocks for simulation purposes
    signal sclk           : std_logic;
    signal pclk           : std_logic;
    signal cclk           : std_logic; -- CPU P0 reference

    -- Structural simulation of TIA's CPU clock (i.e. PHI0 clock).
    signal cclk_simcomp   : std_logic;
    
    -- System reset (deasserted 3 cycles after "reset" )
    signal tia_reset      : std_logic;
    
    -- These signals provide reference to both
    -- the rising and falling edge of the main
    -- oscillator input...
    signal cclk_re        : std_logic;
    signal cclk_fe        : std_logic;
    signal sclk_re        : std_logic;
    signal sclk_fe        : std_logic;
    signal pclk_re        : std_logic;
    signal pclk_fe        : std_logic;
    
    -- CPU clock I/O 
    signal ctl_rst_cpu_i    : std_logic; -- TIA control to sync CPU
    signal ctl_rst_cpu      : std_logic; -- TIA control to sync CPU

begin

    -- 10MHz simulation clock
    clka_0 : s_sim_clockgen_v1_00_a
    generic map (
        CLK_PERIOD  => 100 ns
    ) 
    port map (
    
        clkout   => clk,
        clkout_n => open
    
    );

    -- Here we drive the TIA "ctl_rst_cpu_i" varying widths to insure
    -- that the CPU PHI0 clock remains in sync with the rest of
    -- the TIA component ...
    process
        variable pass_cnt  : natural := 0;
        variable rst_width : time    := 1 ns;
        variable shift_time : time   := 10 ns;
    begin

        -- Power up in the reset state.  Hold it
        -- for a few microseconds.
        reset         <= '1';
        ctl_rst_cpu_i <= '0';
        wait for 5 us;
        reset         <= '0';

        while (pass_cnt < 200) loop

            reset <= '1';
            wait for 1 us;
            reset <= '0';
            wait for (3 us + shift_time);

            ctl_rst_cpu_i <= '1';
            wait for rst_width;
            ctl_rst_cpu_i <= '0';

            wait for 5 us;

            -- Advance counts.
            shift_time := shift_time + 10 ns;
            pass_cnt  := pass_cnt + 1;

        end loop;

        reset <= '1';
        wait for 1 us;

        reset       <= '0'; 
        ctl_rst_cpu_i <= '0';

        wait;

    end process;

    ctl_rst_cpu <= ctl_rst_cpu_i after 1 ns;

    -- TIA clock / reset component.
    uut_0 : tia_clocking_and_reset
    port map
    (
    
        -- Master Clock and Master Reset 
        clk            => clk,
        clk_ena        => '1',
        reset          => reset,

        -- TIA reset control to sync CPU
        ctl_rst_cpu    => ctl_rst_cpu,
    
        -- Atari system reset (reset TIA internally, RIOT, and 6502)
        tia_reset      => tia_reset,
    
        -- "Clock" signals used for combinational circuits.  These
        -- do NOT clock flip flops under any circumstances.
        sclk           => sclk,
        pclk           => pclk,
        cclk           => cclk,

        -- Structural CPU clock for simulation comparison.
        cclk_simcomp   => cclk_simcomp,
    
        -- Next up are the clock enables.  These signals correspond to the
        -- rising and falling edges of the actual clock in the device.
        -- They trigger so that we can register data on the rising edge
        -- of "clk" at the exact same time it would be registered in a
        -- real TIA device.
    
        -- CPU clock enables (div 3 NTSC/PAL color clock)
        cclk_re        => cclk_re,
        cclk_fe        => cclk_fe,
                                        -- degree out of phase clock).
        -- TIA 'clk' clock enables 
        sclk_re        => sclk_re,
        sclk_fe        => sclk_fe,
    
        -- TIA Pixel 'pclk' clock enables
        pclk_re        => pclk_re,
        pclk_fe        => pclk_fe
    
    );



end test;
