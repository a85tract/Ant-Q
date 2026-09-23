interface iflocalbus# (parameter integer DATA_WIDTH = 32,
parameter integer ADDR_WIDTH = 10
,parameter integer WSTRB_WIDTH=1
,parameter integer CLK_FREQ_HZ=600000000
)();
logic [WSTRB_WIDTH-1:0] wren;
logic rden;
logic rdenlast;
logic [ADDR_WIDTH-1:0] waddr;
logic [DATA_WIDTH-1:0] wdata;
logic [ADDR_WIDTH-1:0] raddr;
logic [DATA_WIDTH-1:0] rdata;
logic rvalid;
logic rvalidlast;
wire clk;
wire aresetn;
reg [14:0] rden15=0;
reg [14:0] rdenlast15=0;
reg [15*ADDR_WIDTH-1:0] raddr15=0;
wire [15:0] rden16={rden15,rden};
wire [15:0] rdenlast16={rdenlast15,rdenlast};
wire [16*ADDR_WIDTH-1:0] raddr16={raddr15,raddr};
always @(posedge clk) begin
	rden15<=rden16[14:0];
	rdenlast15<=rdenlast16[14:0];
	raddr15<={raddr15[14*ADDR_WIDTH-1:0],raddr};
end
modport lb(input rden,wren,waddr,wdata,clk,aresetn,raddr,rdenlast,rden16,rdenlast16,raddr16
,output rdata,rvalid,rvalidlast
);
modport axi(output rden,wren,waddr,wdata,raddr,clk,aresetn,rdenlast,rden16,rdenlast16,raddr16
,input rdata,rvalid,rvalidlast
);
endinterface

module localbus_mappin#(parameter integer DATA_WIDTH=32
,parameter integer ADDR_WIDTH=10
,parameter integer WSTRB_WIDTH=1
)(iflocalbus.axi lb
,input rden
,input rdenlast
,input [WSTRB_WIDTH-1:0] wren
,input [ADDR_WIDTH-1:0] waddr
,input [DATA_WIDTH-1:0] wdata
,output rvalid
,output rvalidlast
,input [ADDR_WIDTH-1:0] raddr
,output [DATA_WIDTH-1:0] rdata
,input clk
,input aresetn
);
assign rvalid=lb.rvalid;
assign rvalidlast=lb.rvalidlast;
assign lb.rden=rden;
assign lb.rdenlast=rdenlast;
assign lb.wren=wren;
assign lb.waddr=waddr;
assign lb.wdata=wdata;
assign lb.raddr=raddr;
assign rdata=lb.rdata;
assign lb.clk=clk;
assign lb.aresetn=aresetn;
endmodule
