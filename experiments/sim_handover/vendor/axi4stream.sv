interface axi4stream #(parameter integer DATA_WIDTH = 64)
();
wire clk;
wire resetn;
logic ready;
logic valid;
logic last;
logic [DATA_WIDTH/8-1:0] strb;
logic [DATA_WIDTH-1:0] data;
reg [31:0] cnt=0;
always @(posedge clk) begin
	cnt<=cnt+1;
end
modport clkrst(output clk,output resetn);
modport slave(input valid,data,last,strb
,output ready
,input clk,resetn,cnt
);
modport master(output valid,data,last,strb
,input ready,cnt
,input clk,resetn
);
endinterface


module axi4stream_clkrst(axi4stream.clkrst axi4
,input clk
,input resetn
);
assign axi4.clk=clk;
assign axi4.resetn=resetn;
endmodule
module axi4stream_master_map#(parameter integer DATA_WIDTH = 64)
(
	axi4stream.slave axis
	,input ready
	,output valid
	,output [DATA_WIDTH-1:0] data
	,output [DATA_WIDTH/8-1:0] strb
	,output last
);
assign valid=axis.valid;
assign data=axis.data;
assign last=axis.last;
assign strb=axis.strb;
assign axis.ready=ready;
endmodule

module axi4stream_slave_map#(parameter integer DATA_WIDTH = 64)
(
	axi4stream.master axis
	,output ready
	,input valid
	,input [DATA_WIDTH-1:0] data
	,input [DATA_WIDTH/8-1:0] strb
	,input last
);
assign axis.valid=valid;
assign axis.data=data;
assign axis.last=last;
assign axis.strb=strb;
assign ready=axis.ready;
endmodule


module axi4stream_master_handshake_data #(parameter integer DATA_WIDTH = 64)
(axi4stream.master axis
,input datavalid
,input [DATA_WIDTH-1:0] data
);

enum {IDLE		= 3'b000
,READY			= 3'b001
,VALID			= 3'b010
,READYANDVALID	= 3'b110
,SEND			= 3'b011
} state,nextstate;
//reg [$clog2(NSTATE):0] state=0;
reg r_valid=0;
reg r_txen=0;
always @(posedge axis.clk) begin
	if (~axis.resetn) begin
		state <= IDLE;
	end
	else begin
		state <= nextstate;
	end
end
always @(state) begin
		case (state)
			IDLE: begin
				nextstate= (axis.ready&&datavalid) ? READYANDVALID: (axis.ready? READY : ( datavalid ? VALID : IDLE));
			end
			READYANDVALID: begin
				nextstate=SEND;
			end
			READY: begin
				nextstate=(datavalid) ? SEND : READY;
			end
			VALID: begin
				nextstate=(axis.ready) ? SEND : VALID;
			end
			SEND: begin
				nextstate=SEND;
			end
            default: begin
                nextstate=IDLE;
            end
		endcase
end
always @(posedge axis.clk) begin
	if (~axis.resetn) begin
		r_valid<= 1'b0;
	end
	else begin
		case (nextstate)
			IDLE: begin
				r_valid<= 1'b0;
				r_txen<=1'b0;
			end
			READYANDVALID: begin
				r_valid<= 1'b1;
				r_txen<=1'b1;
			end
			READY: begin
				r_valid<= 1'b0;
				r_txen<=1'b0;
			end
			VALID: begin
				r_valid<= 1'b1;
				r_txen<=1'b0;
			end
			SEND: begin
				r_valid<= 1'b1;
				r_txen<=1'b1;
			end
		endcase
	end
end
assign axis.valid=r_valid;
assign axis.data=data ;
endmodule


module axi4stream_slave_handshake_data #(parameter integer DATA_WIDTH = 64)
(axi4stream.slave axis
,input ready
,output datavalid
,output [DATA_WIDTH-1:0] data
);

enum {IDLE    	=3'b000
,READY		  	=3'b001
,VALID			=3'b010
,READYANDVALID	=3'b110
,RECV			=3'b011
} state,nextstate;
//reg [$clog2(NSTATE):0] state=0;
reg r_valid=0;
reg r_rxen=0;
always @(posedge axis.clk) begin
	if (~axis.resetn) begin
		state <= IDLE;
	end
	else begin
		state <= nextstate;
	end
end
always @(*) begin
//	if (~axis.resetn) begin
//		nextstate = IDLE;
//	end
//	else begin
		case (state)
			IDLE: begin
				nextstate= (ready&&axis.valid) ? READYANDVALID : (ready? READY : ( axis.valid ? VALID : IDLE));
			end
			READY: begin
				if (axis.valid)
					nextstate=RECV;
				else
				    nextstate=READY;
			end
			VALID: begin
				if (ready)
					nextstate=RECV;
				else
				    nextstate=VALID;
			end
			READYANDVALID: begin
				nextstate=RECV;
			end
			RECV: begin
				nextstate=RECV;
			end
            default: begin
                nextstate=IDLE;
            end
		endcase
//	end
end
always @(posedge axis.clk) begin
	if (~axis.resetn) begin
		r_valid<= 1'b0;
	end
	else begin
		case (nextstate)
			IDLE: begin
				r_valid<= 1'b0;
				r_rxen<=1'b0;
			end
			READY: begin
				r_valid<= 1'b0;
				r_rxen<=1'b0;
			end
			VALID: begin
				r_valid<= 1'b0;
				r_rxen<=1'b0;
			end
			READYANDVALID: begin
				r_valid<= 1'b1;
				r_rxen<=1'b1;
			end
			RECV: begin
				r_valid<= 1'b1;
				r_rxen<=1'b1;
			end
		endcase
	end
end
assign datavalid=r_valid;
assign data=r_rxen ? axis.data : 0;
assign axis.ready=ready;
endmodule
