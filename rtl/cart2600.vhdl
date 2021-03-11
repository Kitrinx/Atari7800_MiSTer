-- A2601 Top Level Entity (ROM stored in on-chip RAM)
-- Copyright 2006, 2010 Retromaster
--
--  This file is part of A2601.
--
--  A2601 is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License,
--  or any later version.
--
--  A2601 is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with A2601.  If not, see <http://www.gnu.org/licenses/>.
--

-- This top level entity supports a single cartridge ROM stored in FPGA built-in
-- memory (such as Xilinx Spartan BlockRAM). To generate the required cart_rom
-- entity, use bin2vhdl.py found in the util directory.
--
-- For more information, see the A2601 Rev B Board Schematics and project
-- website at <http://retromaster.wordpress.org/a2601>.

-- Info about cart sizes
-- http://www.qotile.net/minidig/docs/sizes.txt

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity ramx8 is
    generic(addr_width : integer := 7);
    port(clk: in std_logic;
         r: in std_logic;
         d_in: in std_logic_vector(7 downto 0);
         d_out: out std_logic_vector(7 downto 0);
         a: in std_logic_vector(addr_width - 1 downto 0));
end ramx8;

architecture arch of ramx8 is
    type ram_type is array (0 to 2**addr_width - 1) of
        std_logic_vector(7 downto 0);
    signal ram: ram_type;
