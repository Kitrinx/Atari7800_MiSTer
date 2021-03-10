-------------------------------------------------------------------------------
--
--   Copyright (C) 2004
--
--   Title     :  Atari 2600 RIOT chip.
--
--   Author    :  Ed Henciak 
--
--   Date      :  December 14, 2004
--
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_arith.all;
    use IEEE.std_logic_unsigned.all;

library A2600;
    use A2600.riot_pkg.all;

-- Entity declaration

entity riot is
port
(
   -- Clock and reset 
   clk          : in  std_logic; -- input core clock sclk
   reset        : in  std_logic; -- async. input reset
   go_clk       : in  std_logic; -- restrictor
   go_clk_180   : in  std_logic; -- restrictor out of phase!

   -- IO Ports (Instantiate tristate @ higher level)
   port_a_in    : in  std_logic_vector(7 downto 0);
   port_a_out   : out std_logic_vector(7 downto 0);
   port_a_ctl   : out std_logic_vector(7 downto 0);

   port_b_in    : in  std_logic_vector(7 downto 0);
   port_b_out   : out std_logic_vector(7 downto 0);
   port_b_ctl   : out std_logic_vector(7 downto 0);

   -- Address and data bus (if you want bidir data,
   -- wrap this logic with the included wrapper).
   addr         : in  std_logic_vector(6 downto 0);
   din          : in  std_logic_vector(7 downto 0);
   dout         : out std_logic_vector(7 downto 0);

   -- Read/write
   rwn          : in  std_logic;

   -- RAM select
   ramsel_n     : in  std_logic;

   -- Chip selects
   cs1          : in  std_logic;
   cs2n         : in  std_logic;

   -- Interrupt (active low...use wrapper for "open drain")
   irqn         : out std_logic 

);
end riot;

architecture struct of riot is

   -- Internal chip select
   signal   chip_select   : std_logic;
 
   -- Data direction registers.
   signal   ddra, 
            ddrb          : std_logic_vector(7 downto 0);

   -- Data port I/O registers
   signal   irega, 
            iregb         : std_logic_vector(7 downto 0);
   signal   orega, 
            oregb         : std_logic_vector(7 downto 0);

   -- Current timer value
   signal   timer_val     : std_logic_vector(7 downto 0);

   -- Timer interrupt enable signal
   signal   timer_int_ena : std_logic;
   signal   timer_int     : std_logic;

   -- Timer divide rate type and signal declaration
   signal   timer_div     : timer_div_t;

   -- Divide timer counter
   signal   div_cnt       : std_logic_vector(9 downto 0);

   -- Current interrupt flags.
   signal   int_flags     : std_logic_vector(7 downto 0);

   -- This signal acts as interconnect to tie
   -- RAM read output to the read mux.
   signal   ram_rdata     : std_logic_vector(7 downto 0);

   signal   int_cnt_i     : integer;
   signal   int_cnt       : integer;

   signal   ramsel_ref    : std_logic;
   signal   ramsel        : std_logic;
   signal   ram_write     : std_logic;

   signal   timer_active  : std_logic;

begin

-----------------------------------------------------
-- This PIO is similar to the Motorola 6821
-- in that it has two bidirectional ports 
-- configured by the user.  However, this guy
-- also has a timer as well as an embedded 128x8
-- SRAM.  The following description intends to 
-- mimic the 6532 as described in the datasheets.
-- It is not optimized for power, does not have
-- registered I/O, etc.  I am merely developing 
-- this to recreate this component for use in an
-- Atari 2600 on a chip.  Therefore, please do not
-- harm me for not following proper RTL design 
-- rules.  Beatings or revoked job offers make me
-- feel rather sad.  Beatings hurt and revoked job 
-- offers are even worse if and only if its a cool
-- company doing the revoking.
-----------------------------------------------------

-----------------------------------------------------
-- P.S. It'd be nice if a supplier would make a PLD
-- with embedded memory so that we'd have a 
-- cheap replacement of these parts for old Gottlieb
-- pinball machines!  Remember Black Hole and Haunted
-- House you silly Xilinx, Altera, and Atmel people?
-- Of course, we'd also need 5V tolerant inputs, so
-- even if it does happen, I might as well forget it.
-----------------------------------------------------


--------------------------------------------------
-- All of the following deals with our happy, tiny
-- embedded SRAM.
--------------------------------------------------

-- Invert the RAM select and gate chip selects to
-- create the RAM enable....
ramsel    <= cs1 and not(cs2n) and not(ramsel_n) and go_clk;

-- Invert rwn for the RAM write enable
ram_write <= not(rwn);

-- Instantiate RAM (Xilinx)
-- pia_ram : xil_riot_ram
-- port map (

--   A   => addr,
--   CLK => clk,
--   D   => din,
--   WE  => ram_write,
--   I_CE => ramsel,
--   SPO => ram_rdata

-- );

