-----------------------------------------------------------------------------------------------
--
--   File        : tia_clocking_and_reset.vhd
--
--   Author      : Ed Henciak 
--
--   Date        : February 17, 2005
--
--   Description : This circuit takes an input clock that is 4x the oscillator 
--                 frequency that typically drives TIA and creates various 
--                 clock enables and reference clock signals so that events in TIA 
--                 can be emulated with 100% accuracy while maintaining a 100% 
--                 synchronous design to keep the FPGA timing analysis happy. 
--
--                 For NTSC, the 1x clock frequency is roughly 3.579545MHz. 
--                 For PAL,  the 1x clock frequency is slightly higher @ 4.43361875 MHz.
--                 This is the color subcarrier frequency for each standard.
--
--                 Again, this logic expects this clock to be 4x either of those 
--                 frequencies for accurate emulation.
--
--                 This logic also drives the various resets in the TIA component.
--
--   Update      : 1/23/2015 : * It's been a while since 2005.  Wow!
--                             * Input clock should be 4x the NTSC or PAL color clock.
--                             * Added a clock enable for the 4x clock in case the input
--                               clock is a higher speed clock.
--                             * Made all resets synchronous.
--                             * Renamed "sys_clk" "sclk", renamed "pix_clk" "pclk" 
--                               and "cpu_clk" "cclk".
--                             * Did a far better job defining events to assert sclk
--                               and pclk enables.
--                             * Moved CPU clock generation to this component (as well as
--                               the gate level reference structure).  Made the CPU clock
--                               generation a lot more explicit/easier to understand vs.
--                               the old way.
--
--                             So, here's the overall plan for the new clocking circuit.  
--                             The input clock should be at least 4x the pixel clock.
--                             The pixel clock runs at 3.579545MHz on NTSC systems.
--                             Ideally, you want to provide a 14.31818181818 clock
--                             (for NTSC), but something close will suffice.  Be aware 
--                             that EVERYTHING is derived from this clock ... a wrong frequency
--                             could lead to things like audio being too high/low pitched
--                             when comparing this implementation to a real Atari 2600.  The
--                             same holds true on a real Atari.  If you drove a real Atari 
--                             with a crystal that was +/- several KHz off, the exact same 
--                             phenomena would occur.  
--
-----------------------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;

library a2600;
    use a2600.tia_pkg.all;

-- synthesis translate_off
library A2600_sim;
    use A2600_sim.tia_sim_comps.all;
-- synthesis translate_on

entity tia_clocking_and_reset is
port
(

    -- Master Clock and Master Reset 
    clk            : in  std_logic; -- Input clock.
    clk_ena        : in  std_logic; -- ^^^ clock enable if rate is > 4x NTSC/PAL clock.
    reset          : in  std_logic; -- Initiates an Atari system reset
                                    -- Don't confuse ^^^ with the user reset switch!
    -- TIA reset control to sync CPU
    ctl_rst_cpu    : in  std_logic; -- TIA reset control to sync CPU clock

    -- TIA chipwide (reset TIA internally, RIOT, and 6502)
    tia_reset      : out std_logic;

    -- "Clock" signals used for combinational circuits.  These
    -- do NOT clock flip flops under any circumstances.
    sclk           : out std_logic; -- CLK on the TIA schematics
    pclk           : out std_logic; -- PCLK on the TIA schematics
    cclk           : out std_logic; -- The CPU clock.

    -- synthesis translate_off
    -- Structural CPU clock generator output for simulation reference
    cclk_simcomp   : out std_logic;
    -- synthesis translate_on

    -- Next up are the clock enables.  These signals correspond to the
    -- rising and falling edges of the actual clock in the device.
    -- They trigger so that we can register data on the rising edge
    -- of "clk" at the exact same time it would be registered in a
    -- real TIA device.

    -- CPU clock enables (div 3 NTSC/PAL color clock)
    cclk_re        : out std_logic; -- CPU CLK rising edge
    cclk_fe        : out std_logic; -- CPU CLK falling edge (also rising edge of 180
                                    -- degree out of phase clock).
    -- TIA 'clk' clock enables 
    sclk_re        : out std_logic; -- TIA system clock rising edge
    sclk_fe        : out std_logic; -- TIA system clock falling edge

    -- TIA Pixel 'pclk' clock enables
    pclk_re        : out std_logic; -- Pixel clock rising edge
    pclk_fe        : out std_logic  -- Pixel clock falling edge

);
end tia_clocking_and_reset;

