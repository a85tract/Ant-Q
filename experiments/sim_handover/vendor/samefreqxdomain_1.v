module samefreqxdomain(input clkw
,input clkr
,input [DW-1:0] dataw
,output [DW-1:0] datar
,input [0:0] reset
);
parameter DW=16;
(* ASYNC_REG = "TRUE" , KEEP="TRUE"*) reg [DW-1:0] buf0=0,buf1=0,buf2=0,buf3=0;
always @(posedge clkw) begin
	buf0 <= reset ? 0 : dataw;
end
always @(posedge clkr) begin
	buf1 <= reset ? 0 : buf0;
	buf2 <= reset ? 0 : buf1;
	buf3 <= reset ? 0 : buf2;
end
assign datar=buf3;
endmodule
