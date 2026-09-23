create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ilaauto
set_property -dict {
CONFIG.C_PROBE0_TYPE {0}
CONFIG.C_PROBE0_WIDTH {32}
CONFIG.C_PROBE1_TYPE {0}
CONFIG.C_PROBE1_WIDTH {1}
CONFIG.C_PROBE2_TYPE {0}
CONFIG.C_PROBE2_WIDTH {1}
CONFIG.C_PROBE3_TYPE {0}
CONFIG.C_PROBE3_WIDTH {256}
CONFIG.C_PROBE4_TYPE {0}
CONFIG.C_PROBE4_WIDTH {32}
CONFIG.C_PROBE5_TYPE {0}
CONFIG.C_PROBE5_WIDTH {1}
CONFIG.C_PROBE6_TYPE {0}
CONFIG.C_PROBE6_WIDTH {1}
CONFIG.C_PROBE7_TYPE {0}
CONFIG.C_PROBE7_WIDTH {256}
CONFIG.C_NUM_OF_PROBES {8}
} [get_ips ilaauto]
#generate_target {instantiation_template} [get_files ilaauto.xci]
#generate_target all [get_files  ilaauto.xci]
#export_ip_user_files -of_objects [get_files ilaauto.xci] -no_script -sync -force -quiet
#create_ip_run [get_files -of_objects [get_fileset sources_1] ilaauto.xci]
#CONFIG.C_EN_STRG_QUAL {1}
#CONFIG.C_TRIGIN_EN {true}
