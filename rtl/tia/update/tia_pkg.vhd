-------------------------------------------------------------------------------
--
--   Copyright (C) 2004 Retrocircuits, LLC.
--
--   Title       : TIA -> Package of useful things
--
--   Description : This package holds all component declarations
--                 as well as addresses for all registers in TIA 
--
--   Author      : Ed Henciak
--
--   Date        : December 18, 2004
--
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

package tia_pkg is

  --------------------------------------------------------------
  -- The following addresses are write addresses to the TIA   --
  --------------------------------------------------------------

  -- VSYNC and VBLANK registers.
  constant VSYNC_A   : std_logic_vector(5 downto 0) := "000000";
  constant VBLANK_A  : std_logic_vector(5 downto 0) := "000001";

  -- Wait for sync and reset horizontal timing counter
  constant WSYNC_A   : std_logic_vector(5 downto 0) := "000010";
  constant RSYNC_A   : std_logic_vector(5 downto 0) := "000011";

  -- Player/Missile number and size register
  constant NUSIZ0_A  : std_logic_vector(5 downto 0) := "000100";
  constant NUSIZ1_A  : std_logic_vector(5 downto 0) := "000101";

  -- Color registers for players, playfield, and background
  constant COLUP0_A  : std_logic_vector(5 downto 0) := "000110";
  constant COLUP1_A  : std_logic_vector(5 downto 0) := "000111";
  constant COLUPF_A  : std_logic_vector(5 downto 0) := "001000";
  constant COLUBK_A  : std_logic_vector(5 downto 0) := "001001";

  -- Playfield and ball control register.
  constant CTRLPF_A  : std_logic_vector(5 downto 0) := "001010";

  -- Player reflect bits.
  constant REFP0_A   : std_logic_vector(5 downto 0) := "001011";
  constant REFP1_A   : std_logic_vector(5 downto 0) := "001100";

  -- Playfield graphic data registers
  constant PF0_A     : std_logic_vector(5 downto 0) := "001101";
  constant PF1_A     : std_logic_vector(5 downto 0) := "001110";
  constant PF2_A     : std_logic_vector(5 downto 0) := "001111";

  -- Horizontal timing reset strobes for players, missiles and,
  -- uh...heh heh....uh....heh heh, ball.
  constant RESP0_A   : std_logic_vector(5 downto 0) := "010000";
  constant RESP1_A   : std_logic_vector(5 downto 0) := "010001";
  constant RESM0_A   : std_logic_vector(5 downto 0) := "010010";
  constant RESM1_A   : std_logic_vector(5 downto 0) := "010011";
  constant RESBL_A   : std_logic_vector(5 downto 0) := "010100";

  -- Audio control registers
  constant AUDC0_A   : std_logic_vector(5 downto 0) := "010101";
  constant AUDC1_A   : std_logic_vector(5 downto 0) := "010110";
  constant AUDF0_A   : std_logic_vector(5 downto 0) := "010111";
  constant AUDF1_A   : std_logic_vector(5 downto 0) := "011000";
  constant AUDV0_A   : std_logic_vector(5 downto 0) := "011001";
  constant AUDV1_A   : std_logic_vector(5 downto 0) := "011010";

  -- Player graphic registers.
  constant GRP0_A    : std_logic_vector(5 downto 0) := "011011";
  constant GRP1_A    : std_logic_vector(5 downto 0) := "011100";

  -- Missile and ball enable registers
  constant ENAM0_A   : std_logic_vector(5 downto 0) := "011101";
  constant ENAM1_A   : std_logic_vector(5 downto 0) := "011110";
  constant ENABL_A   : std_logic_vector(5 downto 0) := "011111";

  -- Horizontal motion magnitude registers
  constant HMP0_A    : std_logic_vector(5 downto 0) := "100000";
  constant HMP1_A    : std_logic_vector(5 downto 0) := "100001";
  constant HMM0_A    : std_logic_vector(5 downto 0) := "100010";
  constant HMM1_A    : std_logic_vector(5 downto 0) := "100011";
  constant HMBL_A    : std_logic_vector(5 downto 0) := "100100";

  -- Vertical delay registers
  constant VDELP0_A  : std_logic_vector(5 downto 0) := "100101";
  constant VDELP1_A  : std_logic_vector(5 downto 0) := "100110";
  constant VDELBL_A  : std_logic_vector(5 downto 0) := "100111";

  -- Reset missile to player
  constant RESMP0_A  : std_logic_vector(5 downto 0) := "101000";
  constant RESMP1_A  : std_logic_vector(5 downto 0) := "101001";

  -- Horizontal move and clear strobe
  constant HMOVE_A   : std_logic_vector(5 downto 0) := "101010";
  constant HMCLR_A   : std_logic_vector(5 downto 0) := "101011";

  -- Collision latch clear strobe
  constant CXCLR_A   : std_logic_vector(5 downto 0) := "101100";

  --------------------------------------------------------------------
  -- These constants and subtypes represent various bits/fields     --
  -- that are latched from the databus into TIA (i.e. write fields) --
  --------------------------------------------------------------------

  -- VSYNC latch value
  constant D_VSYNC        : integer := 1;

  -- VBLANK registers. 
  constant D_VBLANK       : integer := 1;
  constant D_VBL_ENA_I4I5 : integer := 6;
  constant D_VBL_DUMP_RPT : integer := 7;

  -- Alter player/missile number/size registers
  subtype  D_NUMPM0       is integer range 2 downto 0;
  subtype  D_SIZPM0       is integer range 5 downto 4;
  subtype  D_NUMPM1       is integer range 2 downto 0;
  subtype  D_SIZPM1       is integer range 5 downto 4;

  -- Fruity color registers
  subtype  D_COLUP0       is integer range 7 downto 1;
  subtype  D_COLUP1       is integer range 7 downto 1;
  subtype  D_COLUPF       is integer range 7 downto 1;
  subtype  D_COLUBK       is integer range 7 downto 1;

  -- Playfield control bits.
  constant D_PF_REF       : integer := 0;
  constant D_PF_SCORE     : integer := 1;
  constant D_PF_PRIO      : integer := 2;
  subtype  D_PF_BSIZE     is integer range 5 downto 4;

  -- Player reflection bit.
  constant D_REFP0        : integer := 3;
  constant D_REFP1        : integer := 3;

  -- Playfield graphics registers.
  subtype  D_PF0          is integer range 7 downto 4;
  subtype  D_PF1          is integer range 7 downto 0;
  subtype  D_PF2          is integer range 7 downto 0;

  -- Audio control registers
  subtype  D_AUDC0        is integer range 3 downto 0;
  subtype  D_AUDC1        is integer range 3 downto 0;
  subtype  D_AUDF0        is integer range 4 downto 0;
  subtype  D_AUDF1        is integer range 4 downto 0;
  subtype  D_AUDV0        is integer range 3 downto 0;
  subtype  D_AUDV1        is integer range 3 downto 0;

  -- Player graphics register.
  subtype  D_GRP0         is integer range 7 downto 0;
  subtype  D_GRP1         is integer range 7 downto 0;

  -- Missile/Ball enable bit.
  constant D_ENAM0        : integer := 1;
  constant D_ENAM1        : integer := 1;
  constant D_ENABL        : integer := 1;

  -- Vertical delay bits 
  constant D_VDELP0       : integer := 0;
  constant D_VDELP1       : integer := 0;
  constant D_VDELBL       : integer := 0;

  -- Missile to player resets
  constant D_RESMP0       : integer := 1;
  constant D_RESMP1       : integer := 1;

  -- Any horizontal motion register
  subtype  D_HORMOT       is integer range 7 downto 4;

  -------------------------------------------------
  -- The following are read addresses in the TIA --
  -------------------------------------------------

  -- Collision between missile 0 and player 0/1
  constant CXM0P_A        : std_logic_vector(3 downto 0) := "0000";

  -- Collision between missile 1 and player 0/1
  constant CXM1P_A        : std_logic_vector(3 downto 0) := "0001";

  -- Collision between player 0 and playfield/ball
  constant CXP0FB_A       : std_logic_vector(3 downto 0) := "0010";

  -- Collision between player 1 and playfield/ball
  constant CXP1FB_A       : std_logic_vector(3 downto 0) := "0011";
  
  -- Collision between missile 0 and playfield/ball
  constant CXM0FB_A       : std_logic_vector(3 downto 0) := "0100";

  -- Collision between missile 1 and playfield/ball
  constant CXM1FB_A       : std_logic_vector(3 downto 0) := "0101";

  -- Collision between ball and playfield
  constant CXBLPF_A       : std_logic_vector(3 downto 0) := "0110";

  -- Collision between players and missiles
  constant CXPPMM_A       : std_logic_vector(3 downto 0) := "0111";

  -- These addresses allow one to read pots and triggers (most of the
  -- time these bits are for that...)
  constant INPT0_A        : std_logic_vector(3 downto 0) := "1000";
  constant INPT1_A        : std_logic_vector(3 downto 0) := "1001";
  constant INPT2_A        : std_logic_vector(3 downto 0) := "1010";
  constant INPT3_A        : std_logic_vector(3 downto 0) := "1011";
  constant INPT4_A        : std_logic_vector(3 downto 0) := "1100";
  constant INPT5_A        : std_logic_vector(3 downto 0) := "1101";

  ----------------------------------------------------------------------
  -- The collision latches are represented  as a 15 bit vector...these
  -- constants are used to point to the various collisions that occur...
  ----------------------------------------------------------------------
  constant COL_M0P0       : integer :=  0;
  constant COL_M0P1       : integer :=  1;
  constant COL_M1P1       : integer :=  2;
  constant COL_M1P0       : integer :=  3;
  constant COL_P0BL       : integer :=  4;
  constant COL_P0PF       : integer :=  5;
  constant COL_P1BL       : integer :=  6;
  constant COL_P1PF       : integer :=  7;
  constant COL_M0BL       : integer :=  8;
  constant COL_M0PF       : integer :=  9;
  constant COL_M1BL       : integer := 10;
  constant COL_M1PF       : integer := 11;
  constant COL_BLPF       : integer := 12;
  constant COL_M0M1       : integer := 13;
  constant COL_P0P1       : integer := 14;        

  ----------------------------------------------------------------------
  -- Other subtypes, tricks, trinkets and what-not found throughout
  -- the TIA design....
  ----------------------------------------------------------------------

  -- Silly subtype for the happy sequencing counters
  subtype  seq_int is integer range 0 to 64; 

  -- These constants are used by the control and playfield logic
  -- to trigger events in that component...
  constant SET_HSYNC_CNT     : seq_int :=  4; -- Set horizontal sync
  constant RESET_HSYNC_CNT   : seq_int :=  8; -- Clear horizontal sync
  constant COLORBURST_CNT    : seq_int := 12; -- probably useless
  constant RESET_HBLANK      : seq_int := 16; -- Clear horizontal blank
  constant LATE_RESET_HBLANK : seq_int := 18; -- for motion
  constant CENTER_CNT        : seq_int := 36; -- Indicates PF center
  constant END_SEQ_CNT       : seq_int := 56; -- Resets count & sets the
                                              -- horizontal blank.

  -- This type indicates the type of "TIA" D flip flop to
  -- instantiate.  Heh heh...flop
  type flop_type is (REGULAR_D,   -- Regular H1 H2 flip flop
                     NOR_RST,     -- Flip flop with NOR reset gate @ output
                     FEEDBK_RST); -- Same as above, but the output of flop
                                  -- is fed back into & gated with the input

  -- This constant is used by the ball logic (heh heh ball)
  constant RESET_BALL_COUNTER : seq_int := 39;

  -- Constants used by the player logic
  constant PLAYER_START_1     : seq_int := 3;
  constant PLAYER_START_2     : seq_int := 7;
  constant PLAYER_START_3     : seq_int := 15;
  constant PLAYER_END         : seq_int := 39;

  -- Constants used by the player logic
  constant MISSILE_START_1    : seq_int := 3;
  constant MISSILE_START_2    : seq_int := 7;
  constant MISSILE_START_3    : seq_int := 15;
  constant MISSILE_END        : seq_int := 39;

  -- Size constants used by both player and missile logic
  constant SOLO               : std_logic_vector(2 downto 0) := "000";
  constant DUO_C              : std_logic_vector(2 downto 0) := "001";
  constant DUO_M              : std_logic_vector(2 downto 0) := "010";
  constant TRIO_C             : std_logic_vector(2 downto 0) := "011";
  constant DUO_W              : std_logic_vector(2 downto 0) := "100";
  constant DSIZE              : std_logic_vector(2 downto 0) := "101";
  constant TRIO_M             : std_logic_vector(2 downto 0) := "110";
  constant QUAD               : std_logic_vector(2 downto 0) := "111";

  ------------------------------------------------------------------
  -- Next up are TIA component declarations found throughout this --
  -- lovely design.  Yes, it is so lovely...                      --
  ------------------------------------------------------------------

  -- Basic TIA latch circuit (where they are absolutely needed)
  component tia_latch is
  port
  (

     -- 2X clock input
     clk    : in std_logic;

     -- Bits that set and clear
     set    : in std_logic;
     clear  : in std_logic;

     -- Our output bit...
     output : out std_logic

  );
  end component;

  -- This component acts as one of the wacky pass-gate based
  -- flip flops found throughout TIA...
  component tia_d_flop
  generic(
     flop_style   : flop_type := REGULAR_D
  );
  port
  (

     -- Clock and feedback reset 
     clk          : in  std_logic; -- Main clock
     reset        : in  std_logic; -- Active high reset
     reset_gate   : in  std_logic; -- NOR based reset

     -- Clock phase enables
     p1_clk       : in  std_logic;
     p2_clk       : in  std_logic;

     -- Input data
     data_in      : in  std_logic;

     -- D-Flop outputs based on phase
     p1_out       : out std_logic;
     p2_out       : out std_logic

  );
  end component;

  -- TIA cpu clock reset latch.
  component tia_clocking_and_reset_crst_latch
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
  end component;

  -- TIA clocking and reset.
  component tia_clocking_and_reset
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
  end component;


  -- This component handles all writes from the outside world.
  component tia_wregs
  port
  (
     -- Clock and reset 
     clk          : in  std_logic; -- clock (CPU clock)
     clk_ena      : in  std_logic; -- clock "enable"
     cpu_clk_ref  : in  std_logic; -- Actual CPU clock reference...
     reset_sys    : in  std_logic; -- async. input reset
 
     -- Control bus 
     chip_select  : in  std_logic;
     addr         : in  std_logic_vector(5 downto 0);
     din          : in  std_logic_vector(7 downto 0);
     rwn          : in  std_logic;

     -- Here's all the happy, write-only registers
     -- The mneumonics are taken from the Stella guide.

     -- From the VSYNC register
     vsync        : out std_logic;
  
     -- From the VBLANK register
     vblank       : out std_logic;
     vbl_ena_i4i5 : out std_logic;
     vbl_dump_prt : out std_logic;
  
     -- Wait SYNC strobe
     wsync        : out std_logic;
  
     -- Reset HSYNC counter
     rsync        : out std_logic;
  
     -- Number-size player missile regs (NUSIZ0 & NUSIZ1)
     numpm0       : out std_logic_vector(2 downto 0);
     sizpm0       : out std_logic_vector(1 downto 0);
     numpm1       : out std_logic_vector(2 downto 0);
     sizpm1       : out std_logic_vector(1 downto 0);
  
     -- Color registers (signals represent mneumonics).
     colup0       : out std_logic_vector(6 downto 0);
     colup1       : out std_logic_vector(6 downto 0);
     colupf       : out std_logic_vector(6 downto 0);
     colubk       : out std_logic_vector(6 downto 0);
  
     -- Playfield control (CTRLPF)
     pf_ref       : out std_logic;                    -- Reflection
     pf_score     : out std_logic;                    -- Score
     pf_prio      : out std_logic;                    -- Priority
     pf_bsize     : out std_logic_vector(1 downto 0); -- Ball size
  
     -- Player reflection bits (signals represent mneumonics).
     refp0        : out std_logic;
     refp1        : out std_logic;
  
     -- Playfield registers (signals represent mneumonics).
     pf0          : out std_logic_vector(3 downto 0);
     pf1          : out std_logic_vector(7 downto 0);
     pf2          : out std_logic_vector(7 downto 0);
  
     -- Object reset strobes (signals represent mneumonics).
     resp0        : out std_logic;
     resp1        : out std_logic;
     resm0        : out std_logic;
     resm1        : out std_logic;
     resbl        : out std_logic;
  
     -- Silly Audio Control registers (signals represent mneumonics).
     audc0        : out std_logic_vector(3 downto 0);
     audc1        : out std_logic_vector(3 downto 0);
     audf0        : out std_logic_vector(4 downto 0);
     audf1        : out std_logic_vector(4 downto 0);
     audv0        : out std_logic_vector(3 downto 0);
     audv1        : out std_logic_vector(3 downto 0);
  
     -- Player graphics registers (signals represent mneumonics).
     old_grp0     : out std_logic_vector(7 downto 0);
     grp0         : out std_logic_vector(7 downto 0);
     old_grp1     : out std_logic_vector(7 downto 0);
     grp1         : out std_logic_vector(7 downto 0);
  
     -- Graphics enable bits (signals represent mneumonics).
     enam0        : out std_logic;
     enam1        : out std_logic;
     enabl_n      : out std_logic;
  
     -- Horizontal Motion values (signals represent mnuemonics).
     hmp0         : out std_logic_vector(3 downto 0);
     hmp1         : out std_logic_vector(3 downto 0);
     hmm0         : out std_logic_vector(3 downto 0);
     hmm1         : out std_logic_vector(3 downto 0);
     hmbl         : out std_logic_vector(3 downto 0);
  
     -- Vertical delay bits
     vdelp0       : out std_logic;
     vdelp1       : out std_logic;
  
     -- Missile reset bits
     resmp0       : out std_logic;
     resmp1       : out std_logic;
  
     -- Horizontal motion clear strobes
     hmove        : out std_logic;
     hmclr        : out std_logic;
  
     -- Collision latch clear strobe
     cxclr        : out std_logic
  
  );
  end component;

  -- This component is the bank of collision latches.
  component tia_cx_latches
  port
  (

     -- 2X clock for the "latches"
     clk      : in  std_logic;

     -- Signal which clears all latches
     cx_clr   : in  std_logic;

     -- Not in vertical blank
     vblank_n : in std_logic;

     -- These 6 inputs are the serial graphics
     -- being shifted out of TIA.

     ball     : in  std_logic; -- Heh, heh...ball
     pl_0     : in  std_logic; -- Player 0 graphics
     mis_0    : in  std_logic; -- Missile 0 graphics
     pl_1     : in  std_logic; -- Player 1 graphics
     mis_1    : in  std_logic; -- Missile 1 graphics
     playf    : in  std_logic; -- Playfield graphics

     -- This output is the collision vector!  This
     -- is tied to the TIA read register logic.
     cx_vec   : out std_logic_vector(14 downto 0)


  );
  end component;


  -- This component muxes out read values requested by the
  -- outside world...
  component tia_rdregs
  port
  (
     -- Address bus from the outside world
     addr         : in  std_logic_vector( 5 downto 0);

     -- Data input (bus hold emulation)
     din          : in  std_logic_vector( 7 downto 0);

     -- Data output
     dout         : out std_logic_vector( 7 downto 0);

     -- Collision vector input
     cx_vector    : in  std_logic_vector(14 downto 0);

     -- Input latch/pot threshold registers
     input_lat    : in  std_logic_vector( 5 downto 0)

  );
  end component;

  -- TIA master control and playfield logic...
  component tia_ctl_pf
  port
  (

     -- Clock and reset 
     clk          : in  std_logic; -- Main oscillator 
     reset_sys    : in  std_logic; -- Primary reset

     -- Reference enable inputs to sync
     -- system clock to actual TIA rates.
     ena_sys      : in  std_logic;
     ena_pix      : in  std_logic;

     -- Simulation only reference signals
     -- synthesis translate_off
     ref_sys_clk  : in  std_logic;
     ref_pix_clk  : in  std_logic;
     ref_newline  : out std_logic;
     -- synthesis translate_on

     -- RSYNC strobe
     rsync        : in  std_logic;

     -- WSYNC strobe
     wsync        : in  std_logic;

     -- VSYNC & VBLANK register inputs
     vsync        : in  std_logic;
     vblank       : in  std_logic;

     -- Horizontal motion pulse
     hmove        : in  std_logic;

     -- Playfield register inputs
     pf0          : in  std_logic_vector(3 downto 0);
     pf1          : in  std_logic_vector(7 downto 0);
     pf2          : in  std_logic_vector(7 downto 0);

     -- Playfield reflect bit from regfile
     pf_ref       : in  std_logic;

     -- Horizontal motion input vectors
     hmp0         : in  std_logic_vector(3 downto 0);
     hmp1         : in  std_logic_vector(3 downto 0);
     hmm0         : in  std_logic_vector(3 downto 0);
     hmm1         : in  std_logic_vector(3 downto 0);
     hmbl         : in  std_logic_vector(3 downto 0);

     -- CPU clock reference
     cpu_clk      : in  std_logic;

     -- CPU clock reset control
     ctl_rst_cpu  : out std_logic;

     -- CPU ready signal 
     cpu_rdy      : out std_logic;

     -- Playfield graphics output
     pf_out       : out std_logic;

     -- Playfield Center Delayed
     cntd         : out std_logic;

     -- Signals driven to video control logic
     vid_csync    : out std_logic;
     vid_hsync    : out std_logic;
     vid_vsync    : out std_logic;
     vid_cburst   : out std_logic;
     vid_blank    : out std_logic;

     -- The following signals are related to horizontal
     -- motion.  These are to be used as simulation
     -- references in the event something goes wrong...
     -- synthesis translate_off
     ref_motclk   : out std_logic;
     ref_en_blm_n : out std_logic;
     ref_en_p0m_n : out std_logic;
     ref_en_m0m_n : out std_logic;
     ref_en_p1m_n : out std_logic;
     ref_en_m1m_n : out std_logic;
     -- synthesis translate_on

     -- This signal allows the object counters
     -- to advance (i.e. draw the things!)
     adv_obj      : out std_logic;

     -- These are the motion signals used
     -- in the synthesizable application...see
     -- objects for details.
     ball_mot     : out std_logic;
     p0_mot       : out std_logic;
     m0_mot       : out std_logic;
     p1_mot       : out std_logic;
     m1_mot       : out std_logic;

     -- Audio clock signals
     aud_clk1     : out std_logic;
     aud_clk2     : out std_logic

  );
  end component;

  -- TIA sequencing circuit w. simulation prims inside!
  -- This is used in all TIA object circuits.
  component tia_sequencer
  port
  (

     -- First, this clock is a "simulation"
     -- clock...it's used for comparing "real"
     -- TIA operation against my silly mess...

     -- synthesis translate_off
     sim_clk   : in  std_logic;
     -- synthesis translate_on

     -- Clock input
     clk       : in  std_logic;

     -- System reset (power-on reset)
     reset_sys : in  std_logic;

     -- Enable input...this allows the internal
     -- logic to advance.
     enable    : in  std_logic;

     -- This reset clears the counter...
     reset_ctr : in  std_logic;

     -- This reset sets the sequencer
     -- reset latch...
     rlat_in   : in  std_logic;

     -- Divided clock outputs
     p1_clk    : out std_logic;
     p2_clk    : out std_logic;

     -- Divided clock enable outputs
     -- (See main readme file)
     p1_ena    : out std_logic;
     p2_ena    : out std_logic;

     -- Output of the sequence counter
     cnt_out   : out seq_int;

     -- Output of the reset latch...
     rlat_out  : out std_logic;

     -- Finally, the "tap" output used
     -- by the missile sequencer
     tap_out   : out std_logic

  );
  end component;

  -- Heh heh ball object logic
  component tia_ball_obj
  port
  (

     -- Clocks and resets
     clk           : in std_logic; -- System Clock (x2)
     pix_clk       : in std_logic; -- Pixel Clock 
     reset_sys     : in std_logic; -- System reset

     -- synthesis translate_off
     motclk        : in std_logic; -- Motion clock
     ball_mot_n    : in std_logic; -- Enable motion
     -- synthesis translate_on

     -- These are the synthesizable enables synchronized
     -- to clk...
     ball_mot      : in std_logic; -- Enable motion
     adv_obj       : in std_logic; -- Enable counter.

     -- Enable ball graphics bit...from the 
     -- write registers (gating between it 
     -- and the delay info are already taken into
     -- account).
     enabl_n       : in  std_logic;

     -- Reset the ball counter strobe
     -- from the write register file...
     resbl         : in std_logic;

     -- Ball size (HEH HEHEEH H HEEHEHEH)
     -- That just sounds wrong...
     pf_bsize      : in std_logic_vector(1 downto 0);


     -- Serialized ball graphic bit...
     g_bl          : out std_logic

  );
  end component;

  component tia_player_obj
  port
  (

     -- Clocks and resets
     clk           : in  std_logic; -- System Clock (x2)
     pix_clk       : in  std_logic; -- Pixel Clock
     reset_sys     : in  std_logic; -- System reset

     -- synthesis translate_off
     -- These are for simulation reference only
     pl_mot_n      : in  std_logic;
     motclk        : in  std_logic;
     -- synthesis translate_on

     -- These signals move the object counter
     -- for synthesis applications ;)
     pl_mot        : in  std_logic;
     adv_obj       : in  std_logic;

     -- Player number/size info
     nusiz         : in  std_logic_vector(2 downto 0);

     -- Player reflect bit.
     pl_refl       : in  std_logic;
     pl_vdel       : in  std_logic;

     -- Player sprite registers
     play_new      : in  std_logic_vector(7 downto 0);
     play_old      : in  std_logic_vector(7 downto 0);

     -- Reset the player counter strobe
     respl         : in  std_logic;

     -- Missile to player reset
     m2p_reset     : out std_logic;

     -- Serialized player graphic bit...
     g_pl          : out std_logic

  );
  end component;

  -- The missile object...
  component tia_missile_obj 
  port
  (

     -- Clocks and resets
     clk           : in  std_logic; -- System clock (x2)
     pix_clk       : in  std_logic; -- Pixel clock
     reset_sys     : in  std_logic; -- System reset

     -- synthesis translate_off
     -- These are for simulation reference only
     motclk        : in  std_logic;
     mis_mot_n     : in  std_logic;
     -- synthesis translate_on

     -- These signals move the object counter
     -- for synthesis applications ;)
     mis_mot       : in  std_logic;
     adv_obj       : in  std_logic;

     -- Missile number/size info
     mis_num       : in  std_logic_vector(2 downto 0);
     mis_siz       : in  std_logic_vector(1 downto 0);

     -- Missile enable
     mis_ena       : in  std_logic;

     -- Player to missile reset enable
     m2p_ena       : in  std_logic;

     -- Reset the missile strobe
     resmis        : in  std_logic;

     -- Missile to player reset strobe
     m2p_reset     : in std_logic;

     -- Serialized missile graphic bit...
     g_mis         : out std_logic

  );
  end component;


  -- The video mux (determines pixel color...)
  component tia_vidmux
  port
  (

     -- Clock (2x) for the latch
     clk         : in  std_logic;

     -- Signals from horizontal control (master control 
     -- for you Tron fans...)
     blank       : in  std_logic;                    -- Blank
     cntd        : in  std_logic;                    -- Center Delayed

     -- Non-inverted signals from the register file
     score       : in  std_logic;
     pf_prio     : in  std_logic;

     -- Serialized graphics...
     g_p0        : in  std_logic; -- Player 0
     g_m0        : in  std_logic; -- Missile 0
     g_p1        : in  std_logic; -- Player 1
     g_m1        : in  std_logic; -- Missile 1
     g_pf        : in  std_logic; -- Playfield
     g_bl        : in  std_logic; -- Heh heh Ball.

     -- Input from color registers...TIA uses
     -- a 7 downto 1 notation...I use 6 downto 0.
     -- Please don't harm me with Tastycakes if you
     -- disagree.
     colup0      : in  std_logic_vector(6 downto 0);
     colup1      : in  std_logic_vector(6 downto 0);
     colupf      : in  std_logic_vector(6 downto 0);
     colubk      : in  std_logic_vector(6 downto 0);

     -- This is what is output from TIA's video logic.
     -- Sorry, but analog stuff cannot be designed in 
     -- an FPGA....yet :)!  All of the following need registered
     -- on CLKP elsewhere...
     vid_lum     : out std_logic_vector(2 downto 0); -- Luminance
     vid_color   : out std_logic_vector(3 downto 0); -- Color
     vid_blank_n : out std_logic                     -- blank_n

  );
  end component;

  -- The circuit that allows us to sync the object counters
  -- up to the system clock multiplied by two and phase aligned
  -- to the main oscillator clock!
  component tia_enabler
  port
  (

     -- Clock input (main oscillator clock x2)
     clk        : in  std_logic;

     -- Resets this logic...generally system reset and
     -- whatever reset pulse is sent to the object from wregs.
     reset      : in  std_logic;

     -- This signal states that we are driving a visible
     -- scanline.  As a result, we better move the counter
     -- or else we won't see stuff.
     noblank    : in  std_logic;

     -- Motion logic enable input...we use this to determine
     -- when to advance a counter with respect to the
     -- system_clk x2.  This is part of the TIA conspiracy...
     hmotion    : in  std_logic;

     -- Main "enable counter" signal....this advances the counter
     -- with respect to the x2 clock.
     obj_enable : out std_logic

  );
  end component;

  -- The actual TIA component
  component tia
  port
  (

     -- Clock and system reset
     clk            : in std_logic;                     -- Main oscillator clock 
     master_reset   : in std_logic;                     -- not on TIA, but useful

     -- System control
     pix_ref        : out std_logic;                    -- Not on TIA...pixel clk reference
     sys_rst        : out std_logic;                    -- Not on TIA...system reset
     cpu_p0_ref     : out std_logic;                    -- CPU P0 reference
     cpu_p0_ref_180 : out std_logic;                    -- CPU P0 reference (180 deg. oop)

     -- synthesis translate_off
     ref_newline    : out std_logic;                    -- Debug (SHB)
     -- synthesis translate_on

     -- CPU signals
     cpu_p0         : out std_logic;                    -- CPU clock gen. by TIA
     cpu_clk        : in  std_logic;                    -- Phi2 CPU clockA
     cpu_cs0n       : in  std_logic;                    -- Chip select 0 (act. low)
     cpu_cs1        : in  std_logic;                    -- Chip select 0 (act. high)
     cpu_cs2n       : in  std_logic;                    -- Chip select 0 (act. low)
     cpu_cs3n       : in  std_logic;                    -- Chip select 0 (act. low)
     cpu_rwn        : in  std_logic;                    -- Read / Write_n
     cpu_addr       : in  std_logic_vector(5 downto 0); -- CPU address
     cpu_din        : in  std_logic_vector(7 downto 0); -- CPU data in
     cpu_dout       : out std_logic_vector(7 downto 0); -- CPU data out
     cpu_rdy        : out std_logic;                    -- Halts CPU if low
 
     -- Controller (or other) input bits
     ctl_in         : in  std_logic_vector(5 downto 0); -- Happy inputs from paddles
                                                        -- and triggers.

     -- Video outputs (Not all are necessary depending on your app.)
 
     vid_csync      : out std_logic;                    -- Composite sync
     vid_hsync      : out std_logic;                    -- Horiz. sync
     vid_vsync      : out std_logic;                    -- Vert. sync
     vid_lum        : out std_logic_vector(2 downto 0); -- Luminance
     vid_color      : out std_logic_vector(3 downto 0); -- Color vector
     vid_cb         : out std_logic;                    -- Color burst
     vid_blank_n    : out std_logic;                    -- Blank signal
 
     -- Audio outputs
     aud_ch0        : out std_logic_vector(3 downto 0); -- Audio channel 0
     aud_ch1        : out std_logic_vector(3 downto 0)  -- Audio channel 1

  );
  end component;

  -- Audio component
  component tia_audio
  port
  (
  
      -- Clock input (2X osc clk) & reset
      clk         : in  std_logic;
      reset       : in  std_logic;
  
      -- CPU clock resference (runs @ 1.19MHz)
      cpu_clk_ena : in  std_logic;
  
      -- Audio frequency, volume, and control inputs
      audf        : in  std_logic_vector(4 downto 0);
      audc        : in  std_logic_vector(3 downto 0);
      audv        : in  std_logic_vector(3 downto 0);
  
      -- Audio output (4 bit vector)
      aout        : out std_logic_vector(3 downto 0)
  
  
  );
  end component;

end tia_pkg;
