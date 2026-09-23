module areset #(parameter WIDTH=1,parameter SRWIDTH=4)
(input [WIDTH-1:0] areset
,input clk
,output [WIDTH-1:0] sreset_val
,output [WIDTH-1:0] sreset
);
genvar iw;
generate
	for (iw=0;iw<WIDTH;iw=iw+1) begin
		areset_1 #(.SRWIDTH(SRWIDTH)) areset_i(.clk(clk),.areset(areset[iw]),.sreset(sreset[iw]),.sreset_val(sreset_val[iw]));
	end
endgenerate
endmodule


`timescale 1ns/1ps
module areset_1 #(parameter SRWIDTH=4)
(input clk
,input areset
,output sreset
,output sreset_val
);
(* ASYNC_REG = "TRUE" , KEEP="TRUE"*) reg reset_p=0;
(* ASYNC_REG = "TRUE" , KEEP="TRUE"*) reg [SRWIDTH-1:0] reset_sr=0;
always @(posedge clk or posedge areset) begin
	if (areset)
		reset_p<=1'b1;
	else
		reset_p<=1'b0;
end
always @(posedge clk)
	reset_sr <= {reset_sr[SRWIDTH-2:0], reset_p};
assign sreset= (~reset_sr[SRWIDTH-1] & reset_sr[SRWIDTH-2]);
assign sreset_val = reset_sr[SRWIDTH-2];
endmodule
