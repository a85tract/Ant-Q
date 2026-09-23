
bram_cfg qubit_command0_R_cfg(.bram(qubit_command0_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH))
qubit_command0_R_read(.bram(qubit_command0_R),.addr(dspif.addr_qubit_command[0]),.data(dspif.data_qubit_command[0]));

bram_cfg qubit_command1_R_cfg(.bram(qubit_command1_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH))
qubit_command1_R_read(.bram(qubit_command1_R),.addr(dspif.addr_qubit_command[1]),.data(dspif.data_qubit_command[1]));

bram_cfg qubit_command2_R_cfg(.bram(qubit_command2_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH))
qubit_command2_R_read(.bram(qubit_command2_R),.addr(dspif.addr_qubit_command[2]),.data(dspif.data_qubit_command[2]));

bram_cfg qubit_command3_R_cfg(.bram(qubit_command3_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH))
qubit_command3_R_read(.bram(qubit_command3_R),.addr(dspif.addr_qubit_command[3]),.data(dspif.data_qubit_command[3]));

bram_cfg qubit_command4_R_cfg(.bram(qubit_command4_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH))
qubit_command4_R_read(.bram(qubit_command4_R),.addr(dspif.addr_qubit_command[4]),.data(dspif.data_qubit_command[4]));

bram_cfg qubit_command5_R_cfg(.bram(qubit_command5_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH))
qubit_command5_R_read(.bram(qubit_command5_R),.addr(dspif.addr_qubit_command[5]),.data(dspif.data_qubit_command[5]));

bram_cfg qubit_command6_R_cfg(.bram(qubit_command6_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH))
qubit_command6_R_read(.bram(qubit_command6_R),.addr(dspif.addr_qubit_command[6]),.data(dspif.data_qubit_command[6]));

bram_cfg qubit_command7_R_cfg(.bram(qubit_command7_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH))
qubit_command7_R_read(.bram(qubit_command7_R),.addr(dspif.addr_qubit_command[7]),.data(dspif.data_qubit_command[7]));

bram_cfg qubit_qdrv_env0_R_cfg(.bram(qubit_qdrv_env0_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH))
qubit_qdrv_env0_R_read(.bram(qubit_qdrv_env0_R),.addr(dspif.addr_qubit_qdrv_env[0]),.data(dspif.data_qubit_qdrv_env[0]));

bram_cfg qubit_qdrv_env1_R_cfg(.bram(qubit_qdrv_env1_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH))
qubit_qdrv_env1_R_read(.bram(qubit_qdrv_env1_R),.addr(dspif.addr_qubit_qdrv_env[1]),.data(dspif.data_qubit_qdrv_env[1]));

bram_cfg qubit_qdrv_env2_R_cfg(.bram(qubit_qdrv_env2_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH))
qubit_qdrv_env2_R_read(.bram(qubit_qdrv_env2_R),.addr(dspif.addr_qubit_qdrv_env[2]),.data(dspif.data_qubit_qdrv_env[2]));

bram_cfg qubit_qdrv_env3_R_cfg(.bram(qubit_qdrv_env3_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH))
qubit_qdrv_env3_R_read(.bram(qubit_qdrv_env3_R),.addr(dspif.addr_qubit_qdrv_env[3]),.data(dspif.data_qubit_qdrv_env[3]));

bram_cfg qubit_qdrv_env4_R_cfg(.bram(qubit_qdrv_env4_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH))
qubit_qdrv_env4_R_read(.bram(qubit_qdrv_env4_R),.addr(dspif.addr_qubit_qdrv_env[4]),.data(dspif.data_qubit_qdrv_env[4]));

bram_cfg qubit_qdrv_env5_R_cfg(.bram(qubit_qdrv_env5_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH))
qubit_qdrv_env5_R_read(.bram(qubit_qdrv_env5_R),.addr(dspif.addr_qubit_qdrv_env[5]),.data(dspif.data_qubit_qdrv_env[5]));

bram_cfg qubit_qdrv_env6_R_cfg(.bram(qubit_qdrv_env6_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH))
qubit_qdrv_env6_R_read(.bram(qubit_qdrv_env6_R),.addr(dspif.addr_qubit_qdrv_env[6]),.data(dspif.data_qubit_qdrv_env[6]));

bram_cfg qubit_qdrv_env7_R_cfg(.bram(qubit_qdrv_env7_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH))
qubit_qdrv_env7_R_read(.bram(qubit_qdrv_env7_R),.addr(dspif.addr_qubit_qdrv_env[7]),.data(dspif.data_qubit_qdrv_env[7]));

