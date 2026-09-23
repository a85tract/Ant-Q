/*fakecore #(.DATA_WIDTH(DATA_WIDTH), .CMD_WIDTH(CMD_WIDTH),.CMD_ADDR_WIDTH(CMD_ADDR_WIDTH), .REG_ADDR_WIDTH(REG_ADDR_WIDTH),.SYNC_BARRIER_WIDTH(SYNC_BARRIER_WIDTH),.CMD_MEM_READ_LATENCY(5)) 
fakecore(.clk(clk), .reset(reset),.cmd_iface(memif), .fproc(fproc), .sync(sync), .pulseout(pulseout),.done_gate(procdone));
cmd_mem_iface #(.CMD_ADDR_WIDTH(16), .MEM_WIDTH(128), .MEM_TO_CMD(1)) memif();
fproc_iface #(.FPROC_ID_WIDTH(8), .FPROC_RESULT_WIDTH(32)) fproc();
sync_iface #(.SYNC_BARRIER_WIDTH(8)) sync();
pulse_iface #(.PHASE_WIDTH(PHASE_WIDTH), .FREQ_WIDTH(FREQ_WIDTH),.ENV_WORD_WIDTH(ENV_WIDTH), .AMP_WIDTH(AMP_WIDTH), .CFG_WIDTH(CFG_WIDTH)) 
pulseout();
*/
module fakecore#(parameter DATA_WIDTH=32
,parameter CMD_WIDTH=128
,parameter CMD_ADDR_WIDTH=8
,parameter REG_ADDR_WIDTH=4
,parameter SYNC_BARRIER_WIDTH=8
,parameter DAC_SAMPLES_PER_CLK=4
,parameter CMD_MEM_READ_LATENCY=3
,parameter QCLKDELAYSTART=13
)(input clk
,input reset
,cmd_mem_iface cmd_iface
,sync_iface.proc sync
,fproc_iface.proc fproc
,pulse_iface.proc pulseout
,output done_gate
,output reg [3:0] state_dbg
,output reg [3:0] nextstate_dbg
);

parameter PULSE_WRITE_TRIG = 4'b1001;
parameter DONE = 4'b1010;
parameter PULSE_RESET = 4'b1011;

reg [CMD_ADDR_WIDTH-1:0] instr_ptr=0;
reg [CMD_ADDR_WIDTH-1:0] next_instr_ptr=0;
assign cmd_iface.instr_ptr=instr_ptr;
wire [CMD_WIDTH-1:0] cmd_read=cmd_iface.cmd_read;

reg pulseout_reset=0;
assign pulseout.reset=pulseout_reset;
reg pulseout_cstrobe=0;
assign pulseout.cstrobe=pulseout_cstrobe;
reg [3:0] pulseout_cfg;
assign pulseout.cfg=pulseout_cfg;
reg [9:0] pulseout_env_word_start;
reg [9:0] pulseout_env_word_length;
assign pulseout.env_word={2'b0,pulseout_env_word_length,2'b0,pulseout_env_word_start};
reg [15:0] pulseout_amp;
assign pulseout.amp=pulseout_amp;
reg [8:0] pulseout_freq;
assign pulseout.freq=pulseout_freq;
reg [16:0] pulseout_phase;
assign pulseout.phase=pulseout_phase;
reg done=0;
assign done_gate=done;
reg [3:0] opcodes=0;
reg [31:0] pulse_cmd_time=0;
reg [31:0] qclk_out=0;
reg [15:0] reset_sr=0;
reg dummyresetsr=0;

enum {IDLE      =4'b1011
,RESETDONE      =4'b1001
,WAITFORCMDBUF  =4'b1000
,PARSECMD       =4'b0000
,RESETELEM      =4'b0001
,WAITFORTRIGT   =4'b0010
,TRIGT          =4'b0011
,ENDCIRCUIT		=4'b0100
,NEXTCMD		=4'b0101
,ERROR			=4'b1010
} state=IDLE,nextstate=IDLE;
always @(posedge clk) begin
state_dbg<=state;
nextstate_dbg<=nextstate;
end
reg [7:0] addrgatesr=0;
reg addrgate=0;
reg dummyaddrgatesr=0;
wire [3:0] t1=opcodes^PULSE_RESET;
wire [3:0] t2=opcodes^DONE;
wire [3:0] t3=opcodes^PULSE_WRITE_TRIG;
always @(posedge clk) begin
	if (reset) begin
		state <= IDLE;
	end
	else begin
		state <= nextstate;
	end
	{dummyaddrgatesr,addrgatesr}<={addrgatesr,addrgate};
