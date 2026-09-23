interface ifcfgregs #(parameter integer DATA_WIDTH = 32,parameter integer ADDR_WIDTH=24, parameter integer READDELAY=1)(    iflocalbus.lb lb
);
modport regs(input r0,stb_r0,r1,stb_r1,r3,stb_r3,test,stb_test,test1,stb_test1,r2,stb_r2
,output fclk100,fclk125,fusersi570c0,fusersi570c1,fclk104plsysref,fclk104plclk,fclk_dac0,fclk_dac1,fclk_dac2,fclk_dac3,fclk_adc0,fclk_adc1,fclk_adc2,fclk_adc3,fclkadc3_300,fclkadc3_600,fpl_clk0,gitrevision
);
logic [DATA_WIDTH-1:0] rdata;
logic [DATA_WIDTH-1:0] wdata;
logic [ADDR_WIDTH-1:0] waddr;
logic [1-1:0] wren;

wire [32-1:0] fclk100;
wire [32-1:0] fclk125;
wire [32-1:0] fusersi570c0;
wire [32-1:0] fusersi570c1;
wire [32-1:0] fclk104plsysref;
wire [32-1:0] fclk104plclk;
wire [32-1:0] fclk_dac0;
wire [32-1:0] fclk_dac1;
wire [32-1:0] fclk_dac2;
wire [32-1:0] fclk_dac3;
wire [32-1:0] fclk_adc0;
wire [32-1:0] fclk_adc1;
wire [32-1:0] fclk_adc2;
wire [32-1:0] fclk_adc3;
wire [32-1:0] fclkadc3_300;
wire [32-1:0] fclkadc3_600;
wire [32-1:0] r0;reg [32-1:0] reg_r0=0;reg stb_r0;assign r0=reg_r0;
wire [32-1:0] r1;reg [32-1:0] reg_r1=0;reg stb_r1;assign r1=reg_r1;
wire [32-1:0] fpl_clk0;
wire [32-1:0] r3;reg [32-1:0] reg_r3=0;reg stb_r3;assign r3=reg_r3;
wire signed [32-1:0] test;reg signed [32-1:0] reg_test=-123;reg stb_test;assign test=reg_test;
wire [32-1:0] test1;reg [32-1:0] reg_test1=0;reg stb_test1;assign test1=reg_test1;
wire [32-1:0] r2;reg [32-1:0] reg_r2=0;reg stb_r2;assign r2=reg_r2;
wire [32-1:0] gitrevision;
always @(posedge lb.clk) begin
wdata<=lb.wdata;
waddr<=lb.waddr;
wren<=lb.wren;
stb_r0<=(lb.waddr==17)&lb.wren;if (stb_r0) reg_r0<=wdata[32-1:0];
stb_r1<=(lb.waddr==18)&lb.wren;if (stb_r1) reg_r1<=wdata[32-1:0];
stb_r3<=(lb.waddr==20)&lb.wren;if (stb_r3) reg_r3<=wdata[32-1:0];
stb_test<=(lb.waddr==21)&lb.wren;if (stb_test) reg_test<=wdata[32-1:0];
stb_test1<=(lb.waddr==22)&lb.wren;if (stb_test1) reg_test1<=wdata[32-1:0];
stb_r2<=(lb.waddr==23)&lb.wren;if (stb_r2) reg_r2<=wdata[32-1:0];
end
always @(posedge lb.clk) begin
if (lb.rden16[READDELAY]) begin
case (lb.raddr16[(READDELAY+1)*ADDR_WIDTH-1:READDELAY*ADDR_WIDTH]) 

1: rdata <= fclk100;
2: rdata <= fclk125;
3: rdata <= fusersi570c0;
4: rdata <= fusersi570c1;
5: rdata <= fclk104plsysref;
6: rdata <= fclk104plclk;
7: rdata <= fclk_dac0;
8: rdata <= fclk_dac1;
9: rdata <= fclk_dac2;
10: rdata <= fclk_dac3;
11: rdata <= fclk_adc0;
12: rdata <= fclk_adc1;
13: rdata <= fclk_adc2;
14: rdata <= fclk_adc3;
15: rdata <= fclkadc3_300;
16: rdata <= fclkadc3_600;
17: rdata <= r0;
18: rdata <= r1;
19: rdata <= fpl_clk0;
20: rdata <= r3;
21: rdata <= test;
22: rdata <= test1;
23: rdata <= r2;
24: rdata <= gitrevision;
   default:rdata <= 32'hdeadbeef;
  endcase
 end
end
assign lb.rdata=rdata;
assign lb.rvalid=lb.rden16[READDELAY+1];
assign lb.rvalidlast=lb.rdenlast16[READDELAY+1];
endinterface