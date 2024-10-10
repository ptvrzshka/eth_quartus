create_clock -name clk_clk -period 20.000 -waveform {0 10.000} [get_ports {clk_clk}]
derive_clock_uncertainty
set_false_path -from [get_clocks {cllk_clk}] -to [get_ports {test[0}]