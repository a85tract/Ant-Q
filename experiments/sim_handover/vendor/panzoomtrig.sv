interface panzoomtrigif #(parameter NCHAN=6,parameter ADDRWIDTH=9,parameter DATAWIDTH=64
	)();
	logic clk;
	logic reset;
	localparam SELWIDTH=$clog2(NCHAN)+1;
	logic stb_start;
	logic [DATAWIDTH-1:0] chan [0:NCHAN-1];


	reg trig=0;
	always @(posedge clk) begin
		trig<=stb_start; // add more later
	end

	reg [15:0]  delayaftertrigcnt=0;
	logic [15:0]  delayaftertrig;
	wire delayaftertrigcnt0=~|delayaftertrigcnt;
	logic [7:0] decimator;
	reg [7:0] decimatorcnt=0;
	wire decimator0=~|decimatorcnt;
	reg [ADDRWIDTH-1:0] addr=0;
	wire [ADDRWIDTH-1:0] nextaddr=addr+1;
	reg [DATAWIDTH-1:0] data=0;
	reg [DATAWIDTH-1:0] datasel=0;
	reg we=0;
	logic [4:0] chansel;
	wire buffull=&addr;
	enum {IDLE		=3'b111
	,WAITFORTRIG	=3'b101
	,DELAYAFTERTRIG	=3'b100
	,ADDRDECI		=3'b001
	,WRITEBUF		=3'b000
	,BUFFULL		=3'b010
	}state=IDLE,nextstate=IDLE;

	always @(posedge clk) begin
		if (reset) begin
			state <= IDLE;
		end
		else begin
			state <= nextstate;
		end
	end
	always @(state) begin
		nextstate=IDLE;
		case (state)
			IDLE: begin
				nextstate = WAITFORTRIG;
			end
			WAITFORTRIG: begin
				nextstate= trig ? (delayaftertrigcnt0 ? WRITEBUF : DELAYAFTERTRIG) : WAITFORTRIG;
			end
			DELAYAFTERTRIG : begin
				nextstate= delayaftertrigcnt0 ? WRITEBUF : DELAYAFTERTRIG ;
			end
			ADDRDECI: begin
				nextstate=decimator0 ? WRITEBUF: ADDRDECI;
			end
			WRITEBUF: begin
				nextstate= buffull ? BUFFULL : decimator0 ? WRITEBUF : ADDRDECI;
			end
			BUFFULL: begin
				nextstate=BUFFULL;
			end
		endcase
	end
	always @(posedge clk) begin
		datasel<=chan[chansel];
		if (reset) begin
			delayaftertrigcnt<=delayaftertrig;
			addr<=0;
			decimatorcnt<=decimator;
			we<=1'b0;
		end
		else begin
			case (nextstate)
				IDLE: begin
					addr<=0;
					we<=1'b0;
			        decimatorcnt<=decimator;
			        delayaftertrigcnt<=delayaftertrig;
				end
				WAITFORTRIG: begin
					we<=1'b0;
				end
				DELAYAFTERTRIG: begin
					delayaftertrigcnt<=delayaftertrigcnt-1;
					we<=1'b0;
				end
				ADDRDECI: begin
					decimatorcnt<=decimatorcnt-1;
					we<=1'b0;
				end
				WRITEBUF: begin
					decimatorcnt<=decimator;
					addr<=nextaddr;
					data<=datasel;
					we<=1'b1;
				end
				BUFFULL: begin
					we<=1'b0;
				end
			endcase
		end
	end
endinterface
