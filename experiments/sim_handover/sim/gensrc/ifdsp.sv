    interface ifdsp #( 
      `include "plps_para.vh" 
      ,`include "bram_para.vh" 
      ,`include "braminit_para.vh" 
      )(); 

      wire clk; 
      wire reset; 
      logic [ADC_AXIS_DATAWIDTH-1:0] adc[0:NADC-1]; 
      logic [DAC_AXIS_DATAWIDTH-1:0] dac[0:NDAC-1]; 
    
      logic [DACMON_W_DATAWIDTH-1:0] data_dacmon[0:NDACMON-1]; 
      reg [DACMON_W_ADDRWIDTH-1:0] addr_dacmon[0:NDACMON-1]; 
      reg we_dacmon[0:NDACMON-1]; 
     
      logic [ACQBUF_W_DATAWIDTH-1:0] data_acqbuf[0:NACQ-1]; 
      reg [ACQBUF_W_ADDRWIDTH-1:0] addr_acqbuf[0:NACQ-1]; 
      reg we_acqbuf[0:NACQ-1]; 
     
      logic [QUBIT_COMMAND_R_DATAWIDTH-1:0] data_qubit_command[0:8-1]; 
      reg [QUBIT_COMMAND_R_ADDRWIDTH-1:0] addr_qubit_command[0:8-1]; 
      reg we_qubit_command[0:8-1]; 

      logic [QUBIT_QDRV_ENV_R_DATAWIDTH-1:0] data_qubit_qdrv_env[0:8-1]; 
      reg [QUBIT_QDRV_ENV_R_ADDRWIDTH-1:0] addr_qubit_qdrv_env[0:8-1]; 
      reg we_qubit_qdrv_env[0:8-1]; 

      logic [QUBIT_QDRV_FREQ_R_DATAWIDTH-1:0] data_qubit_qdrv_freq[0:8-1]; 
      reg [QUBIT_QDRV_FREQ_R_ADDRWIDTH-1:0] addr_qubit_qdrv_freq[0:8-1]; 
      reg we_qubit_qdrv_freq[0:8-1]; 

      logic [QUBIT_RDRV_ENV_R_DATAWIDTH-1:0] data_qubit_rdrv_env[0:8-1]; 
      reg [QUBIT_RDRV_ENV_R_ADDRWIDTH-1:0] addr_qubit_rdrv_env[0:8-1]; 
      reg we_qubit_rdrv_env[0:8-1]; 

      logic [QUBIT_RDRV_FREQ_R_DATAWIDTH-1:0] data_qubit_rdrv_freq[0:8-1]; 
      reg [QUBIT_RDRV_FREQ_R_ADDRWIDTH-1:0] addr_qubit_rdrv_freq[0:8-1]; 
      reg we_qubit_rdrv_freq[0:8-1]; 

      logic [QUBIT_ACCBUF_W_DATAWIDTH-1:0] data_qubit_accbuf[0:8-1]; 
      reg [QUBIT_ACCBUF_W_ADDRWIDTH-1:0] addr_qubit_accbuf[0:8-1]; 
      reg we_qubit_accbuf[0:8-1]; 

      logic [QUBIT_RDLO_ENV_R_DATAWIDTH-1:0] data_qubit_rdlo_env[0:8-1]; 
      reg [QUBIT_RDLO_ENV_R_ADDRWIDTH-1:0] addr_qubit_rdlo_env[0:8-1]; 
      reg we_qubit_rdlo_env[0:8-1]; 

      logic [QUBIT_RDLO_FREQ_R_DATAWIDTH-1:0] data_qubit_rdlo_freq[0:8-1]; 
      reg [QUBIT_RDLO_FREQ_R_ADDRWIDTH-1:0] addr_qubit_rdlo_freq[0:8-1]; 
      reg we_qubit_rdlo_freq[0:8-1]; 

      logic stb_start; 
      logic start; 
      logic [31:0] nshot; 
      logic resetacc; 
      logic stb_reset_bram_read; 
      logic lastshotdone; 
      logic [31:0] shotcnt; 
      logic stopreq; 
      logic [31:0] actualshots; 
      logic stopped; 
      logic [10:0] addr_accbuf_mon0; 
      logic [10:0] addr_accbuf_mon1; 
      logic [10:0] addr_accbuf_mon2; 
      logic [10:0] addr_accbuf_mon3; 
      (* ram_style = "registers" *) 
      logic [31:0]coef  [0:NDAC-1][0:NDAC-1]; 
     
     
      logic acqbufreset; 
      logic dacmonreset; 
      logic [15:0] acqchansel[0:NACQ-1]; 
      logic [15:0] dacmonchansel[0:NACQ-1]; 
      logic [31:0] delayaftertrig; 
      logic [15:0] decimator; 
      logic [15:0] mixbb1sel; 
      logic [15:0] mixbb2sel; 
      logic [4:0] acc_shift; 
      logic [NPROC-1:0] procdone; 
     
     
      logic [23:0] test_freq; 
      logic [15:0] test_amp; 
      modport dsp(input clk,reset,acqbufreset,dacmonreset,acqchansel,dacmonchansel,delayaftertrig,decimator 
                  ,input data_qubit_command
                  ,input data_qubit_qdrv_env, data_qubit_qdrv_freq, data_qubit_rdrv_env, data_qubit_rdrv_freq, data_qubit_rdlo_env, data_qubit_rdlo_freq 
                  ,input adc 
                  ,input stb_start,start,nshot,resetacc,stb_reset_bram_read 
                  ,input stopreq 
                  ,input coef,mixbb1sel,mixbb2sel,acc_shift 
 
                  ,output lastshotdone,shotcnt,addr_accbuf_mon0,addr_accbuf_mon1,addr_accbuf_mon2,addr_accbuf_mon3,procdone 
                  ,output actualshots,stopped 
                  ,output dac 
                  ,output addr_qubit_command
                  ,output addr_qubit_qdrv_env, addr_qubit_qdrv_freq, addr_qubit_rdrv_env, addr_qubit_rdrv_freq, addr_qubit_rdlo_env, addr_qubit_rdlo_freq 
                  ,output addr_qubit_accbuf 
                  ,output data_qubit_accbuf 
                  ,output we_qubit_accbuf 
                  ,output addr_dacmon, data_acqbuf, addr_acqbuf, we_acqbuf, data_dacmon, we_dacmon 
                  ,input test_amp,test_freq 
      ); 
 
      modport cfg(output adc 
                  ,output clk,reset 
                  ,output data_qubit_command
                  ,output data_qubit_qdrv_env, data_qubit_qdrv_freq, data_qubit_rdrv_env, data_qubit_rdrv_freq, data_qubit_rdlo_env, data_qubit_rdlo_freq 
                  ,output stb_start,start,nshot,resetacc,stb_reset_bram_read,acqbufreset,dacmonreset,acqchansel,dacmonchansel,delayaftertrig,decimator 
                  ,output stopreq 
                  ,output coef,mixbb1sel,mixbb2sel,acc_shift 
                  ,input dac 
                  ,input addr_dacmon, data_acqbuf, addr_acqbuf, we_acqbuf, data_dacmon, we_dacmon 
                  ,input addr_qubit_command
                  ,input addr_qubit_qdrv_env, addr_qubit_qdrv_freq, addr_qubit_rdrv_env, addr_qubit_rdrv_freq, addr_qubit_rdlo_env, addr_qubit_rdlo_freq 
                  ,input addr_qubit_accbuf 
                  ,input data_qubit_accbuf 
                  ,input we_qubit_accbuf 
                  ,input lastshotdone,shotcnt,addr_accbuf_mon0,addr_accbuf_mon1,addr_accbuf_mon2,addr_accbuf_mon3,procdone 
                  ,input actualshots,stopped 
                  ,output test_amp,test_freq 
      ); 
    endinterface 
