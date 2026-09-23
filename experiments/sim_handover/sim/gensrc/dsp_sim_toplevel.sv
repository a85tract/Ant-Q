module dsp_sim_toplevel#( 
	`include "plps_para.vh" 
	,`include "bram_para.vh")( 
    input clk, 
    input reset, 
    input stb_start, 
    input[31:0] nshot, 
    input[31:0] mem_write_data, 
    input[15:0] mem_write_ind, 
    input[31:0] mem_write_addr, 
    input mem_write_en, 
    input[12:0] mem_read_addr, 
    input[ADC_AXIS_DATAWIDTH-1:0] adc[0:NADC-1], 
    output[DAC_AXIS_DATAWIDTH-1:0] dac[0:NDAC-1], 
    output[63:0] mem_read_data[0:8-1], 
    output[ACQBUF_W_DATAWIDTH-1:0] acq_read_data[0:NADC-1]); 
 
    ifdsp dspif(); 
    assign dac = dspif.dac; 
    assign dspif.adc = adc; 
    assign dspif.clk = clk; 
    assign dspif.reset = reset; 
    assign dspif.resetacc = reset; 
    assign dspif.stb_start = stb_start; 
    assign dspif.nshot = nshot; 
    assign dspif.acc_shift = 15; 

    dsp dspmod(.dspif(dspif)); 

    wire wen_0; 
    assign wen_0 = mem_write_en & (mem_write_ind == 0); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(4), .DOUT_ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH-1), .READ_LATENCY(2)) 
    mem_w_0(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_0), .read_addr(dspif.addr_qubit_command[0]),  
        .read_data(dspif.data_qubit_command[0])); 

    wire wen_1; 
    assign wen_1 = mem_write_en & (mem_write_ind == 1); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_1(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_1), .read_addr(dspif.addr_qubit_qdrv_env[0]),  
        .read_data(dspif.data_qubit_qdrv_env[0])); 

    wire wen_2; 
    assign wen_2 = mem_write_en & (mem_write_ind == 2); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_2(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_2), .read_addr(dspif.addr_qubit_qdrv_freq[0]),  
        .read_data(dspif.data_qubit_qdrv_freq[0])); 

    wire wen_3; 
    assign wen_3 = mem_write_en & (mem_write_ind == 3); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_3(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_3), .read_addr(dspif.addr_qubit_rdrv_env[0]),  
        .read_data(dspif.data_qubit_rdrv_env[0])); 

    wire wen_4; 
    assign wen_4 = mem_write_en & (mem_write_ind == 4); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_4(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_4), .read_addr(dspif.addr_qubit_rdrv_freq[0]),  
        .read_data(dspif.data_qubit_rdrv_freq[0])); 

    wire wen_5; 
    assign wen_5 = mem_write_en & (mem_write_ind == 5); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_5(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_5), .read_addr(dspif.addr_qubit_rdlo_env[0]),  
        .read_data(dspif.data_qubit_rdlo_env[0])); 

    wire wen_6; 
    assign wen_6 = mem_write_en & (mem_write_ind == 6); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_6(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_6), .read_addr(dspif.addr_qubit_rdlo_freq[0]),  
        .read_data(dspif.data_qubit_rdlo_freq[0])); 

    aligned_ram #(.DIN_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH), .N_DIN_TO_DOUT(1), .DOUT_ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH), .READ_LATENCY(1)) 
        mem_r_0(.clk(clk), .write_data(dspif.data_qubit_accbuf[0]), .write_addr(dspif.addr_qubit_accbuf[0]), 
            .write_enable(dspif.we_qubit_accbuf[0]), .read_addr(mem_read_addr[QUBIT_ACCBUF_W_ADDRWIDTH-1:0]),  
                  .read_data(mem_read_data[0])); 
    wire wen_7; 
    assign wen_7 = mem_write_en & (mem_write_ind == 7); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(4), .DOUT_ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH-1), .READ_LATENCY(2)) 
    mem_w_7(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_7), .read_addr(dspif.addr_qubit_command[1]),  
        .read_data(dspif.data_qubit_command[1])); 

    wire wen_8; 
    assign wen_8 = mem_write_en & (mem_write_ind == 8); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_8(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_8), .read_addr(dspif.addr_qubit_qdrv_env[1]),  
        .read_data(dspif.data_qubit_qdrv_env[1])); 

    wire wen_9; 
    assign wen_9 = mem_write_en & (mem_write_ind == 9); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_9(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_9), .read_addr(dspif.addr_qubit_qdrv_freq[1]),  
        .read_data(dspif.data_qubit_qdrv_freq[1])); 

    wire wen_10; 
    assign wen_10 = mem_write_en & (mem_write_ind == 10); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_10(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_10), .read_addr(dspif.addr_qubit_rdrv_env[1]),  
        .read_data(dspif.data_qubit_rdrv_env[1])); 

    wire wen_11; 
    assign wen_11 = mem_write_en & (mem_write_ind == 11); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_11(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_11), .read_addr(dspif.addr_qubit_rdrv_freq[1]),  
        .read_data(dspif.data_qubit_rdrv_freq[1])); 

    wire wen_12; 
    assign wen_12 = mem_write_en & (mem_write_ind == 12); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_12(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_12), .read_addr(dspif.addr_qubit_rdlo_env[1]),  
        .read_data(dspif.data_qubit_rdlo_env[1])); 

    wire wen_13; 
    assign wen_13 = mem_write_en & (mem_write_ind == 13); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_13(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_13), .read_addr(dspif.addr_qubit_rdlo_freq[1]),  
        .read_data(dspif.data_qubit_rdlo_freq[1])); 

    aligned_ram #(.DIN_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH), .N_DIN_TO_DOUT(1), .DOUT_ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH), .READ_LATENCY(1)) 
        mem_r_1(.clk(clk), .write_data(dspif.data_qubit_accbuf[1]), .write_addr(dspif.addr_qubit_accbuf[1]), 
            .write_enable(dspif.we_qubit_accbuf[1]), .read_addr(mem_read_addr[QUBIT_ACCBUF_W_ADDRWIDTH-1:0]),  
                  .read_data(mem_read_data[1])); 
    wire wen_14; 
    assign wen_14 = mem_write_en & (mem_write_ind == 14); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(4), .DOUT_ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH-1), .READ_LATENCY(2)) 
    mem_w_14(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_14), .read_addr(dspif.addr_qubit_command[2]),  
        .read_data(dspif.data_qubit_command[2])); 

    wire wen_15; 
    assign wen_15 = mem_write_en & (mem_write_ind == 15); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_15(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_15), .read_addr(dspif.addr_qubit_qdrv_env[2]),  
        .read_data(dspif.data_qubit_qdrv_env[2])); 

    wire wen_16; 
    assign wen_16 = mem_write_en & (mem_write_ind == 16); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_16(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_16), .read_addr(dspif.addr_qubit_qdrv_freq[2]),  
        .read_data(dspif.data_qubit_qdrv_freq[2])); 

    wire wen_17; 
    assign wen_17 = mem_write_en & (mem_write_ind == 17); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_17(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_17), .read_addr(dspif.addr_qubit_rdrv_env[2]),  
        .read_data(dspif.data_qubit_rdrv_env[2])); 

    wire wen_18; 
    assign wen_18 = mem_write_en & (mem_write_ind == 18); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_18(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_18), .read_addr(dspif.addr_qubit_rdrv_freq[2]),  
        .read_data(dspif.data_qubit_rdrv_freq[2])); 

    wire wen_19; 
    assign wen_19 = mem_write_en & (mem_write_ind == 19); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_19(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_19), .read_addr(dspif.addr_qubit_rdlo_env[2]),  
        .read_data(dspif.data_qubit_rdlo_env[2])); 

    wire wen_20; 
    assign wen_20 = mem_write_en & (mem_write_ind == 20); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_20(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_20), .read_addr(dspif.addr_qubit_rdlo_freq[2]),  
        .read_data(dspif.data_qubit_rdlo_freq[2])); 

    aligned_ram #(.DIN_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH), .N_DIN_TO_DOUT(1), .DOUT_ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH), .READ_LATENCY(1)) 
        mem_r_2(.clk(clk), .write_data(dspif.data_qubit_accbuf[2]), .write_addr(dspif.addr_qubit_accbuf[2]), 
            .write_enable(dspif.we_qubit_accbuf[2]), .read_addr(mem_read_addr[QUBIT_ACCBUF_W_ADDRWIDTH-1:0]),  
                  .read_data(mem_read_data[2])); 
    wire wen_21; 
    assign wen_21 = mem_write_en & (mem_write_ind == 21); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(4), .DOUT_ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH-1), .READ_LATENCY(2)) 
    mem_w_21(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_21), .read_addr(dspif.addr_qubit_command[3]),  
        .read_data(dspif.data_qubit_command[3])); 

    wire wen_22; 
    assign wen_22 = mem_write_en & (mem_write_ind == 22); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_22(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_22), .read_addr(dspif.addr_qubit_qdrv_env[3]),  
        .read_data(dspif.data_qubit_qdrv_env[3])); 

    wire wen_23; 
    assign wen_23 = mem_write_en & (mem_write_ind == 23); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_23(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_23), .read_addr(dspif.addr_qubit_qdrv_freq[3]),  
        .read_data(dspif.data_qubit_qdrv_freq[3])); 

    wire wen_24; 
    assign wen_24 = mem_write_en & (mem_write_ind == 24); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_24(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_24), .read_addr(dspif.addr_qubit_rdrv_env[3]),  
        .read_data(dspif.data_qubit_rdrv_env[3])); 

    wire wen_25; 
    assign wen_25 = mem_write_en & (mem_write_ind == 25); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_25(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_25), .read_addr(dspif.addr_qubit_rdrv_freq[3]),  
        .read_data(dspif.data_qubit_rdrv_freq[3])); 

    wire wen_26; 
    assign wen_26 = mem_write_en & (mem_write_ind == 26); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_26(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_26), .read_addr(dspif.addr_qubit_rdlo_env[3]),  
        .read_data(dspif.data_qubit_rdlo_env[3])); 

    wire wen_27; 
    assign wen_27 = mem_write_en & (mem_write_ind == 27); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_27(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_27), .read_addr(dspif.addr_qubit_rdlo_freq[3]),  
        .read_data(dspif.data_qubit_rdlo_freq[3])); 

    aligned_ram #(.DIN_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH), .N_DIN_TO_DOUT(1), .DOUT_ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH), .READ_LATENCY(1)) 
        mem_r_3(.clk(clk), .write_data(dspif.data_qubit_accbuf[3]), .write_addr(dspif.addr_qubit_accbuf[3]), 
            .write_enable(dspif.we_qubit_accbuf[3]), .read_addr(mem_read_addr[QUBIT_ACCBUF_W_ADDRWIDTH-1:0]),  
                  .read_data(mem_read_data[3])); 
    wire wen_28; 
    assign wen_28 = mem_write_en & (mem_write_ind == 28); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(4), .DOUT_ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH-1), .READ_LATENCY(2)) 
    mem_w_28(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_28), .read_addr(dspif.addr_qubit_command[4]),  
        .read_data(dspif.data_qubit_command[4])); 

    wire wen_29; 
    assign wen_29 = mem_write_en & (mem_write_ind == 29); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_29(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_29), .read_addr(dspif.addr_qubit_qdrv_env[4]),  
        .read_data(dspif.data_qubit_qdrv_env[4])); 

    wire wen_30; 
    assign wen_30 = mem_write_en & (mem_write_ind == 30); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_30(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_30), .read_addr(dspif.addr_qubit_qdrv_freq[4]),  
        .read_data(dspif.data_qubit_qdrv_freq[4])); 

    wire wen_31; 
    assign wen_31 = mem_write_en & (mem_write_ind == 31); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_31(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_31), .read_addr(dspif.addr_qubit_rdrv_env[4]),  
        .read_data(dspif.data_qubit_rdrv_env[4])); 

    wire wen_32; 
    assign wen_32 = mem_write_en & (mem_write_ind == 32); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_32(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_32), .read_addr(dspif.addr_qubit_rdrv_freq[4]),  
        .read_data(dspif.data_qubit_rdrv_freq[4])); 

    wire wen_33; 
    assign wen_33 = mem_write_en & (mem_write_ind == 33); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_33(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_33), .read_addr(dspif.addr_qubit_rdlo_env[4]),  
        .read_data(dspif.data_qubit_rdlo_env[4])); 

    wire wen_34; 
    assign wen_34 = mem_write_en & (mem_write_ind == 34); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_34(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_34), .read_addr(dspif.addr_qubit_rdlo_freq[4]),  
        .read_data(dspif.data_qubit_rdlo_freq[4])); 

    aligned_ram #(.DIN_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH), .N_DIN_TO_DOUT(1), .DOUT_ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH), .READ_LATENCY(1)) 
        mem_r_4(.clk(clk), .write_data(dspif.data_qubit_accbuf[4]), .write_addr(dspif.addr_qubit_accbuf[4]), 
            .write_enable(dspif.we_qubit_accbuf[4]), .read_addr(mem_read_addr[QUBIT_ACCBUF_W_ADDRWIDTH-1:0]),  
                  .read_data(mem_read_data[4])); 
    wire wen_35; 
    assign wen_35 = mem_write_en & (mem_write_ind == 35); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(4), .DOUT_ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH-1), .READ_LATENCY(2)) 
    mem_w_35(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_35), .read_addr(dspif.addr_qubit_command[5]),  
        .read_data(dspif.data_qubit_command[5])); 

    wire wen_36; 
    assign wen_36 = mem_write_en & (mem_write_ind == 36); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_36(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_36), .read_addr(dspif.addr_qubit_qdrv_env[5]),  
        .read_data(dspif.data_qubit_qdrv_env[5])); 

    wire wen_37; 
    assign wen_37 = mem_write_en & (mem_write_ind == 37); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_37(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_37), .read_addr(dspif.addr_qubit_qdrv_freq[5]),  
        .read_data(dspif.data_qubit_qdrv_freq[5])); 

    wire wen_38; 
    assign wen_38 = mem_write_en & (mem_write_ind == 38); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_38(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_38), .read_addr(dspif.addr_qubit_rdrv_env[5]),  
        .read_data(dspif.data_qubit_rdrv_env[5])); 

    wire wen_39; 
    assign wen_39 = mem_write_en & (mem_write_ind == 39); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_39(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_39), .read_addr(dspif.addr_qubit_rdrv_freq[5]),  
        .read_data(dspif.data_qubit_rdrv_freq[5])); 

    wire wen_40; 
    assign wen_40 = mem_write_en & (mem_write_ind == 40); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_40(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_40), .read_addr(dspif.addr_qubit_rdlo_env[5]),  
        .read_data(dspif.data_qubit_rdlo_env[5])); 

    wire wen_41; 
    assign wen_41 = mem_write_en & (mem_write_ind == 41); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_41(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_41), .read_addr(dspif.addr_qubit_rdlo_freq[5]),  
        .read_data(dspif.data_qubit_rdlo_freq[5])); 

    aligned_ram #(.DIN_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH), .N_DIN_TO_DOUT(1), .DOUT_ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH), .READ_LATENCY(1)) 
        mem_r_5(.clk(clk), .write_data(dspif.data_qubit_accbuf[5]), .write_addr(dspif.addr_qubit_accbuf[5]), 
            .write_enable(dspif.we_qubit_accbuf[5]), .read_addr(mem_read_addr[QUBIT_ACCBUF_W_ADDRWIDTH-1:0]),  
                  .read_data(mem_read_data[5])); 
    wire wen_42; 
    assign wen_42 = mem_write_en & (mem_write_ind == 42); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(4), .DOUT_ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH-1), .READ_LATENCY(2)) 
    mem_w_42(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_42), .read_addr(dspif.addr_qubit_command[6]),  
        .read_data(dspif.data_qubit_command[6])); 

    wire wen_43; 
    assign wen_43 = mem_write_en & (mem_write_ind == 43); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_43(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_43), .read_addr(dspif.addr_qubit_qdrv_env[6]),  
        .read_data(dspif.data_qubit_qdrv_env[6])); 

    wire wen_44; 
    assign wen_44 = mem_write_en & (mem_write_ind == 44); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_44(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_44), .read_addr(dspif.addr_qubit_qdrv_freq[6]),  
        .read_data(dspif.data_qubit_qdrv_freq[6])); 

    wire wen_45; 
    assign wen_45 = mem_write_en & (mem_write_ind == 45); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_45(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_45), .read_addr(dspif.addr_qubit_rdrv_env[6]),  
        .read_data(dspif.data_qubit_rdrv_env[6])); 

    wire wen_46; 
    assign wen_46 = mem_write_en & (mem_write_ind == 46); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_46(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_46), .read_addr(dspif.addr_qubit_rdrv_freq[6]),  
        .read_data(dspif.data_qubit_rdrv_freq[6])); 

    wire wen_47; 
    assign wen_47 = mem_write_en & (mem_write_ind == 47); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_47(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_47), .read_addr(dspif.addr_qubit_rdlo_env[6]),  
        .read_data(dspif.data_qubit_rdlo_env[6])); 

    wire wen_48; 
    assign wen_48 = mem_write_en & (mem_write_ind == 48); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_48(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_48), .read_addr(dspif.addr_qubit_rdlo_freq[6]),  
        .read_data(dspif.data_qubit_rdlo_freq[6])); 

    aligned_ram #(.DIN_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH), .N_DIN_TO_DOUT(1), .DOUT_ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH), .READ_LATENCY(1)) 
        mem_r_6(.clk(clk), .write_data(dspif.data_qubit_accbuf[6]), .write_addr(dspif.addr_qubit_accbuf[6]), 
            .write_enable(dspif.we_qubit_accbuf[6]), .read_addr(mem_read_addr[QUBIT_ACCBUF_W_ADDRWIDTH-1:0]),  
                  .read_data(mem_read_data[6])); 
    wire wen_49; 
    assign wen_49 = mem_write_en & (mem_write_ind == 49); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(4), .DOUT_ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH-1), .READ_LATENCY(2)) 
    mem_w_49(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_COMMAND_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_49), .read_addr(dspif.addr_qubit_command[7]),  
        .read_data(dspif.data_qubit_command[7])); 

    wire wen_50; 
    assign wen_50 = mem_write_en & (mem_write_ind == 50); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_50(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_50), .read_addr(dspif.addr_qubit_qdrv_env[7]),  
        .read_data(dspif.data_qubit_qdrv_env[7])); 

    wire wen_51; 
    assign wen_51 = mem_write_en & (mem_write_ind == 51); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_QDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_51(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_QDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_51), .read_addr(dspif.addr_qubit_qdrv_freq[7]),  
        .read_data(dspif.data_qubit_qdrv_freq[7])); 

    wire wen_52; 
    assign wen_52 = mem_write_en & (mem_write_ind == 52); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_52(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_52), .read_addr(dspif.addr_qubit_rdrv_env[7]),  
        .read_data(dspif.data_qubit_rdrv_env[7])); 

    wire wen_53; 
    assign wen_53 = mem_write_en & (mem_write_ind == 53); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDRV_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_53(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDRV_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_53), .read_addr(dspif.addr_qubit_rdrv_freq[7]),  
        .read_data(dspif.data_qubit_rdrv_freq[7])); 

    wire wen_54; 
    assign wen_54 = mem_write_en & (mem_write_ind == 54); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_ENV_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_54(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_ENV_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_54), .read_addr(dspif.addr_qubit_rdlo_env[7]),  
        .read_data(dspif.data_qubit_rdlo_env[7])); 

    wire wen_55; 
    assign wen_55 = mem_write_en & (mem_write_ind == 55); 
    aligned_ram #(.DIN_WIDTH(32), .N_DIN_TO_DOUT(QUBIT_RDLO_FREQ_R_DATAWIDTH/32), .DOUT_ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH-1), 
                 .READ_LATENCY(2)) 
    mem_w_55(.clk(clk), .write_data(mem_write_data), .write_addr(mem_write_addr[QUBIT_RDLO_FREQ_W_ADDRWIDTH-1:0]), 
        .write_enable(wen_55), .read_addr(dspif.addr_qubit_rdlo_freq[7]),  
        .read_data(dspif.data_qubit_rdlo_freq[7])); 

    aligned_ram #(.DIN_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH), .N_DIN_TO_DOUT(1), .DOUT_ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH), .READ_LATENCY(1)) 
        mem_r_7(.clk(clk), .write_data(dspif.data_qubit_accbuf[7]), .write_addr(dspif.addr_qubit_accbuf[7]), 
            .write_enable(dspif.we_qubit_accbuf[7]), .read_addr(mem_read_addr[QUBIT_ACCBUF_W_ADDRWIDTH-1:0]),  
                  .read_data(mem_read_data[7])); 
endmodule