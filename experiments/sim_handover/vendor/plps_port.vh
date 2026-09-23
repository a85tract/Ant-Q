input aresetn
,input pl_clk0
,`include "reset_port.vh"
,input [0:0] lb1_wren
,input lb1_rden
,input lb1_rdenlast
,input [LB1_ADDRWIDTH-1:0] lb1_waddr
,input [LB1_DATAWIDTH-1:0] lb1_wdata
,input [LB1_ADDRWIDTH-1:0] lb1_raddr
,output [LB1_DATAWIDTH-1:0] lb1_rdata
,output lb1_rvalid
,output lb1_rvalidlast
,input lb1_clk
,input  lb1_aresetn


,input [0:0] lb2_wren,input lb2_rden,input lb2_rdenlast,input [LB2_ADDRWIDTH-1:0] lb2_waddr,input [LB2_DATAWIDTH-1:0] lb2_wdata,input [LB2_ADDRWIDTH-1:0] lb2_raddr,output [LB2_DATAWIDTH-1:0] lb2_rdata,output lb2_rvalid,output lb2_rvalidlast,input lb2_clk,input  lb2_aresetn
,input [0:0] lb3_wren,input lb3_rden,input lb3_rdenlast,input [LB3_ADDRWIDTH-1:0] lb3_waddr,input [LB3_DATAWIDTH-1:0] lb3_wdata,input [LB3_ADDRWIDTH-1:0] lb3_raddr,output [LB3_DATAWIDTH-1:0] lb3_rdata,output lb3_rvalid,output lb3_rvalidlast,input lb3_clk,input  lb3_aresetn
,input [0:0] lb4_wren,input lb4_rden,input lb4_rdenlast,input [LB4_ADDRWIDTH-1:0] lb4_waddr,input [LB4_DATAWIDTH-1:0] lb4_wdata,input [LB4_ADDRWIDTH-1:0] lb4_raddr,output [LB4_DATAWIDTH-1:0] lb4_rdata,output lb4_rvalid,output lb4_rvalidlast,input lb4_clk,input  lb4_aresetn
//,include "bram_port.vh"

,`include "rfdc_port.vh"

,output cfgclk
,output dspclk
