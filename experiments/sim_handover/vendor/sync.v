module sync #(parameter TXLEN=8
)(input clk
,output tx_data
,input tx_rst
,input rx_data
,input [63:0] clkcnt
,output [63:0] tx_clkcnt
,output [63:0] rx_clkcnt
);

reg tx_data_r=0;
reg tx_pulse=0;
reg tx_rst_d=0;
reg tx_rst_d2=0;
reg tx_rst_d3=0;
reg tx_rst_d4=0;
reg [63:0] tx_clkcnt_r=0;
//wire tx_rst_d_long;
//reg_delay1 #(.DW(1),.LEN(TXLEN)) reg_delay(.clk(clk),.gate(1'b1),.din(tx_rst),.dout(tx_rst_d_long),.reset(1'b0));
always @(posedge clk) begin
	tx_rst_d <= tx_rst;
	tx_pulse <= tx_rst & ~tx_rst_d;
	tx_rst_d2 <= tx_rst_d;
	tx_rst_d3 <= tx_rst_d2;
	tx_rst_d4 <= tx_rst_d3;
	//tx_data_r <= tx_pulse;
	//tx_data_r <= tx_rst & ~tx_rst_d_long;
	tx_data_r <= tx_rst & ~tx_rst_d4;
	if (tx_pulse) begin
		tx_clkcnt_r <= clkcnt;
	end
end
assign tx_data=tx_data_r;
assign tx_clkcnt=tx_clkcnt_r;

reg rx_data_d=0;
reg rx_pulse=0;
reg [63:0] rx_clkcnt_r=0;
always @(negedge clk) begin
	rx_data_d <= rx_data;
	rx_pulse <= rx_data & ~rx_data_d;
	if (rx_pulse) begin
		rx_clkcnt_r <= clkcnt;
	end
end
assign rx_clkcnt=rx_clkcnt_r;

endmodule