begin

    process (clk, r, a)
    begin
        if (clk'event and clk = '1') then
            if (r = '1') then
                d_out <= ram(to_integer(unsigned(a)));
            else
                ram(to_integer(unsigned(a))) <= d_in;
            end if;
        end if;
    end process;

end arch;

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity cart2600 is
   port (
		reset     : in std_logic;
		clk       : in std_logic;
		ph0_en    : in std_logic;

		cpu_d_out : out std_logic_vector(7 downto 0);
		cpu_d_in  : in  std_logic_vector(7 downto 0);
	   cpu_a     : in  std_logic_vector(12 downto 0);
		
		sc        : in  std_logic; --SuperChip enable
		force_bs  : in  std_logic_vector(3 downto 0); -- forced bank switch type
		rom_a     : out std_logic_vector(15 downto 0);
		rom_do    : in  std_logic_vector(7 downto 0);
		rom_size  : in  std_logic_vector(16 downto 0)

	);
end cart2600;

architecture arch of cart2600 is

signal a_ram: std_logic_vector(14 downto 0);
signal pa: std_logic_vector(7 downto 0);
signal pb: std_logic_vector(7 downto 0);
signal inpt4: std_logic;
signal inpt5: std_logic;
signal au0: std_logic;
signal au1: std_logic;
signal av0: std_logic_vector(3 downto 0);
signal av1: std_logic_vector(3 downto 0);

signal rst: std_logic := '1';
signal old_rst: std_logic := '1';
signal sys_clk_dvdr: unsigned(4 downto 0) := "00000";

--signal ph0_en: std_logic;

signal rgbx2: std_logic_vector(23 downto 0);
signal hsyn: std_logic;
signal vsyn: std_logic;

signal ctrl_cntr: unsigned(3 downto 0);
signal p_fn: std_logic;

signal rst_cntr: unsigned(12 downto 0) := "0000000000000";
signal sc_clk: std_logic;
signal sc_r: std_logic;
signal sc_d_out: std_logic_vector(7 downto 0);
signal sc_a: std_logic_vector(10 downto 0);
signal clr_a: std_logic_vector(10 downto 0);

subtype bss_type is std_logic_vector(3 downto 0);

signal bank: std_logic_vector(3 downto 0) := "0000";
signal banks32: std_logic_vector(4 downto 0) := "00000";
signal last_1FF0: std_logic;
signal tf_bank: std_logic_vector(1 downto 0);
signal e0_bank: std_logic_vector(2 downto 0);
signal e0_bank0: std_logic_vector(2 downto 0) := "000";
signal e0_bank1: std_logic_vector(2 downto 0) := "000";
signal e0_bank2: std_logic_vector(2 downto 0) := "000";

signal FE_latch: std_logic;

signal e7_bank0: std_logic_vector(2 downto 0);   -- 1000-17ff
signal e7_rambank: std_logic_vector(1 downto 0); -- 1800-19ff

--signal cpu_a: std_logic_vector(12 downto 0);
--signal cpu_d: std_logic_vector(7 downto 0);

constant BANK00: bss_type := "0000";
constant BANKF8: bss_type := "0001";
constant BANKF6: bss_type := "0010";
constant BANKFE: bss_type := "0011";
constant BANKE0: bss_type := "0100";
constant BANK3F: bss_type := "0101";
constant BANKF4: bss_type := "0110";
constant BANKP2: bss_type := "0111";
constant BANKFA: bss_type := "1000";
constant BANKCV: bss_type := "1001";
constant BANK2K: bss_type := "1010";
constant BANKUA: bss_type := "1011";
constant BANKE7: bss_type := "1100";
constant BANKF0: bss_type := "1101";
constant BANK32: bss_type := "1110";

signal bss:  bss_type := BANK00; 	--bank switching method
 
signal paddle_ena12 : std_logic := '0';
signal paddle_ena34 : std_logic := '0';

signal inpt03_chg: std_logic;
signal inpt0, pd0: std_logic;
signal inpt1, pd1: std_logic;
signal inpt2, pd2: std_logic;
signal inpt3, pd3: std_logic;


--- DPC signals
type B3_type is array(2 downto 0) of std_logic_vector(7 downto 0);
type B8_type is array(0 to 7) of std_logic_vector(7 downto 0);
type B8_11_type is array(7 downto 0) of std_logic_vector(10 downto 0);

signal soundAmplitudes : B8_type := (
	0 => x"00",
	1 => x"04",
	2 => x"05",
	3 => x"09",
	4 => x"06",
	5 => x"0a",
	6 => x"0b",
	7 => x"0f"
	);

signal DpcMusicModes : B3_type := (	others => (others=>'0'));
signal DpcMusicFlags : B3_type := (	others => (others=>'0'));
signal DpcTops : B8_type := (	others => (others=>'0'));
signal DpcBottoms : B8_type := (	others => (others=>'0'));
signal DpcFlags : B8_type := (	others => (others=>'0'));
signal DpcCounters : B8_11_type := (	others => (others=>'0'));
signal DpcRandom	: std_logic_vector(7 downto 0) := x"01";
signal DpcWrite	: std_logic := '0';
signal DpcClocks : unsigned(15 downto 0) := (others=>'0');
signal clk_music : unsigned(3 downto 0) := (others=>'0');	 -- 3 e o melhor
signal DpcClockDivider : unsigned(9 downto 0);
 
begin

--cpu_d_out <= cpu_d;

process(clk)
begin
    if rising_edge(clk) then
		if ph0_en = '1' then
	        rst <= reset;
	    end if;
    end if;
end process;
ram: work.ramx8 generic map(11) port map(clk, sc_r, cpu_d_in, sc_d_out, sc_a);

sc_r <= '0' when rst = '1' else
        '1' when bss = BANKCV and cpu_a(12 downto 10) = "100" else
        '0' when bss = BANKCV and cpu_a(12 downto 10) = "101" else
        '1' when bss = BANKFA and cpu_a(12 downto  8) = "10001" else
        '0' when bss = BANKFA and cpu_a(12 downto  8) = "10000" else
        '1' when bss = BANKE7 and cpu_a(12 downto 11) = "10" and (cpu_a(10) = '1' or e7_bank0 /= "111") else -- 1400 - 17ff
        '0' when bss = BANKE7 and cpu_a(12 downto 10) = "100" and e7_bank0 = "111" else -- 1000-13ff
        '1' when bss = BANKE7 and cpu_a(12 downto  8) = "11001" else
        '0' when bss = BANKE7 and cpu_a(12 downto  8) = "11000" else
        '0' when (cpu_a(12 downto  7) = "100000" and sc = '1') or reset = '1' else '1';

sc_a <= clr_a                                when rst = '1'    else
        "0" & cpu_a(9 downto 0)              when bss = BANKCV else
        "000" & cpu_a(7 downto 0)            when bss = BANKFA else
        "0" & cpu_a(9 downto 0)              when bss = BANKE7 and cpu_a(12 downto 11) = "10" else
        "1" & e7_rambank & cpu_a(7 downto 0) when bss = BANKE7 and cpu_a(12 downto 9) = "1100" else
        "0000" & cpu_a(6 downto 0);

-- ROM and SC output
process(cpu_a, rom_do, sc_d_out, sc, bss, DpcFlags, DpcRandom, DpcMusicModes, DpcMusicFlags, soundAmplitudes, e7_bank0)
	variable ampI_v :std_logic_vector(2 downto 0);
	variable masked0_v :std_logic_vector(7 downto 0);
	variable masked1_v :std_logic_vector(7 downto 0);
	variable masked2_v :std_logic_vector(7 downto 0);
	variable newlow_v : integer;
begin
	if (bss = BANKP2 and cpu_a >= "1" & x"008" and cpu_a <= "1" & x"00f")  then -- DPC READ - 0x1008 to 0x100f (read graphics from extra 2kb)
		cpu_d_out <= rom_do;
	elsif (bss = BANKP2 and cpu_a >= "1" & x"010" and cpu_a <= "1" & x"017")  then -- DPC READ - 0x1010 to 0x1017 (read graphics from extra 2kb ANDed)
		cpu_d_out <= rom_do and DpcFlags(to_integer(unsigned(cpu_a(2 downto 0))));
	elsif (bss = BANKP2 and cpu_a >= "1" & x"000" and cpu_a <= "1" & x"003") then -- DPC READ - 0x1000 to 0x1003 (random number)
		cpu_d_out <= DpcRandom;
	elsif (bss = BANKP2 and cpu_a >= "1" & x"004" and cpu_a <= "1" & x"007") then -- DPC READ - 0x1004 to 0x1007 (Sound)
		ampI_v := "000";

		if DpcMusicModes(0)(4) = '1' and DpcMusicFlags(0)(4) = '1' then ampI_v(0) := '1'; end if;
		if DpcMusicModes(1)(4) = '1' and DpcMusicFlags(1)(4) = '1' then ampI_v(1) := '1'; end if;
		if DpcMusicModes(2)(4) = '1' and DpcMusicFlags(2)(4) = '1' then ampI_v(2) := '1'; end if;

		cpu_d_out <= soundAmplitudes(to_integer(unsigned(ampI_v)));

	elsif (bss = BANKP2 and cpu_a >= "1" & x"038" and cpu_a <= "1" & x"03f") then -- DPC READ -  0x1038 to 0x103f (Flags)
		cpu_d_out <= DpcFlags(to_integer(unsigned(cpu_a(2 downto 0))));
--	elsif (bss = BANKP2 and cpu_a >= "1" & x"040" and cpu_a <= "1" & x"07f") then
--		cpu_d_out <= "ZZZZZZZZ";

	elsif bss = BANKCV and cpu_a(12 downto 10) = "100" then
		cpu_d_out <= sc_d_out;
--	elsif bss = BANKCV and cpu_a(12 downto 10) = "101" then
--		cpu_d_out <= "ZZZZZZZZ";
	elsif bss = BANKFA and cpu_a(12 downto 8) = "10001" then
		cpu_d_out <= sc_d_out;
--	elsif bss = BANKFA and cpu_a(12 downto 8) = "10000" then
--		cpu_d_out <= "ZZZZZZZZ";

	elsif bss = BANKE7 and cpu_a(12 downto 10) = "101" and e7_bank0 = "111" then
		cpu_d_out <= sc_d_out;
--	elsif bss = BANKE7 and cpu_a(12 downto 10) = "100" and e7_bank0 = "111" then
--		cpu_d_out <= "ZZZZZZZZ";
	elsif bss = BANKE7 and cpu_a(12 downto 8) = "11001" then
		cpu_d_out <= sc_d_out;
--	elsif bss = BANKE7 and cpu_a(12 downto 8) = "11000" then
--		cpu_d_out <= "ZZZZZZZZ";

	elsif (cpu_a(12 downto 7) = "100001" and sc = '1') then
		cpu_d_out <= sc_d_out;
--	elsif (cpu_a(12 downto 7) = "100000" and sc = '1') then
--		cpu_d_out <= "ZZZZZZZZ";
	elsif (cpu_a(12) = '1') then
		cpu_d_out <= rom_do;
	else
		cpu_d_out <= "00000000";
	end if;
end process;

with cpu_a(11 downto 10) select e0_bank <=
	e0_bank0 when "00",
	e0_bank1 when "01",
	e0_bank2 when "10",
	"111" when "11",
	"---" when others;

tf_bank <= bank(1 downto 0) when (cpu_a(11) = '0') else "11";

rom_a <= "000" & e0_bank & cpu_a(9 downto 0)  when bss = BANKE0 else
         "000" & tf_bank & cpu_a(10 downto 0) when bss = BANK3F else
         "00100" & std_logic_vector(not DpcCounters(to_integer(unsigned(cpu_a(2 downto 0))))(10 downto 0))
                                              when bss = BANKP2 and cpu_a >= "1" & x"008" and cpu_a <= "1" & x"017" else
         "00000" & cpu_a(10 downto 0)         when bss = BANKCV else
         "00000" & cpu_a(10 downto 0)         when bss = BANK2K else
         "00" & e7_bank0 & cpu_a(10 downto 0) when bss = BANKE7 and cpu_a(12 downto 11) = "10" else
         "00111" & cpu_a(10 downto 0)         when bss = BANKE7 and (cpu_a(12 downto 11) = "11" or cpu_a(12 downto 10) = "101") else
         banks32 & cpu_a(10 downto 0)         when bss = BANK32 else
         bank(3 downto 0) & cpu_a(11 downto 0);

bankswch: process(clk)
	variable w_index_v :integer; 
	variable addr_v :std_logic_vector(12 downto 0); 
	variable DpcCounterNext: std_logic_vector(10 downto 0);
begin
    if rising_edge(clk) then
		if ph0_en = '1' then
			old_rst <= rst;
			clr_a <= clr_a + 1;
			if (rst = '1') then
				bank <= "0000";
				last_1FF0 <= '0';
				e0_bank0 <= "000";
				e0_bank1 <= "000";
				e0_bank2 <= "000";
				if old_rst = '0' then
					banks32 <= banks32 + 1;
				end if;
				if bss /= BANK32 then
					banks32 <= "00000";
				end if;
			else
				case bss is
					when BANKFA =>
						if (cpu_a = "1" & X"FF8") then
							bank <= "0000";
						elsif (cpu_a = "1" & X"FF9") then
							bank <= "0001";
						elsif (cpu_a = "1" & X"FFA") then
							bank <= "0010";
						end if;
					when BANKF8 =>
						if (cpu_a = "1" & X"FF8") then
							bank <= "0000";
						elsif (cpu_a = "1" & X"FF9") then
							bank <= "0001";
						end if;
					when BANKF6 =>
						if (cpu_a = "1" & X"FF6") then
							bank <= "0000";
						elsif (cpu_a = "1" & X"FF7") then
							bank <= "0001";
						elsif (cpu_a = "1" & X"FF8") then
							bank <= "0010";
						elsif (cpu_a = "1" & X"FF9") then
							bank <= "0011";
						end if;
					when BANKF4 =>
						if (cpu_a = "1" & X"FF4") then
							bank <= "0000";
						elsif (cpu_a = "1" & X"FF5") then
							bank <= "0001";
						elsif (cpu_a = "1" & X"FF6") then
							bank <= "0010";
						elsif (cpu_a = "1" & X"FF7") then
							bank <= "0011";
						elsif (cpu_a = "1" & X"FF8") then
							bank <= "0100";
						elsif (cpu_a = "1" & X"FF9") then
							bank <= "0101";
						elsif (cpu_a = "1" & X"FFA") then
							bank <= "0110";
						elsif (cpu_a = "1" & X"FFB") then
							bank <= "0111";
						end if;
					when BANKP2 => -- DPC - included by Victor Trucco - 25/05/2018
						if cpu_a /= addr_v then -- single execution for each cpu address
							addr_v := cpu_a;
	
							if (cpu_a(12) = '1' ) then -- A12 - HIGH
								w_index_v := to_integer(unsigned(cpu_a(2 downto 0)));
								if (cpu_a(12 downto 6) = "1000000") then -- DPC READ - 0x1000 to 0x103F (1 0000 0000 0000 to 1 0000 0011 1111)

									case cpu_a(5 downto 3)  is
										when "000" =>  -- 0x1000 to 0x1007 - random number and music fetcher
											if(cpu_a(2) = '0') then -- 0x1000 to 0x1003
												-- random number read
												DpcRandom <= DpcRandom(6 downto 0) & (not(DpcRandom(7) xor DpcRandom(5) xor DpcRandom(4) xor DpcRandom(3)));
											end if;
										when others => NULL;
									end case;
	
									-- Clock the selected data fetcher's counter if needed
                                    DpcCounterNext := DpcCounters(w_index_v);
									if (w_index_v < 5 or (w_index_v >= 5 and DpcMusicModes(5 - w_index_v)(4) = '1')) then
										DpcCounterNext := DpcCounters(w_index_v) - 1;
									end if;

									DpcCounters(w_index_v) <= DpcCounterNext;
									-- Update flag register for selected data fetcher
									if (DpcCounterNext(7 downto 0) = DpcTops(w_index_v)) then
										 DpcFlags(w_index_v) <= x"ff";
									elsif (DpcCounterNext(7 downto 0) = DpcBottoms(w_index_v)) then
										 DpcFlags(w_index_v) <= x"00";
									end if;

								elsif (cpu_a(12 downto 6) = "1000001") then -- DPC WRITE - 0x1040 to 0x107F (1 0000 0100 0000 to 1 0000 0111 1111)
									case cpu_a(5 downto 3)  is
										when "000" => --0x1040 to 0x1047
											-- DFx top count
											DpcTops(w_index_v) <= cpu_d_in;
                                            if (DpcCounters(w_index_v)(7 downto 0) = cpu_d_in) then
                                                DpcFlags(w_index_v) <= x"ff";
                                            else
												DpcFlags(w_index_v) <= x"00";
                                            end if;
										when "001" => -- 0x1048 to 0x104F
											-- DFx bottom count
											DpcBottoms(w_index_v) <= cpu_d_in;
										when "010" => -- 0x1050 to 0x1057
											-- DFx counter low
											DpcCounters(w_index_v)(7 downto 0) <= cpu_d_in;
										when "011" => -- 0x1058 to 105F
											-- DFx counter high
											DpcCounters(w_index_v)(10 downto 8) <= cpu_d_in(2 downto 0);
											if(w_index_v >= 5) then -- 0x105D to 0x105F
												DpcMusicModes(5 - w_index_v) <= "000" & cpu_d_in(4) & "0000"; -- Music On or Off
											end if;
										when "110" => -- 0x1070 to 0x1077
											DpcRandom <= x"01";
										when others => NULL;
									end case;
								else
									-- bank switch F8 style
									if (cpu_a = "1" & X"FF8") then
										bank <= "0000";
									elsif (cpu_a = "1" & X"FF9") then
										bank <= "0001";
									end if;
								end if;
							end if;
						end if;
					when BANKFE => -- BANK FE fixed by Victor Trucco - 24/05/2018
						-- If was latched, check the 5th bit of the data bus for the bank-switch
						if FE_latch = '1' then
							bank <= "000"& not cpu_d_in(5);
						end if;
	
						-- Access at 0x01fe trigger the latch, but on the next cpu cycle
						if (cpu_a(12 downto 0) = "0000111111110" ) then -- 0x01FE
							FE_latch <= '1';
						else
							FE_latch <= '0';
						end if;
					when BANKE0 =>
						if (cpu_a(12 downto 4) = "1" & X"FE" and cpu_a(3) = '0') then
							e0_bank0 <= cpu_a(2 downto 0);
						elsif (cpu_a(12 downto 4) = "1" & X"FE" and cpu_a(3) = '1') then
							e0_bank1 <= cpu_a(2 downto 0);
						elsif (cpu_a(12 downto 4) = "1" & X"FF" and cpu_a(3) = '0') then
							e0_bank2 <= cpu_a(2 downto 0);
						end if;
					when BANK3F =>
						if (cpu_a = "0" & X"03F") then
							bank(1 downto 0) <= cpu_d_in(1 downto 0);
						end if;
					when BANKUA =>
						if (cpu_a = "0" & X"220") then
							bank <= "0000";
						elsif (cpu_a = "0" & X"240") then
							bank <= "0001";
						end if;
					when BANKE7 =>
						if cpu_a(12 downto 4) = "1" & X"FE" then
							if cpu_a(3) = '0' then
								e7_bank0 <= cpu_a(2 downto 0);   -- FE0-FE7
							elsif cpu_a(2) = '0' then
								e7_rambank <= cpu_a(1 downto 0); -- FE8-FEB
							end if;
						end if;
					when BANKF0 =>
						if cpu_a = "1" & X"FF0" then
							if last_1FF0 = '0' then
								bank <= bank + 1;
							end if;
							last_1FF0 <= '1';
						else
							last_1FF0 <= '0';
						end if;
					when others =>
						null;
				end case;
			end if;
		end if;
	end if;
end process;

-- derive banking scheme from cartridge size
process(rom_size, force_bs)
begin
	if(force_bs /= "0000") then
		bss <= force_bs;
	elsif(rom_size  = '0'&x"0000") then
		bss <= BANK00;
	elsif(rom_size <= '0'&x"0800") then -- 2k and less
		bss <= BANK2K;
	elsif(rom_size <= '0'&x"1000") then -- 4k and less
		bss <= BANK00;
	elsif(rom_size <= '0'&x"2000") then -- 8k and less
		bss <= BANKF8;
	elsif (rom_size>='0'&x"2800" and rom_size<= '0'&x"2900") then -- 10k+256 and less, should be > 10k < 10k+256?
		bss <= BANKP2;
	elsif(rom_size <= '0'&x"3000") then -- 12k and less
		bss <= BANKFA;
	elsif(rom_size <= '0'&x"4000") then -- 16k and less
		bss <= BANKF6;
	elsif(rom_size <= '0'&x"8000") then -- 32k and less
		bss <= BANKF4;
	elsif(rom_size <= '1'&x"0000") then -- 64k and less
		bss <= BANK32;
	else
		bss <= BANK00;
	end if;
end process;

process (clk)
begin
	if rising_edge(clk) then
		DpcClockDivider <= DpcClockDivider + 1;
		if DpcClockDivider = 342 then DpcClockDivider <= (others => '0'); end if; --(~ 10.5 kHz)
		if DpcClockDivider = 0 then
			DpcClocks <= DpcClocks + 1;
			if to_integer(unsigned(DpcClocks)) mod to_integer(unsigned(DpcTops(5))+1) > DpcBottoms(5) then
				DpcMusicFlags(0) <= x"ff";
			else
				DpcMusicFlags(0) <= x"00";
			end if;
			if to_integer(unsigned(DpcClocks)) mod to_integer(unsigned(DpcTops(6))+1) > DpcBottoms(6) then
				DpcMusicFlags(1) <= x"ff";
			else
				DpcMusicFlags(1) <= x"00";
			end if;
			if to_integer(unsigned(DpcClocks)) mod to_integer(unsigned(DpcTops(7))+1) > DpcBottoms(7) then
				DpcMusicFlags(2) <= x"ff";
			else
				DpcMusicFlags(2) <= x"00";
			end if;
		end if;
	end if;
end process;

end arch;