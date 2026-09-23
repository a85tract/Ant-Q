//`timescale 1ns / 1ns

module freq_count3 #(parameter REFCNTWIDTH=26)
(
	input clk,  // clock of know frequency
	input fin,  // clock to be measured
	output [31:0] frequency
);

reg [31:0] frequency_r=0;
reg strobe_r=0;

reg [REFCNTWIDTH:0] refcnt=0;
wire refcarry=refcnt[REFCNTWIDTH];
always @(posedge clk) begin
	refcnt<=refcnt+1;
end

reg [31:0] fcnt=0;
(* ASYNC_REG = "TRUE" , KEEP="TRUE"*) reg [4:0] carryf=0;
wire cedge=carryf[4]^carryf[3];
reg [31:0] accum=0;
(* ASYNC_REG = "TRUE" , KEEP="TRUE"*) reg [31:0] diff=0;
always @(posedge fin) begin
	fcnt<=fcnt+1;
	carryf<={carryf[3:0],refcarry};
	if (cedge) begin
		accum<=fcnt;
		diff<=fcnt-accum;
	end
end
(* ASYNC_REG = "TRUE" , KEEP="TRUE"*) reg [4:0] cedgeinclk=0;
reg [31:0] diffclk=0;
wire outstrobe=cedgeinclk[4]^cedgeinclk[3];
always@(posedge clk) begin
	cedgeinclk<={cedgeinclk[3:0],carryf[4]};
	if (outstrobe)  begin
		diffclk<=diff;
	end
end
assign frequency=diffclk;
endmodule
