library ieee;
use ieee.std_logic_1164.all;

entity lfsr6 is
   port(clk: in std_logic;
		  prst: in std_logic;
		  cnt: in std_logic;
		  o: out std_logic_vector(5 downto 0)
	   );
end lfsr6;

architecture arch of lfsr6 is 
	
	signal d: std_logic_vector(5 downto 0);
	signal prst_l: std_logic := '1';

begin

	o <= d;

	process(clk, prst)
	begin

		if (clk'event and clk = '1') then
			if (prst = '1' and prst_l = '0') then
				prst_l <= '1'; 
			elsif (cnt = '1') then
				prst_l <= '0';
			end if;
		end if;

		if (clk'event and clk = '1') then
			if (cnt = '1') then
				if (prst_l = '1') then 
					d <= "000000";
				else
					d <= (d(0) xnor d(1)) & d(5 downto 1);
				end if;
			end if;
		end if;

	end process;

end arch;

library ieee;
use ieee.std_logic_1164.all;

entity cntr2 is
   port(clk: in std_logic;
		  rst: in std_logic;
		  en: in std_logic;
		  o: out std_logic_vector(1 downto 0)
	   );
end cntr2;

architecture arch of cntr2 is 

	signal d: std_logic_vector(1 downto 0) := "00";

begin

	o <= d;

	process(clk, rst)
	begin
		if (clk'event and clk = '1') then
			if (rst = '1') then
				d <= "00";
			elsif (en = '1') then
				case d is
					when "00" => d <= "10";
					when "10" => d <= "11";
					when "11" => d <= "01";
					when "01" => d <= "00";
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
end arch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cntr3 is
   port(clk: in std_logic;
		  rst: in std_logic;
		  en: in std_logic;
		  o: out std_logic_vector(2 downto 0)
	   );
end cntr3;

architecture arch of cntr3 is 
	
	signal d: unsigned(2 downto 0) := "000";
	
begin

	o <= std_logic_vector(d);

	process(clk, rst)
	begin
		if (clk'event and clk = '1') then
			if (rst = '1') then 
				d <= "000";
			elsif (en = '1') then
				d <= d + 1;
			end if;
		end if;
	end process;

end arch;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity player is
   port(clk: in std_logic;
		  prst: in std_logic;
		  count: in std_logic;
		  nusiz: in std_logic_vector(2 downto 0);
		  reflect: in std_logic;
		  grpnew: in std_logic_vector(7 downto 0);
		  grpold: in std_logic_vector(7 downto 0);
		  vdel: in std_logic;
		  mrst: out std_logic;
		  pix: out std_logic
	   );
end player;

architecture arch of player is 

	signal lfsr_out: std_logic_vector(5 downto 0);
	signal lfsr_rst: std_logic;
	signal lfsr_cnt: std_logic;

	signal cntr_out: std_logic_vector(1 downto 0);
	signal cntr_rst: std_logic;
	signal cntr_en: std_logic;

	signal scan_out: std_logic_vector(2 downto 0);
	signal scan_clk: std_logic := '0';
	signal scan_en: std_logic := '0';
	signal scan_cnt: std_logic;

	signal start: std_logic := '0';

	signal scan_adr: std_logic_vector(2 downto 0);

	signal pix_sel: std_logic_vector(1 downto 0);

	signal ph0: std_logic;
	signal ph1: std_logic;
	signal ph1_edge: std_logic;
	signal fstob: std_logic;

begin

	lfsr: work.lfsr6 port map(clk, lfsr_rst, lfsr_cnt, lfsr_out);
	cntr: work.cntr2 port map(clk, cntr_rst, cntr_en, cntr_out);
	scan: work.cntr3 port map(clk, '0', scan_cnt, scan_out); 

	ph0 <= '1' when (cntr_out = "00") else '0';
	ph1_edge <= '1' when (cntr_out = "10") else '0';
	ph1 <= '1' when (cntr_out = "11") else '0';

	cntr_rst <= prst;
	cntr_en <= count;

	lfsr_rst <= '1' when (lfsr_out = "101101") or (lfsr_out = "111111") or (prst = '1') else '0';
	lfsr_cnt <= '1' when (ph1_edge = '1') and (count = '1') else '0';

	mrst <= '1' when fstob = '1' and scan_out = "001" else '0';

	process(clk, count)
	begin
		if (clk'event and clk = '1' and count = '1') then
			if (ph1_edge = '1') then
				if (lfsr_out = "101101") or
					((lfsr_out = "111000") and ((nusiz = "001") or (nusiz = "011"))) or
					((lfsr_out = "101111") and ((nusiz = "011") or (nusiz = "010") or (nusiz = "110"))) or
					((lfsr_out = "111001") and ((nusiz = "100") or (nusiz = "110"))) then
					start <= '1';
					if (lfsr_out = "101101") then
						fstob <= '1';
					else
						fstob <= '0';
					end if;
				else
					start <= '0';
				end if;
			end if;
		end if;
	end process;

	process(clk, scan_clk, start, scan_out, count)
	begin
		if (clk'event and clk = '1' and count = '1') then
			if (scan_clk = '1') then
				if (start = '1') then
					scan_en <= '1';
				elsif (scan_out = "111") then
					scan_en <= '0';
				end if;
			end if;
		end if;
	end process;

	process (clk, ph0, ph1, count)
	begin
		if (clk'event and clk = '1' and count = '1') then
			if (nusiz = "111") then
				scan_clk <= ph1;
			elsif (nusiz = "101") then
				scan_clk <= ph0 or ph1;
			else
				scan_clk <= '1';
			end if;
		end if;
	end process;

	scan_adr <= scan_out when reflect = '1' else not scan_out;

	scan_cnt <= scan_en and scan_clk and count;

	pix_sel <= scan_en & vdel;
	with pix_sel select pix <=
		grpnew(to_integer(unsigned(scan_adr))) when "10",
		grpold(to_integer(unsigned(scan_adr))) when "11",
		'0' when others;

end arch;

library ieee;
use ieee.std_logic_1164.all;

entity missile is
   port(clk: in std_logic;
		  prst: in std_logic;
		  count: in std_logic;
		  enable: in std_logic;
		  nusiz: in std_logic_vector(2 downto 0);
		  size: in std_logic_vector(1 downto 0);
		  pix: out std_logic
	   );
end missile;

architecture arch of missile is 

	signal lfsr_out: std_logic_vector(5 downto 0);
	signal lfsr_rst: std_logic;
	signal lfsr_cnt: std_logic;

	signal cntr_out: std_logic_vector(1 downto 0);
	signal cntr_rst: std_logic;
	signal cntr_en: std_logic;

	signal start1: std_logic := '0';
	signal start2: std_logic := '0';

	signal ph1: std_logic;
	signal ph1_edge: std_logic;

begin

	lfsr: work.lfsr6 port map(clk, lfsr_rst, lfsr_cnt, lfsr_out);
	cntr: work.cntr2 port map(clk, cntr_rst, cntr_en, cntr_out);

	ph1_edge <= '1' when (cntr_out = "10") else '0';
	ph1 <= '1' when (cntr_out = "11") else '0';

	cntr_rst <= prst;
	cntr_en <= count;

	lfsr_rst <= '1' when (lfsr_out = "101101") or (lfsr_out = "111111") or (prst = '1') else '0';
	lfsr_cnt <= '1' when (ph1_edge = '1') and (count = '1') else '0';

	process(clk)
	begin 
		if (clk'event and clk = '1') then                       
			if (ph1_edge = '1') then            
				if (lfsr_out = "101101") or
					((lfsr_out = "111000") and ((nusiz = "001") or (nusiz = "011"))) or 
					((lfsr_out = "101111") and ((nusiz = "011") or (nusiz = "010") or (nusiz = "110"))) or 
					((lfsr_out = "111001") and ((nusiz = "100") or (nusiz = "110"))) then
					start1 <= '1';                  
				else 
					start1 <= '0';
				end if;

				start2 <= start1;
			end if;
		end if;
	end process;

	pix <= '1' when 
		(enable = '1' and (
			(start1 = '1' and (
				(size(1) = '1') or 
				(ph1 = '1') or 
				(cntr_out(0) = '1' and size(0) = '1'))) or
				(start2 = '1' and size = "11")))
		else '0';

end arch;

library ieee;
use ieee.std_logic_1164.all;

entity ball is
   port(clk: in std_logic;
		  prst: in std_logic;
		  count: in std_logic;
		  ennew: in std_logic;
		  enold: in std_logic;
		  vdel: in std_logic;
		  size: in std_logic_vector(1 downto 0);
		  pix: out std_logic
	   );
end ball;

architecture arch of ball is 

	signal lfsr_out: std_logic_vector(5 downto 0);
	signal lfsr_rst: std_logic;
	signal lfsr_cnt: std_logic;

	signal cntr_out: std_logic_vector(1 downto 0);
	signal cntr_rst: std_logic;
	signal cntr_en: std_logic;

	signal start1: std_logic := '0';
	signal start2: std_logic := '0';

	signal ph1: std_logic;
	signal ph1_edge: std_logic;
	
begin

	lfsr: work.lfsr6 port map(clk, lfsr_rst, lfsr_cnt, lfsr_out);
	cntr: work.cntr2 port map(clk, cntr_rst, cntr_en, cntr_out);

	ph1_edge <= '1' when (cntr_out = "10") else '0';
	ph1 <= '1' when (cntr_out = "11") else '0';

	cntr_rst <= prst;
	cntr_en <= count;

	lfsr_rst <= '1' when (lfsr_out = "101101") or (lfsr_out = "111111") or (prst = '1') else '0';
	lfsr_cnt <= '1' when (ph1_edge = '1') and (count = '1') else '0';

	process(clk)
	begin 
		if (clk'event and clk = '1') then
			if (ph1_edge = '1') then
				if (lfsr_out = "101101") or (prst = '1') then
					start1 <= '1';
				else
					start1 <= '0';
				end if;

				start2 <= start1;
			end if;
		end if;
	end process;

	pix <= '1' when 
		((ennew = '1' and vdel = '0') or (enold = '1' and vdel = '1')) and (
			(start1 = '1' and (
				(size(1) = '1') or 
				(ph1 = '1') or 
				(cntr_out(0) = '1' and size(0) = '1'))) or
			(start2 = '1' and size = "11"))
		else '0';

end arch;
