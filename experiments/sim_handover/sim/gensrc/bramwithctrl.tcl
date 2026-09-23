proc bramwithctrl {bramname Awidth Adepth Bwidth latency} {
	incr $Awidth 0
	incr $Adepth 0
	incr $Bwidth 0
	incr $latency 0
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 ${bramname}_ctrl
	create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 ${bramname}_mem
	set_property -dict [list CONFIG.READ_LATENCY ${latency} CONFIG.SINGLE_PORT_BRAM {1} CONFIG.DATA_WIDTH ${Awidth}] [get_bd_cells ${bramname}_ctrl]
	set_property -dict [list CONFIG.use_bram_block {Stand_Alone} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Depth_A ${Adepth} CONFIG.Write_Width_A ${Awidth} CONFIG.Read_Width_A ${Awidth} CONFIG.Write_Width_B ${Bwidth} CONFIG.Read_Width_B ${Bwidth} CONFIG.Enable_32bit_Address {true} CONFIG.Use_Byte_Write_Enable {true} CONFIG.Byte_Size {8} CONFIG.Use_RSTA_Pin {false} CONFIG.Use_RSTB_Pin {false} CONFIG.Enable_A {Always_Enabled} CONFIG.Enable_B {Always_Enabled} CONFIG.EN_SAFETY_CKT {false}] [get_bd_cells ${bramname}_mem]
}
bramwithctrl acqbuf0 64 4096 32 2
bramwithctrl acqbuf1 64 4096 32 2
bramwithctrl dacmon0 256 512 32 2
bramwithctrl dacmon1 256 512 32 2
bramwithctrl dacmon2 256 512 32 2
bramwithctrl dacmon3 256 512 32 2
bramwithctrl qubit_accbuf0 64 1024 32 2
bramwithctrl qubit_accbuf1 64 1024 32 2
bramwithctrl qubit_accbuf2 64 1024 32 2
bramwithctrl qubit_accbuf3 64 1024 32 2
bramwithctrl qubit_accbuf4 64 1024 32 2
bramwithctrl qubit_accbuf5 64 1024 32 2
bramwithctrl qubit_accbuf6 64 1024 32 2
bramwithctrl qubit_accbuf7 64 1024 32 2
bramwithctrl qubit_command0 32 8192 128 2
bramwithctrl qubit_command1 32 8192 128 2
bramwithctrl qubit_command2 32 8192 128 2
bramwithctrl qubit_command3 32 8192 128 2
bramwithctrl qubit_command4 32 8192 128 2
bramwithctrl qubit_command5 32 8192 128 2
bramwithctrl qubit_command6 32 8192 128 2
bramwithctrl qubit_command7 32 8192 128 2
bramwithctrl qubit_qdrv_env0 32 4096 128 2
bramwithctrl qubit_qdrv_env1 32 4096 128 2
bramwithctrl qubit_qdrv_env2 32 4096 128 2
bramwithctrl qubit_qdrv_env3 32 4096 128 2
bramwithctrl qubit_qdrv_env4 32 4096 128 2
bramwithctrl qubit_qdrv_env5 32 4096 128 2
bramwithctrl qubit_qdrv_env6 32 4096 128 2
bramwithctrl qubit_qdrv_env7 32 4096 128 2
bramwithctrl qubit_qdrv_freq0 32 4096 512 2
bramwithctrl qubit_qdrv_freq1 32 4096 512 2
bramwithctrl qubit_qdrv_freq2 32 4096 512 2
bramwithctrl qubit_qdrv_freq3 32 4096 512 2
bramwithctrl qubit_qdrv_freq4 32 4096 512 2
bramwithctrl qubit_qdrv_freq5 32 4096 512 2
bramwithctrl qubit_qdrv_freq6 32 4096 512 2
bramwithctrl qubit_qdrv_freq7 32 4096 512 2
bramwithctrl qubit_rdlo_env0 32 4096 32 2
bramwithctrl qubit_rdlo_env1 32 4096 32 2
bramwithctrl qubit_rdlo_env2 32 4096 32 2
bramwithctrl qubit_rdlo_env3 32 4096 32 2
bramwithctrl qubit_rdlo_env4 32 4096 32 2
bramwithctrl qubit_rdlo_env5 32 4096 32 2
bramwithctrl qubit_rdlo_env6 32 4096 32 2
bramwithctrl qubit_rdlo_env7 32 4096 32 2
bramwithctrl qubit_rdlo_freq0 32 4096 128 2
bramwithctrl qubit_rdlo_freq1 32 4096 128 2
bramwithctrl qubit_rdlo_freq2 32 4096 128 2
bramwithctrl qubit_rdlo_freq3 32 4096 128 2
bramwithctrl qubit_rdlo_freq4 32 4096 128 2
bramwithctrl qubit_rdlo_freq5 32 4096 128 2
bramwithctrl qubit_rdlo_freq6 32 4096 128 2
bramwithctrl qubit_rdlo_freq7 32 4096 128 2
bramwithctrl qubit_rdrv_env0 32 4096 32 2
bramwithctrl qubit_rdrv_env1 32 4096 32 2
bramwithctrl qubit_rdrv_env2 32 4096 32 2
bramwithctrl qubit_rdrv_env3 32 4096 32 2
bramwithctrl qubit_rdrv_env4 32 4096 32 2
bramwithctrl qubit_rdrv_env5 32 4096 32 2
bramwithctrl qubit_rdrv_env6 32 4096 32 2
bramwithctrl qubit_rdrv_env7 32 4096 32 2
bramwithctrl qubit_rdrv_freq0 32 4096 512 2
bramwithctrl qubit_rdrv_freq1 32 4096 512 2
bramwithctrl qubit_rdrv_freq2 32 4096 512 2
bramwithctrl qubit_rdrv_freq3 32 4096 512 2
bramwithctrl qubit_rdrv_freq4 32 4096 512 2
bramwithctrl qubit_rdrv_freq5 32 4096 512 2
bramwithctrl qubit_rdrv_freq6 32 4096 512 2
bramwithctrl qubit_rdrv_freq7 32 4096 512 2