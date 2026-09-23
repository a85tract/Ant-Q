module sum #(parameter DWIDTH=16
,parameter NITEM=8
)(input clk
,input signed [DWIDTH-1:0] vin [0:NITEM-1]
,output signed [DWIDTH-1:0] vout
,input gin
,output gout
);

localparam NITEMLOG=$clog2(NITEM);
localparam NITEM2=2**(NITEMLOG);
wire signed [DWIDTH-1:0] vin_w [0:NITEM2-1];
reg [NITEMLOG-2:0] gsr=0;
reg gout_r=0;
always @(posedge clk) begin
	{gout_r,gsr}<={gsr,gin};
end
generate
for (genvar i=0;i<NITEM2;i=i+1) begin: init
	if (i<NITEM) begin
		assign vin_w[i]=vin[i];
	end
	else begin
		assign vin_w[i]=0;
	end
end
endgenerate

(* ram_style = "registers" *)
reg [DWIDTH-1:0] vtemp[0:NITEMLOG-1][0:2**(NITEMLOG-1)-1];
generate
for (genvar i=0;i<NITEMLOG;i=i+1) begin: l1
	wire [DWIDTH-1:0] vtemp_w[0:2**(NITEMLOG-1)-1];
	assign vtemp_w=vtemp[i];
	for (genvar j=0;j<2**(i);j=j+1) begin: l2
		always @(posedge clk) begin
		if (i==NITEMLOG-1)
			vtemp[i][j]<=vin[2*j]+vin[2*j+1];
		else
			vtemp[i][j]<=vtemp[i+1][2*j]+vtemp[i+1][2*j+1];
	end
	end
end
endgenerate
assign vout=vtemp[0][0];
assign gout=gout_r;
endmodule
