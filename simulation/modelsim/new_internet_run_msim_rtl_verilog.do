transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src {D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src/RamControlSeqFifo.v}
vlog -vlog01compat -work work +incdir+D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src {D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src/HyperRamFifo.v}
vlog -vlog01compat -work work +incdir+D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src {D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src/hyperRamPll.v}
vlog -vlog01compat -work work +incdir+D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus {D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/ramRead.v}
vlog -vlog01compat -work work +incdir+D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/db {D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/db/hyperrampll_altpll.v}
vlog -sv -work work +incdir+D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src {D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src/hyperRamDriver.sv}
vlog -sv -work work +incdir+D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src {D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/src/hyperRAMcontroller.sv}

vlog -vlog01compat -work work +incdir+D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/simulation/modelsim {D:/__PROJECTS/001_Granulit/2._QUARTUS/eth_quartus/simulation/modelsim/hyperRAMcontroller.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclone10lp_ver -L rtl_work -L work -voptargs="+acc"  sv

add wave *
view structure
view signals
run -all