architecture struct of tia_clocking_and_reset is

    -- Number of cycles TIA reset is delayed WRT the reset input
    constant TIA_RESET_DELAY : positive range 2 to integer'high := 3;

    -- Timing signals set/cleared with respect to the input clock :

    -- Timing related to the TIA "clk" clock (we call it sclk)
    signal sclk_i            : std_logic;
    signal sclk_re_i         : std_logic;
    signal sclk_fe_i         : std_logic;

    -- Timing related to the TIA "pclk" clock.
    signal pclk_i            : std_logic;
    signal pclk_re_i         : std_logic;
    signal pclk_fe_i         : std_logic;

    -- Timing related to the TIA CPU clock (PHI0)
    signal cclk_i            : std_logic;
    signal cclk_re_i         : std_logic;
    signal cclk_fe_i         : std_logic;

    -- Signal used to disable clock enables during powerup.
    signal disable_ena_n     : std_logic;

    -- Main clock divider counter
    signal clk_div_cnt       : positive range 1 to 4;
    signal clk_div_lock_n    : std_logic;

    -- Resync/reset CPU clock
    signal cclk_reset         : std_logic;
    signal cclk_latched_reset : std_logic;

    -- Signals used to generate the reference signals WRT CPU clock
   
    -- State vector
    type cclk_state_t is (CCLK_START, CCLK_WAIT_2_RE, CCLK_WAIT_1_FE);
    signal cclk_state : cclk_state_t; 

    -- Delay flag for 2nd SCLK rising edge detect
    signal del_sec_sclk_re : std_logic;

    -- Signals used for TIA reset.
    signal tia_reset_chain : std_logic_vector(TIA_RESET_DELAY-1 downto 0); 
    signal tia_reset_i     : std_logic;

