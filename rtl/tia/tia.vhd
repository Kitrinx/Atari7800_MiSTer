-------------------------------------------------------------------------------
--
--   Copyright (C) 2005
--
--   Title     :  Atari 2600 TIA 
--
--   Author    :  Ed Henciak 
--
--   Notes     :  The classic graphics/audio controller that
--                ruined my life.  Thanks...
--
--   Date      :  January 12, 2005
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

library A2600;
    use A2600.tia_pkg.all;

entity tia is
port
(

    -- Clock and system reset
    clk            : in  std_logic;                    -- Main oscillator clock x2
    master_reset   : in  std_logic;                    -- not on TIA, but useful

    -- System control
    pix_ref        : out std_logic;                    -- Not on TIA...pixel clk reference
    sys_rst        : out std_logic;                    -- Not on TIA...system reset
    cpu_p0_ref     : out std_logic;                    -- CPU P0 reference
    cpu_p0_ref_180 : out std_logic;                    -- CPU P0 reference (180 deg. oop)

    -- synthesis translate_off
    ref_newline    : out std_logic;                    -- Start of line (for debug)
    -- synthesis translate_on

    -- CPU signals
    cpu_p0         : out std_logic;                    -- CPU clock gen. by TIA
    cpu_clk        : in  std_logic;                    -- Phi2 CPU clock
    cpu_cs0n       : in  std_logic;                    -- Chip select 0 (act. low)
    cpu_cs1        : in  std_logic;                    -- Chip select 1 (act. high)
    cpu_cs2n       : in  std_logic;                    -- Chip select 2 (act. low)
    cpu_cs3n       : in  std_logic;                    -- Chip select 3 (act. low)
    cpu_rwn        : in  std_logic;                    -- Read / Write_n
    cpu_addr       : in  std_logic_vector(5 downto 0); -- CPU address
    cpu_din        : in  std_logic_vector(7 downto 0); -- CPU data in
    cpu_dout       : out std_logic_vector(7 downto 0); -- CPU data out
    cpu_rdy        : out std_logic;                    -- Halts CPU if low
   
    -- Controller (or other) input bits
    ctl_in         : in  std_logic_vector(5 downto 0); -- Happy inputs from paddles
                                                    -- and triggers.

    -- Video outputs (blank_n, color & luminance still
    -- require a CLKP register)
    vid_csync      : out std_logic;                    -- Composite sync
    vid_hsync      : out std_logic;                    -- Horiz. sync
    vid_vsync      : out std_logic;                    -- Vert. sync
    vid_lum        : out std_logic_vector(2 downto 0); -- Luminance
    vid_color      : out std_logic_vector(3 downto 0); -- Color 
    vid_cb         : out std_logic;                    -- Color burst 
    vid_blank_n    : out std_logic;                    -- Blank_n
    vid_vblank     : out std_logic;                    -- vblank
    vid_hblank     : out std_logic;

    -- Audio outputs
    aud_ch0        : out std_logic_vector(3 downto 0); -- Audio channel 0
    aud_ch1        : out std_logic_vector(3 downto 0)  -- Audio channel 1

);
end tia;