bram_cfg qubit_qdrv_freq0_R_cfg(.bram(qubit_qdrv_freq0_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH))
qubit_qdrv_freq0_R_read(.bram(qubit_qdrv_freq0_R),.addr(dspif.addr_qubit_qdrv_freq[0]),.data(dspif.data_qubit_qdrv_freq[0]));

bram_cfg qubit_qdrv_freq1_R_cfg(.bram(qubit_qdrv_freq1_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH))
qubit_qdrv_freq1_R_read(.bram(qubit_qdrv_freq1_R),.addr(dspif.addr_qubit_qdrv_freq[1]),.data(dspif.data_qubit_qdrv_freq[1]));

bram_cfg qubit_qdrv_freq2_R_cfg(.bram(qubit_qdrv_freq2_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH))
qubit_qdrv_freq2_R_read(.bram(qubit_qdrv_freq2_R),.addr(dspif.addr_qubit_qdrv_freq[2]),.data(dspif.data_qubit_qdrv_freq[2]));

bram_cfg qubit_qdrv_freq3_R_cfg(.bram(qubit_qdrv_freq3_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH))
qubit_qdrv_freq3_R_read(.bram(qubit_qdrv_freq3_R),.addr(dspif.addr_qubit_qdrv_freq[3]),.data(dspif.data_qubit_qdrv_freq[3]));

bram_cfg qubit_qdrv_freq4_R_cfg(.bram(qubit_qdrv_freq4_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH))
qubit_qdrv_freq4_R_read(.bram(qubit_qdrv_freq4_R),.addr(dspif.addr_qubit_qdrv_freq[4]),.data(dspif.data_qubit_qdrv_freq[4]));

bram_cfg qubit_qdrv_freq5_R_cfg(.bram(qubit_qdrv_freq5_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH))
qubit_qdrv_freq5_R_read(.bram(qubit_qdrv_freq5_R),.addr(dspif.addr_qubit_qdrv_freq[5]),.data(dspif.data_qubit_qdrv_freq[5]));

bram_cfg qubit_qdrv_freq6_R_cfg(.bram(qubit_qdrv_freq6_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH))
qubit_qdrv_freq6_R_read(.bram(qubit_qdrv_freq6_R),.addr(dspif.addr_qubit_qdrv_freq[6]),.data(dspif.data_qubit_qdrv_freq[6]));

bram_cfg qubit_qdrv_freq7_R_cfg(.bram(qubit_qdrv_freq7_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH))
qubit_qdrv_freq7_R_read(.bram(qubit_qdrv_freq7_R),.addr(dspif.addr_qubit_qdrv_freq[7]),.data(dspif.data_qubit_qdrv_freq[7]));

bram_cfg qubit_rdlo_env0_R_cfg(.bram(qubit_rdlo_env0_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH))
qubit_rdlo_env0_R_read(.bram(qubit_rdlo_env0_R),.addr(dspif.addr_qubit_rdlo_env[0]),.data(dspif.data_qubit_rdlo_env[0]));

bram_cfg qubit_rdlo_env1_R_cfg(.bram(qubit_rdlo_env1_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH))
qubit_rdlo_env1_R_read(.bram(qubit_rdlo_env1_R),.addr(dspif.addr_qubit_rdlo_env[1]),.data(dspif.data_qubit_rdlo_env[1]));

bram_cfg qubit_rdlo_env2_R_cfg(.bram(qubit_rdlo_env2_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH))
qubit_rdlo_env2_R_read(.bram(qubit_rdlo_env2_R),.addr(dspif.addr_qubit_rdlo_env[2]),.data(dspif.data_qubit_rdlo_env[2]));

bram_cfg qubit_rdlo_env3_R_cfg(.bram(qubit_rdlo_env3_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH))
qubit_rdlo_env3_R_read(.bram(qubit_rdlo_env3_R),.addr(dspif.addr_qubit_rdlo_env[3]),.data(dspif.data_qubit_rdlo_env[3]));

bram_cfg qubit_rdlo_env4_R_cfg(.bram(qubit_rdlo_env4_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH))
qubit_rdlo_env4_R_read(.bram(qubit_rdlo_env4_R),.addr(dspif.addr_qubit_rdlo_env[4]),.data(dspif.data_qubit_rdlo_env[4]));

