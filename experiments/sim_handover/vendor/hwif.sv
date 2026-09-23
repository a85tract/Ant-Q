interface hwif(
);
wire [2:0] ledrgb [7:0];
//	wire [4:0] buttons;
wire clk100;
wire clk125;
wire usersi570c0;
wire usersi570c1;
wire clk104_pl_sysref;
wire clk104_pl_clk;
wire clk104_sync_in;
wire cpu_reset;
wire [7:0] pmod0;
wire [7:0] pmod1;
wire [15:0] dacio;
wire [15:0] adcio;
wire gpio_sw_s;
wire gpio_sw_n;
wire gpio_sw_e;
wire gpio_sw_c;
wire gpio_sw_w;
wire gpio_dip_sw0;
wire gpio_dip_sw1;
wire gpio_dip_sw2;
wire gpio_dip_sw3;
wire gpio_dip_sw4;
wire gpio_dip_sw5;
wire gpio_dip_sw6;
wire gpio_dip_sw7;
wire sfp0_tx_p;
wire sfp0_tx_n;
wire sfp0_rx_p;
wire sfp0_rx_n;
wire sfp1_tx_p;
wire sfp1_tx_n;
wire sfp1_rx_p;
wire sfp1_rx_n;
wire sfp2_tx_p;
wire sfp2_tx_n;
wire sfp2_rx_p;
wire sfp2_rx_n;
wire sfp3_tx_p;
wire sfp3_tx_n;
wire sfp3_rx_p;
wire sfp3_rx_n;

wire mgtrefclk1_128;
wire mgtrefclk0_128;
wire mgtrefclk1_129;
wire mgtrefclk0_129;
wire vin00_n,vin00_p,vin01_n,vin01_p,vin02_n,vin02_p,vin03_n,vin03_p,vin10_n,vin10_p,vin11_n,vin11_p,vin12_n,vin12_p,vin13_n,vin13_p,vin20_n,vin20_p,vin21_n,vin21_p,vin22_n,vin22_p,vin23_n,vin23_p,vin30_n,vin30_p,vin31_n,vin31_p,vin32_n,vin32_p,vin33_n,vin33_p,adc0_clk_n,adc0_clk_p,adc1_clk_n,adc1_clk_p,adc2_clk_n,adc2_clk_p,adc3_clk_n,adc3_clk_p,dac0_clk_n,dac0_clk_p,dac1_clk_n,dac1_clk_p,dac2_clk_n,dac2_clk_p,dac3_clk_n,dac3_clk_p,sysref_in_n,sysref_in_p;
wire vout00_n,vout00_p,vout01_n,vout01_p,vout02_n,vout02_p,vout03_n,vout03_p,vout10_n,vout10_p,vout11_n,vout11_p,vout12_n,vout12_p,vout13_n,vout13_p,vout20_n,vout20_p,vout21_n,vout21_p,vout22_n,vout22_p,vout23_n,vout23_p,vout30_n,vout30_p,vout31_n,vout31_p,vout32_n,vout32_p,vout33_n,vout33_p;

modport addapin(output vin00_n,vin00_p,vin01_n,vin01_p,vin02_n,vin02_p,vin03_n,vin03_p,vin10_n,vin10_p,vin11_n,vin11_p,vin12_n,vin12_p,vin13_n,vin13_p,vin20_n,vin20_p,vin21_n,vin21_p,vin22_n,vin22_p,vin23_n,vin23_p,vin30_n,vin30_p,vin31_n,vin31_p,vin32_n,vin32_p,vin33_n,vin33_p,adc0_clk_n,adc0_clk_p,adc1_clk_n,adc1_clk_p,adc2_clk_n,adc2_clk_p,adc3_clk_n,adc3_clk_p,dac0_clk_n,dac0_clk_p,dac1_clk_n,dac1_clk_p,dac2_clk_n,dac2_clk_p,dac3_clk_n,dac3_clk_p,sysref_in_n,sysref_in_p
,input vout00_n,vout00_p,vout01_n,vout01_p,vout02_n,vout02_p,vout03_n,vout03_p,vout10_n,vout10_p,vout11_n,vout11_p,vout12_n,vout12_p,vout13_n,vout13_p,vout20_n,vout20_p,vout21_n,vout21_p,vout22_n,vout22_p,vout23_n,vout23_p,vout30_n,vout30_p,vout31_n,vout31_p,vout32_n,vout32_p,vout33_n,vout33_p
);

