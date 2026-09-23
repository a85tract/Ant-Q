`timescale 1 ns / 1 ps
module plsv #(`include "plps_para.vh"
,`include "bram_para.vh"
,`include "braminit_para.vh"
)(	`include "plps_port.vh"
,hwif hw
,input clkadc3_300
,input clkadc3_600
);

wire cfgreset;
wire dspreset;
wire psreset;
wire adc3reset;
wire psclk=pl_clk0;
wire adc3clk=clkadc3_600;

`include "reset_plsv.vh"

iflocalbus #(.DATA_WIDTH(LB1_DATAWIDTH),.ADDR_WIDTH(LB1_ADDRWIDTH))
lb1();
iflocalbus #(.DATA_WIDTH(LB2_DATAWIDTH),.ADDR_WIDTH(LB2_ADDRWIDTH))
lb2();
iflocalbus #(.DATA_WIDTH(LB3_DATAWIDTH),.ADDR_WIDTH(LB3_ADDRWIDTH))
lb3();
iflocalbus #(.DATA_WIDTH(LB4_DATAWIDTH),.ADDR_WIDTH(LB4_ADDRWIDTH))
lb4();

localbus_mappin #(.DATA_WIDTH(LB1_DATAWIDTH),.ADDR_WIDTH(LB1_ADDRWIDTH))
lb1map(.lb(lb1),.wren(lb1_wren),.rden(lb1_rden),.rdenlast(lb1_rdenlast),.waddr(lb1_waddr),.rvalid(lb1_rvalid),.rvalidlast(lb1_rvalidlast),.wdata(lb1_wdata),.raddr(lb1_raddr),.rdata(lb1_rdata),.clk(lb1_clk),.aresetn(lb1_aresetn));
localbus_mappin #(.DATA_WIDTH(LB2_DATAWIDTH),.ADDR_WIDTH(LB2_ADDRWIDTH))
lb2map(.lb(lb2),.wren(lb2_wren),.rden(lb2_rden),.rdenlast(lb2_rdenlast),.waddr(lb2_waddr),.rvalid(lb2_rvalid),.rvalidlast(lb2_rvalidlast),.wdata(lb2_wdata),.raddr(lb2_raddr),.rdata(lb2_rdata),.clk(lb2_clk),.aresetn(lb2_aresetn));
localbus_mappin #(.DATA_WIDTH(LB3_DATAWIDTH),.ADDR_WIDTH(LB3_ADDRWIDTH))
lb3map(.lb(lb3),.wren(lb3_wren),.rden(lb3_rden),.rdenlast(lb3_rdenlast),.waddr(lb3_waddr),.rvalid(lb3_rvalid),.rvalidlast(lb3_rvalidlast),.wdata(lb3_wdata),.raddr(lb3_raddr),.rdata(lb3_rdata),.clk(lb3_clk),.aresetn(lb3_aresetn));
localbus_mappin #(.DATA_WIDTH(LB4_DATAWIDTH),.ADDR_WIDTH(LB4_ADDRWIDTH))
lb4map(.lb(lb4),.wren(lb4_wren),.rden(lb4_rden),.rdenlast(lb4_rdenlast),.waddr(lb4_waddr),.rvalid(lb4_rvalid),.rvalidlast(lb4_rvalidlast),.wdata(lb4_wdata),.raddr(lb4_raddr),.rdata(lb4_rdata),.clk(lb4_clk),.aresetn(lb4_aresetn));

`include "bram_plsv.vh"

ifbramctrl#(.DATA_WIDTH(LB3_DATAWIDTH),.ADDR_WIDTH(LB3_ADDRWIDTH),.READDELAY(5)
,`include "bram_parainst.vh"
,`include "braminit_parainst.vh"
)
ifbramctrl(.lb(lb3)
,`include "bramif_lbportinst.vh"
);

ifcfgregs #(.DATA_WIDTH(LB1_DATAWIDTH),.ADDR_WIDTH(LB1_ADDRWIDTH))
cfgregs(.lb(lb1));

ifdspregs #(.DATA_WIDTH(LB2_DATAWIDTH),.ADDR_WIDTH(LB2_ADDRWIDTH))
dspregs(.lb(lb2));

`include "rfdc_plsv.vh"

ifdsp #(`include "plps_parainst.vh"
,`include "bram_parainst.vh"
,`include "braminit_parainst.vh"
)
dspif();

boardcfg #(`include "plps_parainst.vh"
,`include "bram_parainst.vh"
,`include "braminit_parainst.vh"
)
boardcfg(.hw(hw),.cfgregs(cfgregs.regs)
,.dspregs(dspregs.regs)
,`include "bramif_portinst.vh"
,`include "rfdcif_portinst.vh"
,.dspif(dspif.cfg)
,.pl_clk0(pl_clk0)
,.cfgclk(cfgclk)
,.dspclk(dspclk)
,.clk_dac0(clk_dac0)
,.clk_dac1(clk_dac1)
,.clk_dac2(clk_dac2)
,.clk_dac3(clk_dac3)
,.clk_adc0(clk_adc0)
,.clk_adc1(clk_adc1)
,.clk_adc2(clk_adc2)
,.clk_adc3(clk_adc3)
,.clkadc3_300(clkadc3_300)
,.clkadc3_600(clkadc3_600)
,.aresetn(aresetn)
,.cfgreset(cfgreset)
,.dspreset(dspreset)
,.psreset(psreset)
,.adc3reset(adc3reset)
);

dsp #(`include "plps_parainst.vh"
,`include "bram_parainst.vh"
,`include "braminit_parainst.vh"
)
dsp(.dspif(dspif)
);

endmodule
