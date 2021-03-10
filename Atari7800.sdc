# create_clock -name {emu:emu|Atari7800:main|maria:maria_inst|timing_ctrl:timing_ctrl_inst|fast_clk} -period 30

# derive_clocks -period 30
# derive_clock_uncertainty

set_false_path -from   {*emu|reset}
set_false_path -to   {*emu|reset}
