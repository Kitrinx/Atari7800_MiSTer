-------------------------------------------------------------------------------
--
--   Copyright (C) 2005
--
--   Title     :  Atari 2600 TIA 
--
--   Author    :  Ed Henciak 
--
--   Notes     :  This basically determines which pixel of the PF, BG,
--                Ball, missile or player to shift out when we're not in
--                a blank interval.
-- 
--                I only put the combinational logic part of the video mux
--                in this circuit.  I am using a lookup table at a higher
--                level to translate color and luma values to those
--                that will eventually drive the DAC on the output of the
--                FPGA...
--
--   Date      :  1-29-2005
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

library A2600;
    use A2600.tia_pkg.all;

entity tia_vidmux is
port
(

    -- Clock input (2X) for the latch
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
    -- an FPGA....yet :)!
    vid_lum     : out std_logic_vector(2 downto 0); -- Luminance
    vid_color   : out std_logic_vector(3 downto 0); -- Color
    vid_blank_n : out std_logic                     -- blank_n (1 CLKP delay)

);
end tia_vidmux;

architecture synth of tia_vidmux is

   -- Output of center of screen latch.
   signal lat_cnt : std_logic;

begin

   -- First, a latch is used to trap the center delayed
   -- pulse sent to us from horizontal control (tia_ctl_pf).
   cntd_latch :  tia_latch
   port map
   (

       -- Clock the "latch"
       clk    => clk,

       -- Bits that set and clear
       set    => cntd,
       clear  => blank,

       -- Our output bit...
       output => lat_cnt 

   );

   -- NOTE : The following is text I left here for reference.
   -- I got so sick of staring at the schematics and deducing
   -- what a VHDL based if-elsif priority encoder would look like.
   -- So, what I did is explicitly write out the gates and built
   -- the encoder based on the following blather.  This blather and
   -- the end result are functionally equivalent...
  
   -- We need the latch's compliment
   -- lat_cnt_n <= not(lat_cnt);

   -- Next, we need to see which color register is selected
   -- for ouptut...a whole bunch of combinational logic is used
   -- to determine which color is selected.  Migrate this to
   -- a priority encoder once it's better understood.

   -- Invert settings from the write registers.
   -- no_score      <= not(score);
   -- pf_prio_n     <= not(pf_prio); 

   -- Some gates that check for certain graphic bit
   -- settings...
   -- no_pf_or_ball <= g_pf nor g_bl;
   -- no_pf         <= not(g_pf);

   -- Gate 1
   -- gate_1 <= not(lat_cnt or no_pf or no_score);

   -- Gate 3
   -- gate_3 <= not(gate_1 or g_p0 or g_m0);

   -- Gate 5
   -- gate_5 <= not(no_pf_prio or no_pf_or_ball);

   ----------------------------------
   -- This enables the player 0 color
   ----------------------------------
   -- en_p0_color <= not(blank or gate_3 or gate_5);

   -- More gates...

   -- gate_2 <= not(no_lat_cnt or no_score or no_pf);

   -- gate_4 <= not(gate_2 or g_p1 or g_m1);

   ----------------------------------
   -- This enables Player 1 color
   ----------------------------------
   -- en_p1_color <= not(en_p0_color or blank or gate_5 or gate_4);


   ----------------------------------
   -- This enables Playfield color
   ----------------------------------
   -- en_pf_color <= not(en_p0_color or en_p1_color or blank or pf_prio_n);

   ----------------------------------
   -- This enables Background color
   ----------------------------------
   -- en_bg_color <= not(blank or en_p0_color or en_p1_color or en_pf_color);

   -- Now for the real stuff....

   -- This is the priority encoder which either
   -- selects no color or one of the four color
   -- registers....there are a lot of signals in
   -- play here....make sure all of them are in the
   -- sensitivity list!!!!!!!!!!!!  Simulations will
   -- be erroneous otherwise!  TIA actually outputs
   -- the compliments of the luma values seen below!
   process(blank , score, pf_prio, g_pf  , g_bl  , g_p0  , g_m0,
           g_p1  ,  g_m1, lat_cnt, colup0, colup1, colupf,
           colubk) 

   begin

      -- When we're blanked, darkness is in the air!
      if (blank = '1') then

          vid_lum   <= (others => '0');
          vid_color <= (others => '0');

      -- We're not blanked...turn on a color!
      else

          -- First, determine if player 0 is the color
          -- selected...this one's complicated...

          -- Either we're not centered and there's a playfield bit
          -- and we're drawing the score such that it 
          -- takes the player's color...
          if ( (((lat_cnt = '0') and
                 (g_pf    = '1') and
                 (score   = '1')) 

                       or

                -- ... or there's a player or missile drawn for
                -- player 0.
                ((g_p0    = '1')  or
                 (g_m0    = '1'))) 

                      and

                -- And there's either no playfield drawing priority or
                -- playfield bit and ball bit drawn.
                ((pf_prio = '0') or

                 ((g_pf    = '0') and 
                  (g_bl    = '0')))   ) then     


                   -- Take the player 0 color!
                   vid_lum   <= colup0(2 downto 0);
                   vid_color <= colup0(6 downto 3);

          -- OK, Player wasn't selected, so check for 
          -- player 1...

          -- Either we're centered and there's a playfield bit
          -- and we're drawing the score such that it 
          -- takes the player's color
          elsif ( (((lat_cnt = '1') and
                    (g_pf    = '1') and
                    (score   = '1')) 

                          or

                   -- ... or there's a player or missile drawn for
                   -- player 1.
                   ((g_p1    = '1')  or
                    (g_m1    = '1'))) 

                         and

                   -- And there's either no playfield drawing priority or
                   -- no playfield bit and no ball bit drawn.
                   ((pf_prio = '0') or

                    ((g_pf    = '0') and 
                     (g_bl    = '0')))   ) then     

                   -- Take the player 1 color!
                   vid_lum   <= colup1(2 downto 0);
                   vid_color <= colup1(6 downto 3);

          -- OK, if we got here, then check to see if we should 
          -- enable the playfield color!
          elsif(g_pf = '1') or (g_bl = '1') then

                   -- Take the playfield color...
                   vid_lum   <= colupf(2 downto 0);
                   vid_color <= colupf(6 downto 3);

          -- Draw the background....nothing else needed drawn!
          else
                   -- Take the background color...
                   vid_lum   <= colubk(2 downto 0);
                   vid_color <= colubk(6 downto 3);

          end if;


      end if;

   end process;

   -- Concurrent signal assignments...There is still one pix_clk (CLKP)
   -- delay to take into account, but that'll be done at a higher level.
   -- Also, we invert blank here....we'll register delay it with the
   -- color lookup table...note that the needed register delay applies to
   -- all signals output from this block of logic.
   vid_blank_n <= not(blank);

end synth;
