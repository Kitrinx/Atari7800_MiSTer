-------------------------------------------------------------------------------
--
--   Copyright (C) 2005
--
--   Title     :  Atari 2600 Data flip flop
--
--   Author    :  Ed Henciak 
--
--   Notes     :  Acts as the H1 - H2 gated flip flop found 
--                throughout TIA.  During the first pass, I found a
--                few bugs when merely latching data on the H2 rising
--                edge of the clock.  Most bugs were related to resetting
--                the sequencer circuit.  As a result, to be safe, I
--                made this circuit so that everything remains Okey Dokey.
--                This should mimic the functionality of the N-channel
--                based flop pretty much faithfully.
--
--   Date      :  January 17, 2005
--                
-------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;

library A2600;
    use A2600.tia_pkg.all;


entity tia_d_flop is
generic(
   flop_style   : flop_type := REGULAR_D
);
port
(

   -- Clock and feedback reset 
   clk          : in  std_logic; -- Main clock
   reset        : in  std_logic; -- Active high reset (system)
   reset_gate   : in  std_logic; -- "NOR" reset

   -- Clock phase enables
   p1_clk       : in  std_logic;
   p2_clk       : in  std_logic;

   -- Input data
   data_in      : in  std_logic;

   -- D-Flop outputs based on phase
   p1_out       : out std_logic;
   p2_out       : out std_logic 

);
end tia_d_flop;


architecture struct of tia_d_flop is

    -- Nodes related to the 1st phase of the clock
    signal p1_c_node    : std_logic; -- Combinational node
    signal p1_s_node    : std_logic; -- Sequential node
    signal p1_out_node  : std_logic; -- Output node

    -- Nodes related to the second phase of the clock
    signal p2_c_node    : std_logic; -- Combinational node
    signal p2_s_node    : std_logic; -- Sequential node
    signal p2_out_node  : std_logic; -- Output node
    signal p2_out_final : std_logic; -- The gated reset node...

    -- Reset inverted...
    signal reset_n      : std_logic;

begin

   -- First, this combinational process acts as the H1
   -- pass transistor....
   process(data_in, p2_out_final)
   begin

       -- Use the generic to see what kind of flop to emulate.
       case flop_style is

          when FEEDBK_RST => p1_c_node <= data_in or p2_out_final;
          when others     => p1_c_node <= data_in;

       end case;

   end process;

   -- Next, this process acts as the sequential component
   -- of the latch. 
   process(reset, clk)
   begin

       if (reset = '1') then

           p1_s_node <= '0';

       elsif(clk'event and clk = '1') then

           if (p1_clk = '1') then
               p1_s_node <= p1_c_node;
           end if;

       end if;

   end process;

   -- Finally, gate the output of the combinational circuit
   -- with the sequential component...
   p1_out_node <= p1_c_node when (p1_clk = '1') else p1_s_node;

   -- Now we need to do a similar thing for the H2 phase of the 
   -- clock....

   -- "Combinational node"... note that, for all intents and purposes,
   -- this node is only going to be the sequential output of p1 since the
   -- two phase clock generator guarantees that both pass gates of the latch
   -- are never enabled simultaneously;
   --p2_c_node <= p1_out_node;
   p2_c_node <= p1_s_node;

   -- And now the sequential process...
   process(reset, clk)
   begin

       if (reset = '1') then

           p2_s_node <= '0';

       elsif(clk'event and clk = '1') then

           if (p2_clk = '1') then
               p2_s_node <= p2_c_node;
           end if;

       end if;

   end process;

   -- And the H2 clock gate...
   p2_out_node <= p2_c_node when (p2_clk = '1') else p2_s_node;

   -- Now, this process shall direct what appears at the output 
   -- based on the flop-type generic

   -- Final output enable...tie reset_gate to gnd if not needed.
   reset_n  <= not(reset_gate);

   process(reset_n, p2_s_node, p2_out_node)
   begin

        case flop_style is

             when REGULAR_D => p2_out_final <= p2_out_node;
             when others    => p2_out_final <= p2_out_node and reset_n;

        end case;
 
   end process;

   -- Concurrent signal assignments
   p1_out <= p1_out_node;
   p2_out <= p2_out_final;

end struct;