modport hw(input ledrgb,sfp0_tx_p,sfp0_tx_n,sfp1_tx_p,sfp1_tx_n,sfp2_tx_p,sfp2_tx_n,sfp3_tx_p,sfp3_tx_n,mgtrefclk0_128,mgtrefclk0_129
,output clk100,clk125,usersi570c0,usersi570c1,clk104_pl_sysref,clk104_pl_clk,gpio_sw_s,gpio_sw_n,gpio_sw_e,gpio_sw_c,gpio_sw_w,gpio_dip_sw0,gpio_dip_sw1,gpio_dip_sw2,gpio_dip_sw3,gpio_dip_sw4,gpio_dip_sw5,gpio_dip_sw6,gpio_dip_sw7,clk104_sync_in,cpu_reset,sfp0_rx_p,sfp0_rx_n,sfp1_rx_p,sfp1_rx_n,sfp2_rx_p,sfp2_rx_n,sfp3_rx_p,sfp3_rx_n,mgtrefclk1_128,mgtrefclk1_129
,inout pmod0,pmod1,dacio,adcio
,input vin00_n,vin00_p,vin01_n,vin01_p,vin02_n,vin02_p,vin03_n,vin03_p,vin10_n,vin10_p,vin11_n,vin11_p,vin12_n,vin12_p,vin13_n,vin13_p,vin20_n,vin20_p,vin21_n,vin21_p,vin22_n,vin22_p,vin23_n,vin23_p,vin30_n,vin30_p,vin31_n,vin31_p,vin32_n,vin32_p,vin33_n,vin33_p,adc0_clk_n,adc0_clk_p,adc1_clk_n,adc1_clk_p,adc2_clk_n,adc2_clk_p,adc3_clk_n,adc3_clk_p,dac0_clk_n,dac0_clk_p,dac1_clk_n,dac1_clk_p,dac2_clk_n,dac2_clk_p,dac3_clk_n,dac3_clk_p,sysref_in_n,sysref_in_p
,output vout00_n,vout00_p,vout01_n,vout01_p,vout02_n,vout02_p,vout03_n,vout03_p,vout10_n,vout10_p,vout11_n,vout11_p,vout12_n,vout12_p,vout13_n,vout13_p,vout20_n,vout20_p,vout21_n,vout21_p,vout22_n,vout22_p,vout23_n,vout23_p,vout30_n,vout30_p,vout31_n,vout31_p,vout32_n,vout32_p,vout33_n,vout33_p
);
modport cfg(output ledrgb,sfp0_tx_p,sfp0_tx_n,sfp1_tx_p,sfp1_tx_n,sfp2_tx_p,sfp2_tx_n,sfp3_tx_p,sfp3_tx_n,mgtrefclk0_128,mgtrefclk0_129
,input clk100,clk125,usersi570c0,usersi570c1,clk104_pl_sysref,clk104_pl_clk,gpio_sw_s,gpio_sw_n,gpio_sw_e,gpio_sw_c,gpio_sw_w,gpio_dip_sw0,gpio_dip_sw1,gpio_dip_sw2,gpio_dip_sw3,gpio_dip_sw4,gpio_dip_sw5,gpio_dip_sw6,gpio_dip_sw7,clk104_sync_in,cpu_reset,sfp0_rx_p,sfp0_rx_n,sfp1_rx_p,sfp1_rx_n,sfp2_rx_p,sfp2_rx_n,sfp3_rx_p,sfp3_rx_n,mgtrefclk1_128,mgtrefclk1_129
,inout pmod0,pmod1,dacio,adcio
);
modport sim(output ledrgb
,output clk100,clk125,usersi570c0,usersi570c1,clk104_pl_sysref,clk104_pl_clk,gpio_sw_s,gpio_sw_n,gpio_sw_e,gpio_sw_c,gpio_sw_w,gpio_dip_sw0,gpio_dip_sw1,gpio_dip_sw2,gpio_dip_sw3,gpio_dip_sw4,gpio_dip_sw5,gpio_dip_sw6,gpio_dip_sw7,clk104_sync_in,cpu_reset
,inout pmod0,pmod1,dacio,adcio
);
endinterface

module hwifsim(hwif.sim hw
,input clk100
,input clk125
,input usersi570c0
,input usersi570c1
,input clk104_pl_sysref
,input clk104_pl_clk
);
assign hw.clk100=clk100;
assign hw.clk125=clk125;
assign hw.usersi570c0=usersi570c0;
assign hw.usersi570c1=usersi570c1;
assign hw.clk104_pl_sysref=clk104_pl_sysref;
assign hw.clk104_pl_clk=clk104_pl_clk;

endmodule
