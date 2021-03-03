onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tia_clocking_and_reset_tb/clk
add wave -noupdate -color Gray90 /tia_clocking_and_reset_tb/reset
add wave -noupdate -color Gray90 /tia_clocking_and_reset_tb/tia_reset
add wave -noupdate -color {Steel Blue} /tia_clocking_and_reset_tb/cclk_fe
add wave -noupdate -color {Steel Blue} /tia_clocking_and_reset_tb/cclk_re
add wave -noupdate -color {Steel Blue} /tia_clocking_and_reset_tb/cclk
add wave -noupdate -color Yellow /tia_clocking_and_reset_tb/cclk_simcomp
add wave -noupdate -color Red /tia_clocking_and_reset_tb/ctl_rst_cpu
add wave -noupdate -color Magenta /tia_clocking_and_reset_tb/pclk
add wave -noupdate -color Magenta /tia_clocking_and_reset_tb/pclk_fe
add wave -noupdate -color Magenta /tia_clocking_and_reset_tb/pclk_re
add wave -noupdate -color Cyan /tia_clocking_and_reset_tb/sclk
add wave -noupdate -color Cyan /tia_clocking_and_reset_tb/sclk_fe
add wave -noupdate -color Cyan /tia_clocking_and_reset_tb/sclk_re
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {129520 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 341
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {129286 ns} {132657 ns}