begin

    -- Here we have a small set of flops to create the "TIA reset"
    -- signal.  It's simply the component's reset signal delayed.
    process(clk)
    begin

        if rising_edge(clk) then

            if (reset = '1') then

                tia_reset_chain <= (others => '1');

            else

                -- Delay chain for reset output.
                tia_reset_chain(0) <= reset;
                for i in 1 to TIA_RESET_DELAY-1 loop
                    tia_reset_chain(i) <= tia_reset_chain(i-1);
                end loop; 

            end if;

        end if;

    end process;

    -- Drive the TIA reset out to the rest of the world.
    tia_reset_i <= tia_reset_chain(TIA_RESET_DELAY-1);

    -- This logic generates the TIA system clock reference as well
    -- as the pixel clock reference from the "x4" clock source.
    process(clk)
    begin
 
         if rising_edge(clk) then
 
             if (tia_reset_i = '1') then

                 sclk_i        <= '0';
                 sclk_re_i     <= '0';
                 sclk_fe_i     <= '0';

                 pclk_i        <= '0';
                 pclk_re_i     <= '0';
                 pclk_fe_i     <= '0';
 
                 disable_ena_n <= '0';

                 clk_div_cnt   <= 1;

             else

                 -- Defaults
                 sclk_re_i     <= '0';
                 sclk_fe_i     <= '0';
                 pclk_re_i     <= '0';
                 pclk_fe_i     <= '0';

                 -- Enable toggles when "clk" is higher than 4x
                 -- the NTSC/PAL color clock. Otherwise it is high
                 -- all of the time.
                 if (clk_ena = '1') then

                     case clk_div_cnt is

                         when 1   => sclk_re_i      <= '1';
                                     pclk_fe_i      <= disable_ena_n;
                                     disable_ena_n  <= '1';              

                         when 2   => sclk_i         <= '1';
                                     pclk_i         <= '0';

                         when 3   => sclk_fe_i      <= '1';
                                     pclk_re_i      <= '1';
                                         
                         when 4   => sclk_i         <= '0';
                                     pclk_i         <= '1';

                     end case;

                     -- Advance the counter
                     if (clk_div_cnt = 4) then
                         clk_div_cnt <= 1;
                     else
                         clk_div_cnt <= clk_div_cnt + 1;
                     end if;

                 end if;
 
             end if;
 
         end if;
 
    end process;

    -- CCLK generator reset
    cclk_reset <= tia_reset_i or ctl_rst_cpu;

    -- CCLK latched reset/resync logic
    cclk_rst_0 : tia_clocking_and_reset_crst_latch
    port map
    (
        clk                => clk, 
        clk_ena            => clk_ena,
        reset              => reset,
        ctl_rst_cclk       => cclk_reset,
        cclk_latched_reset => cclk_latched_reset
    );

    -----------------------------------------------------
    -- This logic generates the CPU clock and references.
    -- We need a state machine to emulate the clock 
    -- properly.
    -----------------------------------------------------
    process(clk)
    begin

        if rising_edge(clk) then

            if (cclk_latched_reset = '1') then

                cclk_i          <= '0';
                del_sec_sclk_re <= '0';
                cclk_state      <= CCLK_START;

            else

                case cclk_state is
 
                    when CCLK_START =>
                   
                        -- When we see our first rising edge
                        -- reference out of reset, assert CCLK. 
                        if (sclk_fe_i = '1') then
                            cclk_i     <= '1';
                            cclk_state <= CCLK_WAIT_2_RE;
                        end if;

                    when CCLK_WAIT_2_RE =>

                        -- Here we have to wait for the second
                        -- rising edge of sclk ... on that edge
                        -- we want to drive CCLK low.
                        if (sclk_re_i = '1') then

                            if (del_sec_sclk_re = '0') then
                                del_sec_sclk_re <= '1';
                            else
                                del_sec_sclk_re <= '0';
                                cclk_i          <= '0';
                                cclk_state      <= CCLK_WAIT_1_FE;
                            end if;

                        end if;

                    when CCLK_WAIT_1_FE =>

                        -- Here we simply wait for one SCLK
                        -- falling edge and head back to IDLE
                        if (sclk_fe_i = '1') then
                            cclk_state <= CCLK_START;
                        end if;

                end case;

            end if;

        end if;

    end process;

    -- These gates create the cclk rising and falling edge references.
    process(cclk_state, sclk_fe_i, sclk_re_i, cclk_latched_reset)
    begin

        -- Determine when to drive the CCLK rising edge reference.
        if ((cclk_state         = CCLK_START) and 
            (sclk_fe_i          = '1')        and 
            (cclk_latched_reset = '0')) then

            cclk_re_i <= '1';
        else
            cclk_re_i <= '0';
        end if;

        -- Determine when to drive the CCLK falling edge reference.
        if ((cclk_state         = CCLK_WAIT_2_RE) and 
            (sclk_re_i          = '1')            and 
            (del_sec_sclk_re    = '1')            and
            (cclk_latched_reset = '0'))           then

            cclk_fe_i <= '1';
        else
            cclk_fe_i <= '0';
        end if;
    
    end process;

    -- Concurrent signal assignments to drive out
    -- useful signals across TIA and to the external
    -- CPU ...
    cclk         <= cclk_i and not(cclk_latched_reset);
    cclk_re      <= cclk_re_i;
    cclk_fe      <= cclk_fe_i;
 
    sclk         <= sclk_i;
    sclk_re      <= sclk_re_i;
    sclk_fe      <= sclk_fe_i;

    pclk         <= pclk_i;
    pclk_re      <= pclk_re_i;
    pclk_fe      <= pclk_fe_i;

    tia_reset    <= tia_reset_i;

    ------------------------------------------------------
    -- TIA gate level component for simulation purposes
    -- only ... use this to insure more abstract VHDL
    -- techniques are 100% identical to the real thing ...
    ------------------------------------------------------

    -- synthesis translate_off

    ---------------------------------------------------
    -- This component here is a gate level description
    -- of the TIA's CPU clock generator.  I made this
    -- so that the above "abstract" description can be
    -- compared against the real design...this is not
    -- synthesized at all...it is here for simulation
    -- reference...be aware that if the clk and reset
    -- lines switch states at the exact same simulation
    -- times, the simulation will halt due to a race
    -- condition error.  This would happen in the real
    -- chip too though the error would resolve itself
    ---------------------------------------------------
    
    ref_cpu_clk_0 : tia_struct_cclk
    port map(

        clk  => sclk_i,
        rst  => cclk_reset,

        cclk => cclk_simcomp
    );

    -- synthesis translate_on

end struct;
