`timescale 1 ns / 1 ps
module axi4_lb#(parameter integer ID_WIDTH	 = 1
,parameter integer DATA_WIDTH	 = 32
,parameter integer ADDR_WIDTH	 = 10
,parameter integer AWUSER_WIDTH	 = 0
,parameter integer ARUSER_WIDTH	 = 0
,parameter integer WUSER_WIDTH	 = 0
,parameter integer RUSER_WIDTH	 = 0
,parameter integer BUSER_WIDTH	 = 0
,parameter integer CLK_FREQ_HZ = 600000000
)(input wire axi_aclk
,input wire axi_aresetn
,input wire [ID_WIDTH-1 : 0] axi_awid
,input wire [ADDR_WIDTH-1 : 0] axi_awaddr
,input wire [7 : 0] axi_awlen
,input wire [2 : 0] axi_awsize
,input wire [1 : 0] axi_awburst
,input wire axi_awlock
,input wire [3 : 0] axi_awcache
,input wire [2 : 0] axi_awprot
,input wire [3 : 0] axi_awqos
,input wire [3 : 0] axi_awregion
,input wire [AWUSER_WIDTH-1 : 0] axi_awuser
,input wire axi_awvalid
,output wire axi_awready
,input wire [DATA_WIDTH-1 : 0] axi_wdata
,input wire [(DATA_WIDTH/8)-1 : 0] axi_wstrb
,input wire axi_wlast
,input wire [WUSER_WIDTH-1 : 0] axi_wuser
,input wire axi_wvalid
,output wire axi_wready
,output wire [ID_WIDTH-1 : 0] axi_bid
,output wire [1 : 0] axi_bresp
,output wire [BUSER_WIDTH-1 : 0] axi_buser
,output wire axi_bvalid
,input wire axi_bready
,input wire [ID_WIDTH-1 : 0] axi_arid
,input wire [ADDR_WIDTH-1 : 0] axi_araddr
,input wire [7 : 0] axi_arlen
,input wire [2 : 0] axi_arsize
,input wire [1 : 0] axi_arburst
,input wire axi_arlock
,input wire [3 : 0] axi_arcache
,input wire [2 : 0] axi_arprot
,input wire [3 : 0] axi_arqos
,input wire [3 : 0] axi_arregion
,input wire [ARUSER_WIDTH-1 : 0] axi_aruser
,input wire axi_arvalid
,output wire axi_arready
,output wire [ID_WIDTH-1 : 0] axi_rid
,output wire [DATA_WIDTH-1 : 0] axi_rdata
,output wire [1 : 0] axi_rresp
,output wire axi_rlast
,output wire [RUSER_WIDTH-1 : 0] axi_ruser
,output wire axi_rvalid
,input wire axi_rready

,output [ADDR_WIDTH-DATA_WIDTH/32- 1-1:0] lb_raddr
,output [ADDR_WIDTH-DATA_WIDTH/32- 1-1:0] lb_waddr

,output [0:0] lb_wren
,output lb_rden
,output lb_rdenlast
,input lb_rvalid
,input lb_rvalidlast
,output [DATA_WIDTH-1 : 0] lb_wdata
,input [DATA_WIDTH-1 : 0] lb_rdata
,output lb_clk
,output lb_aresetn

,output [7:0] awstate_dbg
,output [7:0] arstate_dbg
,output [7:0] wstate_dbg
,output [7:0] rstate_dbg
,output [7:0] bstate_dbg
);

wire lb_arready = 1'b1;
wire lb_awready = 1'b1;
wire lb_wready = 1'b1;
reg [ADDR_WIDTH-1 : 0] awaddr = 0;
reg [ADDR_WIDTH-1 : 0] waddr_d = 0;
reg [ADDR_WIDTH-1 : 0] awaddr_init = 0;
reg awready = 1'b0;
reg wready = 1'b0;
reg [1 : 0] bresp = 2'b0;
reg [BUSER_WIDTH-1 : 0] buser = 0;
reg bvalid = 1'b0;
reg [ADDR_WIDTH-1 : 0] araddr = 0;
reg arready = 1'b0;
reg [DATA_WIDTH-1 : 0] rdata = 0;
reg [1 : 0] rresp = 0;
reg rlast = 0;
reg [RUSER_WIDTH-1 : 0] ruser = 0;
reg rvalid = 0;
wire aw_wrap_en=0;
wire ar_wrap_en=0;
wire [ADDR_WIDTH-1:0] aw_wrap_size ;
wire [ADDR_WIDTH-1:0] ar_wrap_size ;
reg awv_awr_flag = 1'b0;
reg arv_arr_flag = 1'b0;
reg [7:0] awlen_cntr = 0;
reg awlen_cntr_last=0;
reg awlen_cntr_last_r=0;
reg arlen_cntr_last=0;
reg arlen_cntr_last_r=0;
reg [7:0] arlen_cntr = 0;
reg [7:0] rlen_cntr = 0;
reg rlastcnt = 0;
reg [7:0] arlen_cntr_next = 0;
reg [1:0] arburst = 0;
reg [1:0] awburst = 0;
reg [7:0] arlen = 0;
reg [7:0] awlen = 0;

//local parameter for addressing 32 bit / 64 bit DATA_WIDTH
//ADDR_LSB is used for addressing 32/64 bit registers/memories
//ADDR_LSB = 2 for 32 bits (n downto 2)
//ADDR_LSB = 3 for 64 bits (n downto 3)

localparam integer ADDR_LSB = (DATA_WIDTH/32)+ 1;

assign axi_awready = awready;
assign axi_wready = wready;
assign axi_bresp = bresp;
assign axi_buser = buser;
assign axi_bvalid = bvalid;
assign axi_arready = arready;
assign axi_rdata = rdata;
assign axi_rresp = rresp;
assign axi_rlast = rlast;
assign axi_ruser = ruser;
assign axi_rvalid = rvalid;
assign axi_bid = axi_awid;
assign axi_rid = axi_arid;
assign aw_wrap_size = (DATA_WIDTH/8 * (awlen));
assign ar_wrap_size = (DATA_WIDTH/8 * (arlen));
//assign aw_wrap_en = ((awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
//assign ar_wrap_en = ((araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;

reg reset = 1'b0; 
always @(posedge axi_aclk) begin
	reset <= ~axi_aresetn;
end
wire clk = axi_aclk;

reg wbusy = 0;
reg wdone = 0;
reg rdone = 0;
reg awdone = 0;
reg ardone = 0;
reg bdone = 0;
reg bbusy = 0;
reg awbusy = 0;
reg rbusy = 0;
reg arbusy = 0;
reg [0:0] wren = 0;
reg [0:0] wren_d = 0;
reg rden = 0;
reg rdenlast = 0;
reg [DATA_WIDTH-1 : 0] wdata = 0;
reg [DATA_WIDTH-1 : 0] wdata_d = 0;
reg [ADDR_WIDTH-1 : 0] raddr;
reg [ADDR_WIDTH-1 : 0] waddr;

localparam AWIDLE = 8'h00;
localparam AWREADY = 8'h01;
localparam AWVALID = 8'h02;
localparam AWREADYANDVALID = 8'h04;
localparam AWDONE = 8'h07;

localparam WIDLE = 8'h10;
localparam WREADY = 8'h11;
localparam WVALID = 8'h12;
localparam WREADYANDVALID = 8'h14;
localparam WDONE = 8'h17;

localparam BIDLE = 8'h20;
localparam BREADY = 8'h21;
localparam BVALID = 8'h22;
localparam BREADYANDVALID = 8'h24;
localparam BDONE = 8'h27;

localparam ARIDLE = 8'h30;
localparam ARREADY = 8'h31;
localparam ARVALID = 8'h32;
localparam ARREADYANDVALID = 8'h34;
localparam ARDONE = 8'h37;

localparam RIDLE = 8'h40;
localparam RREADY = 8'h41;
localparam RVALID = 8'h42;
localparam RREADYANDVALID = 8'h44;
localparam RDONE = 8'h47;

(* dont_touch = "yes" *) reg [7:0] awstate = AWIDLE,awnextstate = AWIDLE;
(* dont_touch = "yes" *) reg [7:0] arstate = ARIDLE,arnextstate = ARIDLE;
(* dont_touch = "yes" *) reg [7:0] wstate = WIDLE,wnextstate = WIDLE;
(* dont_touch = "yes" *) reg [7:0] rstate = RIDLE,rnextstate = RIDLE;
(* dont_touch = "yes" *) reg [7:0] bstate = BIDLE,bnextstate = BIDLE;

assign awstate_dbg = awstate;
assign arstate_dbg = arstate;
assign wstate_dbg = wstate;
assign rstate_dbg = rstate;
assign bstate_dbg = bstate;
always @(posedge clk) begin
	if (reset) begin
		awstate <= AWIDLE;
		wstate <= WIDLE;
		arstate <= ARIDLE;
		rstate <= RIDLE;
		bstate <= BIDLE;
	end
	else begin
		awstate <= awnextstate;
		arstate <= arnextstate;
		wstate <= wnextstate;
		rstate <= rnextstate;
		bstate <= bnextstate;
	end
end
wire busy = |{awbusy,wbusy,bbusy,arbusy,rbusy};
/*reg [31:0] clkcnt = 0;
always @(posedge clk) begin
	clkcnt <= clkcnt+1;
end
*/
wire notawready = ~axi_awready;
always @(awstate) begin
	awnextstate = AWIDLE;
	case (awstate)
		AWIDLE: begin
			awnextstate =(awready && axi_awvalid) ? AWREADYANDVALID : awready ? AWREADY : (axi_awvalid) ? AWVALID : AWIDLE;
		end
		AWREADY: begin
			awnextstate = (axi_awvalid) ? AWREADYANDVALID : (~awready) ? AWIDLE : AWREADY;
		end
		AWVALID: begin
			awnextstate = (awready) ? AWREADYANDVALID : AWVALID;
		end
		AWREADYANDVALID: begin
			//awnextstate =(awlen_cntr == awlen+1) ? AWDONE : AWREADYANDVALID;
			awnextstate =awlen_cntr_last_r ? AWDONE : AWREADYANDVALID;
		end
		AWDONE: begin
			awnextstate =(bdone) ? AWIDLE : AWDONE;
		end
		default: begin
			awnextstate = AWIDLE ;
		end
	endcase
end
always @(wnextstate) begin
	wnextstate = WIDLE;
	case (wstate)
		WIDLE: begin
			wnextstate =(wready && axi_wvalid) ? WREADYANDVALID : (wready)? WREADY : (axi_wvalid) ? WVALID : WIDLE;
		end
		WREADY: begin
			wnextstate =(axi_wvalid)? WREADYANDVALID : (~wready)? WIDLE: WREADY;
		end
		WVALID: begin
			wnextstate =(wready)? WREADYANDVALID: WVALID;
		end
		WREADYANDVALID: begin
			//wnextstate =(awlen_cntr == awlen+1)? WDONE : WREADYANDVALID;
			wnextstate = awlen_cntr_last_r ? WDONE : WREADYANDVALID;
		end
		WDONE: begin
			wnextstate =(bdone) ? WIDLE : WDONE;
		end
		default: begin
			wnextstate = WIDLE;
		end
	endcase
end
always @(bnextstate) begin
	bnextstate = BIDLE;
	case (bstate)
		BIDLE: begin
			bnextstate =(axi_bready && bvalid)? BREADYANDVALID : (axi_bready) ? BREADY : (bvalid) ? BVALID : BIDLE;
		end
		BREADY: begin
			bnextstate =wdone ? BREADYANDVALID : BREADY;
		end
		BVALID: begin
			bnextstate =(axi_bready)? BREADYANDVALID : BVALID;
		end
		BREADYANDVALID: begin
			bnextstate = BDONE;
		end
		BDONE: begin
			bnextstate = BIDLE;
		end
		default: begin
			bnextstate = BIDLE;
		end
	endcase
end
always @(arnextstate) begin
	arnextstate = ARIDLE;
	case (arstate)
		ARIDLE: begin
			arnextstate =(arready && axi_arvalid)? ARREADYANDVALID :(arready) ? ARREADY :(axi_arvalid)? ARVALID : ARIDLE;
		end
		ARREADY: begin
			arnextstate =(axi_arvalid) ? ARREADYANDVALID : ARREADY;
		end
		ARVALID: begin
			arnextstate =(arready)? ARREADYANDVALID : ARVALID;
		end
		ARREADYANDVALID: begin
			//arnextstate =(arlen_cntr == arlen+1) ? ARDONE : ARREADYANDVALID;
			arnextstate = arlen_cntr_last_r ? ARDONE : ARREADYANDVALID;
		end
		ARDONE: begin
			arnextstate = (rdone) ? ARIDLE : ARDONE;
		end
		default: begin
			arnextstate = ARIDLE;
		end
	endcase
end
always @(rnextstate) begin
	rnextstate = RIDLE;
	case (rstate)
		RIDLE: begin
			rnextstate =(axi_rready && rvalid) ? RREADYANDVALID : (axi_rready) ? RREADY : (rvalid) ? RVALID : RIDLE;
		end
		RREADY: begin
			rnextstate = (rvalid) ? RREADYANDVALID : RREADY;
		end
		RVALID: begin
			rnextstate =(axi_rready)? RREADYANDVALID : RVALID;
		end
		RREADYANDVALID: begin
			rnextstate =(rlen_cntr == arlen+1) ? RDONE : RREADYANDVALID;
		end
		RDONE: begin
			rnextstate = 	RIDLE;
		end
		default: begin
			rnextstate = RIDLE;
		end
	endcase
end
wire readydefault = 1'b0;
always @(posedge clk) begin
	if (reset) begin
		awaddr <= 0;
		awlen_cntr <= 0;
		arlen_cntr <= 0;
		rlen_cntr <= 0;
		awburst <= 0;
		awlen <= 0;
		awbusy <= 1'b0;
		//		awready <= 1'b1;
		//		wready <= 1'b1;
		//		bvalid <= 1'b1;
		//		arready <= 1'b1;
		//		rlast <= 1'b1;
	end
	else begin
		case (awnextstate)
			AWIDLE: begin
				awready <= readydefault;
				awbusy <= 1'b0;
				awlen_cntr <= 0;
				wren <= 1'b0;
				awdone <= 1'b0;
			end
			AWREADY:begin
				awbusy <= 1'b0;
				wren <= 1'b0;
				awdone <= 1'b0;
			end
			AWVALID: begin
				awbusy <= 1'b1;
				awready <= 1'b1;
				wren <= 1'b0;
				awdone <= 1'b0;
			end
			AWREADYANDVALID: begin
				awbusy <= 1'b1;
				awready <= 1'b0;
				awburst <= axi_awburst;
				awlen <= axi_awlen;
				wren <= axi_wvalid && wready;
				if (awlen_cntr == 0) begin
					awaddr <= axi_awaddr[ADDR_WIDTH - 1:0];
				end
				else if (axi_wvalid && wready) begin
					case (awburst)
						2'b00: begin
							awaddr <= awaddr;
						end
						2'b01: begin
							awaddr[ADDR_WIDTH - 1:ADDR_LSB] <= awaddr[ADDR_WIDTH - 1:ADDR_LSB] + 1;
							awaddr[ADDR_LSB-1:0] <= {ADDR_LSB{1'b0}}; 
						end

						2'b10: begin
							if (aw_wrap_en) begin
								awaddr <= (awaddr - aw_wrap_size);
							end
							else begin
								awaddr[ADDR_WIDTH - 1:ADDR_LSB] <= awaddr[ADDR_WIDTH - 1:ADDR_LSB] + 1;
								awaddr[ADDR_LSB-1:0] <= {ADDR_LSB{1'b0}};
							end
						end

						default: begin
							awaddr[ADDR_WIDTH - 1:ADDR_LSB] <= awaddr[ADDR_WIDTH - 1:ADDR_LSB] + 1;
							awaddr[ADDR_LSB-1:0] <= {ADDR_LSB{1'b0}}; 
						end

					endcase
				end
				if (axi_wvalid && wready) begin
					awlen_cntr <= awlen_cntr + 1;
				end

				waddr <= awaddr;
				wbusy <= 1'b1;
				awdone <= 1'b0;
			end
			AWDONE: begin
				awbusy <= 1'b1;
				awready <= 1'b0;
				wren <= 1'b0;
				awdone <= 1'b1;
			end
			default: begin
				awbusy <= 1'b0;
				awready <= 1'b1;
				wren <= 1'b0;
				awdone <= 1'b0;
			end
		endcase
		case (wnextstate)
			WIDLE: begin
				wready <= readydefault;
				wbusy <= 1'b0;
				wdone <= 1'b0;
			end
			WREADY: begin
				wbusy <= 1'b0;
				wdone <= 1'b0;
			end
			WVALID: begin
				wready <= 1'b1;
				wbusy <= 1'b1;
				wdone <= 1'b0;
			end
			WREADYANDVALID: begin
				wbusy <= 1'b1;
				wdata <= axi_wdata;
				wdone <= 1'b0;
			end
			WDONE: begin
				wready <= 1'b0;
				wbusy <= 1'b1;
				wdone <= 1'b1;
			end
			default: begin
				wready <= 1'b1;
				wbusy <= 1'b0;
				wdone <= 1'b0;
			end
		endcase
		case (bnextstate)
			BIDLE: begin
				bvalid <= 1'b0;
				bbusy <= 1'b0;
				bdone <= 1'b0;
			end
			BREADY: begin
				bvalid <= 1'b0;
				bresp <= 2'b0;
				bbusy <= 1'b1;
				bdone <= 1'b0;
			end
			BVALID: begin
				bbusy <= 1'b1;
				bdone <= 1'b0;
			end
			BREADYANDVALID: begin
				bvalid <= 1'b1;
				bbusy <= 1'b1;
				bdone <= 1'b0;
			end
			BDONE: begin
				bvalid <= 1'b0;
				bbusy <= 1'b0;
				bdone <= 1'b1;
			end
			default: begin
				bvalid <= 1'b1; 
				bbusy <= 1'b0;
				bdone <= 1'b0;
			end
		endcase
		case (arnextstate)
			ARIDLE: begin
				arready <= readydefault;
				arbusy <= 1'b0;
				rden <= 1'b0;
				rdenlast <= 1'b0;
				arlen_cntr <= 0;
				ardone <= 1'b0;

			end
			ARREADY: begin
				arbusy <= 1'b0;
				rden <= 1'b0;
				rdenlast <= 1'b0;
				ardone <= 1'b0;
			end
			ARVALID: begin
				arready <= 1'b1;
				arbusy <= 1'b1;
				rden <= 1'b0;
				rdenlast <= 1'b0;
				ardone <= 1'b0;
			end
			ARREADYANDVALID: begin
				arready <= 1'b0;
				arbusy <= 1'b1;
				rden <= 1'b1;
				rdenlast <= arlen_cntr == axi_arlen;
				arlen_cntr <= arlen_cntr + 1;
				if (arlen_cntr == 0) begin
					araddr <= axi_araddr[ADDR_WIDTH - 1:0];
					arburst <= axi_arburst;
					arlen <= axi_arlen;
				end
				else begin
					case (arburst)
						2'b00:begin
							araddr <= araddr;
						end
						2'b01:begin
							araddr[ADDR_WIDTH - 1:ADDR_LSB] <= araddr[ADDR_WIDTH - 1:ADDR_LSB] + 1;
							araddr[ADDR_LSB-1:0] <= {ADDR_LSB{1'b0}};

						end
						2'b10: begin
							if (ar_wrap_en)begin
								araddr <= (araddr - ar_wrap_size);
							end
							else begin
								araddr[ADDR_WIDTH - 1:ADDR_LSB] <= araddr[ADDR_WIDTH - 1:ADDR_LSB] + 1;
								araddr[ADDR_LSB-1:0] <= {ADDR_LSB{1'b0}};
							end
						end

						default: begin
							araddr[ADDR_WIDTH - 1:ADDR_LSB] <= araddr[ADDR_WIDTH - 1:ADDR_LSB] + 1;
							araddr[ADDR_LSB-1:0] <= {ADDR_LSB{1'b0}};

						end
					endcase
				end
				raddr <= araddr;
				ardone <= 1'b0;
			end
			ARDONE: begin
				rden <= 1'b0;
				rdenlast <= 1'b0;
				arbusy <= 1'b1;
				ardone <= 1'b1;
			end
			default: begin
				arready <= 1'b1;
				arbusy <= 1'b0;
				ardone <= 1'b0;
			end
		endcase
		case (rnextstate)
			RIDLE: begin
				rlen_cntr <= 0;
				rlastcnt <= 1'b0;
				rbusy <= 1'b0;
				rdone <= 1'b0;
			end
			RREADY: begin
				rbusy <= 1'b0;
				rdone <= 1'b0;
			end
			RVALID: begin
				rbusy <= 1'b1;
				rdone <= 1'b0;
			end
			RREADYANDVALID: begin
				if (rvalid) begin
					rlen_cntr <= rlen_cntr +1;
				end
				rlastcnt <= rlen_cntr == arlen;
				rbusy <= 1'b1;
				rdone <= 1'b0;
			end
			RDONE: begin
				rbusy <= 1'b1;
				rlastcnt <= 1'b0;
				rdone <= 1'b1;
			end
			default: begin
				rbusy <= 1'b0;
				rdone <= 1'b0;
			end
		endcase
	end
	wdata_d <= wdata;
	waddr_d <= awaddr;
	wren_d <= wren;
	rdata <= lb_rdata;
	rvalid <= lb_rvalid;
	rlast <= lb_rvalidlast;
	//	awlen_cntr_last<=awlen_cntr==axi_awlen;
	awlen_cntr_last_r<=awlen_cntr_last && wready && axi_wvalid;
	//	arlen_cntr_last<=arlen_cntr==axi_arlen;
	arlen_cntr_last_r<=arlen_cntr_last;
end

always @(negedge  clk) begin
	awlen_cntr_last<=awlen_cntr==axi_awlen;
	//awlen_cntr_last_r<=awlen_cntr_last && wready && axi_wvalid;
	arlen_cntr_last<=arlen_cntr==axi_arlen;
	//arlen_cntr_last_r<=arlen_cntr_last;
end
wire awlencheck=(awlen_cntr == awlen+1);
wire awlencheck2=awlen_cntr_last_r;
wire arlencheck=(arlen_cntr == arlen+1);
wire arlencheck2=arlen_cntr_last_r;

assign lb_waddr = waddr_d[ADDR_WIDTH-1:ADDR_LSB];
assign lb_wren = wren_d;
assign lb_wdata = wdata_d;
assign lb_raddr = araddr[ADDR_WIDTH-1:ADDR_LSB];
assign lb_rden = rden;
assign lb_rdenlast = rdenlast;
assign lb_clk = axi_aclk;
assign lb_aresetn = axi_aresetn;

endmodule
