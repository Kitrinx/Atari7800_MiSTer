# create_clock -name {emu:emu|Atari7800:main|maria:maria_inst|timing_ctrl:timing_ctrl_inst|fast_clk} -period 250
# create_clock -name {emu:emu|Atari7800:main|maria:maria_inst|timing_ctrl:timing_ctrl_inst|tia_clk} -period 250
# create_clock -name {emu:emu|Atari7800:main|TIA:tia_inst|clk_30} -period 250

# derive_clocks -period 250
# derive_clock_uncertainty

set_false_path -from   {*emu|reset}