bram_cfg qubit_rdlo_env5_R_cfg(.bram(qubit_rdlo_env5_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH))
qubit_rdlo_env5_R_read(.bram(qubit_rdlo_env5_R),.addr(dspif.addr_qubit_rdlo_env[5]),.data(dspif.data_qubit_rdlo_env[5]));

bram_cfg qubit_rdlo_env6_R_cfg(.bram(qubit_rdlo_env6_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH))
qubit_rdlo_env6_R_read(.bram(qubit_rdlo_env6_R),.addr(dspif.addr_qubit_rdlo_env[6]),.data(dspif.data_qubit_rdlo_env[6]));

bram_cfg qubit_rdlo_env7_R_cfg(.bram(qubit_rdlo_env7_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH))
qubit_rdlo_env7_R_read(.bram(qubit_rdlo_env7_R),.addr(dspif.addr_qubit_rdlo_env[7]),.data(dspif.data_qubit_rdlo_env[7]));

bram_cfg qubit_rdlo_freq0_R_cfg(.bram(qubit_rdlo_freq0_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH))
qubit_rdlo_freq0_R_read(.bram(qubit_rdlo_freq0_R),.addr(dspif.addr_qubit_rdlo_freq[0]),.data(dspif.data_qubit_rdlo_freq[0]));

bram_cfg qubit_rdlo_freq1_R_cfg(.bram(qubit_rdlo_freq1_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH))
qubit_rdlo_freq1_R_read(.bram(qubit_rdlo_freq1_R),.addr(dspif.addr_qubit_rdlo_freq[1]),.data(dspif.data_qubit_rdlo_freq[1]));

bram_cfg qubit_rdlo_freq2_R_cfg(.bram(qubit_rdlo_freq2_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH))
qubit_rdlo_freq2_R_read(.bram(qubit_rdlo_freq2_R),.addr(dspif.addr_qubit_rdlo_freq[2]),.data(dspif.data_qubit_rdlo_freq[2]));

bram_cfg qubit_rdlo_freq3_R_cfg(.bram(qubit_rdlo_freq3_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH))
qubit_rdlo_freq3_R_read(.bram(qubit_rdlo_freq3_R),.addr(dspif.addr_qubit_rdlo_freq[3]),.data(dspif.data_qubit_rdlo_freq[3]));

bram_cfg qubit_rdlo_freq4_R_cfg(.bram(qubit_rdlo_freq4_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH))
qubit_rdlo_freq4_R_read(.bram(qubit_rdlo_freq4_R),.addr(dspif.addr_qubit_rdlo_freq[4]),.data(dspif.data_qubit_rdlo_freq[4]));

bram_cfg qubit_rdlo_freq5_R_cfg(.bram(qubit_rdlo_freq5_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH))
qubit_rdlo_freq5_R_read(.bram(qubit_rdlo_freq5_R),.addr(dspif.addr_qubit_rdlo_freq[5]),.data(dspif.data_qubit_rdlo_freq[5]));

bram_cfg qubit_rdlo_freq6_R_cfg(.bram(qubit_rdlo_freq6_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH))
qubit_rdlo_freq6_R_read(.bram(qubit_rdlo_freq6_R),.addr(dspif.addr_qubit_rdlo_freq[6]),.data(dspif.data_qubit_rdlo_freq[6]));

bram_cfg qubit_rdlo_freq7_R_cfg(.bram(qubit_rdlo_freq7_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH))
qubit_rdlo_freq7_R_read(.bram(qubit_rdlo_freq7_R),.addr(dspif.addr_qubit_rdlo_freq[7]),.data(dspif.data_qubit_rdlo_freq[7]));

bram_cfg qubit_rdrv_env0_R_cfg(.bram(qubit_rdrv_env0_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH))
qubit_rdrv_env0_R_read(.bram(qubit_rdrv_env0_R),.addr(dspif.addr_qubit_rdrv_env[0]),.data(dspif.data_qubit_rdrv_env[0]));

bram_cfg qubit_rdrv_env1_R_cfg(.bram(qubit_rdrv_env1_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH))
qubit_rdrv_env1_R_read(.bram(qubit_rdrv_env1_R),.addr(dspif.addr_qubit_rdrv_env[1]),.data(dspif.data_qubit_rdrv_env[1]));

bram_cfg qubit_rdrv_env2_R_cfg(.bram(qubit_rdrv_env2_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH))
qubit_rdrv_env2_R_read(.bram(qubit_rdrv_env2_R),.addr(dspif.addr_qubit_rdrv_env[2]),.data(dspif.data_qubit_rdrv_env[2]));