pia_ram : spram
generic map (7)
port map (
    clock   => clk,
    address => addr,
    data    => din,
    enable  => '1',
    wren    => ram_write,
    q       => ram_rdata,
    cs      => ramsel
);

-- Create addressing control signals
chip_select <= cs1 and not(cs2n);
ramsel_ref  <= not(ramsel_n);

-- Create interrupt flags..
int_flags <= timer_int & "0000000";

-----------------------------------------------------
-- This process is combinational. It decodes the
-- address bus so that the proper location is read
-- out of the device when selected.  Think of it
-- as a "higher level" description of some fancy
-- multiplexor!
-----------------------------------------------------
read_decode : process(addr, ramsel_ref, ddra, ddrb, irega, 
                      iregb, timer_val, int_flags, ram_rdata)
begin

    -- If the ram is not selected, then
    -- one of the internal registers is chosen.
    if (ramsel_ref = '0') then

        case addr(2 downto 0) is

            -- DDRA is selected
            when "001"         => dout <= ddra;
            when "011"         => dout <= ddrb;
            when "000"         => dout <= irega;
            when "010"         => dout <= iregb;
            when "100" | "110" => dout <= timer_val;
            when "101" | "111" => dout <= int_flags;
            when others        => dout <= (others => '0');

        end case;

    -- If the RAM is selected, then read out the 
    -- RAM data.
    else
        dout <= ram_rdata;
    end if;

end process;

