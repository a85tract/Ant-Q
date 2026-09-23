proc bram_map {busname inst} {
	set brampins {RST CLK DIN EN DOUT WE ADDR}
	foreach pin $brampins {
		ipx::add_port_map $pin [ipx::get_bus_interfaces $busname -of_objects [ipx::current_core]]
		set_property physical_name ${inst}_[string tolower $pin] [ipx::get_port_maps $pin -of_objects [ipx::get_bus_interfaces $busname -of_objects [ipx::current_core]]]
	}
}
proc brambus {bramname} {
	ipx::add_bus_interface ${bramname} [ipx::current_core]
	set_property abstraction_type_vlnv xilinx.com:interface:bram_rtl:1.0 [ipx::get_bus_interfaces ${bramname} -of_objects [ipx::current_core]]
	set_property bus_type_vlnv xilinx.com:interface:bram:1.0 [ipx::get_bus_interfaces ${bramname} -of_objects [ipx::current_core]]
	set_property interface_mode master [ipx::get_bus_interfaces ${bramname} -of_objects [ipx::current_core]]
	bram_map ${bramname} [string toupper $bramname]
}
brambus acqbuf0
brambus acqbuf1
brambus qubit_command0
brambus qubit_command1
brambus qubit_command2
brambus qubit_command3
brambus qubit_command4
brambus qubit_command5
brambus qubit_command6
brambus qubit_command7
brambus dacmon0
brambus dacmon1
brambus dacmon2
brambus dacmon3
brambus qubit_qdrv_env0
brambus qubit_qdrv_env1
brambus qubit_qdrv_env2
brambus qubit_qdrv_env3
brambus qubit_qdrv_env4
brambus qubit_qdrv_env5
brambus qubit_qdrv_env6
brambus qubit_qdrv_env7
brambus qubit_qdrv_freq0
brambus qubit_qdrv_freq1
brambus qubit_qdrv_freq2
brambus qubit_qdrv_freq3
brambus qubit_qdrv_freq4
brambus qubit_qdrv_freq5
brambus qubit_qdrv_freq6
brambus qubit_qdrv_freq7
brambus qubit_rdlo_env0
brambus qubit_rdlo_env1
brambus qubit_rdlo_env2
brambus qubit_rdlo_env3
brambus qubit_rdlo_env4
brambus qubit_rdlo_env5
brambus qubit_rdlo_env6
brambus qubit_rdlo_env7
brambus qubit_rdlo_freq0
brambus qubit_rdlo_freq1
brambus qubit_rdlo_freq2
brambus qubit_rdlo_freq3
brambus qubit_rdlo_freq4
brambus qubit_rdlo_freq5
brambus qubit_rdlo_freq6
brambus qubit_rdlo_freq7
brambus qubit_rdrv_env0
brambus qubit_rdrv_env1
brambus qubit_rdrv_env2
brambus qubit_rdrv_env3
brambus qubit_rdrv_env4
brambus qubit_rdrv_env5
brambus qubit_rdrv_env6
brambus qubit_rdrv_env7
brambus qubit_rdrv_freq0
brambus qubit_rdrv_freq1
brambus qubit_rdrv_freq2
brambus qubit_rdrv_freq3
brambus qubit_rdrv_freq4
brambus qubit_rdrv_freq5
brambus qubit_rdrv_freq6
brambus qubit_rdrv_freq7
brambus qubit_accbuf0
brambus qubit_accbuf1
brambus qubit_accbuf2
brambus qubit_accbuf3
brambus qubit_accbuf4
brambus qubit_accbuf5
brambus qubit_accbuf6
brambus qubit_accbuf7