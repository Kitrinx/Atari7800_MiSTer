-------------------------------------------------------------------------------
--
--   Copyright (C) 2004 Retrocircuits, LLC.
--
--   Title       : TIA -> Write registers.
--
--   Description : This block of logic handles all those registers
--                 that can be written in the TIA.
--
--   Author      : Ed Henciak...still borderline unstable.
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
entity tia_wregs is
port
(
   -- Clock and reset 
   clk          : in  std_logic; -- clock (CPU clock)
   clk_ena      : in  std_logic; -- Qualifies the clock 
   cpu_clk_ref  : in  std_logic; -- CPU clock reference
   reset_sys    : in  std_logic; -- async. input reset

   -- We only need the address and data in busses...we
   -- never output any of these reigsters to the microprocessor
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
   grp0         : out std_logic_vector(7 downto 0);
   old_grp0     : out std_logic_vector(7 downto 0);
   grp1         : out std_logic_vector(7 downto 0);
   old_grp1     : out std_logic_vector(7 downto 0);

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
end tia_wregs;

architecture rtl of tia_wregs is

  -- Registers local to this logic.  Keep in mind that
  -- the outputs in the port map above are mostly registers
  -- as well!
  signal hmclr_i   : std_logic;

  -- This is the register the user sets to enable the ball
  signal enabl_i   : std_logic;

  -- Delayed ball enable ... this is latched with a write
  -- to the player 1 graphics register
  signal d_ebl     : std_logic;

  -- Ball is vertically delayed....this is gated to create 
  -- the "master" ball enable...
  signal vdelbl    : std_logic;

  -- Player graphics registers
  signal grp0_i    : std_logic_vector(7 downto 0);
  signal grp1_i    : std_logic_vector(7 downto 0);

  -- Internal strobes...
  signal wsync_i   : std_logic; 
  signal rsync_i   : std_logic; 
  signal resp0_i   : std_logic; 
  signal resp1_i   : std_logic; 
  signal resm0_i   : std_logic; 
  signal resm1_i   : std_logic; 
  signal resbl_i   : std_logic; 
  signal hmove_i   : std_logic; 
  signal hmclr_i_i : std_logic; 
  signal cxclr_i   : std_logic; 

begin

  -- This process registers and resets the HMOVE regs.
  process (clk, reset_sys, hmclr_i) 
  begin

      if (reset_sys ='1') or (hmclr_i = '1') then

         hmp0 <= (others => '0');
         hmp1 <= (others => '0');
         hmm0 <= (others => '0');
         hmm1 <= (others => '0');
         hmbl <= (others => '0');

      elsif(clk'event and clk = '1') then

         if (clk_ena = '1') then

             if (chip_select = '1') and (rwn = '0') then

                -- Decode address and see what we should do
                case addr is

                   when HMP0_A   => hmp0 <= din(D_HORMOT); 
                   when HMP1_A   => hmp1 <= din(D_HORMOT); 
                   when HMM0_A   => hmm0 <= din(D_HORMOT); 
                   when HMM1_A   => hmm1 <= din(D_HORMOT); 
                   when HMBL_A   => hmbl <= din(D_HORMOT); 
                   when others   => null; 

                end case;

             end if;

         end if;

      end if;

    end process;


    -- This process registers data driven to this logic
    -- on the falling edge of the clock
    process (clk, reset_sys) 
    begin

        if (reset_sys ='1') then

           vsync        <= '0';

           vblank       <= '0';
           vbl_ena_i4i5 <= '0';
           vbl_dump_prt <= '0';

           numpm0       <= (others => '0');
           sizpm0       <= (others => '0');
           numpm1       <= (others => '0');
           sizpm1       <= (others => '0');

           colup0       <= (others => '0');
           colup1       <= (others => '0');
           colupf       <= (others => '0');
           colubk       <= (others => '0');

           pf_ref       <= '0';
           pf_score     <= '0';
           pf_prio      <= '0';
           pf_bsize     <= (others => '0');

           refp0        <= '0';
           refp1        <= '0';

           pf0          <= (others => '0');
           pf1          <= (others => '0');
           pf2          <= (others => '0');

           audc0        <= (others => '0');
           audc1        <= (others => '0');
           audf0        <= (others => '0');
           audf1        <= (others => '0');
           audv0        <= (others => '0');
           audv1        <= (others => '0');

           grp0_i       <= (others => '0');
           grp1_i       <= (others => '0');
           old_grp0     <= (others => '0');
           old_grp1     <= (others => '0');

           enam0        <= '0';
           enam1        <= '0';
           enabl_i      <= '0';
           d_ebl        <= '0';

           vdelp0       <= '0';
           vdelp1       <= '0';
           vdelbl       <= '0';

           resmp0       <= '0';
           resmp1       <= '0';

        elsif(clk'event and clk = '1') then

           -- When the clock is enabled...
           if (clk_ena = '1') then

               -- See if we need to write anything here.
               if (chip_select = '1') and (rwn = '0') then

                  case addr is

                     when VSYNC_A  => vsync        <= din(D_VSYNC); 
   
                     when VBLANK_A => vblank       <= din(D_VBLANK); 
                                      vbl_ena_i4i5 <= din(D_VBL_ENA_I4I5);
                                      vbl_dump_prt <= din(D_VBL_DUMP_RPT);
   
                     when NUSIZ0_A => numpm0       <= din(D_NUMPM0); 
                                      sizpm0       <= din(D_SIZPM0);

                     when NUSIZ1_A => numpm1       <= din(D_NUMPM1); 
                                      sizpm1       <= din(D_SIZPM1);

                     when COLUP0_A => colup0       <= din(D_COLUP0); 
                     when COLUP1_A => colup1       <= din(D_COLUP1);
                     when COLUPF_A => colupf       <= din(D_COLUPF);
                     when COLUBK_A => colubk       <= din(D_COLUBK);

                     when CTRLPF_A => pf_ref       <= din(D_PF_REF);
                                      pf_score     <= din(D_PF_SCORE);
                                      pf_prio      <= din(D_PF_PRIO);
                                      pf_bsize     <= din(D_PF_BSIZE);

                     when REFP0_A  => refp0        <= din(D_REFP0); 
                     when REFP1_A  => refp1        <= din(D_REFP1); 

                     when PF0_A    => pf0          <= din(D_PF0); 
                     when PF1_A    => pf1          <= din(D_PF1); 
                     when PF2_A    => pf2          <= din(D_PF2); 

                     when AUDC0_A  => audc0        <= din(D_AUDC0); 
                     when AUDC1_A  => audc1        <= din(D_AUDC1);
                     when AUDF0_A  => audf0        <= din(D_AUDF0);
                     when AUDF1_A  => audf1        <= din(D_AUDF1);
                     when AUDV0_A  => audv0        <= din(D_AUDV0);
                     when AUDV1_A  => audv1        <= din(D_AUDV1);

                     -- Recall crazy cross couple here....this is painful if
                     -- you forget....trust me ;)!
                     when GRP0_A   => grp0_i       <= din(D_GRP0); 
                                      old_grp1     <= grp1_i; -- Write cur P1 to old P1
                     when GRP1_A   => grp1_i       <= din(D_GRP1); 
                                      old_grp0     <= grp0_i; -- Write cur P0 to old P0
                                      d_ebl        <= enabl_i; -- Grab last ball enable

                     when ENAM0_A  => enam0        <= din(D_ENAM0); 
                     when ENAM1_A  => enam1        <= din(D_ENAM1); 
                     when ENABL_A  => enabl_i      <= din(D_ENABL); 
  
                     when VDELP0_A => vdelp0       <= din(D_VDELP0); 
                     when VDELP1_A => vdelp1       <= din(D_VDELP1); 
                     when VDELBL_A => vdelbl       <= din(D_VDELBL); 

                     when RESMP0_A => resmp0       <= din(D_RESMP0); 
                     when RESMP1_A => resmp1       <= din(D_RESMP1); 

                     when others   => null; -- Do nothing you lazy drunk

                  end case;

               end if;

           end if;

        end if;

    end process; 

    -- Drive out the player graphics registers
    grp0 <= grp0_i;
    grp1 <= grp1_i;

    -- This logic enables the ball output object...do not confuse this
    -- with enabling the clock to the ball logic.  That's handles in the
    -- control and playfield logic (tia_ctl_pf.vhd)
    enabl_n <= (not(enabl_i) or vdelbl) and (not(d_ebl) or not(vdelbl));

    -- This process generates reset strobes...
    process (clk, reset_sys)
    begin


         if (reset_sys = '1') then

             wsync_i   <= '0';
             rsync_i   <= '0';
             resp0_i   <= '0';       
             resp1_i   <= '0'; 
             resm0_i   <= '0'; 
             resm1_i   <= '0'; 
             resbl_i   <= '0'; 
             hmove_i   <= '0';
             hmclr_i_i <= '0';
             cxclr_i   <= '0';

         elsif(clk'event and clk = '1') then

             -- When the clock fires...
             if (clk_ena = '1') then

                -- Most of the time these bits will be
                -- low.  Only a leap from the lion's head
                -- will they prove their worth...
                wsync_i   <= '0';
                rsync_i   <= '0';
                resp0_i   <= '0';       
                resp1_i   <= '0'; 
                resm0_i   <= '0'; 
                resm1_i   <= '0'; 
                resbl_i   <= '0'; 
                hmove_i   <= '0';
                hmclr_i_i <= '0';
                cxclr_i   <= '0';

                -- Only do the following if we're selected for write.
                -- Failing to do so is bad...
                if (chip_select = '1') and (rwn = '0') then

                    -- The lion's head in this case is
                    -- the address...if we're pointing to a
                    -- strobe register, then strobe it!
                    case addr is

                       when WSYNC_A => wsync_i   <= '1';
                       when RSYNC_A => rsync_i   <= '1';
                       when RESP0_A => resp0_i   <= '1';
                       when RESP1_A => resp1_i   <= '1';
                       when RESM0_A => resm0_i   <= '1';
                       when RESM1_A => resm1_i   <= '1';
                       when RESBL_A => resbl_i   <= '1';
                       when HMOVE_A => hmove_i   <= '1';
                       when HMCLR_A => hmclr_i_i <= '1';
                       when CXCLR_A => cxclr_i   <= '1';
                       when others  => null; -- Do nothing you lazy bastard.
                                             -- We don't care above the address
                                             -- in this process & in this case.
 
                    end case;

                end if;

             end if;

         end if;

    end process;

    -- The reference CPU clock (not a real clock) gates the 
    -- strobe outputs....
    wsync   <= wsync_i   and not(cpu_clk_ref);
    rsync   <= rsync_i   and not(cpu_clk_ref);
    resp0   <= resp0_i   and not(cpu_clk_ref);
    resp1   <= resp1_i   and not(cpu_clk_ref);
    resm0   <= resm0_i   and not(cpu_clk_ref);
    resm1   <= resm1_i   and not(cpu_clk_ref);
    resbl   <= resbl_i   and not(cpu_clk_ref);
    hmove   <= hmove_i   and not(cpu_clk_ref);
    hmclr_i <= hmclr_i_i and not(cpu_clk_ref);
    cxclr   <= cxclr_i   and not(cpu_clk_ref);

    -- Concurrent signal assignment required for hmclr.
    -- We could have used a "buffer" in the port map as 
    -- opposed to "out", but I'm old fashioned and stuck
    -- in the 80s with VHDL.
    hmclr <= hmclr_i;

end rtl;
