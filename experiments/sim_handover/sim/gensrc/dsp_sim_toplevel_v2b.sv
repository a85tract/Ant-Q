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
    output[ACQBUF_W_DATAWIDTH-1:0] acq_read_data[0:NADC-1],
    // ---- v2-B command-streaming ports (gate 3) ----
    input ddr_clk,
    input ddr_rst_n,
    input[255:0] s_axis_tdata,
    input s_axis_tvalid,
    output s_axis_tready,
    input[31:0] n_shots,
    input n_shots_enable,
    input[31:0] production_gap_val,
    input production_gap_en,
    input global_start,
    input[15:0] last_circuit_id,
    output[15:0] v2b_circuit_id,
    output v2b_batch_done,
    // ---- v2-B readout writeback outputs (gate 5) ----
    output ro_current_user_done,
    output[23:0] ro_final_addr); 
 
    ifdsp dspif(); 
    assign dac = dspif.dac; 
    assign dspif.adc = adc; 
    assign dspif.clk = clk; 
    assign dspif.reset = reset; 
    assign dspif.resetacc = reset;   
    assign dspif.acc_shift = 15; 

    dsp dspmod(.dspif(dspif)); 
 

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
    // ==================== v2-B command-streaming integration (gate 3) ====================
    localparam integer V2B_NUM_CH   = 8;
    localparam integer V2B_PPBUF_AW = 7;                       // 128 read words/bank (SIM-ONLY reduced depth)
    localparam integer V2B_BPC      = (1<<V2B_PPBUF_AW)/2;     // BEATS_PER_CHUNK = 64
    localparam integer V2B_CMD_W    = 128;
    localparam integer V2B_AXI_DW   = 256;
    localparam integer V2B_AXI_AW   = 24;

    wire [V2B_NUM_CH-1:0]               v2b_able, v2b_empty;
    wire [V2B_NUM_CH*V2B_PPBUF_AW-1:0]  v2b_rd_addr_valid;
    wire [V2B_NUM_CH*V2B_CMD_W-1:0]     v2b_rd_data;
    wire [V2B_NUM_CH*V2B_PPBUF_AW-1:0]  v2b_rd_addr;
    wire [V2B_NUM_CH-1:0]               v2b_rd_en = {V2B_NUM_CH{1'b1}};
    wire [V2B_NUM_CH-1:0]               v2b_read_finished;
    wire [31:0]                         v2b_nshots_staged;

    // command read: dspif.addr_qubit_command[c] (low PPBUF_AW bits) -> ppbuf; ppbuf rd_data -> dspif (no reg)
    genvar gc;
    generate for (gc=0; gc<V2B_NUM_CH; gc=gc+1) begin : g_v2bcmd
        assign v2b_rd_addr[gc*V2B_PPBUF_AW +: V2B_PPBUF_AW] = dspif.addr_qubit_command[gc][V2B_PPBUF_AW-1:0];
        assign dspif.data_qubit_command[gc] = v2b_rd_data[gc*V2B_CMD_W +: V2B_CMD_W];
        always @(posedge clk) if (|dspif.addr_qubit_command[gc][QUBIT_COMMAND_R_ADDRWIDTH-1:V2B_PPBUF_AW])
            $error("v2b: cmd ch %0d addr %0h exceeds reduced ppbuf depth", gc, dspif.addr_qubit_command[gc]);
    end endgenerate

    wire [3:0] v2b_awid,v2b_arid,v2b_bid,v2b_rid; wire [V2B_AXI_AW-1:0] v2b_awaddr,v2b_araddr;
    wire [7:0] v2b_awlen,v2b_arlen; wire [2:0] v2b_awsize,v2b_arsize;
    wire [1:0] v2b_awburst,v2b_arburst,v2b_bresp,v2b_rresp;
    wire v2b_awvalid,v2b_awready,v2b_wvalid,v2b_wready,v2b_wlast,v2b_bvalid,v2b_bready;
    wire v2b_arvalid,v2b_arready,v2b_rvalid,v2b_rready,v2b_rlast;
    wire [V2B_AXI_DW-1:0] v2b_wdata,v2b_rdata; wire [V2B_AXI_DW/8-1:0] v2b_wstrb;

    mmu_writedown #(.NUM_CMD_CHANNELS(V2B_NUM_CH), .CMD_WIDTH(V2B_CMD_W), .AXI_DATA_WIDTH(V2B_AXI_DW),
        .AXI_ADDR_WIDTH(V2B_AXI_AW), .AXI_ID_WIDTH(4), .BEATS_PER_CHUNK(V2B_BPC), .MAX_BURST_LEN(V2B_BPC),
        .PPBUF_ADDR_WIDTH(V2B_PPBUF_AW))
    u_v2b_mmu (.wr_clk(clk), .wr_rst_n(~reset), .rd_clk(ddr_clk), .rd_rst_n(ddr_rst_n),
        .trigger_switch(1'b0), .global_start(global_start), .config_fifo_full(),
        .n_shots(n_shots), .n_shots_enable(n_shots_enable),
        .production_gap_val(production_gap_val), .production_gap_en(production_gap_en),
        .nshots_out(), .production_gap_out(), .config_valid_out(),
        .nshots_staged_out(v2b_nshots_staged), .pgap_staged_out(),
        .s_axis_tdata(s_axis_tdata), .s_axis_tvalid(s_axis_tvalid), .s_axis_tready(s_axis_tready),
        .ppbuf_able_to_read(v2b_able), .ppbuf_rd_empty(v2b_empty), .ppbuf_rd_addr_valid(v2b_rd_addr_valid),
        .ppbuf_rd_data(v2b_rd_data), .ppbuf_rd_addr(v2b_rd_addr), .ppbuf_rd_en(v2b_rd_en),
        .ppbuf_read_finished(v2b_read_finished),
        .m_axi_awid(v2b_awid),.m_axi_awaddr(v2b_awaddr),.m_axi_awlen(v2b_awlen),.m_axi_awsize(v2b_awsize),
        .m_axi_awburst(v2b_awburst),.m_axi_awvalid(v2b_awvalid),.m_axi_awready(v2b_awready),
        .m_axi_wdata(v2b_wdata),.m_axi_wstrb(v2b_wstrb),.m_axi_wlast(v2b_wlast),.m_axi_wvalid(v2b_wvalid),.m_axi_wready(v2b_wready),
        .m_axi_bid(v2b_bid),.m_axi_bresp(v2b_bresp),.m_axi_bvalid(v2b_bvalid),.m_axi_bready(v2b_bready),
        .m_axi_arid(v2b_arid),.m_axi_araddr(v2b_araddr),.m_axi_arlen(v2b_arlen),.m_axi_arsize(v2b_arsize),
        .m_axi_arburst(v2b_arburst),.m_axi_arvalid(v2b_arvalid),.m_axi_arready(v2b_arready),
        .m_axi_rid(v2b_rid),.m_axi_rdata(v2b_rdata),.m_axi_rresp(v2b_rresp),.m_axi_rlast(v2b_rlast),
        .m_axi_rvalid(v2b_rvalid),.m_axi_rready(v2b_rready),
        .fifo_empty(),.fifo_full(),.fetch_complete(),.switch_done());

    axi_dpram #(.AXI_ADDR_WIDTH(V2B_AXI_AW), .AXI_DATA_WIDTH(V2B_AXI_DW), .AXI_ID_WIDTH(4), .MEM_AW(15))
    u_v2b_ddr (.aclk(ddr_clk), .aresetn(ddr_rst_n),
        .s_axi_awid(v2b_awid),.s_axi_awaddr(v2b_awaddr),.s_axi_awlen(v2b_awlen),.s_axi_awsize(v2b_awsize),
        .s_axi_awburst(v2b_awburst),.s_axi_awvalid(v2b_awvalid),.s_axi_awready(v2b_awready),
        .s_axi_wdata(v2b_wdata),.s_axi_wstrb(v2b_wstrb),.s_axi_wlast(v2b_wlast),.s_axi_wvalid(v2b_wvalid),.s_axi_wready(v2b_wready),
        .s_axi_bid(v2b_bid),.s_axi_bresp(v2b_bresp),.s_axi_bvalid(v2b_bvalid),.s_axi_bready(v2b_bready),
        .s_axi_arid(v2b_arid),.s_axi_araddr(v2b_araddr),.s_axi_arlen(v2b_arlen),.s_axi_arsize(v2b_arsize),
        .s_axi_arburst(v2b_arburst),.s_axi_arvalid(v2b_arvalid),.s_axi_arready(v2b_arready),
        .s_axi_rid(v2b_rid),.s_axi_rdata(v2b_rdata),.s_axi_rresp(v2b_rresp),.s_axi_rlast(v2b_rlast),
        .s_axi_rvalid(v2b_rvalid),.s_axi_rready(v2b_rready));

    wire v2b_seq_stb; wire [31:0] v2b_seq_nshot;
    assign dspif.stb_start = v2b_seq_stb;
    assign dspif.nshot     = v2b_seq_nshot;

    cmd_sequencer #(.NUM_CH(V2B_NUM_CH), .NSHOT_W(32), .CID_W(16))
    u_v2b_seq (.clk(clk), .rst_n(~reset), .global_start(global_start), .last_circuit_id(last_circuit_id),
        .ppbuf_able_to_read(v2b_able), .ppbuf_rd_empty(v2b_empty), .nshots_staged(v2b_nshots_staged),
        .stb_start(v2b_seq_stb), .nshot(v2b_seq_nshot), .lastshotdone(dspif.lastshotdone),
        .ppbuf_read_finished(v2b_read_finished), .circuit_id(v2b_circuit_id), .batch_done(v2b_batch_done));

    always @(posedge clk) if (v2b_seq_stb && !(&(v2b_able & ~v2b_empty)))
        $error("v2b: stb_start asserted before all command banks ready");

    // ==================== v2-B READOUT writeback (gate 5): accbuf -> tagger -> mmu_para -> readout DDR ====
    // Tap the real dsp's IQ accumulator writes (dspif.data/we_qubit_accbuf), tag, and stream to a separate
    // readout DDR. Flush per circuit on the sequencer's read_finished (= per-circuit done). Idle in gate-3
    // (no measurement -> no accbuf writes). Host decode: tagged 64b = {tag[63:56], I=[55:28]=accx[31:4],
    // Q=[27:0]=accy[31:4]} (gate-4 contract).
    localparam integer RO_CB_AW = 4;
    wire [V2B_NUM_CH*64-1:0] ro_tin, ro_tout;
    wire [V2B_NUM_CH-1:0]    ro_tin_en, ro_tout_en;
    genvar gr;
    generate for (gr=0; gr<V2B_NUM_CH; gr=gr+1) begin : g_ro
        assign ro_tin[gr*64 +: 64] = dspif.data_qubit_accbuf[gr];
        assign ro_tin_en[gr]       = dspif.we_qubit_accbuf[gr];
    end endgenerate
    data_tagger_top #(.NUM_CH(V2B_NUM_CH)) u_ro_tagger (.clk(clk), .rst_n(~reset),
        .data_in(ro_tin), .data_in_en(ro_tin_en), .data_out(ro_tout), .data_out_en(ro_tout_en));

    wire [V2B_AXI_AW-1:0] ro_awaddr; wire [7:0] ro_awlen; wire [2:0] ro_awsize; wire [1:0] ro_awburst, ro_bresp;
    wire ro_awvalid, ro_awready, ro_wvalid, ro_wready, ro_wlast, ro_bvalid, ro_bready;
    wire [V2B_AXI_DW-1:0] ro_wdata; wire [V2B_AXI_DW/8-1:0] ro_wstrb;

    mmu_para #(.NUM_CHANNELS(V2B_NUM_CH), .WR_DATA_WIDTH(64), .RD_DATA_WIDTH(V2B_AXI_DW),
        .ADDR_WIDTH(RO_CB_AW), .AXI_ADDR_WIDTH(V2B_AXI_AW))
    u_ro_mmu (.wr_clk(clk), .wr_rst_n(~reset), .rd_clk(ddr_clk), .rd_rst_n(ddr_rst_n),
        .ch_wr_en(ro_tout_en), .ch_wr_data(ro_tout),
        .N_shot_finished(v2b_read_finished[0]), .max_bank_size(4'hF),
        .base_addr({V2B_AXI_AW{1'b0}}), .base_reset(1'b0),
        .final_addr(ro_final_addr), .current_user_done(ro_current_user_done), .cur_axi_addr_out(),
        .m_axi_awaddr(ro_awaddr), .m_axi_awlen(ro_awlen), .m_axi_awsize(ro_awsize), .m_axi_awburst(ro_awburst),
        .m_axi_awvalid(ro_awvalid), .m_axi_awready(ro_awready),
        .m_axi_wdata(ro_wdata), .m_axi_wstrb(ro_wstrb), .m_axi_wlast(ro_wlast), .m_axi_wvalid(ro_wvalid), .m_axi_wready(ro_wready),
        .m_axi_bresp(ro_bresp), .m_axi_bvalid(ro_bvalid), .m_axi_bready(ro_bready));

    axi_dpram #(.AXI_ADDR_WIDTH(V2B_AXI_AW), .AXI_DATA_WIDTH(V2B_AXI_DW), .AXI_ID_WIDTH(4), .MEM_AW(12))
    u_ro_ddr (.aclk(ddr_clk), .aresetn(ddr_rst_n),
        .s_axi_awid(4'd0), .s_axi_awaddr(ro_awaddr), .s_axi_awlen(ro_awlen), .s_axi_awsize(ro_awsize),
        .s_axi_awburst(ro_awburst), .s_axi_awvalid(ro_awvalid), .s_axi_awready(ro_awready),
        .s_axi_wdata(ro_wdata), .s_axi_wstrb(ro_wstrb), .s_axi_wlast(ro_wlast), .s_axi_wvalid(ro_wvalid), .s_axi_wready(ro_wready),
        .s_axi_bid(), .s_axi_bresp(ro_bresp), .s_axi_bvalid(ro_bvalid), .s_axi_bready(ro_bready),
        .s_axi_arid(4'd0), .s_axi_araddr(24'd0), .s_axi_arlen(8'd0), .s_axi_arsize(3'd0),
        .s_axi_arburst(2'd0), .s_axi_arvalid(1'b0), .s_axi_arready(),
        .s_axi_rid(), .s_axi_rdata(), .s_axi_rresp(), .s_axi_rlast(), .s_axi_rvalid(), .s_axi_rready(1'b1));

endmodule