end
always @(state) begin
	nextstate=IDLE;
	case (state)
		IDLE: begin
			nextstate=RESETDONE;
		end
		RESETDONE: begin
			nextstate= WAITFORCMDBUF;
		end
		WAITFORCMDBUF: begin
			nextstate= addrgatesr[CMD_MEM_READ_LATENCY] ? PARSECMD : WAITFORCMDBUF;
		end
		PARSECMD: begin
			nextstate= ~|(opcodes^PULSE_RESET) ? RESETELEM : ~|(opcodes^DONE) ? ENDCIRCUIT : ~|(opcodes^PULSE_WRITE_TRIG) ? WAITFORTRIGT : PARSECMD;
		end
		RESETELEM: begin
			nextstate=NEXTCMD;
		end
		WAITFORTRIGT: begin
			nextstate= ~|(pulse_cmd_time^qclk_out) ? TRIGT : WAITFORTRIGT ;
		end
		TRIGT: begin
			nextstate= NEXTCMD;
		end
		ENDCIRCUIT: begin
			nextstate= ENDCIRCUIT;
		end
		NEXTCMD: begin
			nextstate= WAITFORCMDBUF;
		end
		ERROR: begin
			nextstate=ERROR;
		end
	endcase
end
always @(posedge clk) begin
	if (reset) begin
		instr_ptr<=0;
		next_instr_ptr<=0;
		qclk_out<=0;
		done<=0;
		addrgate<=1'b0;
		pulseout_reset<=1'b0;
		pulseout_cstrobe<=1'b0;
	end
	else begin
		qclk_out<=reset_sr[QCLKDELAYSTART] ? 0 : qclk_out+1;
		case (nextstate)
			IDLE: begin
				addrgate<=1'b0;
				pulseout_reset<=1'b0;
				pulseout_cstrobe<=1'b0;
				done<=1;
				next_instr_ptr<=instr_ptr+1;
			end
			RESETDONE: begin
				addrgate<=1'b1;
				pulseout_reset<=1'b0;
				pulseout_cstrobe<=1'b0;
				done<=0;
				next_instr_ptr<=instr_ptr+1;
			end
			WAITFORCMDBUF: begin
				addrgate<=1'b0;
				pulseout_reset<=1'b0;
				pulseout_cstrobe<=1'b0;
				done<=0;
				next_instr_ptr<=instr_ptr+1;
			end
			PARSECMD: begin
				addrgate<=1'b0;
				pulseout_reset<=1'b0;
				pulseout_cstrobe<=1'b0;
				pulse_cmd_time<=cmd_read[5+:32];
				pulseout_cfg<=cmd_read[37+:4];
				pulseout_amp<=cmd_read[42+:16];
				pulseout_freq<=cmd_read[60+:9];
				pulseout_phase<=cmd_read[71+:17];
				pulseout_env_word_start<=cmd_read[90+:10];
				pulseout_env_word_length<=cmd_read[102+:10];
				opcodes<=cmd_read[127-:4];
			
				done<=0;
				next_instr_ptr<=instr_ptr+1;
			end
			RESETELEM: begin
				addrgate<=1'b0;
				pulseout_reset<=1'b1;
				pulseout_cstrobe<=1'b0;
				done<=0;
				next_instr_ptr<=instr_ptr+1;
			end
			WAITFORTRIGT: begin
				addrgate<=1'b0;
				pulseout_reset<=1'b0;
				pulseout_cstrobe<=1'b0;
				done<=0;
				next_instr_ptr<=instr_ptr+1;
			end
			TRIGT: begin
				addrgate<=1'b0;
				pulseout_reset<=1'b0;
				pulseout_cstrobe<=1'b1;
				done<=0;
				next_instr_ptr<=instr_ptr+1;
			end
			ENDCIRCUIT: begin
				addrgate<=1'b0;
				pulseout_reset<=1'b0;
				pulseout_cstrobe<=1'b0;
				done<=1'b1;
				next_instr_ptr<=instr_ptr+1;
			end
			NEXTCMD: begin
				instr_ptr<=next_instr_ptr;
				addrgate<=1'b1;
				pulseout_reset<=1'b0;
				pulseout_cstrobe<=1'b0;
				done<=0;
			end
		endcase
	end
	{dummyresetsr,reset_sr}<={reset_sr,reset};
end
/*always @(negedge clk) begin
case (nextstate)
	PARSECMD: begin
		pulse_cmd_time<=cmd_read[5+:32];
		pulseout_cfg<=cmd_read[37+:4];
		pulseout_amp<=cmd_read[42+:16];
		pulseout_freq<=cmd_read[60+:9];
		pulseout_phase<=cmd_read[71+:17];
		pulseout_env_word_start<=cmd_read[90+:10];
		pulseout_env_word_length<=cmd_read[102+:10];
		opcodes<=cmd_read[127-:4];
	end
endcase
end
*/

endmodule