architecture struct of tia is

    -- Decoded chip select
    signal chip_select     : std_logic;

    -- Here's all the happy, write-only register interconnect.
    -- The mneumonics are taken from the Stella guide.

    -- From the VSYNC register
    signal vsync           : std_logic;

    -- From the VBLANK register
    signal vblank          : std_logic;
    signal vblank_n        : std_logic;
    signal vbl_ena_i4i5    : std_logic;
    signal vbl_dump_prt    : std_logic;

    -- Wait SYNC strobe
    signal wsync           : std_logic;

    -- Reset HSYNC counter
    signal rsync           : std_logic;

    -- Number-size player missile (NUSIZ0 & NUSIZ1)
    signal numpm0          : std_logic_vector(2 downto 0);
    signal sizpm0          : std_logic_vector(1 downto 0);
    signal numpm1          : std_logic_vector(2 downto 0);
    signal sizpm1          : std_logic_vector(1 downto 0);

    -- Color registers (signals represent mneumonics).
    signal colup0          : std_logic_vector(6 downto 0);
    signal colup1          : std_logic_vector(6 downto 0);
    signal colupf          : std_logic_vector(6 downto 0);
    signal colubk          : std_logic_vector(6 downto 0);

    -- Playfield control (CTRLPF)
    signal pf_ref          : std_logic;                    -- Reflection
    signal pf_score        : std_logic;                    -- Score
    signal pf_prio         : std_logic;                    -- Priority
    signal pf_bsize        : std_logic_vector(1 downto 0); -- Ball size

    -- Player reflection bits (signals represent mneumonics).
    signal refp0           : std_logic;
    signal refp1           : std_logic;

    -- Playfield registers (signals represent mneumonics).
    signal pf0             : std_logic_vector(3 downto 0);
    signal pf1             : std_logic_vector(7 downto 0);
    signal pf2             : std_logic_vector(7 downto 0);

    -- Object reset strobes (signals represent mneumonics).
    signal resp0           : std_logic;
    signal resp1           : std_logic;
    signal resm0           : std_logic;
    signal resm1           : std_logic;
    signal resbl           : std_logic;

    -- Silly Audio Control (signals represent mneumonics).
    signal audc0           : std_logic_vector(3 downto 0);
    signal audc1           : std_logic_vector(3 downto 0);
    signal audf0           : std_logic_vector(4 downto 0);
    signal audf1           : std_logic_vector(4 downto 0);
    signal audv0           : std_logic_vector(3 downto 0);
    signal audv1           : std_logic_vector(3 downto 0);

    -- Player graphics (signals represent mneumonics).
    signal old_grp0, grp0  : std_logic_vector(7 downto 0);
    signal old_grp1, grp1  : std_logic_vector(7 downto 0);

    -- Graphics enable bits (signals represent mneumonics).
    signal enam0           : std_logic;
    signal enam1           : std_logic;
    signal enabl_n         : std_logic;

    -- Horizontal Motion values (signals represent mnuemonics).
    signal hmp0            : std_logic_vector(3 downto 0);
    signal hmp1            : std_logic_vector(3 downto 0);
    signal hmm0            : std_logic_vector(3 downto 0);
    signal hmm1            : std_logic_vector(3 downto 0);
    signal hmbl            : std_logic_vector(3 downto 0);

    -- Vertical delay bits
    signal vdelp0          : std_logic;
    signal vdelp1          : std_logic;

    -- Missile reset bits
    signal resmp0          : std_logic;
    signal resmp1          : std_logic;

    -- Horizontal motion clear strobes
    signal hmove           : std_logic;
    signal hmclr           : std_logic;

    -- Collision latch clear strobe
    signal cxclr           : std_logic;

    -- Collision vector interconnect
    signal cx_vector       : std_logic_vector(14 downto 0);

    -- Serialized graphics bits.
    signal g_ball          : std_logic; -- Heh, heh...ball
    signal g_pl_0          : std_logic; -- Player 0 graphics
    signal g_mis_0         : std_logic; -- Missile 0 graphics
    signal g_pl_1          : std_logic; -- Player 1 graphics
    signal g_mis_1         : std_logic; -- Missile 1 graphics
    signal g_playf         : std_logic; -- Playfield graphics

    -- Scanline center indicator (delayed by 1 H2 phase)
    signal cntd            : std_logic;
  
    -- Blank signal generated by the control and playfield logic 
    signal blank_i         : std_logic;

    -- Audio clock signals...these are actually clock enables
    -- for the clk signal.
    signal aud_clk1        : std_logic;
    signal aud_clk2        : std_logic;

    -- Clear the Collision latches
    signal reset_cxlat     : std_logic;

    -- Reference signals for simulation purposes only...
    -- synthesis translate_off
    signal ref_motclk      : std_logic;
    signal ref_en_blm_n    : std_logic;
    signal ref_en_p0m_n    : std_logic;
    signal ref_en_m0m_n    : std_logic;
    signal ref_en_p1m_n    : std_logic;
    signal ref_en_m1m_n    : std_logic;
    -- synthesis translate_on

    -- This signal allows the object counters
    -- to advance (i.e. draw the things!)
    signal adv_obj         : std_logic;

    -- These are the motion signals used
    -- in the synthesizable application...see
    -- objects for details.
    signal ball_mot        : std_logic;
    signal p0_mot          : std_logic;
    signal m0_mot          : std_logic;
    signal p1_mot          : std_logic;
    signal m1_mot          : std_logic;

    -- Missile to player reset pulses
    signal m2p_rst_0       : std_logic;
    signal m2p_rst_1       : std_logic;

    -- Logical 0 
    signal gnd             : std_logic;

    -- SORT THESE LATER

    -- synthesis translate_off
    signal ref_sys_clk     : std_logic;
    signal ref_pix_clk     : std_logic;
    -- synthesis translate_on

    -- These signals provide reference to both
    -- the rising and falling edge of the main
    -- oscillator input...
    signal ena_sys          : std_logic;
    signal ena_pix          : std_logic;
    signal ctl_rst_cpu      : std_logic;
    signal cpu_clk_p0_ref   : std_logic;
    signal cpu_p0_ref_180_i : std_logic;
    signal reset_sys        : std_logic;

    signal g_ball_del       : std_logic;
    signal g_mis_0_del      : std_logic;
    signal g_mis_1_del      : std_logic;
    signal g_pl_0_del       : std_logic;
    signal g_pl_1_del       : std_logic;
    signal hblank           : std_logic;

