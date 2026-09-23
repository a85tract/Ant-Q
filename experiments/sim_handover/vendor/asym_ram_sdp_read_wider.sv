// Asymmetric port RAM
// Read Wider than Write. Read Statement in loop
//asym_ram_sdp_read_wider.v
// from UG901

module asym_ram_sdp_read_wider (clkA, clkB, weA, addrA, addrB, diA, doB);
parameter integer DATAWIDTHA = 32;
parameter integer SIZEA = 16384;
parameter integer ADDRWIDTHA = 14;
parameter integer DATAWIDTHB = 512;
parameter integer SIZEB = 1024;
parameter integer ADDRWIDTHB = 10;
parameter RAM_STYLE= "block";
parameter INIT_FILE="";
input clkA;
input clkB;
input weA;
input [ADDRWIDTHA-1:0] addrA;
input [ADDRWIDTHB-1:0] addrB;
input [DATAWIDTHA-1:0] diA;
output [DATAWIDTHB-1:0] doB;
`define max(a,b) ((a) > (b)) ? (a) : (b)
`define min(a,b) ((a) < (b)) ? (a) : (b)
/*function integer log2;
	input integer value;
	reg [31:0] shifted;
	integer res;
	begin
		if (value < 2)
			log2 = value;
		else
		begin
			shifted = value-1;
			for (res=0; shifted>0; res=res+1)
				shifted = shifted>>1;
			log2 = res;
		end
	end
endfunction
*/
localparam maxSIZE = `max(SIZEA, SIZEB);
localparam maxWIDTH = `max(DATAWIDTHA, DATAWIDTHB);
localparam minWIDTH = `min(DATAWIDTHA, DATAWIDTHB);
localparam RATIO = maxWIDTH / minWIDTH;
localparam log2RATIO = $clog2(RATIO);
(* ram_style= RAM_STYLE ,cascade_height=2 *)
reg [minWIDTH-1:0] RAM [0:maxSIZE-1];
reg [ADDRWIDTHB-1:0] addrB_d=0;
reg [DATAWIDTHB-1:0] readB=0;
reg [DATAWIDTHB-1:0] readB_d=0;
reg [DATAWIDTHB-1:0] readB_d2=0;
reg weA_d=0;
reg [ADDRWIDTHA-1:0] addrA_d=0;
reg [DATAWIDTHA-1:0] diA_d=0;
always @(posedge clkA) begin
	weA_d<=weA;
	addrA_d<=addrA;
	diA_d<=diA;
	if (weA_d)
		RAM[addrA_d] <= diA_d;
end
always @(posedge clkB) begin 
	addrB_d<=addrB;
end
always @(posedge clkB) begin : ramread
	integer i;
	reg [log2RATIO-1:0] lsbaddr;
	for (i = 0; i < RATIO; i = i+1) begin
		lsbaddr = i;
		//readB[(i+1)*minWIDTH-1 -: minWIDTH] <= RAM[{addrB_d, lsbaddr}];
		if (log2RATIO>0)
			readB[(i+1)*minWIDTH-1 -: minWIDTH] <= RAM[{addrB, lsbaddr}];
		else
			readB[(i+1)*minWIDTH-1 -: minWIDTH] <= RAM[{addrB}];
	end
end
always @(posedge clkB) begin 
	readB_d<=readB;
	readB_d2<=readB_d;
end
//assign doB = readB_d2;
//assign doB = readB;
assign doB = readB_d;

generate
	if (INIT_FILE!="") begin
		initial
			$readmemh(INIT_FILE,RAM);//,0,SIZEA-1);
	end
	else begin
		integer i;
		initial begin
			for (i=0;i<=SIZEA;i=i+1)
				RAM[i]=32'h0;

		end
	end
endgenerate

endmodule