bram_cfg qubit_rdrv_env3_R_cfg(.bram(qubit_rdrv_env3_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH))
qubit_rdrv_env3_R_read(.bram(qubit_rdrv_env3_R),.addr(dspif.addr_qubit_rdrv_env[3]),.data(dspif.data_qubit_rdrv_env[3]));

bram_cfg qubit_rdrv_env4_R_cfg(.bram(qubit_rdrv_env4_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH))
qubit_rdrv_env4_R_read(.bram(qubit_rdrv_env4_R),.addr(dspif.addr_qubit_rdrv_env[4]),.data(dspif.data_qubit_rdrv_env[4]));

bram_cfg qubit_rdrv_env5_R_cfg(.bram(qubit_rdrv_env5_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH))
qubit_rdrv_env5_R_read(.bram(qubit_rdrv_env5_R),.addr(dspif.addr_qubit_rdrv_env[5]),.data(dspif.data_qubit_rdrv_env[5]));

bram_cfg qubit_rdrv_env6_R_cfg(.bram(qubit_rdrv_env6_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH))
qubit_rdrv_env6_R_read(.bram(qubit_rdrv_env6_R),.addr(dspif.addr_qubit_rdrv_env[6]),.data(dspif.data_qubit_rdrv_env[6]));

bram_cfg qubit_rdrv_env7_R_cfg(.bram(qubit_rdrv_env7_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH))
qubit_rdrv_env7_R_read(.bram(qubit_rdrv_env7_R),.addr(dspif.addr_qubit_rdrv_env[7]),.data(dspif.data_qubit_rdrv_env[7]));

bram_cfg qubit_rdrv_freq0_R_cfg(.bram(qubit_rdrv_freq0_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH))
qubit_rdrv_freq0_R_read(.bram(qubit_rdrv_freq0_R),.addr(dspif.addr_qubit_rdrv_freq[0]),.data(dspif.data_qubit_rdrv_freq[0]));

bram_cfg qubit_rdrv_freq1_R_cfg(.bram(qubit_rdrv_freq1_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH))
qubit_rdrv_freq1_R_read(.bram(qubit_rdrv_freq1_R),.addr(dspif.addr_qubit_rdrv_freq[1]),.data(dspif.data_qubit_rdrv_freq[1]));

bram_cfg qubit_rdrv_freq2_R_cfg(.bram(qubit_rdrv_freq2_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH))
qubit_rdrv_freq2_R_read(.bram(qubit_rdrv_freq2_R),.addr(dspif.addr_qubit_rdrv_freq[2]),.data(dspif.data_qubit_rdrv_freq[2]));

bram_cfg qubit_rdrv_freq3_R_cfg(.bram(qubit_rdrv_freq3_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH))
qubit_rdrv_freq3_R_read(.bram(qubit_rdrv_freq3_R),.addr(dspif.addr_qubit_rdrv_freq[3]),.data(dspif.data_qubit_rdrv_freq[3]));

bram_cfg qubit_rdrv_freq4_R_cfg(.bram(qubit_rdrv_freq4_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH))
qubit_rdrv_freq4_R_read(.bram(qubit_rdrv_freq4_R),.addr(dspif.addr_qubit_rdrv_freq[4]),.data(dspif.data_qubit_rdrv_freq[4]));

bram_cfg qubit_rdrv_freq5_R_cfg(.bram(qubit_rdrv_freq5_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH))
qubit_rdrv_freq5_R_read(.bram(qubit_rdrv_freq5_R),.addr(dspif.addr_qubit_rdrv_freq[5]),.data(dspif.data_qubit_rdrv_freq[5]));

bram_cfg qubit_rdrv_freq6_R_cfg(.bram(qubit_rdrv_freq6_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH))
qubit_rdrv_freq6_R_read(.bram(qubit_rdrv_freq6_R),.addr(dspif.addr_qubit_rdrv_freq[6]),.data(dspif.data_qubit_rdrv_freq[6]));

bram_cfg qubit_rdrv_freq7_R_cfg(.bram(qubit_rdrv_freq7_R),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_read#(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH))
qubit_rdrv_freq7_R_read(.bram(qubit_rdrv_freq7_R),.addr(dspif.addr_qubit_rdrv_freq[7]),.data(dspif.data_qubit_rdrv_freq[7]));
