-------------------------------------------------------------------------------
--
--   File        : tia_cx_latches.vhd
--
--   Author      : Ed Henciak
--
--   Date        : December 18, 2004...uh, wait, December 19, 2004
--
--   Description : TIA -> Collision latches
--
--                 This is the bank of latches found in TIA that
--                 indicate when two bits overlap.  The user can
--                 read these latches to easily know when one object
--                 hits another.  Nice, huh?
--                 
--                 All constants, subtypes, tricks, trinkets and what-not
--                 are found in the TIA package.
--
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

library a2600;
    use a2600.tia_pkg.all;

entity tia_cx_latches is
port
(

   -- 2X clock for the latches
   clk      : in  std_logic;

   -- Signal which clears all latches
   cx_clr   : in  std_logic;

   -- Not in Vertical blank!
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
end tia_cx_latches;

architecture synth of tia_cx_latches is

   signal hit_vec : std_logic_vector(14 downto 0);

begin

   -- First, concurrently, the 15 AND gates are
   -- described here...these detect overlap...
   hit_vec(COL_M0P0) <= mis_0 and pl_0  and vblank_n;
   hit_vec(COL_M0P1) <= mis_0 and pl_1  and vblank_n;
   hit_vec(COL_M1P1) <= mis_1 and pl_1  and vblank_n;
   hit_vec(COL_M1P0) <= mis_1 and pl_0  and vblank_n;
   hit_vec(COL_P0BL) <= pl_0  and ball  and vblank_n;
   hit_vec(COL_P0PF) <= pl_0  and playf and vblank_n;
   hit_vec(COL_P1BL) <= pl_1  and ball  and vblank_n;
   hit_vec(COL_P1PF) <= pl_1  and playf and vblank_n;
   hit_vec(COL_M0BL) <= mis_0 and ball  and vblank_n;
   hit_vec(COL_M0PF) <= mis_0 and playf and vblank_n;
   hit_vec(COL_M1BL) <= mis_1 and ball  and vblank_n;
   hit_vec(COL_M1PF) <= mis_1 and playf and vblank_n;
   hit_vec(COL_BLPF) <= ball  and playf and vblank_n;
   hit_vec(COL_M0M1) <= mis_0 and mis_1 and vblank_n;
   hit_vec(COL_P0P1) <= pl_0  and pl_1  and vblank_n;

   -- Next, we can use a generate statement to cleanly
   -- instantiate the 15 latches.
   generate_cx_latches : for i in 0 to 14 generate

       cx_latch : tia_latch
       port map(

           clk    => clk,
           set    => hit_vec(i),
           clear  => cx_clr,
           output => cx_vec(i)
       );

   end generate generate_cx_latches;


end synth;