begin

    -- Here we decode chip select....
    chip_select <= not(cpu_cs0n) and 
                       cpu_cs1   and 
                   not(cpu_cs2n) and 
                   not(cpu_cs3n);

    vid_vblank <= vblank;

    rsync <= '0'; -- Tie off for z26 comparison

    --gnd <= '0';

    -- This component controls clocking and
    -- resets for the system...
    tia_clk_rst_0 : tia_clk_rst_ctl
    port map
    (

       clk            => clk,
       master_reset   => master_reset,
       -- synthesis translate_off
       ref_sys_clk    => ref_sys_clk,
       ref_pix_clk    => ref_pix_clk,
       -- synthesis translate_on
       cpu_p0_ref     => cpu_p0_ref,
       cpu_p0_ref_180 => cpu_p0_ref_180_i,
       system_reset   => reset_sys,
       ena_sys        => ena_sys,
       ena_pix        => ena_pix,
       ctl_rst_cpu    => ctl_rst_cpu,
       cpu_clk        => cpu_clk_p0_ref

    );
 
    -- Concurrent output of CPU clock enable signal... 
    cpu_p0_ref_180 <= cpu_p0_ref_180_i;

    -- Ouput the CPU clock
    cpu_p0         <= cpu_clk_p0_ref;

    -- Pixel clock reference.
    pix_ref        <= ena_pix;

    -- System reset (goes out of 2600 for other devices)
    sys_rst        <= reset_sys;

    -- Instantiate the write registers.
    tia_wregs_0 : tia_wregs
    port map
    (
       clk          => clk,
       clk_ena      => cpu_p0_ref_180_i,
       cpu_clk_ref  => cpu_clk_p0_ref,
       reset_sys    => reset_sys,
       chip_select  => chip_select,
       addr         => cpu_addr,
       din          => cpu_din,
       rwn          => cpu_rwn,
       vsync        => vsync,
       vblank       => vblank,
       --vbl_ena_i4i5 => vbl_ena_i4i5,
       --vbl_dump_prt => vbl_dump_prt,
       wsync        => wsync,
       --rsync        => rsync, 
       rsync        => open, 
       numpm0       => numpm0,
       sizpm0       => sizpm0,
       numpm1       => numpm1,
       sizpm1       => sizpm1,
       colup0       => colup0,
       colup1       => colup1,
       colupf       => colupf,
       colubk       => colubk,
       pf_ref       => pf_ref,
       pf_score     => pf_score,
       pf_prio      => pf_prio,
       pf_bsize     => pf_bsize,
       refp0        => refp0,
       refp1        => refp1,
       pf0          => pf0,
       pf1          => pf1,
       pf2          => pf2,
       resp0        => resp0,
       resp1        => resp1,
       resm0        => resm0,
       resm1        => resm1,
       resbl        => resbl,
       audc0        => audc0,
       audc1        => audc1,
       audf0        => audf0,
       audf1        => audf1,
       audv0        => audv0,
       audv1        => audv1,
       grp0         => grp0,
       old_grp0     => old_grp0,
       grp1         => grp1,
       old_grp1     => old_grp1,
       enam0        => enam0,
       enam1        => enam1,
       enabl_n      => enabl_n,
       hmp0         => hmp0,
       hmp1         => hmp1,
       hmm0         => hmm0,
       hmm1         => hmm1,
       hmbl         => hmbl,
       vdelp0       => vdelp0,
       vdelp1       => vdelp1,
       resmp0       => resmp0,
       resmp1       => resmp1,
       hmove        => hmove,
       --hmclr        => hmclr,
       cxclr        => cxclr

    );

    -- This resets the collision latches
    reset_cxlat <= reset_sys or cxclr;

    -- Invert vertical blank
    vblank_n    <= not(vblank);

    -- Instantiate the collision latches.
    tia_cx_lats_0 : tia_cx_latches
    port map
    (

       clk      => clk,
       cx_clr   => reset_cxlat,
       vblank_n => vblank_n,
       ball     => g_ball,
       pl_0     => g_pl_0,
       mis_0    => g_mis_0,
       pl_1     => g_pl_1,
       mis_1    => g_mis_1,
       playf    => g_playf,
       cx_vec   => cx_vector

    );

    process(clk, reset_sys)
    begin

        if (reset_sys = '1') then

            g_ball  <= '0';
            g_mis_0 <= '0';
            g_mis_1 <= '0';
            g_pl_0  <= '0';
            g_pl_1  <= '0';

        elsif (clk'event and clk = '1') then

            if (ena_pix = '1') then

                g_ball  <= g_ball_del;
                g_mis_0 <= g_mis_0_del;
                g_mis_1 <= g_mis_1_del;
                g_pl_0  <= g_pl_0_del;
                g_pl_1  <= g_pl_1_del;

            end if;

        end if;

    end process;

    -- Instantiate the TIA read registers.
    tia_rdregs_0 : tia_rdregs
    port map
    (
       addr         => cpu_addr,
       din          => cpu_din,
       dout         => cpu_dout,
       cx_vector    => cx_vector,
       input_lat    => ctl_in

    );

    -- Instantiate the control and playfield logic
    tia_ctl_pf_0 : tia_ctl_pf
    port map
    (

       clk          => clk,
       reset_sys    => reset_sys,
       ena_sys      => ena_sys,
       ena_pix      => ena_pix,
       -- synthesis translate_off
       ref_sys_clk  => ref_sys_clk,
       ref_pix_clk  => ref_pix_clk,
       ref_newline  => ref_newline,
       -- synthesis translate_on
       rsync        => rsync,
       wsync        => wsync,
       vsync        => vsync,
       vblank       => vblank,
       hmove        => hmove,
       pf0          => pf0,
       pf1          => pf1,
       pf2          => pf2,
       pf_ref       => pf_ref,
       hmp0         => hmp0,
       hmp1         => hmp1,
       hmm0         => hmm0,
       hmm1         => hmm1,
       hmbl         => hmbl,
       cpu_clk      => cpu_clk_p0_ref, -- Not a "real" clock
       ctl_rst_cpu  => ctl_rst_cpu,
       cpu_rdy      => cpu_rdy,
       pf_out       => g_playf,
       cntd         => cntd,
       vid_csync    => vid_csync,
       vid_hsync    => vid_hsync,
       vid_vsync    => vid_vsync,
       vid_cburst   => vid_cb,
       vid_blank    => blank_i,
       vid_hblank   => vid_hblank,
       -- synthesis translate_off
       ref_motclk   => ref_motclk,
       ref_en_blm_n => ref_en_blm_n,
       ref_en_p0m_n => ref_en_p0m_n,
       ref_en_m0m_n => ref_en_m0m_n,
       ref_en_p1m_n => ref_en_p1m_n,
       ref_en_m1m_n => ref_en_m1m_n,
       -- synthesis translate_on
       adv_obj      => adv_obj,
       ball_mot     => ball_mot,
       p0_mot       => p0_mot,
       m0_mot       => m0_mot,
       p1_mot       => p1_mot,
       m1_mot       => m1_mot
       --aud_clk1     => aud_clk1,
       --aud_clk2     => aud_clk2

    );

    -- Heh heh Ball object logic...
    ball_obj_0 : tia_ball_obj
    port map
    (

       clk           => clk,
       pix_clk       => ena_pix,
       reset_sys     => reset_sys,
       -- synthesis translate_off
       motclk        => ref_motclk,
       ball_mot_n    => ref_en_blm_n,
       -- synthesis translate_on
       ball_mot      => ball_mot,
       adv_obj       => adv_obj,
       enabl_n       => enabl_n,
       resbl         => resbl,
       pf_bsize      => pf_bsize,
       g_bl          => g_ball_del

    );

    -- Player 0 logic.
    pl0_obj_0 : tia_player_obj
    port map
    (

       clk           => clk,
       pix_clk       => ena_pix,
       reset_sys     => reset_sys,
       -- synthesis translate_off
       motclk        => ref_motclk,
       pl_mot_n      => ref_en_p0m_n,
       -- synthesis translate_on
       pl_mot        => p0_mot,
       adv_obj       => adv_obj,
       nusiz         => numpm0,
       pl_refl       => refp0,
       pl_vdel       => vdelp0,
       play_new      => grp0,
       play_old      => old_grp0,
       respl         => resp0,
       m2p_reset     => m2p_rst_0,
       g_pl          => g_pl_0_del

    );

    -- Player 1 logic.
    pl1_obj_0 : tia_player_obj
    port map
    (

       clk           => clk,
       pix_clk       => ena_pix,
       reset_sys     => reset_sys,
       -- synthesis translate_off
       motclk        => ref_motclk,
       pl_mot_n      => ref_en_p1m_n,
       -- synthesis translate_on
       pl_mot        => p1_mot,
       adv_obj       => adv_obj,
       nusiz         => numpm1,
       pl_refl       => refp1,
       pl_vdel       => vdelp1,
       play_new      => grp1,
       play_old      => old_grp1,
       respl         => resp1,
       m2p_reset     => m2p_rst_1,
       g_pl          => g_pl_1_del

    );

    -- Missile zero object
    m0_obj_0 : tia_missile_obj
    port map
    (

       clk           => clk,
       pix_clk       => ena_pix,
       reset_sys     => reset_sys,
       -- synthesis translate_off
       motclk        => ref_motclk,
       mis_mot_n     => ref_en_m0m_n,
       -- synthesis translate_on
       mis_mot       => m0_mot,
       adv_obj       => adv_obj,
       mis_num       => numpm0,
       mis_siz       => sizpm0,
       mis_ena       => enam0,
       m2p_ena       => resmp0,
       resmis        => resm0,
       m2p_reset     => m2p_rst_0,
       g_mis         => g_mis_0_del

    );

    -- Missile one object
    m1_obj_0 : tia_missile_obj
    port map
    (

       clk           => clk,
       pix_clk       => ena_pix,
       reset_sys     => reset_sys,
       -- synthesis translate_off
       motclk        => ref_motclk,
       mis_mot_n     => ref_en_m1m_n,
       -- synthesis translate_on
       mis_mot       => m1_mot,
       adv_obj       => adv_obj,
       mis_num       => numpm1,
       mis_siz       => sizpm1,
       mis_ena       => enam1,
       m2p_ena       => resmp1,
       resmis        => resm1,
       m2p_reset     => m2p_rst_1,
       g_mis         => g_mis_1_del

    );


    -- This determines the color of the current 
    -- pixel that is to be drawn...
    tia_vid_mux_0 : tia_vidmux
    port map
    (
        clk         => clk,
        blank       => blank_i,
        cntd        => cntd,
        score       => pf_score,
        pf_prio     => pf_prio,
        g_p0        => g_pl_0,
        g_m0        => g_mis_0,
        g_p1        => g_pl_1,
        g_m1        => g_mis_1,
        g_pf        => g_playf,
        g_bl        => g_ball,
        colup0      => colup0,
        colup1      => colup1,
        colupf      => colupf,
        colubk      => colubk,
        vid_lum     => vid_lum,
        vid_color   => vid_color,
        vid_blank_n => vid_blank_n 

    );

    -- Finally, instantiate the two audio circuits.

    -- Channel 0
    tia_aud_0 : tia_audio
    port map
    (

        clk         => clk,
        reset       => reset_sys,
        cpu_clk_ena => cpu_p0_ref_180_i,
        audf        => audf0,
        audc        => audc0,
        audv        => audv0,
        aout        => aud_ch0

    );

    -- Channel 1
    tia_aud_1 : tia_audio
    port map
    (

        clk         => clk,
        reset       => reset_sys,
        cpu_clk_ena => cpu_p0_ref_180_i,
        audf        => audf1,
        audc        => audc1,
        audv        => audv1,
        aout        => aud_ch1

    );

    -- All your life is channel 13....


end struct;
