`timescale 1 ns / 1 ps
// plsv_v2b: the REAL plsv board PL top with ring_buffer_simple's mmu_readout_cmd bundle integrated INSIDE.
// = plsv_obs (real localbus->ifbramctrl->BRAM->real dsp->boardcfg_v2b->DAC) BUT the 8 command BRAMs are
// REPLACED by the DDR-streamed command path (mmu_readout_cmd_top + cmd_sequencer), and the dsp accbuf is
// tapped into the readout path. The two axi_dpram (command DDR + readout DDR) live OUTSIDE (sim wrapper).
// DEFAULTS = REAL BOARD values (PPBUF_AW=11/2048-cmd, BPC=1024, BURST=256, AXI_AW=32, NUM_UNITS=1024). The
// cocotb sim wrapper (gen_plsv_v2b_sim_top.py) OVERRIDES these DOWN to reduced sim depths for fast behavioral
// runs; full board values are validated by full-parameter elaboration. wr_clk=dspclk(500), rd_clk=ddr_clk(333).
module plsv_v2b #(`include "plps_para.vh"
,`include "bram_para.vh"
,`include "braminit_para.vh"
,parameter integer V2B_NUM_CH   = 8
,parameter integer V2B_AXI_AW   = 32
,parameter integer V2B_AXI_DW   = 256
,parameter integer V2B_AXI_ID   = 4
,parameter integer V2B_PPBUF_AW = 11
,parameter integer V2B_CMD_W    = 128
,parameter integer V2B_WR_DW    = 64
,parameter integer V2B_CBUF_AW  = 4
,parameter integer V2B_BPC      = 1024
,parameter integer V2B_BURST    = 256
,parameter integer V2B_NUNITS   = 1024
,parameter integer V2B_CID_W    = 16
)(	`include "plps_port.vh"
,hwif hw
,input clkadc3_300
,input clkadc3_600
,output [DAC_AXIS_DATAWIDTH-1:0] obs_dac [0:NDAC-1]
// ===== v2-B integration ports (ddr/rd_clk domain unless noted) =====
,input  ddr_clk
,input  ddr_rst_n
// command AXI-Stream IN -> stream_cmd_writer
,input  [V2B_AXI_DW-1:0] s_axis_cmd_tdata
,input  s_axis_cmd_tvalid
,output s_axis_cmd_tready
// readout AXI-Stream OUT (m_axis drain)
,output [V2B_AXI_DW-1:0] m_axis_tdata
,output m_axis_tvalid
,output m_axis_tlast
,input  m_axis_tready
// config in
,input  [31:0] n_shots
,input  n_shots_enable
,input  [V2B_NUM_CH-1:0] ch_mask   // [CE]
,input  idle_load                  // [CE] rd_clk level
,output idle_done                  // [CE] rd_clk pulse
,input  global_start
,input  [V2B_CID_W-1:0] last_circuit_id
,input  circuit_id_reset
,input  [V2B_CBUF_AW-1:0] max_bank_size
,input  [V2B_AXI_AW-1:0] wr_base_addr
,input  rd_start
,input  [V2B_AXI_AW-1:0] rd_base_addr
,input  [V2B_AXI_AW:0]   rd_size_bytes
// status out
,output [V2B_CID_W-1:0] current_circuit_id
,output [V2B_AXI_AW-1:0] final_addr
,output current_user_done
,output [V2B_AXI_AW-1:0] cur_axi_addr_out
,output rd_busy
,output rd_done
,output v2b_batch_done
// CNR: did two circuits run continuously? (standalone detector, observes the cmd_sequencer<->bundle boundary)
,output circuit_not_ready
,output [15:0] cnr_wait_counter
,input  cnr_reset
// [stop] early-stop command in (rd_clk) + record out (rd_clk)
,input  [V2B_CID_W-1:0] stop_cid
,input  stop_en
,output stop_rec_valid
,output [31:0] stop_rec_w0
,output [31:0] stop_rec_w1
,output [31:0] stop_rec_w2
,output [31:0] stop_rec_w3
// command DDR AXI-full master
,output [V2B_AXI_ID-1:0] cmd_m_axi_awid  ,output [V2B_AXI_AW-1:0] cmd_m_axi_awaddr ,output [7:0] cmd_m_axi_awlen
,output [2:0] cmd_m_axi_awsize ,output [1:0] cmd_m_axi_awburst ,output cmd_m_axi_awvalid ,input cmd_m_axi_awready
,output [V2B_AXI_DW-1:0] cmd_m_axi_wdata ,output [V2B_AXI_DW/8-1:0] cmd_m_axi_wstrb ,output cmd_m_axi_wlast
,output cmd_m_axi_wvalid ,input cmd_m_axi_wready
,input [V2B_AXI_ID-1:0] cmd_m_axi_bid ,input [1:0] cmd_m_axi_bresp ,input cmd_m_axi_bvalid ,output cmd_m_axi_bready
,output [V2B_AXI_ID-1:0] cmd_m_axi_arid ,output [V2B_AXI_AW-1:0] cmd_m_axi_araddr ,output [7:0] cmd_m_axi_arlen
,output [2:0] cmd_m_axi_arsize ,output [1:0] cmd_m_axi_arburst ,output cmd_m_axi_arvalid ,input cmd_m_axi_arready
,input [V2B_AXI_ID-1:0] cmd_m_axi_rid ,input [V2B_AXI_DW-1:0] cmd_m_axi_rdata ,input [1:0] cmd_m_axi_rresp
,input cmd_m_axi_rlast ,input cmd_m_axi_rvalid ,output cmd_m_axi_rready
// readout DDR AXI-full master
,output [V2B_AXI_ID-1:0] m_axi_awid  ,output [V2B_AXI_AW-1:0] m_axi_awaddr ,output [7:0] m_axi_awlen
,output [2:0] m_axi_awsize ,output [1:0] m_axi_awburst ,output m_axi_awvalid ,input m_axi_awready
,output [V2B_AXI_DW-1:0] m_axi_wdata ,output [V2B_AXI_DW/8-1:0] m_axi_wstrb ,output m_axi_wlast
,output m_axi_wvalid ,input m_axi_wready
,input [V2B_AXI_ID-1:0] m_axi_bid ,input [1:0] m_axi_bresp ,input m_axi_bvalid ,output m_axi_bready
,output [V2B_AXI_ID-1:0] m_axi_arid ,output [V2B_AXI_AW-1:0] m_axi_araddr ,output [7:0] m_axi_arlen
,output [2:0] m_axi_arsize ,output [1:0] m_axi_arburst ,output m_axi_arvalid ,input m_axi_arready
,input [V2B_AXI_ID-1:0] m_axi_rid ,input [V2B_AXI_DW-1:0] m_axi_rdata ,input [1:0] m_axi_rresp
,input m_axi_rlast ,input m_axi_rvalid ,output m_axi_rready
);

wire cfgreset;
wire dspreset;
wire psreset;
wire adc3reset;
wire psclk=pl_clk0;
wire adc3clk=clkadc3_600;

`include "reset_plsv.vh"

iflocalbus #(.DATA_WIDTH(LB1_DATAWIDTH),.ADDR_WIDTH(LB1_ADDRWIDTH)) lb1();
iflocalbus #(.DATA_WIDTH(LB2_DATAWIDTH),.ADDR_WIDTH(LB2_ADDRWIDTH)) lb2();
iflocalbus #(.DATA_WIDTH(LB3_DATAWIDTH),.ADDR_WIDTH(LB3_ADDRWIDTH)) lb3();
iflocalbus #(.DATA_WIDTH(LB4_DATAWIDTH),.ADDR_WIDTH(LB4_ADDRWIDTH)) lb4();

localbus_mappin #(.DATA_WIDTH(LB1_DATAWIDTH),.ADDR_WIDTH(LB1_ADDRWIDTH))
lb1map(.lb(lb1),.wren(lb1_wren),.rden(lb1_rden),.rdenlast(lb1_rdenlast),.waddr(lb1_waddr),.rvalid(lb1_rvalid),.rvalidlast(lb1_rvalidlast),.wdata(lb1_wdata),.raddr(lb1_raddr),.rdata(lb1_rdata),.clk(lb1_clk),.aresetn(lb1_aresetn));
localbus_mappin #(.DATA_WIDTH(LB2_DATAWIDTH),.ADDR_WIDTH(LB2_ADDRWIDTH))
lb2map(.lb(lb2),.wren(lb2_wren),.rden(lb2_rden),.rdenlast(lb2_rdenlast),.waddr(lb2_waddr),.rvalid(lb2_rvalid),.rvalidlast(lb2_rvalidlast),.wdata(lb2_wdata),.raddr(lb2_raddr),.rdata(lb2_rdata),.clk(lb2_clk),.aresetn(lb2_aresetn));
localbus_mappin #(.DATA_WIDTH(LB3_DATAWIDTH),.ADDR_WIDTH(LB3_ADDRWIDTH))
lb3map(.lb(lb3),.wren(lb3_wren),.rden(lb3_rden),.rdenlast(lb3_rdenlast),.waddr(lb3_waddr),.rvalid(lb3_rvalid),.rvalidlast(lb3_rvalidlast),.wdata(lb3_wdata),.raddr(lb3_raddr),.rdata(lb3_rdata),.clk(lb3_clk),.aresetn(lb3_aresetn));
localbus_mappin #(.DATA_WIDTH(LB4_DATAWIDTH),.ADDR_WIDTH(LB4_ADDRWIDTH))
lb4map(.lb(lb4),.wren(lb4_wren),.rden(lb4_rden),.rdenlast(lb4_rdenlast),.waddr(lb4_waddr),.rvalid(lb4_rvalid),.rvalidlast(lb4_rvalidlast),.wdata(lb4_wdata),.raddr(lb4_raddr),.rdata(lb4_rdata),.clk(lb4_clk),.aresetn(lb4_aresetn));

`include "bram_plsv.vh"

ifbramctrl#(.DATA_WIDTH(LB3_DATAWIDTH),.ADDR_WIDTH(LB3_ADDRWIDTH),.READDELAY(5)
,`include "bram_parainst.vh"
,`include "braminit_parainst.vh"
)
ifbramctrl(.lb(lb3)
,`include "bramif_lbportinst.vh"
);

