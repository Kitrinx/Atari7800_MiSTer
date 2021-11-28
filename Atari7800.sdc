# create_clock -name {emu:emu|Atari7800:main|maria:maria_inst|timing_ctrl:timing_ctrl_inst|fast_clk} -period 30

# derive_clocks -period 30
# derive_clock_uncertainty
#create_generated_clock -divide_by 4 -source {emu:emu|clk_sys} -name tia_clk_gen {emu:emu|Atari7800:main|tia_clk_gen}

#set_false_path -rise_from   {*emu|reset}
#set_false_path -to   {*emu|reset}
