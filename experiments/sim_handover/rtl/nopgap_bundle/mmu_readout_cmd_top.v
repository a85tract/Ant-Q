`timescale 1ns/1ps

// Combined Readout + Command Top Module
//
// Readout path: mmu_readout → readout DDR (AXI master #1)
// Command path: mmu_writedown → cmd DDR (AXI master #2)
//
// N_shot_finished (from external dsp aggregation) is CDC'd from
// wr_clk → rd_clk to trigger mmu_writedown's ppbuf switch.
// The cmd_consumer/dsp is external (instantiated in testbench).
//
// Simplified version (ring_buffer_simple): no channel enable (all
// channels always active), no stop mechanism, no actual_shots FIFO.

module mmu_readout_cmd_top #(
    parameter integer NUM_CHANNELS     = 4,
    parameter integer WR_DATA_WIDTH    = 64,
    parameter integer AXI_DATA_WIDTH   = 256,
    parameter integer AXI_ADDR_WIDTH   = 32,
    parameter integer AXI_ID_WIDTH     = 4,
    parameter integer CBUF_ADDR_WIDTH  = 4,
    parameter integer CMD_WIDTH        = 128,
    parameter integer BEATS_PER_CHUNK  = 1024,
    parameter integer MAX_BURST_LEN    = 256,
    parameter integer PPBUF_ADDR_WIDTH = 11,
    parameter integer NUM_UNITS        = 1024,
    parameter integer CHUNK_PTR_WIDTH  = 10,
    parameter integer CIRCUIT_ID_WIDTH = 31,
    parameter integer FETCH_DELAY      = 0
)(
    // ===== Clocks & Resets =====
    input  wire                        wr_clk,
    input  wire                        wr_rst_n,
    input  wire                        rd_clk,
    input  wire                        rd_rst_n,

    // ===== Configurable bank size (rd_clk domain, slow-changing) =====
    input  wire [CBUF_ADDR_WIDTH-1:0]                max_bank_size,

    // ===== Readout Write Channel Inputs (wr_clk domain) =====
    input  wire [NUM_CHANNELS-1:0]                   ch_wr_en,
    input  wire [(NUM_CHANNELS*WR_DATA_WIDTH)-1:0]   ch_wr_data,

    // ===== Readout Control (wr_clk domain) =====
    input  wire                        N_shot_finished,  // from external dsp aggregation
    input  wire                        readout_flush_ext,// PS-controlled flush (wr_clk domain)
    input  wire [AXI_ADDR_WIDTH-1:0]   wr_base_addr,

    // ===== FIFO full status (rd_clk domain) =====
    output wire                        config_fifo_full,

    // ===== Circuit ID tracking (wr_clk domain) =====
    input  wire                        circuit_id_reset,     // HOST run-setup pulse: resets circuit_id AND the
                                                             //   readout DDR write base (quiescent-only; see mmu_readout)
    input  wire                        cid_count_reset,      // RE-ARM pulse: resets ONLY circuit_id (NOT the readout
                                                             //   base) — used between batches by cmd_sequencer S_REARM
    input  wire [CIRCUIT_ID_WIDTH-1:0] last_circuit_id,      // PL auto-flushes readout after this circuit
    output wire [CIRCUIT_ID_WIDTH-1:0] current_circuit_id,

    // ===== Command Trigger (rd_clk domain) =====
    input  wire                        cmd_trigger,  // manual pre-fetch trigger
    input  wire                        global_start, // (legacy) no longer gates the fetch (FIX-A' pop-credit)
    input  wire                        circuit_started_wr, // FIX-A': sequencer stb_start (wr_clk) = config-pop credit

    // ===== N-shots FIFO input (rd_clk domain) =====
    input  wire [31:0]                 n_shots,
    input  wire                        n_shots_enable,
    input  wire [NUM_CHANNELS-1:0]     ch_mask,          // [CE] latched with n_shots_enable
    input  wire                        idle_load,        // [CE]
    output wire                        idle_done,        // [CE]

    // [no-pgap] production_gap_val/en removed (gap is program-controlled via a Delay instruction)

    // ===== CDC'd FIFO values output (wr_clk domain; LEGACY observability,
    //       no longer the DSP execution path since O1b) =====
    output wire [31:0]                 nshots_out,
    output wire                        config_valid_out,

    // ===== O1b staged config bus to external dsp_wrapper (quasi-static
    //       CDC contract, see dsp.v) + circuit-start event back from it =====
    output wire [31:0]                 nshots_staged_out,
    input  wire                        circuit_started,  // dsp_wrapper config_latched (wr_clk)

    // ===== Readout Status (rd_clk domain) =====
    output wire [AXI_ADDR_WIDTH-1:0]   final_addr,
    output wire                        current_user_done,
    output wire [AXI_ADDR_WIDTH-1:0]   cur_axi_addr_out,

    // ===== Readout Read-out (rd_clk domain) =====
    input  wire                        rd_start,
    output wire                        rd_busy,
    output wire                        rd_done,
    input  wire [AXI_ADDR_WIDTH-1:0]   rd_base_addr,
    input  wire [AXI_ADDR_WIDTH:0]     rd_size_bytes,

    // ===== Readout AXI-Stream master out (rd_clk domain) =====
    output wire [AXI_DATA_WIDTH-1:0]   m_axis_tdata,
    output wire                        m_axis_tvalid,
    input  wire                        m_axis_tready,
    output wire                        m_axis_tlast,

    // ===== Readout AXI4-Full Master (#1, rd_clk domain) =====
    output wire [AXI_ID_WIDTH-1:0]     m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]   m_axi_awaddr,
    output wire [7:0]                  m_axi_awlen,
    output wire [2:0]                  m_axi_awsize,
    output wire [1:0]                  m_axi_awburst,
    output wire                        m_axi_awvalid,
    input  wire                        m_axi_awready,

    output wire [AXI_DATA_WIDTH-1:0]   m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                        m_axi_wlast,
    output wire                        m_axi_wvalid,
    input  wire                        m_axi_wready,

    input  wire [AXI_ID_WIDTH-1:0]     m_axi_bid,
    input  wire [1:0]                  m_axi_bresp,
    input  wire                        m_axi_bvalid,
    output wire                        m_axi_bready,

    output wire [AXI_ID_WIDTH-1:0]     m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]   m_axi_araddr,
    output wire [7:0]                  m_axi_arlen,
    output wire [2:0]                  m_axi_arsize,
    output wire [1:0]                  m_axi_arburst,
    output wire                        m_axi_arvalid,
    input  wire                        m_axi_arready,

    input  wire [AXI_ID_WIDTH-1:0]     m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]   m_axi_rdata,
    input  wire [1:0]                  m_axi_rresp,
    input  wire                        m_axi_rlast,
    input  wire                        m_axi_rvalid,
    output wire                        m_axi_rready,

    // ===== Command AXI-Stream Input (rd_clk domain, 256-bit) =====
    input  wire [AXI_DATA_WIDTH-1:0]  s_axis_cmd_tdata,
    input  wire                       s_axis_cmd_tvalid,
    output wire                       s_axis_cmd_tready,

    // ===== ppbuf read-side: outputs to external dsp (wr_clk domain) =====
    output wire [NUM_CHANNELS-1:0]                          ppbuf_able_to_read,
    output wire [NUM_CHANNELS-1:0]                          ppbuf_rd_empty,
    output wire [NUM_CHANNELS*PPBUF_ADDR_WIDTH-1:0]         ppbuf_rd_addr_valid,
    output wire [NUM_CHANNELS*CMD_WIDTH-1:0]                ppbuf_rd_data,

    // ===== ppbuf read-side: inputs from external dsp (wr_clk domain) =====
    input  wire [NUM_CHANNELS*PPBUF_ADDR_WIDTH-1:0]         ppbuf_rd_addr,
    input  wire [NUM_CHANNELS-1:0]                          ppbuf_rd_en,
    input  wire [NUM_CHANNELS-1:0]                          ppbuf_read_finished,

    // ===== Command AXI4-Full Master (#2, rd_clk domain) =====
    output wire [AXI_ID_WIDTH-1:0]     cmd_m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]   cmd_m_axi_awaddr,
    output wire [7:0]                  cmd_m_axi_awlen,
    output wire [2:0]                  cmd_m_axi_awsize,
    output wire [1:0]                  cmd_m_axi_awburst,
    output wire                        cmd_m_axi_awvalid,
    input  wire                        cmd_m_axi_awready,

    output wire [AXI_DATA_WIDTH-1:0]   cmd_m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0] cmd_m_axi_wstrb,
    output wire                        cmd_m_axi_wlast,
    output wire                        cmd_m_axi_wvalid,
    input  wire                        cmd_m_axi_wready,

    input  wire [AXI_ID_WIDTH-1:0]     cmd_m_axi_bid,
    input  wire [1:0]                  cmd_m_axi_bresp,
    input  wire                        cmd_m_axi_bvalid,
    output wire                        cmd_m_axi_bready,

    output wire [AXI_ID_WIDTH-1:0]     cmd_m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]   cmd_m_axi_araddr,
    output wire [7:0]                  cmd_m_axi_arlen,
    output wire [2:0]                  cmd_m_axi_arsize,
    output wire [1:0]                  cmd_m_axi_arburst,
    output wire                        cmd_m_axi_arvalid,
    input  wire                        cmd_m_axi_arready,

    input  wire [AXI_ID_WIDTH-1:0]     cmd_m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]   cmd_m_axi_rdata,
    input  wire [1:0]                  cmd_m_axi_rresp,
    input  wire                        cmd_m_axi_rlast,
    input  wire                        cmd_m_axi_rvalid,
    output wire                        cmd_m_axi_rready,

    // ===== Debug =====
    output wire                        cmd_fifo_empty,
    output wire                        cmd_fifo_full,

    // ===== Command Handshake (rd_clk domain) =====
    output wire                        cmd_fetch_complete,
    output wire                        cmd_switch_done
);

    // ================================================================
    // 0. Circuit ID counter (wr_clk domain)
    //    O1b: increments on circuit_started (the DSP config-latch /
    //    bank-readable event) — the old config_valid_out pulse arrives
    //    too late now that DSPs start executing at the latch event.
    //    The increment strictly precedes the circuit's first readout
    //    word (latch -> ST_IDLE -> ST_CHECK(3) -> first ST_PRODUCE).
    //    PS can reset to 0 via circuit_id_reset pulse for a new experiment.
    // ================================================================
    reg [CIRCUIT_ID_WIDTH-1:0] circuit_id_reg;

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            circuit_id_reg <= {CIRCUIT_ID_WIDTH{1'b1}};  // -1: first increment wraps to 0
        else if (circuit_id_reset || cid_count_reset)
            circuit_id_reg <= {CIRCUIT_ID_WIDTH{1'b1}};  // reset: next increment wraps to 0
                                                         // (host run-setup OR per-batch re-arm; NEITHER touches base here)
        else if (circuit_started)
            circuit_id_reg <= circuit_id_reg + 1;
    end

    assign current_circuit_id = circuit_id_reg;

    // ================================================================
    // 0b. Readout flush (wr_clk domain)
    // Banks fill naturally across circuit boundaries. Readout flush
    // triggers only when the LAST circuit completes; mid-run circuits
    // rely on natural bank-fill seamless switching.
    // PS sets last_circuit_id before starting; PL auto-flushes when
    // circuit_id matches and N_shot_finished fires.
    // readout_flush_ext kept as PS fallback.
    // ================================================================
    wire last_circuit_done = N_shot_finished &
                             (circuit_id_reg == last_circuit_id);
    wire readout_flush = last_circuit_done | readout_flush_ext;

    // ================================================================
    // 1. Readout Path: mmu_readout
    // ================================================================
    mmu_readout #(
        .NUM_CHANNELS    (NUM_CHANNELS),
        .WR_DATA_WIDTH   (WR_DATA_WIDTH),
        .AXI_DATA_WIDTH  (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH    (AXI_ID_WIDTH),
        .CBUF_ADDR_WIDTH (CBUF_ADDR_WIDTH)
    ) u_readout (
        .wr_clk           (wr_clk),
        .wr_rst_n         (wr_rst_n),
        .rd_clk           (rd_clk),
        .rd_rst_n         (rd_rst_n),
        .ch_wr_en         (ch_wr_en),
        .ch_wr_data       (ch_wr_data),
        .max_bank_size    (max_bank_size),
        .N_shot_finished  (readout_flush),
        .wr_base_addr     (wr_base_addr),
        .circuit_id_reset (circuit_id_reset),  // round 10: also resets readout base
        .final_addr       (final_addr),
        .current_user_done(current_user_done),
        .cur_axi_addr_out (cur_axi_addr_out),
        .rd_start         (rd_start),
        .rd_busy          (rd_busy),
        .rd_done          (rd_done),
        .rd_base_addr     (rd_base_addr),
        .rd_size_bytes    (rd_size_bytes),
        .m_axis_tdata     (m_axis_tdata),
        .m_axis_tvalid    (m_axis_tvalid),
        .m_axis_tready    (m_axis_tready),
        .m_axis_tlast     (m_axis_tlast),
        .m_axi_awid       (m_axi_awid),
        .m_axi_awaddr     (m_axi_awaddr),
        .m_axi_awlen      (m_axi_awlen),
        .m_axi_awsize     (m_axi_awsize),
        .m_axi_awburst    (m_axi_awburst),
        .m_axi_awvalid    (m_axi_awvalid),
        .m_axi_awready    (m_axi_awready),
        .m_axi_wdata      (m_axi_wdata),
        .m_axi_wstrb      (m_axi_wstrb),
        .m_axi_wlast      (m_axi_wlast),
        .m_axi_wvalid     (m_axi_wvalid),
        .m_axi_wready     (m_axi_wready),
        .m_axi_bid        (m_axi_bid),
        .m_axi_bresp      (m_axi_bresp),
        .m_axi_bvalid     (m_axi_bvalid),
        .m_axi_bready     (m_axi_bready),
        .m_axi_arid       (m_axi_arid),
        .m_axi_araddr     (m_axi_araddr),
        .m_axi_arlen      (m_axi_arlen),
        .m_axi_arsize     (m_axi_arsize),
        .m_axi_arburst    (m_axi_arburst),
        .m_axi_arvalid    (m_axi_arvalid),
        .m_axi_arready    (m_axi_arready),
        .m_axi_rid        (m_axi_rid),
        .m_axi_rdata      (m_axi_rdata),
        .m_axi_rresp      (m_axi_rresp),
        .m_axi_rlast      (m_axi_rlast),
        .m_axi_rvalid     (m_axi_rvalid),
        .m_axi_rready     (m_axi_rready)
    );

    // ================================================================
    // 2. CDC: N_shot_finished (wr_clk → rd_clk)
    // ================================================================
    wire n_shot_rd;

    pulse_sync u_sync_nshot (
        .src_clk   (wr_clk),
        .src_rst_n (wr_rst_n),
        .src_pulse (N_shot_finished),
        .dst_clk   (rd_clk),
        .dst_rst_n (rd_rst_n),
        .dst_pulse (n_shot_rd)
    );

    wire trigger_switch = n_shot_rd | cmd_trigger;

    // ================================================================
    // 4. Command Path: mmu_writedown
    // ================================================================
    mmu_writedown #(
        .NUM_CMD_CHANNELS  (NUM_CHANNELS),
        .CMD_WIDTH         (CMD_WIDTH),
        .AXI_DATA_WIDTH    (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH    (AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH      (AXI_ID_WIDTH),
        .BEATS_PER_CHUNK   (BEATS_PER_CHUNK),
        .MAX_BURST_LEN     (MAX_BURST_LEN),
        .PPBUF_ADDR_WIDTH  (PPBUF_ADDR_WIDTH),
        .NUM_UNITS         (NUM_UNITS),
        .CHUNK_PTR_WIDTH   (CHUNK_PTR_WIDTH),
        .FETCH_DELAY       (FETCH_DELAY)
    ) u_cmd (
        .wr_clk            (wr_clk),
        .wr_rst_n          (wr_rst_n),
        .rd_clk            (rd_clk),
        .rd_rst_n          (rd_rst_n),
        .trigger_switch    (trigger_switch),
        .global_start      (global_start),
        .circuit_started_wr(circuit_started_wr),
        .config_fifo_full  (config_fifo_full),
        .n_shots           (n_shots),
        .n_shots_enable    (n_shots_enable),
        .ch_mask           (ch_mask),
        .idle_load         (idle_load),
        .idle_done         (idle_done),
        .nshots_out        (nshots_out),
        .config_valid_out  (config_valid_out),
        .nshots_staged_out (nshots_staged_out),
        .s_axis_tdata      (s_axis_cmd_tdata),
        .s_axis_tvalid     (s_axis_cmd_tvalid),
        .s_axis_tready     (s_axis_cmd_tready),
        // ppbuf read-side pass-through
        .ppbuf_able_to_read (ppbuf_able_to_read),
        .ppbuf_rd_empty     (ppbuf_rd_empty),
        .ppbuf_rd_addr_valid(ppbuf_rd_addr_valid),
        .ppbuf_rd_data      (ppbuf_rd_data),
        .ppbuf_rd_addr      (ppbuf_rd_addr),
        .ppbuf_rd_en        (ppbuf_rd_en),
        .ppbuf_read_finished(ppbuf_read_finished),
        // AXI
        .m_axi_awid      (cmd_m_axi_awid),
        .m_axi_awaddr    (cmd_m_axi_awaddr),
        .m_axi_awlen     (cmd_m_axi_awlen),
        .m_axi_awsize    (cmd_m_axi_awsize),
        .m_axi_awburst   (cmd_m_axi_awburst),
        .m_axi_awvalid   (cmd_m_axi_awvalid),
        .m_axi_awready   (cmd_m_axi_awready),
        .m_axi_wdata     (cmd_m_axi_wdata),
        .m_axi_wstrb     (cmd_m_axi_wstrb),
        .m_axi_wlast     (cmd_m_axi_wlast),
        .m_axi_wvalid    (cmd_m_axi_wvalid),
        .m_axi_wready    (cmd_m_axi_wready),
        .m_axi_bid       (cmd_m_axi_bid),
        .m_axi_bresp     (cmd_m_axi_bresp),
        .m_axi_bvalid    (cmd_m_axi_bvalid),
        .m_axi_bready    (cmd_m_axi_bready),
        .m_axi_arid      (cmd_m_axi_arid),
        .m_axi_araddr    (cmd_m_axi_araddr),
        .m_axi_arlen     (cmd_m_axi_arlen),
        .m_axi_arsize    (cmd_m_axi_arsize),
        .m_axi_arburst   (cmd_m_axi_arburst),
        .m_axi_arvalid   (cmd_m_axi_arvalid),
        .m_axi_arready   (cmd_m_axi_arready),
        .m_axi_rid       (cmd_m_axi_rid),
        .m_axi_rdata     (cmd_m_axi_rdata),
        .m_axi_rresp     (cmd_m_axi_rresp),
        .m_axi_rlast     (cmd_m_axi_rlast),
        .m_axi_rvalid    (cmd_m_axi_rvalid),
        .m_axi_rready    (cmd_m_axi_rready),
        .fifo_empty      (cmd_fifo_empty),
        .fifo_full       (cmd_fifo_full),
        .fetch_complete  (cmd_fetch_complete),
        .switch_done     (cmd_switch_done)
    );

endmodule
