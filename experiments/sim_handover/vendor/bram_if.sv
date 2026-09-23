interface ifbram #(parameter ADDR_WIDTH=32,parameter DATA_WIDTH=128)(
);
wire clk;
wire [ADDR_WIDTH-1:0]addr;
wire [DATA_WIDTH-1:0] din;
wire [DATA_WIDTH-1:0] dout;
wire en;
wire rst;
//wire [DATA_WIDTH/8-1:0] we;
wire we;
wire rsta_busy;
wire rstb_busy;
modport write(
output addr,din,we
);
modport read(input dout
,output addr
);
modport map(input addr,din,en,we,clk,rst
,output dout
);
modport cfg(output clk,rst,en
);


endinterface


module bram_portb_read #(parameter ADDR_WIDTH=32,parameter DATA_WIDTH=128)
(ifbram.read bram
,input [ADDR_WIDTH-1:0] addr
,output [DATA_WIDTH-1:0] data
);

assign bram.addr=addr;
assign data=bram.dout;

endmodule

module bram_map#(parameter ADDR_WIDTH=32,parameter DATA_WIDTH=128)
(ifbram.map bram
,output clk
,output rst
,output [ADDR_WIDTH-1:0]addr
,output [DATA_WIDTH-1:0] din
,input [DATA_WIDTH-1:0] dout
,output en
,output we
);
assign clk=bram.clk;
assign en=bram.en;
assign rst=bram.rst;
assign we=bram.we;
assign din=bram.din;
assign addr=bram.addr;
assign bram.dout=dout;
endmodule


module bram_write #(parameter ADDR_WIDTH=32,parameter DATA_WIDTH=128)
(ifbram.write bram
,input [ADDR_WIDTH-1:0] addr
,input [DATA_WIDTH-1:0] data
,input we
);
assign bram.addr=addr;
assign bram.din=data;
assign bram.we=we;
endmodule

module bram_read #(parameter ADDR_WIDTH=32,parameter DATA_WIDTH=128)
(ifbram.read bram
,input [ADDR_WIDTH-1:0] addr
,output [DATA_WIDTH-1:0] data
);
assign bram.addr=addr;
assign data=bram.dout;
endmodule

module bram_cfg
(
input clk
,input rst
,input en
,ifbram.cfg bram
);
assign bram.clk=clk;
assign bram.rst=rst;
assign bram.en=en;
endmodule
