vlib work
vlog ROM_EVEN.v ROM_ODD.v FRACTIONAL_DECIMATION.v TESTBENCH.v
vsim -voptargs=+acc work.FRAC_tb
add wave -position insertpoint  \
sim:/FRAC_tb/rst_n \
sim:/FRAC_tb/out_valid \
sim:/FRAC_tb/out_data \
sim:/FRAC_tb/in_valid \
sim:/FRAC_tb/in_data \
sim:/FRAC_tb/clk
#add wave *
run -all
#quit -sim