ifcfgregs #(.DATA_WIDTH(LB1_DATAWIDTH),.ADDR_WIDTH(LB1_ADDRWIDTH)) cfgregs(.lb(lb1));
ifdspregs #(.DATA_WIDTH(LB2_DATAWIDTH),.ADDR_WIDTH(LB2_ADDRWIDTH)) dspregs(.lb(lb2));

`include "rfdc_plsv.vh"

ifdsp #(`include "plps_parainst.vh"
,`include "bram_parainst.vh"
,`include "braminit_parainst.vh"
)
dspif();

// boardcfg_v2b: identical to boardcfg EXCEPT it no longer drives dspif.data_qubit_command / stb_start / nshot.
boardcfg_v2b #(`include "plps_parainst.vh"
,`include "bram_parainst.vh"
,`include "braminit_parainst.vh"
)
boardcfg(.hw(hw),.cfgregs(cfgregs.regs)
,.dspregs(dspregs.regs)
,`include "bramif_portinst.vh"
,`include "rfdcif_portinst.vh"
,.dspif(dspif.cfg)
,.pl_clk0(pl_clk0),.cfgclk(cfgclk),.dspclk(dspclk)
,.clk_dac0(clk_dac0),.clk_dac1(clk_dac1),.clk_dac2(clk_dac2),.clk_dac3(clk_dac3)
,.clk_adc0(clk_adc0),.clk_adc1(clk_adc1),.clk_adc2(clk_adc2),.clk_adc3(clk_adc3)
,.clkadc3_300(clkadc3_300),.clkadc3_600(clkadc3_600)
,.aresetn(aresetn),.cfgreset(cfgreset),.dspreset(dspreset),.psreset(psreset),.adc3reset(adc3reset)
);

