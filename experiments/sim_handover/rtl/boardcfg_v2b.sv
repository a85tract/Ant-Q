module boardcfg_v2b #(
`include "plps_para.vh"	
,`include "bram_para.vh"
,`include "braminit_para.vh"
)(hwif.cfg hw
,ifcfgregs.regs cfgregs
,ifdspregs.regs dspregs
,`include "bramif_port.vh"
,`include "rfdcif_port.vh"
,ifdsp.cfg dspif
,output cfgclk
,output dspclk
,input pl_clk0
,input clk_dac0
,input clk_dac1
,input clk_dac2
,input clk_dac3
,input clk_adc0
,input clk_adc1
,input clk_adc2
,input clk_adc3
,input clkadc3_300
,input clkadc3_600
,input aresetn
,output cfgreset
,output dspreset
,output psreset
,output adc3reset
);
wire reset=(~aresetn)|hw.gpio_sw_c;
areset #(.WIDTH(1),.SRWIDTH(4))
cfgareset(.clk(cfgclk),.areset(reset),.sreset(cfgreset),.sreset_val());
areset #(.WIDTH(1),.SRWIDTH(4))
dspareset(.clk(dspclk),.areset(reset),.sreset(dspreset),.sreset_val());
areset #(.WIDTH(1),.SRWIDTH(4))
psareset(.clk(pl_clk0),.areset(reset),.sreset(psreset),.sreset_val());
areset #(.WIDTH(1),.SRWIDTH(4))
adc3areset(.clk(clkadc3_600),.areset(reset),.sreset(adc3reset),.sreset_val());

gitrevision gitrevision(cfgregs.gitrevision);


reg [31:0] cnt100=0;
always @(posedge hw.clk100) begin
	cnt100<=cnt100+1;
end
reg [31:0] cnt125=0;
always @(posedge hw.clk125) begin
	cnt125<=cnt125+1;
end
assign cfgclk=hw.clk100;
assign dspclk=hw.clk104_pl_clk;// clk_dac2;
//assign dspclk=clk_dac2;
assign hw.ledrgb[0][1]=cnt100[27];
assign hw.ledrgb[1][1]=cnt100[26];
assign hw.ledrgb[2][1]=cnt100[25];
assign hw.ledrgb[3][1]=cnt100[24];

assign hw.ledrgb[4][1]=cnt125[27];
assign hw.ledrgb[5][1]=cnt125[26];
assign hw.ledrgb[6][1]=cnt125[25];
assign hw.ledrgb[7][1]=cnt125[24];

//assign regs.test1=regs.r0+regs.r1+regs.r2+regs.r3;
assign hw.ledrgb[0][0]=cfgregs.test1[0];
assign hw.ledrgb[1][0]=cfgregs.test1[1];
assign hw.ledrgb[2][0]=cfgregs.test1[2];
assign hw.ledrgb[3][0]=cfgregs.test1[3];
assign hw.ledrgb[4][0]=cfgregs.test1[4];
assign hw.ledrgb[5][0]=cfgregs.test1[5];
assign hw.ledrgb[6][0]=cfgregs.test1[6];
assign hw.ledrgb[7][0]=cfgregs.test1[7];
/*assign hw.pmod0[6]=cnt100[1];
assign hw.pmod0[5]=cnt125[1];
assign hw.pmod0[4]=hw.usersi570c0;
assign hw.pmod0[3]=hw.usersi570c1;
assign hw.pmod0[2]=hw.clk104_pl_sysref;
assign hw.pmod0[1]=hw.clk104_pl_clk;
*/
assign hw.ledrgb[0][2]=cfgregs.test[0];
assign hw.ledrgb[1][2]=cfgregs.test[1];
assign hw.ledrgb[2][2]=cfgregs.test[2];
assign hw.ledrgb[3][2]=cfgregs.test[3];
assign hw.ledrgb[4][2]=cfgregs.test[4];
assign hw.ledrgb[5][2]=cfgregs.test[5];
assign hw.ledrgb[6][2]=cfgregs.test[6];
assign hw.ledrgb[7][2]=cfgregs.test[7];

//enum {CLK100
//,CLK125
//,USERSI570C0
//,USERSI570C1
//,CLK104PLSYSREF
//,CLK104PLCLK
//,CLKDAC0
//,CLKDAC1
//,CLKDAC2
//,CLKDAC3
//,CLKADC0
//,CLKADC1
//,CLKADC2
//,CLKADC3
//,CLKADC3_300
//,CLKADC3_600
//,NFCNT
//} fcnt;

// Frequency counter - commented out (not used)
//wire [32*NFCNT-1:0] freq_cnt;
//assign freq_cnt={cfgregs.fclk100
//,cfgregs.fclk125
//,cfgregs.fusersi570c0
//,cfgregs.fusersi570c1
//,cfgregs.fclk104plsysref
//,cfgregs.fclk104plclk
//,cfgregs.fclk_dac0
//,cfgregs.fclk_dac1
//,cfgregs.fclk_dac2
//,cfgregs.fclk_dac3
//,cfgregs.fclk_adc0
//,cfgregs.fclk_adc1
//,cfgregs.fclk_adc2
//,cfgregs.fclk_adc3
//,cfgregs.fclkadc3_300
//,cfgregs.fclkadc3_600
//};
//
//wire [NFCNT-1:0] freqcnt_clks= {
//	hw.clk100
//	,hw.clk125
//	,hw.usersi570c0
//	,hw.usersi570c1
//	,hw.clk104_pl_sysref
//	,hw.clk104_pl_clk
//	,clk_dac0
//	,clk_dac1
//	,clk_dac2
//	,clk_dac3
//	,clk_adc0
//	,clk_adc1
//	,clk_adc2
//	,clk_adc3
//	,clkadc3_300
//	,clkadc3_600
//};
//
//genvar jx;
//generate for (jx=0; jx<NFCNT; jx=jx+1)	begin: gen_fcnt
//	freq_count3 #(.REFCNTWIDTH(24))
//	freq_count3(.clk(hw.clk100),.fin(freqcnt_clks[jx]),.frequency(freq_cnt[jx*32+31:jx*32]));
////		{regs.fclk100,regs.fclk125,regs.fusersi570c0,regs.fusersi570c1,regs.fclk104plsysref,regs.fclk104plclk,regs.fclk_dac2,regs.fclk_dac3,regs.fclk_adc2,regs.fclkadc2_300,regs.fclkadc2_600}
//end
//endgenerate


`include "bram_read_v2b.vh"
`include "bram_write.vh"

//wire adc00datavalid;
//axi4stream_slave_handshake_data #(.DATA_WIDTH (ADC_AXIS_DATAWIDTH))adc00hsda(.axis(adc00axis),.ready(1'b1),.datavalid(adc00datavalid),.data(dspif.adc[0]));
//wire adc20datavalid;
//axi4stream_slave_handshake_data #(.DATA_WIDTH (ADC_AXIS_DATAWIDTH))adc20hsda(.axis(adc20axis),.ready(1'b1),.datavalid(adc20datavalid),.data(dspif.adc[1]));
wire adc30datavalid;
axi4stream_slave_handshake_data #(.DATA_WIDTH (ADC_AXIS_DATAWIDTH))adc30hsda(.axis(adc30axis),.ready(1'b1),.datavalid(adc30datavalid),.data(dspif.adc[0]));
wire adc31datavalid;
axi4stream_slave_handshake_data #(.DATA_WIDTH (ADC_AXIS_DATAWIDTH))adc31hsda(.axis(adc31axis),.ready(1'b1),.datavalid(adc31datavalid),.data(dspif.adc[1]));
wire adc32datavalid;
axi4stream_slave_handshake_data #(.DATA_WIDTH (ADC_AXIS_DATAWIDTH))adc32hsda(.axis(adc32axis),.ready(1'b1),.datavalid(adc32datavalid),.data(dspif.adc[2]));
wire adc33datavalid;
axi4stream_slave_handshake_data #(.DATA_WIDTH (ADC_AXIS_DATAWIDTH))adc33hsda(.axis(adc33axis),.ready(1'b1),.datavalid(adc33datavalid),.data(dspif.adc[3]));

axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac00hsda(.axis(dac00axis),.datavalid(1'b1),.data(dspif.dac[0])); // 228 0
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac01hsda(.axis(dac01axis),.datavalid(1'b1),.data(dspif.dac[1])); // 228 1
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac02hsda(.axis(dac02axis),.datavalid(1'b1),.data(dspif.dac[2])); // 228 2
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac03hsda(.axis(dac03axis),.datavalid(1'b1),.data(dspif.dac[3])); // 228 3
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac10hsda(.axis(dac10axis),.datavalid(1'b1),.data(dspif.dac[4])); // 229 0
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac11hsda(.axis(dac11axis),.datavalid(1'b1),.data(dspif.dac[5])); // 229 1
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac12hsda(.axis(dac12axis),.datavalid(1'b1),.data(dspif.dac[6])); // 229 2
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac13hsda(.axis(dac13axis),.datavalid(1'b1),.data(dspif.dac[7])); // 229 3
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac20hsda(.axis(dac20axis),.datavalid(1'b1),.data(dspif.dac[8])); // 230 0
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac21hsda(.axis(dac21axis),.datavalid(1'b1),.data(dspif.dac[9])); // 230 1
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac22hsda(.axis(dac22axis),.datavalid(1'b1),.data(dspif.dac[10])); // 230 2
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac23hsda(.axis(dac23axis),.datavalid(1'b1),.data(dspif.dac[11])); // 230 3
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac30hsda(.axis(dac30axis),.datavalid(1'b1),.data(dspif.dac[12])); // 231 0
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac31hsda(.axis(dac31axis),.datavalid(1'b1),.data(dspif.dac[13])); // 231 1
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac32hsda(.axis(dac32axis),.datavalid(1'b1),.data(dspif.dac[14])); // 231 2
axi4stream_master_handshake_data #(.DATA_WIDTH (DAC_AXIS_DATAWIDTH))dac33hsda(.axis(dac33axis),.datavalid(1'b1),.data(dspif.dac[15])); // 231 3
assign dspif.clk=dspclk;
reg dspreset_r=0;
always @(posedge dspclk) begin
	dspreset_r<=dspreset|dspregs.stb_dspreset;
end
assign dspif.reset=dspreset_r;

//assign dspif.stb_start=dspregs.stb_start;
reg stb_ready_dspclk=1'b0;
reg stb_ready_dspclk_d=1'b0;
reg stb_start_d0=1'b0;
reg stb_start_d1=1'b0;
reg use_sync_d0=1'b0;
reg use_sync_d1=1'b0;
reg dsp_stb_start_d0;
reg dsp_stb_start_d1;

always @(posedge dspclk) begin
    stb_start_d0 <= dspregs.stb_start;
    stb_start_d1 <= stb_start_d0;
    use_sync_d0 <= dspregs.use_sync;
    use_sync_d1 <= use_sync_d0;
    stb_ready_dspclk_d <= stb_ready_dspclk;
    dsp_stb_start_d0 <= use_sync_d1 ? stb_ready_dspclk_d : stb_start_d1; 
    dsp_stb_start_d1 <= dsp_stb_start_d0;
end
// [v2b] removed: assign dspif.stb_start = dsp_stb_start_d1;
// [v2b] removed: assign dspif.nshot=dspregs.nshot;
assign dspif.resetacc=dspregs.resetacc;
assign dspif.stb_reset_bram_read=dspregs.stb_reset_bram_read;
assign dspregs.lastshotdone=dspif.lastshotdone;
assign dspregs.shotcnt=dspif.shotcnt;
assign dspregs.addr_accbuf_mon0=dspif.addr_accbuf_mon0;
assign dspregs.addr_accbuf_mon1=dspif.addr_accbuf_mon1;
assign dspregs.addr_accbuf_mon2=dspif.addr_accbuf_mon2;
assign dspregs.addr_accbuf_mon3=dspif.addr_accbuf_mon3;

assign dspif.acqbufreset=dspregs.acqbufreset;
assign dspif.dacmonreset=dspregs.dacmonreset;
assign dspif.delayaftertrig=dspregs.delayaftertrig;
assign dspif.decimator=dspregs.decimator;
assign dspif.acqchansel[0]=dspregs.acqchansel0;
assign dspif.acqchansel[1]=dspregs.acqchansel1;
assign dspif.dacmonchansel[0]=dspregs.dacmonchansel0;
assign dspif.dacmonchansel[1]=dspregs.dacmonchansel1;
assign dspif.dacmonchansel[2]=dspregs.dacmonchansel2;
assign dspif.dacmonchansel[3]=dspregs.dacmonchansel3;

assign dspif.mixbb1sel=dspregs.mixbb1sel;
assign dspif.mixbb2sel=dspregs.mixbb2sel;
assign dspif.acc_shift=dspregs.shift;


reg current_sample=1'b0;
reg last_sample=1'b0;
reg [2:0] sysref_cnt=0;
reg ready_sysref=1'b0;
always @(posedge dspclk) begin
    current_sample <= hw.clk104_pl_sysref;
    last_sample <= current_sample;
    if (dspregs.start) begin
        sysref_cnt <= sysref_cnt + (~last_sample & current_sample);
    end
    if (sysref_cnt[2]) ready_sysref<=1'b1;
end

reg [63:0] dspclkcnt_orig=0;
wire [63:0] corr64={dspregs.copper_corr64_h,dspregs.copper_corr64_l};
reg [63:0] dspclkcnt_corr=0;
always @(posedge dspclk) begin
    if (ready_sysref) dspclkcnt_orig <= dspclkcnt_orig + 1;
    dspclkcnt_corr <= dspclkcnt_orig + corr64;
end

wire dspclkcnt_sw=dspregs.copper_clkcnt_sw;
wire [63:0] dspclkcnt;
assign dspclkcnt = dspclkcnt_sw ? dspclkcnt_corr : dspclkcnt_orig;

wire [63:0] dspclkcnt_trig={dspregs.copper_clkcnt_trig_h,dspregs.copper_clkcnt_trig_l};
reg ready_dspclk=1'b0;
reg ready_dspclk_d=1'b0;
always @(posedge dspclk) begin
    ready_dspclk <= dspclkcnt>=dspclkcnt_trig;
    ready_dspclk_d <= ready_dspclk;
    stb_ready_dspclk <= ready_dspclk & ~ready_dspclk_d;
end


wire [63:0] copper_tx_clkcnt_mst;
wire [63:0] copper_rx_clkcnt_mst;
reg [63:0] copper_tx_clkcnt_mst_r=0;
reg [63:0] copper_rx_clkcnt_mst_r=0;
reg [63:0] copper_dspclkcnt_r=0;
wire copper_tx_data_mst;
wire copper_rx_data_mst;
wire copper_tx_en_mst=dspregs.copper_tx_en_mst;
wire copper_tx_rst_mst=dspregs.copper_tx_rst_mst;

IOBUF synciobuf_mst (.IO(hw.dacio[0]),.I(copper_tx_data_mst),.O(copper_rx_data_mst),.T(~copper_tx_en_mst));
sync sync_copper_mst(.clk(dspclk)
,.tx_data(copper_tx_data_mst)
,.tx_rst(copper_tx_rst_mst)
,.rx_data(copper_rx_data_mst)
,.clkcnt(dspclkcnt)
,.tx_clkcnt(copper_tx_clkcnt_mst)
,.rx_clkcnt(copper_rx_clkcnt_mst)
);
always @(posedge dspclk) begin
    copper_tx_clkcnt_mst_r<=copper_tx_clkcnt_mst;
    copper_rx_clkcnt_mst_r<=copper_rx_clkcnt_mst;
    copper_dspclkcnt_r<=dspclkcnt;
end
assign {dspregs.copper_tx_clkcnt_mst_h,dspregs.copper_tx_clkcnt_mst_l}=copper_tx_clkcnt_mst_r;
assign {dspregs.copper_rx_clkcnt_mst_h,dspregs.copper_rx_clkcnt_mst_l}=copper_rx_clkcnt_mst_r;
assign {dspregs.copper_dspclkcnt_h,dspregs.copper_dspclkcnt_l}=copper_dspclkcnt_r;


wire [63:0] copper_tx_clkcnt_slv;
wire [63:0] copper_rx_clkcnt_slv;
reg [63:0] copper_tx_clkcnt_slv_r=0;
reg [63:0] copper_rx_clkcnt_slv_r=0;
wire copper_tx_data_slv;
wire copper_rx_data_slv;
wire copper_tx_en_slv=dspregs.copper_tx_en_slv;
wire copper_tx_rst_slv=dspregs.copper_tx_rst_slv;

IOBUF synciobuf_slv (.IO(hw.dacio[1]),.I(copper_tx_data_slv),.O(copper_rx_data_slv),.T(~copper_tx_en_slv));
sync sync_copper_slv(.clk(dspclk)
,.tx_data(copper_tx_data_slv)
,.tx_rst(copper_tx_rst_slv)
,.rx_data(copper_rx_data_slv)
,.clkcnt(dspclkcnt)
,.tx_clkcnt(copper_tx_clkcnt_slv)
,.rx_clkcnt(copper_rx_clkcnt_slv)
);
always @(posedge dspclk) begin
    copper_tx_clkcnt_slv_r<=copper_tx_clkcnt_slv;
    copper_rx_clkcnt_slv_r<=copper_rx_clkcnt_slv;
end
assign {dspregs.copper_tx_clkcnt_slv_h,dspregs.copper_tx_clkcnt_slv_l}=copper_tx_clkcnt_slv_r;
assign {dspregs.copper_rx_clkcnt_slv_h,dspregs.copper_rx_clkcnt_slv_l}=copper_rx_clkcnt_slv_r;


assign hw.dacio[15:2]=14'b0;


assign dspif.coef[0][0]=dspregs.coef00;
assign dspif.coef[0][1]=dspregs.coef01;
assign dspif.coef[0][2]=dspregs.coef02;
assign dspif.coef[0][3]=dspregs.coef03;
assign dspif.coef[1][0]=dspregs.coef10;
assign dspif.coef[1][1]=dspregs.coef11;
assign dspif.coef[1][2]=dspregs.coef12;
assign dspif.coef[1][3]=dspregs.coef13;
assign dspif.coef[2][0]=dspregs.coef20;
assign dspif.coef[2][1]=dspregs.coef21;
assign dspif.coef[2][2]=dspregs.coef22;
assign dspif.coef[2][3]=dspregs.coef23;
assign dspif.coef[3][0]=dspregs.coef30;
assign dspif.coef[3][1]=dspregs.coef31;
assign dspif.coef[3][2]=dspregs.coef32;
assign dspif.coef[3][3]=dspregs.coef33;
assign dspregs.procdone=dspif.procdone;
assign dspregs.cnt00=dac00axis.cnt;
assign dspregs.cnt01=dac01axis.cnt;
assign dspregs.cnt02=dac02axis.cnt;
assign dspregs.cnt03=dac03axis.cnt;
assign dspregs.cnt10=dac10axis.cnt;
assign dspregs.cnt11=dac11axis.cnt;
assign dspregs.cnt12=dac12axis.cnt;
assign dspregs.cnt13=dac13axis.cnt;
assign dspregs.cnt20=dac20axis.cnt;
assign dspregs.cnt21=dac21axis.cnt;
assign dspregs.cnt22=dac22axis.cnt;
assign dspregs.cnt23=dac23axis.cnt;
assign dspregs.cnt30=dac30axis.cnt;
assign dspregs.cnt31=dac31axis.cnt;
assign dspregs.cnt32=dac32axis.cnt;
assign dspregs.cnt33=dac33axis.cnt;
//`include "ilaauto.vh"

endmodule