------------------------------------------------------
-- First, the following processes handle writes
-- to registers (i.e. not RAM) in the device.
-- Since I'd like to mimic the datasheets, it
-- appears that all data, etc. is registered on 
-- the falling edge of the clock if the uP is 
-- writing to the device.
------------------------------------------------------
write_ddr : process(clk, reset)
begin

    if (reset = '1') then

        ddra <= (others => '0');
        ddrb <= (others => '0');

    elsif(clk'event and clk = '1') then

        -- If we are on a valid clock...
        if (go_clk_180 = '1') then

           -- Only perform this if the chip is 
           -- selected and write is enabled.
           if (chip_select = '1') and 
              (ramsel_ref  = '0') and 
              (rwn         = '0') then

               -- If the proper address is selected, then
               -- write the appropriate DDR register.

               -- For DDR A ...
               if (addr(2 downto 0) = "001") then
                   ddra <= din;
               end if;

               -- For DDR B ...
               if (addr(2 downto 0) = "011") then
                   ddrb <= din;
               end if;

           end if;

        end if;

    end if;

end process;

------------------------------------------------------
-- Next, the port output reigsters are written if 
-- selected.  Note that not all bits are actually
-- output from the component...the DDR determines
-- if the bits are actually driven off chip.  Also,
-- again note that data is registered on the falling
-- edge of the device...
------------------------------------------------------
write_oregs : process(clk, reset)
begin

    if (reset = '1') then

        orega <= (others => '0');
        oregb <= (others => '0');

    elsif(clk'event and clk = '1') then

        -- If this is a valid clock...
        if (go_clk_180 = '1') then

            -- Only perform this operation if 
            -- the chip is selected and write is enabled...
            if (chip_select = '1') and 
               (ramsel_ref  = '1') and 
               (rwn         = '0') then

                -- For output register A ...
                if (addr(2 downto 0) = "000") then
                    orega <= din;
                end if;

                -- For output register B ...
                if (addr(2 downto 0) = "010") then
                    oregb <= din;
                end if;

            end if;

        end if;

    end if;

end process;

-- Port output
port_a_out <= orega;
port_b_out <= oregb;

-- Port control
port_a_ctl <= ddra;
port_b_ctl <= ddrb;

------------------------------------------------------
-- In this process, data from the I/O ports is 
-- registered on the rising edge of the clock.
-- Note that an output register may drive a port
-- I/O pin...the result is that we'll latch the output
-- register value in an input register.  This is not
-- expected behavior on one port according to the 
-- data sheet!  I'll fix this later once the Atari is 
-- up and running...
------------------------------------------------------
latch_input : process(clk, reset)
begin

    if (reset = '1') then

        irega <= (others => '0');
        iregb <= (others => '0');

    elsif (clk'event and clk = '1') then

        if (go_clk_180 = '1') then

           -- In this case, we are registering data
           -- on every cycle...no control signals are
           -- necessary...
           irega <= port_a_in;
           iregb <= port_b_in;

        end if;

    end if;

end process;

-------------------------------------------------------
-- These processes construct our lovely timer.
-- By default, this guy always downcounts when enabled.
-- Moreover, this guy can downcount at rates specified
-- by writes by the user.  Let's build it!
-------------------------------------------------------
timer_ctl : process(clk, reset)
begin

    if (reset = '1') then

        timer_div     <= DIV_64T;
        timer_val     <= (others => '1');
        timer_active  <= '1';
        timer_int_ena <= '1';
        div_cnt       <= (others => '0');
        int_cnt_i     <= 0;
        
    elsif(clk'event and clk = '1') then

        -- If this is a valid clock...
        if (go_clk_180 = '1') then

            -- Reset the divide timer value if
            -- the timer has expired.
            if (div_cnt = "00000000") then

                -- Decrement the primary timer
                timer_val <= timer_val - 1;

                -- See if we need to 
                -- Reset the secondary counter.
                if (timer_val = "00000000") then
 
                    -- Clear the timer active flag... 
                    timer_active <= '0';

                    -- If the primary timer expired, then
                    -- go back to DIV 1 mode...
                    timer_div    <= DIV_1T;

                else

                    -- Only reset the divide counter if the
                    -- timer is currently executing a downcount.
                    if (timer_active = '1') then

                        -- Reset the secondary counter...
                        case timer_div is

                           when DIV_1T    => div_cnt <= RESET_1T;
                           when DIV_8T    => div_cnt <= RESET_8T;
                           when DIV_64T   => div_cnt <= RESET_64T;
                           when DIV_1024T => div_cnt <= RESET_1024T;

                        end case;

                    -- If the timer is not active, then always
                    -- set this timer to its default, DIV1 state.
                    else

                        div_cnt <= RESET_1T;

                    end if;

                end if;

            else

               -- Decrement the divide timer...
               div_cnt <= div_cnt - 1;

            end if;

            -- Handle the loading of a new timer
            -- value.  This function gets priority
            -- over timer decrements seen above.
            if (chip_select = '1') and 
               (ramsel_ref  = '0') and
               (addr(4)     = '1') and
               (addr(2)     = '1') and
               (rwn         = '0') then

               -- Reset the debug counter 
               int_cnt_i         <= 1;

               -- Load the current timer value minus 1 (see datasheets).
               timer_val       <= din - 1;

               -- Determine the timer divide rate
               case addr(1 downto 0) is

                    -- Keep in mind that "cycle 0" has already
                    -- been accounted for...therefore, reset the
                    -- subcounter to it's value - 1.  This does
                    -- not apply if a divide by one is being done...
                    when "00"   => timer_div <= DIV_1T;
                                   div_cnt   <= RESET_1T;
                    when "01"   => timer_div <= DIV_8T;
                                   div_cnt   <= RESET_8T - 1;
                    when "10"   => timer_div <= DIV_64T;
                                   div_cnt   <= RESET_64T - 1;
                    when others => timer_div <= DIV_1024T;
                                   div_cnt   <= RESET_1024T - 1;

               end case;
    
               -- Set the timer_active flag so that the counter
               -- logic knows when to properly reset the divide
               -- counter as well as generate interrupts.
               timer_active <= '1';

               -- Finally, see if the interrupt enable flag is 
               -- set for this access...
               if (addr(3) = '1') then
                   timer_int_ena <= '1';
               else
                   timer_int_ena <= '0';
               end if;
    
            end if;

            -- This is used for debugging purposes.
            if (int_cnt_i /= 0) then
                int_cnt_i <= int_cnt_i + 1;
            end if;

        end if;

    end if;

end process;

-- This process handles the generation of a timer interrupt flag 
-- in the event the timer expires and interrupts are enabled. 
-- It seems that, according to the data sheet, this is 
-- all done on the rising edge of the clock.
timer_interrupt_ctl : process(clk, reset)
begin

     if (reset = '1') then

         timer_int <= '0';

     elsif(clk'event and clk = '1') then

         if (go_clk_180 = '1') then

             -- This gets highest priority...on the
             -- cycle the timer expires, assert the 
             -- timer interrupt flag if it is enabled.
             -- The datasheets specify that if a read 
             -- occurs on the cycle the timer expires,
             -- the interrupt will still be generated 
             -- on the following cycle as the flag will
             -- NOT be cleared out!!!
             if (timer_val = "11111111") then

                   timer_int <= '1';

             -- The second highest priority is reading
             -- or writing the timer.  If the timer is
             -- known to be accessed, clear the interrupt
             -- flag regardless of read/write access...I
             -- am going on the assumption that the same
             -- would hold true for writes (i.e. we write
             -- the timer on the cycle it expires for whatever
             -- silly reason).
             elsif (chip_select  = '1') and 
                   (ramsel_ref   = '0') and
                   (addr(4)      = '1') and
                   (addr(2)      = '1') then

                   timer_int <= '0';

             end if;

         end if;

    end if;

end process;
         
irqn      <= not(timer_int);
          
-- Stupid process to make int_cnt readable
-- on each high going transition of the clock.
--process(clk, int_cnt_i)
--begin

--     if (clk = '1') then
--        int_cnt <= int_cnt_i;
--     else
--        int_cnt <= 0;
--     end if;
--
--end process;

end struct;