dsp #(`include "plps_parainst.vh"
,`include "bram_parainst.vh"
,`include "braminit_parainst.vh"
)
dsp(.dspif(dspif));

assign obs_dac = dspif.dac;

// ================================================================================================
// v2-B integration: mmu_readout_cmd_top (command-fill + readout) + cmd_sequencer + data_tagger_top
// ================================================================================================
wire                          v2b_wr_clk  = dspclk;     // wr_clk domain = dsp domain
wire                          v2b_wr_rst_n = ~dspreset;
wire                          v2b_rd_clk  = ddr_clk;    // rd_clk domain = ddr/axi domain
wire                          v2b_rd_rst_n = ddr_rst_n;

// ppbuf read-side (wr_clk domain) <-> dsp command read
wire [V2B_NUM_CH-1:0]                 ppbuf_able_to_read;
wire [V2B_NUM_CH-1:0]                 ppbuf_rd_empty;
wire [V2B_NUM_CH*V2B_PPBUF_AW-1:0]    ppbuf_rd_addr_valid;
wire [V2B_NUM_CH*V2B_CMD_W-1:0]       ppbuf_rd_data;
wire [V2B_NUM_CH*V2B_PPBUF_AW-1:0]    ppbuf_rd_addr;
wire [V2B_NUM_CH-1:0]                 ppbuf_rd_en;
wire [V2B_NUM_CH-1:0]                 ppbuf_read_finished;

