interface ifbramctrl#(parameter integer DATA_WIDTH = 32,parameter integer ADDR_WIDTH=24,parameter READDELAY=4
,`include "bram_para.vh"
,`include "braminit_para.vh"
	)(iflocalbus.lb lb
,`include "bramif_lbport.vh")
;
reg [DATA_WIDTH-1:0] rdata=0;
reg qubit_command0_W_we=0;reg [QUBIT_COMMAND_W_ADDRWIDTH-1:0]  qubit_command0_W_waddr=0;reg [QUBIT_COMMAND_W_DATAWIDTH-1:0] qubit_command0_W_din=0;assign {qubit_command0_W.we,qubit_command0_W.addr,qubit_command0_W.din}={qubit_command0_W_we,qubit_command0_W_waddr,qubit_command0_W_din};
reg qubit_command1_W_we=0;reg [QUBIT_COMMAND_W_ADDRWIDTH-1:0]  qubit_command1_W_waddr=0;reg [QUBIT_COMMAND_W_DATAWIDTH-1:0] qubit_command1_W_din=0;assign {qubit_command1_W.we,qubit_command1_W.addr,qubit_command1_W.din}={qubit_command1_W_we,qubit_command1_W_waddr,qubit_command1_W_din};
reg qubit_command2_W_we=0;reg [QUBIT_COMMAND_W_ADDRWIDTH-1:0]  qubit_command2_W_waddr=0;reg [QUBIT_COMMAND_W_DATAWIDTH-1:0] qubit_command2_W_din=0;assign {qubit_command2_W.we,qubit_command2_W.addr,qubit_command2_W.din}={qubit_command2_W_we,qubit_command2_W_waddr,qubit_command2_W_din};
reg qubit_command3_W_we=0;reg [QUBIT_COMMAND_W_ADDRWIDTH-1:0]  qubit_command3_W_waddr=0;reg [QUBIT_COMMAND_W_DATAWIDTH-1:0] qubit_command3_W_din=0;assign {qubit_command3_W.we,qubit_command3_W.addr,qubit_command3_W.din}={qubit_command3_W_we,qubit_command3_W_waddr,qubit_command3_W_din};
reg qubit_command4_W_we=0;reg [QUBIT_COMMAND_W_ADDRWIDTH-1:0]  qubit_command4_W_waddr=0;reg [QUBIT_COMMAND_W_DATAWIDTH-1:0] qubit_command4_W_din=0;assign {qubit_command4_W.we,qubit_command4_W.addr,qubit_command4_W.din}={qubit_command4_W_we,qubit_command4_W_waddr,qubit_command4_W_din};
reg qubit_command5_W_we=0;reg [QUBIT_COMMAND_W_ADDRWIDTH-1:0]  qubit_command5_W_waddr=0;reg [QUBIT_COMMAND_W_DATAWIDTH-1:0] qubit_command5_W_din=0;assign {qubit_command5_W.we,qubit_command5_W.addr,qubit_command5_W.din}={qubit_command5_W_we,qubit_command5_W_waddr,qubit_command5_W_din};
reg qubit_command6_W_we=0;reg [QUBIT_COMMAND_W_ADDRWIDTH-1:0]  qubit_command6_W_waddr=0;reg [QUBIT_COMMAND_W_DATAWIDTH-1:0] qubit_command6_W_din=0;assign {qubit_command6_W.we,qubit_command6_W.addr,qubit_command6_W.din}={qubit_command6_W_we,qubit_command6_W_waddr,qubit_command6_W_din};
reg qubit_command7_W_we=0;reg [QUBIT_COMMAND_W_ADDRWIDTH-1:0]  qubit_command7_W_waddr=0;reg [QUBIT_COMMAND_W_DATAWIDTH-1:0] qubit_command7_W_din=0;assign {qubit_command7_W.we,qubit_command7_W.addr,qubit_command7_W.din}={qubit_command7_W_we,qubit_command7_W_waddr,qubit_command7_W_din};
reg qubit_qdrv_env0_W_we=0;reg [QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]  qubit_qdrv_env0_W_waddr=0;reg [QUBIT_QDRV_ENV_W_DATAWIDTH-1:0] qubit_qdrv_env0_W_din=0;assign {qubit_qdrv_env0_W.we,qubit_qdrv_env0_W.addr,qubit_qdrv_env0_W.din}={qubit_qdrv_env0_W_we,qubit_qdrv_env0_W_waddr,qubit_qdrv_env0_W_din};
reg qubit_qdrv_env1_W_we=0;reg [QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]  qubit_qdrv_env1_W_waddr=0;reg [QUBIT_QDRV_ENV_W_DATAWIDTH-1:0] qubit_qdrv_env1_W_din=0;assign {qubit_qdrv_env1_W.we,qubit_qdrv_env1_W.addr,qubit_qdrv_env1_W.din}={qubit_qdrv_env1_W_we,qubit_qdrv_env1_W_waddr,qubit_qdrv_env1_W_din};
reg qubit_qdrv_env2_W_we=0;reg [QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]  qubit_qdrv_env2_W_waddr=0;reg [QUBIT_QDRV_ENV_W_DATAWIDTH-1:0] qubit_qdrv_env2_W_din=0;assign {qubit_qdrv_env2_W.we,qubit_qdrv_env2_W.addr,qubit_qdrv_env2_W.din}={qubit_qdrv_env2_W_we,qubit_qdrv_env2_W_waddr,qubit_qdrv_env2_W_din};
reg qubit_qdrv_env3_W_we=0;reg [QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]  qubit_qdrv_env3_W_waddr=0;reg [QUBIT_QDRV_ENV_W_DATAWIDTH-1:0] qubit_qdrv_env3_W_din=0;assign {qubit_qdrv_env3_W.we,qubit_qdrv_env3_W.addr,qubit_qdrv_env3_W.din}={qubit_qdrv_env3_W_we,qubit_qdrv_env3_W_waddr,qubit_qdrv_env3_W_din};
reg qubit_qdrv_env4_W_we=0;reg [QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]  qubit_qdrv_env4_W_waddr=0;reg [QUBIT_QDRV_ENV_W_DATAWIDTH-1:0] qubit_qdrv_env4_W_din=0;assign {qubit_qdrv_env4_W.we,qubit_qdrv_env4_W.addr,qubit_qdrv_env4_W.din}={qubit_qdrv_env4_W_we,qubit_qdrv_env4_W_waddr,qubit_qdrv_env4_W_din};
reg qubit_qdrv_env5_W_we=0;reg [QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]  qubit_qdrv_env5_W_waddr=0;reg [QUBIT_QDRV_ENV_W_DATAWIDTH-1:0] qubit_qdrv_env5_W_din=0;assign {qubit_qdrv_env5_W.we,qubit_qdrv_env5_W.addr,qubit_qdrv_env5_W.din}={qubit_qdrv_env5_W_we,qubit_qdrv_env5_W_waddr,qubit_qdrv_env5_W_din};
reg qubit_qdrv_env6_W_we=0;reg [QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]  qubit_qdrv_env6_W_waddr=0;reg [QUBIT_QDRV_ENV_W_DATAWIDTH-1:0] qubit_qdrv_env6_W_din=0;assign {qubit_qdrv_env6_W.we,qubit_qdrv_env6_W.addr,qubit_qdrv_env6_W.din}={qubit_qdrv_env6_W_we,qubit_qdrv_env6_W_waddr,qubit_qdrv_env6_W_din};
reg qubit_qdrv_env7_W_we=0;reg [QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]  qubit_qdrv_env7_W_waddr=0;reg [QUBIT_QDRV_ENV_W_DATAWIDTH-1:0] qubit_qdrv_env7_W_din=0;assign {qubit_qdrv_env7_W.we,qubit_qdrv_env7_W.addr,qubit_qdrv_env7_W.din}={qubit_qdrv_env7_W_we,qubit_qdrv_env7_W_waddr,qubit_qdrv_env7_W_din};
reg qubit_qdrv_freq0_W_we=0;reg [QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_qdrv_freq0_W_waddr=0;reg [QUBIT_QDRV_FREQ_W_DATAWIDTH-1:0] qubit_qdrv_freq0_W_din=0;assign {qubit_qdrv_freq0_W.we,qubit_qdrv_freq0_W.addr,qubit_qdrv_freq0_W.din}={qubit_qdrv_freq0_W_we,qubit_qdrv_freq0_W_waddr,qubit_qdrv_freq0_W_din};
reg qubit_qdrv_freq1_W_we=0;reg [QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_qdrv_freq1_W_waddr=0;reg [QUBIT_QDRV_FREQ_W_DATAWIDTH-1:0] qubit_qdrv_freq1_W_din=0;assign {qubit_qdrv_freq1_W.we,qubit_qdrv_freq1_W.addr,qubit_qdrv_freq1_W.din}={qubit_qdrv_freq1_W_we,qubit_qdrv_freq1_W_waddr,qubit_qdrv_freq1_W_din};
reg qubit_qdrv_freq2_W_we=0;reg [QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_qdrv_freq2_W_waddr=0;reg [QUBIT_QDRV_FREQ_W_DATAWIDTH-1:0] qubit_qdrv_freq2_W_din=0;assign {qubit_qdrv_freq2_W.we,qubit_qdrv_freq2_W.addr,qubit_qdrv_freq2_W.din}={qubit_qdrv_freq2_W_we,qubit_qdrv_freq2_W_waddr,qubit_qdrv_freq2_W_din};
reg qubit_qdrv_freq3_W_we=0;reg [QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_qdrv_freq3_W_waddr=0;reg [QUBIT_QDRV_FREQ_W_DATAWIDTH-1:0] qubit_qdrv_freq3_W_din=0;assign {qubit_qdrv_freq3_W.we,qubit_qdrv_freq3_W.addr,qubit_qdrv_freq3_W.din}={qubit_qdrv_freq3_W_we,qubit_qdrv_freq3_W_waddr,qubit_qdrv_freq3_W_din};
reg qubit_qdrv_freq4_W_we=0;reg [QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_qdrv_freq4_W_waddr=0;reg [QUBIT_QDRV_FREQ_W_DATAWIDTH-1:0] qubit_qdrv_freq4_W_din=0;assign {qubit_qdrv_freq4_W.we,qubit_qdrv_freq4_W.addr,qubit_qdrv_freq4_W.din}={qubit_qdrv_freq4_W_we,qubit_qdrv_freq4_W_waddr,qubit_qdrv_freq4_W_din};
reg qubit_qdrv_freq5_W_we=0;reg [QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_qdrv_freq5_W_waddr=0;reg [QUBIT_QDRV_FREQ_W_DATAWIDTH-1:0] qubit_qdrv_freq5_W_din=0;assign {qubit_qdrv_freq5_W.we,qubit_qdrv_freq5_W.addr,qubit_qdrv_freq5_W.din}={qubit_qdrv_freq5_W_we,qubit_qdrv_freq5_W_waddr,qubit_qdrv_freq5_W_din};
reg qubit_qdrv_freq6_W_we=0;reg [QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_qdrv_freq6_W_waddr=0;reg [QUBIT_QDRV_FREQ_W_DATAWIDTH-1:0] qubit_qdrv_freq6_W_din=0;assign {qubit_qdrv_freq6_W.we,qubit_qdrv_freq6_W.addr,qubit_qdrv_freq6_W.din}={qubit_qdrv_freq6_W_we,qubit_qdrv_freq6_W_waddr,qubit_qdrv_freq6_W_din};
reg qubit_qdrv_freq7_W_we=0;reg [QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_qdrv_freq7_W_waddr=0;reg [QUBIT_QDRV_FREQ_W_DATAWIDTH-1:0] qubit_qdrv_freq7_W_din=0;assign {qubit_qdrv_freq7_W.we,qubit_qdrv_freq7_W.addr,qubit_qdrv_freq7_W.din}={qubit_qdrv_freq7_W_we,qubit_qdrv_freq7_W_waddr,qubit_qdrv_freq7_W_din};
reg qubit_rdlo_env0_W_we=0;reg [QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]  qubit_rdlo_env0_W_waddr=0;reg [QUBIT_RDLO_ENV_W_DATAWIDTH-1:0] qubit_rdlo_env0_W_din=0;assign {qubit_rdlo_env0_W.we,qubit_rdlo_env0_W.addr,qubit_rdlo_env0_W.din}={qubit_rdlo_env0_W_we,qubit_rdlo_env0_W_waddr,qubit_rdlo_env0_W_din};
reg qubit_rdlo_env1_W_we=0;reg [QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]  qubit_rdlo_env1_W_waddr=0;reg [QUBIT_RDLO_ENV_W_DATAWIDTH-1:0] qubit_rdlo_env1_W_din=0;assign {qubit_rdlo_env1_W.we,qubit_rdlo_env1_W.addr,qubit_rdlo_env1_W.din}={qubit_rdlo_env1_W_we,qubit_rdlo_env1_W_waddr,qubit_rdlo_env1_W_din};
reg qubit_rdlo_env2_W_we=0;reg [QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]  qubit_rdlo_env2_W_waddr=0;reg [QUBIT_RDLO_ENV_W_DATAWIDTH-1:0] qubit_rdlo_env2_W_din=0;assign {qubit_rdlo_env2_W.we,qubit_rdlo_env2_W.addr,qubit_rdlo_env2_W.din}={qubit_rdlo_env2_W_we,qubit_rdlo_env2_W_waddr,qubit_rdlo_env2_W_din};
reg qubit_rdlo_env3_W_we=0;reg [QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]  qubit_rdlo_env3_W_waddr=0;reg [QUBIT_RDLO_ENV_W_DATAWIDTH-1:0] qubit_rdlo_env3_W_din=0;assign {qubit_rdlo_env3_W.we,qubit_rdlo_env3_W.addr,qubit_rdlo_env3_W.din}={qubit_rdlo_env3_W_we,qubit_rdlo_env3_W_waddr,qubit_rdlo_env3_W_din};
reg qubit_rdlo_env4_W_we=0;reg [QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]  qubit_rdlo_env4_W_waddr=0;reg [QUBIT_RDLO_ENV_W_DATAWIDTH-1:0] qubit_rdlo_env4_W_din=0;assign {qubit_rdlo_env4_W.we,qubit_rdlo_env4_W.addr,qubit_rdlo_env4_W.din}={qubit_rdlo_env4_W_we,qubit_rdlo_env4_W_waddr,qubit_rdlo_env4_W_din};
reg qubit_rdlo_env5_W_we=0;reg [QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]  qubit_rdlo_env5_W_waddr=0;reg [QUBIT_RDLO_ENV_W_DATAWIDTH-1:0] qubit_rdlo_env5_W_din=0;assign {qubit_rdlo_env5_W.we,qubit_rdlo_env5_W.addr,qubit_rdlo_env5_W.din}={qubit_rdlo_env5_W_we,qubit_rdlo_env5_W_waddr,qubit_rdlo_env5_W_din};
reg qubit_rdlo_env6_W_we=0;reg [QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]  qubit_rdlo_env6_W_waddr=0;reg [QUBIT_RDLO_ENV_W_DATAWIDTH-1:0] qubit_rdlo_env6_W_din=0;assign {qubit_rdlo_env6_W.we,qubit_rdlo_env6_W.addr,qubit_rdlo_env6_W.din}={qubit_rdlo_env6_W_we,qubit_rdlo_env6_W_waddr,qubit_rdlo_env6_W_din};
reg qubit_rdlo_env7_W_we=0;reg [QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]  qubit_rdlo_env7_W_waddr=0;reg [QUBIT_RDLO_ENV_W_DATAWIDTH-1:0] qubit_rdlo_env7_W_din=0;assign {qubit_rdlo_env7_W.we,qubit_rdlo_env7_W.addr,qubit_rdlo_env7_W.din}={qubit_rdlo_env7_W_we,qubit_rdlo_env7_W_waddr,qubit_rdlo_env7_W_din};
reg qubit_rdlo_freq0_W_we=0;reg [QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]  qubit_rdlo_freq0_W_waddr=0;reg [QUBIT_RDLO_FREQ_W_DATAWIDTH-1:0] qubit_rdlo_freq0_W_din=0;assign {qubit_rdlo_freq0_W.we,qubit_rdlo_freq0_W.addr,qubit_rdlo_freq0_W.din}={qubit_rdlo_freq0_W_we,qubit_rdlo_freq0_W_waddr,qubit_rdlo_freq0_W_din};
reg qubit_rdlo_freq1_W_we=0;reg [QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]  qubit_rdlo_freq1_W_waddr=0;reg [QUBIT_RDLO_FREQ_W_DATAWIDTH-1:0] qubit_rdlo_freq1_W_din=0;assign {qubit_rdlo_freq1_W.we,qubit_rdlo_freq1_W.addr,qubit_rdlo_freq1_W.din}={qubit_rdlo_freq1_W_we,qubit_rdlo_freq1_W_waddr,qubit_rdlo_freq1_W_din};
reg qubit_rdlo_freq2_W_we=0;reg [QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]  qubit_rdlo_freq2_W_waddr=0;reg [QUBIT_RDLO_FREQ_W_DATAWIDTH-1:0] qubit_rdlo_freq2_W_din=0;assign {qubit_rdlo_freq2_W.we,qubit_rdlo_freq2_W.addr,qubit_rdlo_freq2_W.din}={qubit_rdlo_freq2_W_we,qubit_rdlo_freq2_W_waddr,qubit_rdlo_freq2_W_din};
reg qubit_rdlo_freq3_W_we=0;reg [QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]  qubit_rdlo_freq3_W_waddr=0;reg [QUBIT_RDLO_FREQ_W_DATAWIDTH-1:0] qubit_rdlo_freq3_W_din=0;assign {qubit_rdlo_freq3_W.we,qubit_rdlo_freq3_W.addr,qubit_rdlo_freq3_W.din}={qubit_rdlo_freq3_W_we,qubit_rdlo_freq3_W_waddr,qubit_rdlo_freq3_W_din};
reg qubit_rdlo_freq4_W_we=0;reg [QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]  qubit_rdlo_freq4_W_waddr=0;reg [QUBIT_RDLO_FREQ_W_DATAWIDTH-1:0] qubit_rdlo_freq4_W_din=0;assign {qubit_rdlo_freq4_W.we,qubit_rdlo_freq4_W.addr,qubit_rdlo_freq4_W.din}={qubit_rdlo_freq4_W_we,qubit_rdlo_freq4_W_waddr,qubit_rdlo_freq4_W_din};
reg qubit_rdlo_freq5_W_we=0;reg [QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]  qubit_rdlo_freq5_W_waddr=0;reg [QUBIT_RDLO_FREQ_W_DATAWIDTH-1:0] qubit_rdlo_freq5_W_din=0;assign {qubit_rdlo_freq5_W.we,qubit_rdlo_freq5_W.addr,qubit_rdlo_freq5_W.din}={qubit_rdlo_freq5_W_we,qubit_rdlo_freq5_W_waddr,qubit_rdlo_freq5_W_din};
reg qubit_rdlo_freq6_W_we=0;reg [QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]  qubit_rdlo_freq6_W_waddr=0;reg [QUBIT_RDLO_FREQ_W_DATAWIDTH-1:0] qubit_rdlo_freq6_W_din=0;assign {qubit_rdlo_freq6_W.we,qubit_rdlo_freq6_W.addr,qubit_rdlo_freq6_W.din}={qubit_rdlo_freq6_W_we,qubit_rdlo_freq6_W_waddr,qubit_rdlo_freq6_W_din};
reg qubit_rdlo_freq7_W_we=0;reg [QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]  qubit_rdlo_freq7_W_waddr=0;reg [QUBIT_RDLO_FREQ_W_DATAWIDTH-1:0] qubit_rdlo_freq7_W_din=0;assign {qubit_rdlo_freq7_W.we,qubit_rdlo_freq7_W.addr,qubit_rdlo_freq7_W.din}={qubit_rdlo_freq7_W_we,qubit_rdlo_freq7_W_waddr,qubit_rdlo_freq7_W_din};
reg qubit_rdrv_env0_W_we=0;reg [QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]  qubit_rdrv_env0_W_waddr=0;reg [QUBIT_RDRV_ENV_W_DATAWIDTH-1:0] qubit_rdrv_env0_W_din=0;assign {qubit_rdrv_env0_W.we,qubit_rdrv_env0_W.addr,qubit_rdrv_env0_W.din}={qubit_rdrv_env0_W_we,qubit_rdrv_env0_W_waddr,qubit_rdrv_env0_W_din};
reg qubit_rdrv_env1_W_we=0;reg [QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]  qubit_rdrv_env1_W_waddr=0;reg [QUBIT_RDRV_ENV_W_DATAWIDTH-1:0] qubit_rdrv_env1_W_din=0;assign {qubit_rdrv_env1_W.we,qubit_rdrv_env1_W.addr,qubit_rdrv_env1_W.din}={qubit_rdrv_env1_W_we,qubit_rdrv_env1_W_waddr,qubit_rdrv_env1_W_din};
reg qubit_rdrv_env2_W_we=0;reg [QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]  qubit_rdrv_env2_W_waddr=0;reg [QUBIT_RDRV_ENV_W_DATAWIDTH-1:0] qubit_rdrv_env2_W_din=0;assign {qubit_rdrv_env2_W.we,qubit_rdrv_env2_W.addr,qubit_rdrv_env2_W.din}={qubit_rdrv_env2_W_we,qubit_rdrv_env2_W_waddr,qubit_rdrv_env2_W_din};
reg qubit_rdrv_env3_W_we=0;reg [QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]  qubit_rdrv_env3_W_waddr=0;reg [QUBIT_RDRV_ENV_W_DATAWIDTH-1:0] qubit_rdrv_env3_W_din=0;assign {qubit_rdrv_env3_W.we,qubit_rdrv_env3_W.addr,qubit_rdrv_env3_W.din}={qubit_rdrv_env3_W_we,qubit_rdrv_env3_W_waddr,qubit_rdrv_env3_W_din};
reg qubit_rdrv_env4_W_we=0;reg [QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]  qubit_rdrv_env4_W_waddr=0;reg [QUBIT_RDRV_ENV_W_DATAWIDTH-1:0] qubit_rdrv_env4_W_din=0;assign {qubit_rdrv_env4_W.we,qubit_rdrv_env4_W.addr,qubit_rdrv_env4_W.din}={qubit_rdrv_env4_W_we,qubit_rdrv_env4_W_waddr,qubit_rdrv_env4_W_din};
reg qubit_rdrv_env5_W_we=0;reg [QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]  qubit_rdrv_env5_W_waddr=0;reg [QUBIT_RDRV_ENV_W_DATAWIDTH-1:0] qubit_rdrv_env5_W_din=0;assign {qubit_rdrv_env5_W.we,qubit_rdrv_env5_W.addr,qubit_rdrv_env5_W.din}={qubit_rdrv_env5_W_we,qubit_rdrv_env5_W_waddr,qubit_rdrv_env5_W_din};
reg qubit_rdrv_env6_W_we=0;reg [QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]  qubit_rdrv_env6_W_waddr=0;reg [QUBIT_RDRV_ENV_W_DATAWIDTH-1:0] qubit_rdrv_env6_W_din=0;assign {qubit_rdrv_env6_W.we,qubit_rdrv_env6_W.addr,qubit_rdrv_env6_W.din}={qubit_rdrv_env6_W_we,qubit_rdrv_env6_W_waddr,qubit_rdrv_env6_W_din};
reg qubit_rdrv_env7_W_we=0;reg [QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]  qubit_rdrv_env7_W_waddr=0;reg [QUBIT_RDRV_ENV_W_DATAWIDTH-1:0] qubit_rdrv_env7_W_din=0;assign {qubit_rdrv_env7_W.we,qubit_rdrv_env7_W.addr,qubit_rdrv_env7_W.din}={qubit_rdrv_env7_W_we,qubit_rdrv_env7_W_waddr,qubit_rdrv_env7_W_din};
reg qubit_rdrv_freq0_W_we=0;reg [QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_rdrv_freq0_W_waddr=0;reg [QUBIT_RDRV_FREQ_W_DATAWIDTH-1:0] qubit_rdrv_freq0_W_din=0;assign {qubit_rdrv_freq0_W.we,qubit_rdrv_freq0_W.addr,qubit_rdrv_freq0_W.din}={qubit_rdrv_freq0_W_we,qubit_rdrv_freq0_W_waddr,qubit_rdrv_freq0_W_din};
reg qubit_rdrv_freq1_W_we=0;reg [QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_rdrv_freq1_W_waddr=0;reg [QUBIT_RDRV_FREQ_W_DATAWIDTH-1:0] qubit_rdrv_freq1_W_din=0;assign {qubit_rdrv_freq1_W.we,qubit_rdrv_freq1_W.addr,qubit_rdrv_freq1_W.din}={qubit_rdrv_freq1_W_we,qubit_rdrv_freq1_W_waddr,qubit_rdrv_freq1_W_din};
reg qubit_rdrv_freq2_W_we=0;reg [QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_rdrv_freq2_W_waddr=0;reg [QUBIT_RDRV_FREQ_W_DATAWIDTH-1:0] qubit_rdrv_freq2_W_din=0;assign {qubit_rdrv_freq2_W.we,qubit_rdrv_freq2_W.addr,qubit_rdrv_freq2_W.din}={qubit_rdrv_freq2_W_we,qubit_rdrv_freq2_W_waddr,qubit_rdrv_freq2_W_din};
reg qubit_rdrv_freq3_W_we=0;reg [QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_rdrv_freq3_W_waddr=0;reg [QUBIT_RDRV_FREQ_W_DATAWIDTH-1:0] qubit_rdrv_freq3_W_din=0;assign {qubit_rdrv_freq3_W.we,qubit_rdrv_freq3_W.addr,qubit_rdrv_freq3_W.din}={qubit_rdrv_freq3_W_we,qubit_rdrv_freq3_W_waddr,qubit_rdrv_freq3_W_din};
reg qubit_rdrv_freq4_W_we=0;reg [QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_rdrv_freq4_W_waddr=0;reg [QUBIT_RDRV_FREQ_W_DATAWIDTH-1:0] qubit_rdrv_freq4_W_din=0;assign {qubit_rdrv_freq4_W.we,qubit_rdrv_freq4_W.addr,qubit_rdrv_freq4_W.din}={qubit_rdrv_freq4_W_we,qubit_rdrv_freq4_W_waddr,qubit_rdrv_freq4_W_din};
reg qubit_rdrv_freq5_W_we=0;reg [QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_rdrv_freq5_W_waddr=0;reg [QUBIT_RDRV_FREQ_W_DATAWIDTH-1:0] qubit_rdrv_freq5_W_din=0;assign {qubit_rdrv_freq5_W.we,qubit_rdrv_freq5_W.addr,qubit_rdrv_freq5_W.din}={qubit_rdrv_freq5_W_we,qubit_rdrv_freq5_W_waddr,qubit_rdrv_freq5_W_din};
reg qubit_rdrv_freq6_W_we=0;reg [QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_rdrv_freq6_W_waddr=0;reg [QUBIT_RDRV_FREQ_W_DATAWIDTH-1:0] qubit_rdrv_freq6_W_din=0;assign {qubit_rdrv_freq6_W.we,qubit_rdrv_freq6_W.addr,qubit_rdrv_freq6_W.din}={qubit_rdrv_freq6_W_we,qubit_rdrv_freq6_W_waddr,qubit_rdrv_freq6_W_din};
reg qubit_rdrv_freq7_W_we=0;reg [QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]  qubit_rdrv_freq7_W_waddr=0;reg [QUBIT_RDRV_FREQ_W_DATAWIDTH-1:0] qubit_rdrv_freq7_W_din=0;assign {qubit_rdrv_freq7_W.we,qubit_rdrv_freq7_W.addr,qubit_rdrv_freq7_W.din}={qubit_rdrv_freq7_W_we,qubit_rdrv_freq7_W_waddr,qubit_rdrv_freq7_W_din};
    always @(posedge lb.clk) begin
 qubit_command0_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_COMMAND_W_ADDRWIDTH]=='h2)&lb.wren; qubit_command0_W_waddr<=lb.waddr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]; qubit_command0_W_din<=lb.wdata; // address: 0x00004000
qubit_command1_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_COMMAND_W_ADDRWIDTH]=='h3)&lb.wren; qubit_command1_W_waddr<=lb.waddr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]; qubit_command1_W_din<=lb.wdata; // address: 0x00006000
qubit_command2_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_COMMAND_W_ADDRWIDTH]=='h4)&lb.wren; qubit_command2_W_waddr<=lb.waddr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]; qubit_command2_W_din<=lb.wdata; // address: 0x00008000
qubit_command3_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_COMMAND_W_ADDRWIDTH]=='h5)&lb.wren; qubit_command3_W_waddr<=lb.waddr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]; qubit_command3_W_din<=lb.wdata; // address: 0x0000a000
qubit_command4_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_COMMAND_W_ADDRWIDTH]=='h6)&lb.wren; qubit_command4_W_waddr<=lb.waddr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]; qubit_command4_W_din<=lb.wdata; // address: 0x0000c000
qubit_command5_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_COMMAND_W_ADDRWIDTH]=='h7)&lb.wren; qubit_command5_W_waddr<=lb.waddr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]; qubit_command5_W_din<=lb.wdata; // address: 0x0000e000
qubit_command6_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_COMMAND_W_ADDRWIDTH]=='h8)&lb.wren; qubit_command6_W_waddr<=lb.waddr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]; qubit_command6_W_din<=lb.wdata; // address: 0x00010000
qubit_command7_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_COMMAND_W_ADDRWIDTH]=='h9)&lb.wren; qubit_command7_W_waddr<=lb.waddr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]; qubit_command7_W_din<=lb.wdata; // address: 0x00012000
qubit_qdrv_env0_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_ENV_W_ADDRWIDTH]=='h18)&lb.wren; qubit_qdrv_env0_W_waddr<=lb.waddr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]; qubit_qdrv_env0_W_din<=lb.wdata; // address: 0x00018000
qubit_qdrv_env1_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_ENV_W_ADDRWIDTH]=='h19)&lb.wren; qubit_qdrv_env1_W_waddr<=lb.waddr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]; qubit_qdrv_env1_W_din<=lb.wdata; // address: 0x00019000
qubit_qdrv_env2_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_ENV_W_ADDRWIDTH]=='h1a)&lb.wren; qubit_qdrv_env2_W_waddr<=lb.waddr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]; qubit_qdrv_env2_W_din<=lb.wdata; // address: 0x0001a000
qubit_qdrv_env3_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_ENV_W_ADDRWIDTH]=='h1b)&lb.wren; qubit_qdrv_env3_W_waddr<=lb.waddr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]; qubit_qdrv_env3_W_din<=lb.wdata; // address: 0x0001b000
qubit_qdrv_env4_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_ENV_W_ADDRWIDTH]=='h1c)&lb.wren; qubit_qdrv_env4_W_waddr<=lb.waddr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]; qubit_qdrv_env4_W_din<=lb.wdata; // address: 0x0001c000
qubit_qdrv_env5_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_ENV_W_ADDRWIDTH]=='h1d)&lb.wren; qubit_qdrv_env5_W_waddr<=lb.waddr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]; qubit_qdrv_env5_W_din<=lb.wdata; // address: 0x0001d000
qubit_qdrv_env6_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_ENV_W_ADDRWIDTH]=='h1e)&lb.wren; qubit_qdrv_env6_W_waddr<=lb.waddr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]; qubit_qdrv_env6_W_din<=lb.wdata; // address: 0x0001e000
qubit_qdrv_env7_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_ENV_W_ADDRWIDTH]=='h1f)&lb.wren; qubit_qdrv_env7_W_waddr<=lb.waddr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]; qubit_qdrv_env7_W_din<=lb.wdata; // address: 0x0001f000
qubit_qdrv_freq0_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_FREQ_W_ADDRWIDTH]=='h20)&lb.wren; qubit_qdrv_freq0_W_waddr<=lb.waddr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_qdrv_freq0_W_din<=lb.wdata; // address: 0x00020000
qubit_qdrv_freq1_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_FREQ_W_ADDRWIDTH]=='h21)&lb.wren; qubit_qdrv_freq1_W_waddr<=lb.waddr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_qdrv_freq1_W_din<=lb.wdata; // address: 0x00021000
qubit_qdrv_freq2_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_FREQ_W_ADDRWIDTH]=='h22)&lb.wren; qubit_qdrv_freq2_W_waddr<=lb.waddr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_qdrv_freq2_W_din<=lb.wdata; // address: 0x00022000
qubit_qdrv_freq3_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_FREQ_W_ADDRWIDTH]=='h23)&lb.wren; qubit_qdrv_freq3_W_waddr<=lb.waddr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_qdrv_freq3_W_din<=lb.wdata; // address: 0x00023000
qubit_qdrv_freq4_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_FREQ_W_ADDRWIDTH]=='h24)&lb.wren; qubit_qdrv_freq4_W_waddr<=lb.waddr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_qdrv_freq4_W_din<=lb.wdata; // address: 0x00024000
qubit_qdrv_freq5_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_FREQ_W_ADDRWIDTH]=='h25)&lb.wren; qubit_qdrv_freq5_W_waddr<=lb.waddr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_qdrv_freq5_W_din<=lb.wdata; // address: 0x00025000
qubit_qdrv_freq6_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_FREQ_W_ADDRWIDTH]=='h26)&lb.wren; qubit_qdrv_freq6_W_waddr<=lb.waddr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_qdrv_freq6_W_din<=lb.wdata; // address: 0x00026000
qubit_qdrv_freq7_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_QDRV_FREQ_W_ADDRWIDTH]=='h27)&lb.wren; qubit_qdrv_freq7_W_waddr<=lb.waddr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_qdrv_freq7_W_din<=lb.wdata; // address: 0x00027000
qubit_rdlo_env0_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_ENV_W_ADDRWIDTH]=='h28)&lb.wren; qubit_rdlo_env0_W_waddr<=lb.waddr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]; qubit_rdlo_env0_W_din<=lb.wdata; // address: 0x00028000
qubit_rdlo_env1_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_ENV_W_ADDRWIDTH]=='h29)&lb.wren; qubit_rdlo_env1_W_waddr<=lb.waddr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]; qubit_rdlo_env1_W_din<=lb.wdata; // address: 0x00029000
qubit_rdlo_env2_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_ENV_W_ADDRWIDTH]=='h2a)&lb.wren; qubit_rdlo_env2_W_waddr<=lb.waddr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]; qubit_rdlo_env2_W_din<=lb.wdata; // address: 0x0002a000
qubit_rdlo_env3_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_ENV_W_ADDRWIDTH]=='h2b)&lb.wren; qubit_rdlo_env3_W_waddr<=lb.waddr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]; qubit_rdlo_env3_W_din<=lb.wdata; // address: 0x0002b000
qubit_rdlo_env4_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_ENV_W_ADDRWIDTH]=='h2c)&lb.wren; qubit_rdlo_env4_W_waddr<=lb.waddr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]; qubit_rdlo_env4_W_din<=lb.wdata; // address: 0x0002c000
qubit_rdlo_env5_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_ENV_W_ADDRWIDTH]=='h2d)&lb.wren; qubit_rdlo_env5_W_waddr<=lb.waddr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]; qubit_rdlo_env5_W_din<=lb.wdata; // address: 0x0002d000
qubit_rdlo_env6_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_ENV_W_ADDRWIDTH]=='h2e)&lb.wren; qubit_rdlo_env6_W_waddr<=lb.waddr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]; qubit_rdlo_env6_W_din<=lb.wdata; // address: 0x0002e000
qubit_rdlo_env7_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_ENV_W_ADDRWIDTH]=='h2f)&lb.wren; qubit_rdlo_env7_W_waddr<=lb.waddr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]; qubit_rdlo_env7_W_din<=lb.wdata; // address: 0x0002f000
qubit_rdlo_freq0_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_FREQ_W_ADDRWIDTH]=='h30)&lb.wren; qubit_rdlo_freq0_W_waddr<=lb.waddr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]; qubit_rdlo_freq0_W_din<=lb.wdata; // address: 0x00030000
qubit_rdlo_freq1_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_FREQ_W_ADDRWIDTH]=='h31)&lb.wren; qubit_rdlo_freq1_W_waddr<=lb.waddr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]; qubit_rdlo_freq1_W_din<=lb.wdata; // address: 0x00031000
qubit_rdlo_freq2_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_FREQ_W_ADDRWIDTH]=='h32)&lb.wren; qubit_rdlo_freq2_W_waddr<=lb.waddr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]; qubit_rdlo_freq2_W_din<=lb.wdata; // address: 0x00032000
qubit_rdlo_freq3_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_FREQ_W_ADDRWIDTH]=='h33)&lb.wren; qubit_rdlo_freq3_W_waddr<=lb.waddr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]; qubit_rdlo_freq3_W_din<=lb.wdata; // address: 0x00033000
qubit_rdlo_freq4_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_FREQ_W_ADDRWIDTH]=='h34)&lb.wren; qubit_rdlo_freq4_W_waddr<=lb.waddr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]; qubit_rdlo_freq4_W_din<=lb.wdata; // address: 0x00034000
qubit_rdlo_freq5_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_FREQ_W_ADDRWIDTH]=='h35)&lb.wren; qubit_rdlo_freq5_W_waddr<=lb.waddr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]; qubit_rdlo_freq5_W_din<=lb.wdata; // address: 0x00035000
qubit_rdlo_freq6_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_FREQ_W_ADDRWIDTH]=='h36)&lb.wren; qubit_rdlo_freq6_W_waddr<=lb.waddr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]; qubit_rdlo_freq6_W_din<=lb.wdata; // address: 0x00036000
qubit_rdlo_freq7_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDLO_FREQ_W_ADDRWIDTH]=='h37)&lb.wren; qubit_rdlo_freq7_W_waddr<=lb.waddr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]; qubit_rdlo_freq7_W_din<=lb.wdata; // address: 0x00037000
qubit_rdrv_env0_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_ENV_W_ADDRWIDTH]=='h38)&lb.wren; qubit_rdrv_env0_W_waddr<=lb.waddr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]; qubit_rdrv_env0_W_din<=lb.wdata; // address: 0x00038000
qubit_rdrv_env1_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_ENV_W_ADDRWIDTH]=='h39)&lb.wren; qubit_rdrv_env1_W_waddr<=lb.waddr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]; qubit_rdrv_env1_W_din<=lb.wdata; // address: 0x00039000
qubit_rdrv_env2_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_ENV_W_ADDRWIDTH]=='h3a)&lb.wren; qubit_rdrv_env2_W_waddr<=lb.waddr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]; qubit_rdrv_env2_W_din<=lb.wdata; // address: 0x0003a000
qubit_rdrv_env3_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_ENV_W_ADDRWIDTH]=='h3b)&lb.wren; qubit_rdrv_env3_W_waddr<=lb.waddr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]; qubit_rdrv_env3_W_din<=lb.wdata; // address: 0x0003b000
qubit_rdrv_env4_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_ENV_W_ADDRWIDTH]=='h3c)&lb.wren; qubit_rdrv_env4_W_waddr<=lb.waddr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]; qubit_rdrv_env4_W_din<=lb.wdata; // address: 0x0003c000
qubit_rdrv_env5_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_ENV_W_ADDRWIDTH]=='h3d)&lb.wren; qubit_rdrv_env5_W_waddr<=lb.waddr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]; qubit_rdrv_env5_W_din<=lb.wdata; // address: 0x0003d000
qubit_rdrv_env6_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_ENV_W_ADDRWIDTH]=='h3e)&lb.wren; qubit_rdrv_env6_W_waddr<=lb.waddr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]; qubit_rdrv_env6_W_din<=lb.wdata; // address: 0x0003e000
qubit_rdrv_env7_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_ENV_W_ADDRWIDTH]=='h3f)&lb.wren; qubit_rdrv_env7_W_waddr<=lb.waddr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]; qubit_rdrv_env7_W_din<=lb.wdata; // address: 0x0003f000
qubit_rdrv_freq0_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_FREQ_W_ADDRWIDTH]=='h40)&lb.wren; qubit_rdrv_freq0_W_waddr<=lb.waddr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_rdrv_freq0_W_din<=lb.wdata; // address: 0x00040000
qubit_rdrv_freq1_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_FREQ_W_ADDRWIDTH]=='h41)&lb.wren; qubit_rdrv_freq1_W_waddr<=lb.waddr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_rdrv_freq1_W_din<=lb.wdata; // address: 0x00041000
qubit_rdrv_freq2_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_FREQ_W_ADDRWIDTH]=='h42)&lb.wren; qubit_rdrv_freq2_W_waddr<=lb.waddr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_rdrv_freq2_W_din<=lb.wdata; // address: 0x00042000
qubit_rdrv_freq3_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_FREQ_W_ADDRWIDTH]=='h43)&lb.wren; qubit_rdrv_freq3_W_waddr<=lb.waddr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_rdrv_freq3_W_din<=lb.wdata; // address: 0x00043000
qubit_rdrv_freq4_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_FREQ_W_ADDRWIDTH]=='h44)&lb.wren; qubit_rdrv_freq4_W_waddr<=lb.waddr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_rdrv_freq4_W_din<=lb.wdata; // address: 0x00044000
qubit_rdrv_freq5_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_FREQ_W_ADDRWIDTH]=='h45)&lb.wren; qubit_rdrv_freq5_W_waddr<=lb.waddr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_rdrv_freq5_W_din<=lb.wdata; // address: 0x00045000
qubit_rdrv_freq6_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_FREQ_W_ADDRWIDTH]=='h46)&lb.wren; qubit_rdrv_freq6_W_waddr<=lb.waddr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_rdrv_freq6_W_din<=lb.wdata; // address: 0x00046000
qubit_rdrv_freq7_W_we<=(lb.waddr[ADDR_WIDTH-1:QUBIT_RDRV_FREQ_W_ADDRWIDTH]=='h47)&lb.wren; qubit_rdrv_freq7_W_waddr<=lb.waddr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]; qubit_rdrv_freq7_W_din<=lb.wdata; // address: 0x00047000
 end
reg [ACQBUF_R_ADDRWIDTH-1:0]  acqbuf0_R_raddr=0;reg [ACQBUF_R_DATAWIDTH-1:0] acqbuf0_R_dout=0;assign acqbuf0_R.addr=acqbuf0_R_raddr;
reg [ACQBUF_R_ADDRWIDTH-1:0]  acqbuf1_R_raddr=0;reg [ACQBUF_R_DATAWIDTH-1:0] acqbuf1_R_dout=0;assign acqbuf1_R.addr=acqbuf1_R_raddr;
reg [DACMON_R_ADDRWIDTH-1:0]  dacmon0_R_raddr=0;reg [DACMON_R_DATAWIDTH-1:0] dacmon0_R_dout=0;assign dacmon0_R.addr=dacmon0_R_raddr;
reg [DACMON_R_ADDRWIDTH-1:0]  dacmon1_R_raddr=0;reg [DACMON_R_DATAWIDTH-1:0] dacmon1_R_dout=0;assign dacmon1_R.addr=dacmon1_R_raddr;
reg [DACMON_R_ADDRWIDTH-1:0]  dacmon2_R_raddr=0;reg [DACMON_R_DATAWIDTH-1:0] dacmon2_R_dout=0;assign dacmon2_R.addr=dacmon2_R_raddr;
reg [DACMON_R_ADDRWIDTH-1:0]  dacmon3_R_raddr=0;reg [DACMON_R_DATAWIDTH-1:0] dacmon3_R_dout=0;assign dacmon3_R.addr=dacmon3_R_raddr;
reg [QUBIT_ACCBUF_R_ADDRWIDTH-1:0]  qubit_accbuf0_R_raddr=0;reg [QUBIT_ACCBUF_R_DATAWIDTH-1:0] qubit_accbuf0_R_dout=0;assign qubit_accbuf0_R.addr=qubit_accbuf0_R_raddr;
reg [QUBIT_ACCBUF_R_ADDRWIDTH-1:0]  qubit_accbuf1_R_raddr=0;reg [QUBIT_ACCBUF_R_DATAWIDTH-1:0] qubit_accbuf1_R_dout=0;assign qubit_accbuf1_R.addr=qubit_accbuf1_R_raddr;
reg [QUBIT_ACCBUF_R_ADDRWIDTH-1:0]  qubit_accbuf2_R_raddr=0;reg [QUBIT_ACCBUF_R_DATAWIDTH-1:0] qubit_accbuf2_R_dout=0;assign qubit_accbuf2_R.addr=qubit_accbuf2_R_raddr;
reg [QUBIT_ACCBUF_R_ADDRWIDTH-1:0]  qubit_accbuf3_R_raddr=0;reg [QUBIT_ACCBUF_R_DATAWIDTH-1:0] qubit_accbuf3_R_dout=0;assign qubit_accbuf3_R.addr=qubit_accbuf3_R_raddr;
reg [QUBIT_ACCBUF_R_ADDRWIDTH-1:0]  qubit_accbuf4_R_raddr=0;reg [QUBIT_ACCBUF_R_DATAWIDTH-1:0] qubit_accbuf4_R_dout=0;assign qubit_accbuf4_R.addr=qubit_accbuf4_R_raddr;
reg [QUBIT_ACCBUF_R_ADDRWIDTH-1:0]  qubit_accbuf5_R_raddr=0;reg [QUBIT_ACCBUF_R_DATAWIDTH-1:0] qubit_accbuf5_R_dout=0;assign qubit_accbuf5_R.addr=qubit_accbuf5_R_raddr;
reg [QUBIT_ACCBUF_R_ADDRWIDTH-1:0]  qubit_accbuf6_R_raddr=0;reg [QUBIT_ACCBUF_R_DATAWIDTH-1:0] qubit_accbuf6_R_dout=0;assign qubit_accbuf6_R.addr=qubit_accbuf6_R_raddr;
reg [QUBIT_ACCBUF_R_ADDRWIDTH-1:0]  qubit_accbuf7_R_raddr=0;reg [QUBIT_ACCBUF_R_DATAWIDTH-1:0] qubit_accbuf7_R_dout=0;assign qubit_accbuf7_R.addr=qubit_accbuf7_R_raddr;
always @(posedge lb.clk) begin
            acqbuf0_R_raddr<=lb.raddr[ACQBUF_R_ADDRWIDTH-1:0];acqbuf0_R_dout<=acqbuf0_R.dout;
acqbuf1_R_raddr<=lb.raddr[ACQBUF_R_ADDRWIDTH-1:0];acqbuf1_R_dout<=acqbuf1_R.dout;
dacmon0_R_raddr<=lb.raddr[DACMON_R_ADDRWIDTH-1:0];dacmon0_R_dout<=dacmon0_R.dout;
dacmon1_R_raddr<=lb.raddr[DACMON_R_ADDRWIDTH-1:0];dacmon1_R_dout<=dacmon1_R.dout;
dacmon2_R_raddr<=lb.raddr[DACMON_R_ADDRWIDTH-1:0];dacmon2_R_dout<=dacmon2_R.dout;
dacmon3_R_raddr<=lb.raddr[DACMON_R_ADDRWIDTH-1:0];dacmon3_R_dout<=dacmon3_R.dout;
qubit_accbuf0_R_raddr<=lb.raddr[QUBIT_ACCBUF_R_ADDRWIDTH-1:0];qubit_accbuf0_R_dout<=qubit_accbuf0_R.dout;
qubit_accbuf1_R_raddr<=lb.raddr[QUBIT_ACCBUF_R_ADDRWIDTH-1:0];qubit_accbuf1_R_dout<=qubit_accbuf1_R.dout;
qubit_accbuf2_R_raddr<=lb.raddr[QUBIT_ACCBUF_R_ADDRWIDTH-1:0];qubit_accbuf2_R_dout<=qubit_accbuf2_R.dout;
qubit_accbuf3_R_raddr<=lb.raddr[QUBIT_ACCBUF_R_ADDRWIDTH-1:0];qubit_accbuf3_R_dout<=qubit_accbuf3_R.dout;
qubit_accbuf4_R_raddr<=lb.raddr[QUBIT_ACCBUF_R_ADDRWIDTH-1:0];qubit_accbuf4_R_dout<=qubit_accbuf4_R.dout;
qubit_accbuf5_R_raddr<=lb.raddr[QUBIT_ACCBUF_R_ADDRWIDTH-1:0];qubit_accbuf5_R_dout<=qubit_accbuf5_R.dout;
qubit_accbuf6_R_raddr<=lb.raddr[QUBIT_ACCBUF_R_ADDRWIDTH-1:0];qubit_accbuf6_R_dout<=qubit_accbuf6_R.dout;
qubit_accbuf7_R_raddr<=lb.raddr[QUBIT_ACCBUF_R_ADDRWIDTH-1:0];qubit_accbuf7_R_dout<=qubit_accbuf7_R.dout;
end
    always @(posedge lb.clk) begin
        if (lb.rden16[READDELAY]) begin
            casex (lb.raddr16[READDELAY*ADDR_WIDTH-1:(READDELAY-1)*ADDR_WIDTH])
            {(ADDR_WIDTH-ACQBUF_R_ADDRWIDTH)'('h0),{ACQBUF_R_ADDRWIDTH{1'bx}}}: rdata <= acqbuf0_R_dout;  // address: 0x00000000
{(ADDR_WIDTH-ACQBUF_R_ADDRWIDTH)'('h1),{ACQBUF_R_ADDRWIDTH{1'bx}}}: rdata <= acqbuf1_R_dout;  // address: 0x00002000
{(ADDR_WIDTH-DACMON_R_ADDRWIDTH)'('h14),{DACMON_R_ADDRWIDTH{1'bx}}}: rdata <= dacmon0_R_dout;  // address: 0x00014000
{(ADDR_WIDTH-DACMON_R_ADDRWIDTH)'('h15),{DACMON_R_ADDRWIDTH{1'bx}}}: rdata <= dacmon1_R_dout;  // address: 0x00015000
{(ADDR_WIDTH-DACMON_R_ADDRWIDTH)'('h16),{DACMON_R_ADDRWIDTH{1'bx}}}: rdata <= dacmon2_R_dout;  // address: 0x00016000
{(ADDR_WIDTH-DACMON_R_ADDRWIDTH)'('h17),{DACMON_R_ADDRWIDTH{1'bx}}}: rdata <= dacmon3_R_dout;  // address: 0x00017000
{(ADDR_WIDTH-QUBIT_ACCBUF_R_ADDRWIDTH)'('h90),{QUBIT_ACCBUF_R_ADDRWIDTH{1'bx}}}: rdata <= qubit_accbuf0_R_dout;  // address: 0x00048000
{(ADDR_WIDTH-QUBIT_ACCBUF_R_ADDRWIDTH)'('h91),{QUBIT_ACCBUF_R_ADDRWIDTH{1'bx}}}: rdata <= qubit_accbuf1_R_dout;  // address: 0x00048800
{(ADDR_WIDTH-QUBIT_ACCBUF_R_ADDRWIDTH)'('h92),{QUBIT_ACCBUF_R_ADDRWIDTH{1'bx}}}: rdata <= qubit_accbuf2_R_dout;  // address: 0x00049000
{(ADDR_WIDTH-QUBIT_ACCBUF_R_ADDRWIDTH)'('h93),{QUBIT_ACCBUF_R_ADDRWIDTH{1'bx}}}: rdata <= qubit_accbuf3_R_dout;  // address: 0x00049800
{(ADDR_WIDTH-QUBIT_ACCBUF_R_ADDRWIDTH)'('h94),{QUBIT_ACCBUF_R_ADDRWIDTH{1'bx}}}: rdata <= qubit_accbuf4_R_dout;  // address: 0x0004a000
{(ADDR_WIDTH-QUBIT_ACCBUF_R_ADDRWIDTH)'('h95),{QUBIT_ACCBUF_R_ADDRWIDTH{1'bx}}}: rdata <= qubit_accbuf5_R_dout;  // address: 0x0004a800
{(ADDR_WIDTH-QUBIT_ACCBUF_R_ADDRWIDTH)'('h96),{QUBIT_ACCBUF_R_ADDRWIDTH{1'bx}}}: rdata <= qubit_accbuf6_R_dout;  // address: 0x0004b000
{(ADDR_WIDTH-QUBIT_ACCBUF_R_ADDRWIDTH)'('h97),{QUBIT_ACCBUF_R_ADDRWIDTH{1'bx}}}: rdata <= qubit_accbuf7_R_dout;  // address: 0x0004b800
                default:rdata <= 32'hdeadbeef;
            endcase
        end
    end
assign lb.rdata=rdata;
assign lb.rvalid=lb.rden16[READDELAY+1];
assign lb.rvalidlast=lb.rdenlast16[READDELAY+1];
endinterface