// command read splice: drive dsp command data FROM ppbuf, feed dsp's program-counter addr TO ppbuf.
genvar gc;
generate for (gc=0; gc<V2B_NUM_CH; gc=gc+1) begin : g_cmd
    assign dspif.data_qubit_command[gc] = ppbuf_rd_data[gc*V2B_CMD_W +: V2B_CMD_W];
    assign ppbuf_rd_addr[gc*V2B_PPBUF_AW +: V2B_PPBUF_AW] = dspif.addr_qubit_command[gc][V2B_PPBUF_AW-1:0];
end endgenerate
assign ppbuf_rd_en = {V2B_NUM_CH{1'b1}};   // dsp reads continuously at its program-counter address

// sequencer: drives dspif.stb_start/nshot + ppbuf_read_finished; produces circuit_started/N_shot_finished
wire                  seq_stb_start;
wire [31:0]           seq_nshot;
wire [V2B_CID_W-1:0]  seq_circuit_id;
wire [31:0]           nshots_staged_out;
wire                  seq_cid_reset_w;   // re-arm: cmd_sequencer auto-resets circuit_id between batches
assign dspif.stb_start = seq_stb_start;
assign dspif.nshot     = seq_nshot;
wire circuit_started   = seq_stb_start;            // circuit begins (precedes 1st readout word); also FIX-A' pop credit
wire seq_run_active;                                // cmd_sequencer: HIGH while a batch is in flight (for cnr_detector)
wire seq_in_run;                                    // [stop] cmd_sequencer S_RUN
wire N_shot_finished   = ppbuf_read_finished[0];   // per-circuit done -> readout flush trigger

cmd_sequencer #(.NUM_CH(V2B_NUM_CH), .NSHOT_W(32), .CID_W(V2B_CID_W))
u_v2b_seq (
    .clk(v2b_wr_clk), .rst_n(v2b_wr_rst_n),
    .global_start(global_start), .last_circuit_id(last_circuit_id),
    .ppbuf_able_to_read(ppbuf_able_to_read), .ppbuf_rd_empty(ppbuf_rd_empty),
    .nshots_staged(nshots_staged_out),
    .stb_start(seq_stb_start), .nshot(seq_nshot), .lastshotdone(dspif.lastshotdone),
    .ppbuf_read_finished(ppbuf_read_finished),
    .seq_circuit_id_reset(seq_cid_reset_w),
    .circuit_id(seq_circuit_id), .batch_done(v2b_batch_done),
    .run_active(seq_run_active), .in_run(seq_in_run)
);

// CNR detector (standalone, OUTSIDE the real dsp + the cmd_sequencer): flags when a circuit boundary stalled
// because the next bank wasn't pre-filled in time (two circuits did NOT run continuously). Same wr_clk domain
// as the sequencer + ppbuf read-side. all_ready = the sequencer's bank-ready condition for ALL channels.
wire v2b_all_ready = &(ppbuf_able_to_read & ~ppbuf_rd_empty);
cnr_detector #(.SWITCH_LATENCY(8), .WAIT_W(16), .CID_W(V2B_CID_W))
u_v2b_cnr (
    .clk(v2b_wr_clk), .rst_n(v2b_wr_rst_n),
    .run_active(seq_run_active),   // CHANGED (E3): was global_start (now a 1-cyc pulse); use sequencer run state
    .circuit_boundary(ppbuf_read_finished[0]),
    .bank_ready(v2b_all_ready),
    .next_start(seq_stb_start),
    .circuit_id(seq_circuit_id), .last_circuit_id(last_circuit_id),
    .cnr_reset(cnr_reset),
    .circuit_not_ready(circuit_not_ready), .wait_counter(cnr_wait_counter)
);


// ================================================================================================
// [stop] early stop: stop_en (rd_clk pulse) -> pulse_sync -> stop_ctrl (wr_clk); record strobe wr->rd.
// stop_cid is a quasi-static level (written before stop_en, held until the record is read): 2-FF.
// ================================================================================================
wire stop_en_w;
pulse_sync u_stop_en_sync (
    .src_clk(v2b_rd_clk), .src_rst_n(v2b_rd_rst_n), .src_pulse(stop_en),
    .dst_clk(v2b_wr_clk), .dst_rst_n(v2b_wr_rst_n), .dst_pulse(stop_en_w)
);
(* ASYNC_REG = "TRUE" *) reg [V2B_CID_W-1:0] stop_cid_m, stop_cid_w;
always @(posedge v2b_wr_clk or negedge v2b_wr_rst_n) begin
    if (!v2b_wr_rst_n) begin stop_cid_m <= {V2B_CID_W{1'b0}}; stop_cid_w <= {V2B_CID_W{1'b0}}; end
    else begin stop_cid_m <= stop_cid; stop_cid_w <= stop_cid_m; end
end
wire        stop_req_w, stop_rec_strobe_w;
wire [31:0] stop_rec_w0_w, stop_rec_w1_w, stop_rec_w2_w, stop_rec_w3_w;
stop_ctrl #(.CID_W(V2B_CID_W)) u_stop (
    .clk(v2b_wr_clk), .rst_n(v2b_wr_rst_n),
    .stop_en(stop_en_w), .stop_cid(stop_cid_w),
    .circuit_id(seq_circuit_id), .in_run(seq_in_run), .batch_end(seq_cid_reset_w),
    .lastshotdone(dspif.lastshotdone), .actualshots(dspif.actualshots), .stopped(dspif.stopped),
    .stopreq(stop_req_w),
    .rec_w0(stop_rec_w0_w), .rec_w1(stop_rec_w1_w), .rec_w2(stop_rec_w2_w), .rec_w3(stop_rec_w3_w),
    .rec_strobe(stop_rec_strobe_w)
);
assign dspif.stopreq = stop_req_w;
pulse_sync u_stop_rec_sync (
    .src_clk(v2b_wr_clk), .src_rst_n(v2b_wr_rst_n), .src_pulse(stop_rec_strobe_w),
    .dst_clk(v2b_rd_clk), .dst_rst_n(v2b_rd_rst_n), .dst_pulse(stop_rec_valid)
);
// record words: quasi-static bundled data (stable from the strobe until the next record) -> 2-FF into rd_clk
(* ASYNC_REG = "TRUE" *) reg [127:0] stop_rec_m, stop_rec_r;
always @(posedge v2b_rd_clk or negedge v2b_rd_rst_n) begin
    if (!v2b_rd_rst_n) begin stop_rec_m <= 128'd0; stop_rec_r <= 128'd0; end
    else begin stop_rec_m <= {stop_rec_w3_w, stop_rec_w2_w, stop_rec_w1_w, stop_rec_w0_w}; stop_rec_r <= stop_rec_m; end
end
assign {stop_rec_w3, stop_rec_w2, stop_rec_w1, stop_rec_w0} = stop_rec_r;

// accbuf tap -> data_tagger_top -> bundle ch_wr (wr_clk domain)
wire [V2B_NUM_CH-1:0]              ch_wr_en;
wire [V2B_NUM_CH*V2B_WR_DW-1:0]    ch_wr_data;
wire [V2B_NUM_CH*V2B_WR_DW-1:0]    tag_in;
wire [V2B_NUM_CH-1:0]              tag_in_en;
genvar gr;
generate for (gr=0; gr<V2B_NUM_CH; gr=gr+1) begin : g_acc
    assign tag_in[gr*V2B_WR_DW +: V2B_WR_DW] = dspif.data_qubit_accbuf[gr];
    assign tag_in_en[gr] = dspif.we_qubit_accbuf[gr];
end endgenerate
data_tagger_top #(.NUM_CH(V2B_NUM_CH))
u_v2b_tagger (.clk(v2b_wr_clk), .rst_n(v2b_wr_rst_n),
    .data_in(tag_in), .data_in_en(tag_in_en), .data_out(ch_wr_data), .data_out_en(ch_wr_en));

mmu_readout_cmd_top #(
    .NUM_CHANNELS(V2B_NUM_CH), .WR_DATA_WIDTH(V2B_WR_DW), .AXI_DATA_WIDTH(V2B_AXI_DW),
    .AXI_ADDR_WIDTH(V2B_AXI_AW), .AXI_ID_WIDTH(V2B_AXI_ID), .CBUF_ADDR_WIDTH(V2B_CBUF_AW),
    .CMD_WIDTH(V2B_CMD_W), .BEATS_PER_CHUNK(V2B_BPC), .MAX_BURST_LEN(V2B_BURST),
    .PPBUF_ADDR_WIDTH(V2B_PPBUF_AW), .NUM_UNITS(V2B_NUNITS), .CHUNK_PTR_WIDTH($clog2(V2B_NUNITS)),
    .CIRCUIT_ID_WIDTH(V2B_CID_W), .FETCH_DELAY(0)
) u_v2b_bundle (
    .wr_clk(v2b_wr_clk), .wr_rst_n(v2b_wr_rst_n), .rd_clk(v2b_rd_clk), .rd_rst_n(v2b_rd_rst_n),
    .max_bank_size(max_bank_size),
    .ch_wr_en(ch_wr_en), .ch_wr_data(ch_wr_data),
    .N_shot_finished(N_shot_finished), .readout_flush_ext(1'b0), .wr_base_addr(wr_base_addr),
    .config_fifo_full(),
    .circuit_id_reset(circuit_id_reset), .cid_count_reset(seq_cid_reset_w), .last_circuit_id(last_circuit_id), .current_circuit_id(current_circuit_id),
    .cmd_trigger(1'b0), .global_start(global_start), .circuit_started_wr(circuit_started),
    .n_shots(n_shots), .n_shots_enable(n_shots_enable), .ch_mask(ch_mask), .idle_load(idle_load), .idle_done(idle_done),
    .nshots_out(), .config_valid_out(),
    .nshots_staged_out(nshots_staged_out), .circuit_started(circuit_started),
    .final_addr(final_addr), .current_user_done(current_user_done), .cur_axi_addr_out(cur_axi_addr_out),
    .rd_start(rd_start), .rd_busy(rd_busy), .rd_done(rd_done),
    .rd_base_addr(rd_base_addr), .rd_size_bytes(rd_size_bytes),
    .m_axis_tdata(m_axis_tdata), .m_axis_tvalid(m_axis_tvalid), .m_axis_tready(m_axis_tready), .m_axis_tlast(m_axis_tlast),
    .m_axi_awid(m_axi_awid), .m_axi_awaddr(m_axi_awaddr), .m_axi_awlen(m_axi_awlen), .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst), .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
    .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb), .m_axi_wlast(m_axi_wlast), .m_axi_wvalid(m_axi_wvalid), .m_axi_wready(m_axi_wready),
    .m_axi_bid(m_axi_bid), .m_axi_bresp(m_axi_bresp), .m_axi_bvalid(m_axi_bvalid), .m_axi_bready(m_axi_bready),
    .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr), .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst), .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp), .m_axi_rlast(m_axi_rlast), .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
    .ppbuf_able_to_read(ppbuf_able_to_read), .ppbuf_rd_empty(ppbuf_rd_empty),
    .ppbuf_rd_addr_valid(ppbuf_rd_addr_valid), .ppbuf_rd_data(ppbuf_rd_data),
    .ppbuf_rd_addr(ppbuf_rd_addr), .ppbuf_rd_en(ppbuf_rd_en), .ppbuf_read_finished(ppbuf_read_finished),
    .cmd_m_axi_awid(cmd_m_axi_awid), .cmd_m_axi_awaddr(cmd_m_axi_awaddr), .cmd_m_axi_awlen(cmd_m_axi_awlen), .cmd_m_axi_awsize(cmd_m_axi_awsize),
    .cmd_m_axi_awburst(cmd_m_axi_awburst), .cmd_m_axi_awvalid(cmd_m_axi_awvalid), .cmd_m_axi_awready(cmd_m_axi_awready),
    .cmd_m_axi_wdata(cmd_m_axi_wdata), .cmd_m_axi_wstrb(cmd_m_axi_wstrb), .cmd_m_axi_wlast(cmd_m_axi_wlast), .cmd_m_axi_wvalid(cmd_m_axi_wvalid), .cmd_m_axi_wready(cmd_m_axi_wready),
    .cmd_m_axi_bid(cmd_m_axi_bid), .cmd_m_axi_bresp(cmd_m_axi_bresp), .cmd_m_axi_bvalid(cmd_m_axi_bvalid), .cmd_m_axi_bready(cmd_m_axi_bready),
    .cmd_m_axi_arid(cmd_m_axi_arid), .cmd_m_axi_araddr(cmd_m_axi_araddr), .cmd_m_axi_arlen(cmd_m_axi_arlen), .cmd_m_axi_arsize(cmd_m_axi_arsize),
    .cmd_m_axi_arburst(cmd_m_axi_arburst), .cmd_m_axi_arvalid(cmd_m_axi_arvalid), .cmd_m_axi_arready(cmd_m_axi_arready),
    .cmd_m_axi_rid(cmd_m_axi_rid), .cmd_m_axi_rdata(cmd_m_axi_rdata), .cmd_m_axi_rresp(cmd_m_axi_rresp), .cmd_m_axi_rlast(cmd_m_axi_rlast), .cmd_m_axi_rvalid(cmd_m_axi_rvalid), .cmd_m_axi_rready(cmd_m_axi_rready),
    .s_axis_cmd_tdata(s_axis_cmd_tdata), .s_axis_cmd_tvalid(s_axis_cmd_tvalid), .s_axis_cmd_tready(s_axis_cmd_tready),
    .cmd_fifo_empty(), .cmd_fifo_full(), .cmd_fetch_complete(), .cmd_switch_done()
);

endmodule
