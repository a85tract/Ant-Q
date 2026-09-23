`timescale 1ns/1ps

// mmu_writedown.v
//
// N-channel command writedown engine with shared DDR ring buffer.
// Each "unit" = NUM_CMD_CHANNELS consecutive chunks (one per qubit).
// Write path: single AXI-Stream → stream_cmd_writer → DDR write port
// Read path:  AXI read sequencer (ch0→ch1→...→chN-1) → Nx chunk_fetcher → Nx ppbuf
// The cmd_consumer (dsp) is now external (instantiated in testbench).
// ppbuf read-side ports are exposed for external dsp connection.
//
// Simplified version (ring_buffer_simple): no channel enable — all
// NUM_CMD_CHANNELS channels are always written/fetched. Unused qubits
// get zero-filled command chunks from the host.

module mmu_writedown #(
    parameter integer NUM_CMD_CHANNELS  = 4,
    parameter integer CMD_WIDTH         = 128,
    parameter integer AXI_DATA_WIDTH    = 256,
    parameter integer AXI_ADDR_WIDTH    = 32,
    parameter integer AXI_ID_WIDTH      = 4,
    parameter integer BEATS_PER_CHUNK   = 1024,
    parameter integer MAX_BURST_LEN     = 256,
    parameter integer PPBUF_ADDR_WIDTH  = 11,
    parameter integer NUM_UNITS         = 1024,
    parameter integer CHUNK_PTR_WIDTH   = 10,     // $clog2(NUM_UNITS)
    parameter integer FETCH_DELAY       = 0,
    parameter integer SHORT_BEATS       = 8       // [CE] beats fetched for a masked channel
)(
    // Clocks & Resets
    input  wire                        wr_clk,
    input  wire                        wr_rst_n,
    input  wire                        rd_clk,
    input  wire                        rd_rst_n,

    // Control (rd_clk domain)
    input  wire                        trigger_switch,
    input  wire                        global_start,      // (legacy) no longer gates the fetch; kept for compat
    // FIX-A' (2026-06-30, pulse-trigger redesign): the DDR->ppbuf prefill is DECOUPLED from global_start. The
    // FIRST config pop is unconditional (prefill circuit0 before the pulse); each SUBSEQUENT pop needs one
    // "credit" from the sequencer's stb_start (= circuit_started_wr, wr_clk pulse) — proving the current circuit's
    // n_shots was already latched (cmd_sequencer latches nshot at S_WAIT, BEFORE stb_start) so raw nshots_staged
    // never advances past what the sequencer has sampled. Preserves one-bank-ahead overlap; closes the config race.
    input  wire                        circuit_started_wr,

    // FIFO full status (rd_clk domain)
    output wire                        config_fifo_full,

    // N-shots FIFO input (rd_clk domain)
    input  wire [31:0]                 n_shots,
    input  wire                        n_shots_enable,
    input  wire [NUM_CMD_CHANNELS-1:0] ch_mask,        // [CE] per-circuit: 1 = channel unused (not uploaded; fetched from the idle slot), latched with n_shots
    input  wire                        idle_load,      // [CE] level: incoming s_axis beats are the batch's idle program
    output wire                        idle_done,      // [CE] pulse: idle program written to the idle slot

    // [no-pgap] production_gap_val/en removed: the inter-circuit gap is program-controlled (a Delay instruction
    // at the head of each command), so the pgap config FIFO is redundant. See nopgap_bundle/README.

    // CDC'd FIFO values output (wr_clk domain; LEGACY observability only —
    // since O1b the DSPs no longer consume this pulse path)
    output wire [31:0]                 nshots_out,
    output wire                        config_valid_out,  // pulse in wr_clk when n_shots is valid

    // O1b quasi-static staged config bus (rd-domain registers exported
    // raw; CDC contract documented in dsp.v: stable from before the
    // unit's fetch until after the DSP's bank-readable latch event —
    // staging only advances at the controller's NEXT pop)
    output wire [31:0]                 nshots_staged_out,

    // AXI-Stream CMD input (rd_clk domain, 256-bit, 2 cmds per beat)
    input  wire [AXI_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                       s_axis_tvalid,
    output wire                       s_axis_tready,

    // ppbuf read-side: outputs to external dsp (wr_clk domain)
    output wire [NUM_CMD_CHANNELS-1:0]                          ppbuf_able_to_read,
    output wire [NUM_CMD_CHANNELS-1:0]                          ppbuf_rd_empty,
    output wire [NUM_CMD_CHANNELS*PPBUF_ADDR_WIDTH-1:0]         ppbuf_rd_addr_valid,
    output wire [NUM_CMD_CHANNELS*CMD_WIDTH-1:0]                ppbuf_rd_data,

    // ppbuf read-side: inputs from external dsp (wr_clk domain)
    input  wire [NUM_CMD_CHANNELS*PPBUF_ADDR_WIDTH-1:0]         ppbuf_rd_addr,
    input  wire [NUM_CMD_CHANNELS-1:0]                          ppbuf_rd_en,
    input  wire [NUM_CMD_CHANNELS-1:0]                          ppbuf_read_finished,

    // AXI4-Full Master Interface (rd_clk domain, single port → external cmd DDR)
    // Write Address Channel
    output wire [AXI_ID_WIDTH-1:0]     m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]   m_axi_awaddr,
    output wire [7:0]                  m_axi_awlen,
    output wire [2:0]                  m_axi_awsize,
    output wire [1:0]                  m_axi_awburst,
    output wire                        m_axi_awvalid,
    input  wire                        m_axi_awready,

    // Write Data Channel
    output wire [AXI_DATA_WIDTH-1:0]   m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                        m_axi_wlast,
    output wire                        m_axi_wvalid,
    input  wire                        m_axi_wready,

    // Write Response Channel
    input  wire [AXI_ID_WIDTH-1:0]     m_axi_bid,
    input  wire [1:0]                  m_axi_bresp,
    input  wire                        m_axi_bvalid,
    output wire                        m_axi_bready,

    // Read Address Channel
    output wire [AXI_ID_WIDTH-1:0]     m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]   m_axi_araddr,
    output wire [7:0]                  m_axi_arlen,
    output wire [2:0]                  m_axi_arsize,
    output wire [1:0]                  m_axi_arburst,
    output wire                        m_axi_arvalid,
    input  wire                        m_axi_arready,

    // Read Data Channel
    input  wire [AXI_ID_WIDTH-1:0]     m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]   m_axi_rdata,
    input  wire [1:0]                  m_axi_rresp,
    input  wire                        m_axi_rlast,
    input  wire                        m_axi_rvalid,
    output wire                        m_axi_rready,

    // Debug / Status
    output wire                        fifo_empty,
    output wire                        fifo_full,

    // Handshake outputs
    output wire                        fetch_complete,  // level: high after all 4 fetchers done
    output wire                        switch_done      // level: high after all 4 ppbufs switched
);

    // ================================================================
    // Local parameters
    // ================================================================
    // derived (Codex #79): per-channel chunk region = BEATS_PER_CHUNK beats
    // x AXI_DATA_WIDTH/8 bytes (1024 x 32B = 32KB -> 15). Never hardcode.
    localparam integer PER_CH_OFFSET_LSB = $clog2(BEATS_PER_CHUNK * (AXI_DATA_WIDTH / 8));
    localparam integer BYTES_PER_BEAT    = AXI_DATA_WIDTH / 8;
    localparam integer NUM_CH_ALIGNED_BITS = $clog2(NUM_CMD_CHANNELS);
    localparam integer CHUNK_ADDR_LSB      = PER_CH_OFFSET_LSB + NUM_CH_ALIGNED_BITS;
    localparam integer CH_IDX_W            = (NUM_CMD_CHANNELS > 1) ? $clog2(NUM_CMD_CHANNELS) : 1;

    // ================================================================
    // 0a. N-shots Sync FIFO (rd_clk domain, depth=NUM_UNITS, width=32)
    //     Written by PS via n_shots/n_shots_enable.
    //     Popped by ctrl FSM when entering CTRL_FETCH.
    //     CDC'd to wr_clk domain for external dsp use.
    // ================================================================
    // Round 6b-1 (Codex #51): storage moved into sync_fifo_bram
    // (synchronous BRAM read). Pop semantics: pop accepted in cycle N
    // (CTRL_POP_WAIT) -> dout_valid pulses in cycle N+1 (CTRL_POP_SETTLE)
    // -> staging register captures at the END of N+1 -> staged value
    // visible from CTRL_FETCH on. It is not CONSUMED until
    // ctrl_nshots_apply (CTRL_SWITCH completion, thousands of cycles
    // later), so the +1 read latency is fully absorbed by the existing
    // FSM states. A pop while empty is ignored by the FIFO (no
    // dout_valid, staging keeps its old value) - identical to the old
    // inline guard's behavior.
    wire        nshots_fifo_empty;
    wire        nshots_fifo_full;
    wire [31:0] nshots_dout;
    wire [NUM_CMD_CHANNELS-1:0] chmask_dout;   // [CE]
    reg  [NUM_CMD_CHANNELS-1:0] chmask_staged_rd;   // [CE] mask of the unit being fetched (visible from CTRL_FETCH)
    wire        nshots_dout_valid;

    reg ctrl_nshots_pop;     // pop request (CTRL_IDLE exit, 1-cycle pulse)
    reg ctrl_nshots_apply;   // apply staged value (at switch completion)
    reg [31:0] nshots_staged_rd;   // staging register (rd_clk)
    reg [31:0] nshots_current_rd;  // active n_shots value in rd_clk domain

    sync_fifo_bram #(
        .WIDTH (32 + NUM_CMD_CHANNELS),   // [CE] {ch_mask, n_shots}
        .DEPTH (NUM_UNITS),
        .PTRW  (CHUNK_PTR_WIDTH)
    ) u_nshots_fifo (
        .clk        (rd_clk),
        .rst_n      (rd_rst_n),
        .push       (n_shots_enable),
        .din        ({ch_mask, n_shots}),
        .pop        (ctrl_nshots_pop),
        .dout       ({chmask_dout, nshots_dout}),
        .dout_valid (nshots_dout_valid),
        .empty      (nshots_fifo_empty),
        .full       (nshots_fifo_full)
    );

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            nshots_staged_rd   <= 32'd0;
            chmask_staged_rd   <= {NUM_CMD_CHANNELS{1'b0}};
            nshots_current_rd  <= 32'd0;
        end else begin
            // capture the popped word one cycle after the accepted pop
            if (nshots_dout_valid) begin
                nshots_staged_rd <= nshots_dout;
                chmask_staged_rd <= chmask_dout;   // [CE]
            end
            // Apply staged value to active register (at switch completion)
            if (ctrl_nshots_apply)
                nshots_current_rd <= nshots_staged_rd;
        end
    end

    // CDC: n_shots from rd_clk → wr_clk
    reg [31:0] nshots_wr;            // stable n_shots in wr_clk domain
    reg        nshots_update_rd;     // pulse in rd_clk when active value changes
    wire       nshots_update_wr;     // pulse in wr_clk after CDC

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            nshots_update_rd <= 1'b0;
        else
            nshots_update_rd <= ctrl_nshots_apply;
    end

    pulse_sync u_nshots_cdc (
        .src_clk   (rd_clk),
        .src_rst_n (rd_rst_n),
        .src_pulse (nshots_update_rd),
        .dst_clk   (wr_clk),
        .dst_rst_n (wr_rst_n),
        .dst_pulse (nshots_update_wr)
    );

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            nshots_wr <= 32'd0;
        else if (nshots_update_wr)
            nshots_wr <= nshots_current_rd;  // safe: stable for thousands of cycles
    end

    assign nshots_out = nshots_wr;
    assign config_valid_out = nshots_update_wr;
    assign nshots_staged_out = nshots_staged_rd;

    // ================================================================
    // FIX-A' pop-credit (rd_clk domain): decouple prefill from global_start without the config race.
    //   credit starts at 1 (the FIRST pop of a run/batch is free -> circuit0 prefills before the pulse);
    //   +1 per synced circuit_started (sequencer stb_start = current n_shots latched);
    //   -1 per config pop (ctrl_nshots_pop). CTRL_IDLE only pops when credit != 0.
    //   Strictly alternates pop/stb_start so credit stays in {0,1}; a few bits + saturation guard CDC jitter.
    //   After a batch (N pops, N stb_starts) credit returns to 1 -> next batch's circuit0 pop is free too.
    wire circuit_started_rd;
    pulse_sync u_circ_started_cdc (
        .src_clk (wr_clk), .src_rst_n (wr_rst_n), .src_pulse (circuit_started_wr),
        .dst_clk (rd_clk), .dst_rst_n (rd_rst_n), .dst_pulse (circuit_started_rd)
    );
    reg [3:0] pop_credit;
    wire      pop_credit_avail = (pop_credit != 4'd0);
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            pop_credit <= 4'd1;                       // first pop free
        end else begin
            case ({circuit_started_rd, ctrl_nshots_pop})
                2'b10: if (pop_credit != 4'hF) pop_credit <= pop_credit + 4'd1;
                2'b01: if (pop_credit != 4'd0) pop_credit <= pop_credit - 4'd1;
                default: ;                            // both or neither: net zero
            endcase
        end
    end

    // [no-pgap] the entire Production-gap Sync FIFO + staging + rd->wr CDC was removed here: the inter-circuit
    // gap is program-controlled (a Delay instruction heading each command), so pgap is redundant.

    // FIFO full status output
    assign config_fifo_full = nshots_fifo_full;

    // synthesis translate_off
    // 6b-1 pairing assertions (Codex #51): the two config FIFOs are always
    // pushed and popped as a pair; every apply must consume a FRESH staged
    // pair (a capture must have occurred since the previous apply).
    reg assert_staged_fresh;
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            assert_staged_fresh <= 1'b0;
        end else begin
            if (ctrl_nshots_apply && !assert_staged_fresh) begin
                $display("[ASSERT-FAIL] apply with STALE staging (apply before dout_valid capture) t=%0t", $time);
                $fatal(1);
            end
            if (nshots_dout_valid)      assert_staged_fresh <= 1'b1;
            else if (ctrl_nshots_apply) assert_staged_fresh <= 1'b0;
            // Fix B (Codex #77): pop-while-empty is now ILLEGAL by
            // construction (Fix A gates CTRL_IDLE on config presence).
            // Any occurrence is a design-contract violation -> fatal.
            if (ctrl_nshots_pop && nshots_fifo_empty) begin
                $display("[ASSERT-FAIL] config FIFO pop while EMPTY (stale staging hazard) t=%0t", $time);
                $fatal(1);
            end
        end
    end
    // synthesis translate_on

    // ================================================================
    // 1. DDR Chunk FIFO Controller (shared, 8 units)
    // ================================================================
    wire [AXI_ADDR_WIDTH-1:0] wr_unit_addr;
    wire [AXI_ADDR_WIDTH-1:0] rd_unit_addr;
    wire                      ddr_fifo_empty;
    wire                      ddr_fifo_full;
    wire                      unit_wr_done;
    wire                      unit_rd_done;

    assign fifo_empty = ddr_fifo_empty;
    assign fifo_full  = ddr_fifo_full;

    ring_buffer_4chunk_ddr #(
        .CHUNK_PTR_WIDTH (CHUNK_PTR_WIDTH),
        .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
        .CHUNK_ADDR_LSB  (CHUNK_ADDR_LSB)
    ) u_fifo_ctrl (
        .clk            (rd_clk),
        .rst_n          (rd_rst_n),
        .wr_chunk_done  (unit_wr_done),
        .rd_chunk_done  (unit_rd_done),
        .base_addr      ({AXI_ADDR_WIDTH{1'b0}}),
        .wr_chunk_addr  (wr_unit_addr),
        .rd_chunk_addr  (rd_unit_addr),
        .fifo_empty     (ddr_fifo_empty),
        .fifo_full      (ddr_fifo_full)
    );

    // ================================================================
    // 1b. [CE] Idle slot + writer mask FIFO.
    //     IDLE_SLOT_ADDR = first byte after the NUM_UNITS ring (board: 1024 x 256 KiB = 0x1000_0000).
    //     The writer mask FIFO is pushed by the SAME n_shots_enable as the config entry and popped one
    //     unit ahead (config-before-image contract): masked channels are skipped by the writer and the
    //     fetcher reads their SHORT_BEATS from the idle slot instead of the unit.
    // ================================================================
    localparam [AXI_ADDR_WIDTH-1:0] IDLE_SLOT_ADDR = NUM_UNITS << CHUNK_ADDR_LSB;
    wire                        wr_mask_empty, wr_mask_full, wr_mask_dv;
    wire [NUM_CMD_CHANNELS-1:0] wr_mask_dout;
    reg  [NUM_CMD_CHANNELS-1:0] writer_mask_cur;
    reg                         writer_mask_loaded, writer_mask_pop;
    sync_fifo_bram #(.WIDTH(NUM_CMD_CHANNELS), .DEPTH(NUM_UNITS), .PTRW(CHUNK_PTR_WIDTH)) u_wr_mask_fifo (
        .clk(rd_clk), .rst_n(rd_rst_n), .push(n_shots_enable), .din(ch_mask), .pop(writer_mask_pop),
        .dout(wr_mask_dout), .dout_valid(wr_mask_dv), .empty(wr_mask_empty), .full(wr_mask_full));
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            writer_mask_cur <= {NUM_CMD_CHANNELS{1'b0}}; writer_mask_loaded <= 1'b0; writer_mask_pop <= 1'b0;
        end else begin
            writer_mask_pop <= 1'b0;
            if (unit_wr_done)                                   writer_mask_loaded <= 1'b0;
            else if (wr_mask_dv) begin writer_mask_cur <= wr_mask_dout; writer_mask_loaded <= 1'b1; end
            else if (!writer_mask_loaded && !wr_mask_empty && !writer_mask_pop) writer_mask_pop <= 1'b1;
        end
    end
    // ================================================================
    // 2. Stream CMD Writer (AXI-Stream → DDR write)
    // ================================================================
    stream_cmd_writer #(
        .AXI_DATA_WIDTH  (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH    (AXI_ID_WIDTH),
        .NUM_CHANNELS    (NUM_CMD_CHANNELS),
        .BEATS_PER_CHUNK (BEATS_PER_CHUNK),
        .MAX_BURST_LEN   (MAX_BURST_LEN),
        .SHORT_BEATS     (SHORT_BEATS)
    ) u_stream_writer (
        .clk            (rd_clk),
        .rst_n          (rd_rst_n),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        .unit_addr      (wr_unit_addr),
        .fifo_full      (ddr_fifo_full),
        .ch_mask        (writer_mask_cur),
        .mask_ready     (writer_mask_loaded),
        .idle_load      (idle_load),
        .idle_addr      (IDLE_SLOT_ADDR),
        .idle_done      (idle_done),
        .unit_done      (unit_wr_done),
        .m_axi_awid     (m_axi_awid),
        .m_axi_awaddr   (m_axi_awaddr),
        .m_axi_awlen    (m_axi_awlen),
        .m_axi_awsize   (m_axi_awsize),
        .m_axi_awburst  (m_axi_awburst),
        .m_axi_awvalid  (m_axi_awvalid),
        .m_axi_awready  (m_axi_awready),
        .m_axi_wdata    (m_axi_wdata),
        .m_axi_wstrb    (m_axi_wstrb),
        .m_axi_wlast    (m_axi_wlast),
        .m_axi_wvalid   (m_axi_wvalid),
        .m_axi_wready   (m_axi_wready),
        .m_axi_bid      (m_axi_bid),
        .m_axi_bresp    (m_axi_bresp),
        .m_axi_bvalid   (m_axi_bvalid),
        .m_axi_bready   (m_axi_bready)
    );

    // ================================================================
    // 3. Fetch Done Latch (per-channel → all_fetch_done)
    // ================================================================
    wire [NUM_CMD_CHANNELS-1:0] cf_chunk_done;
    reg  [NUM_CMD_CHANNELS-1:0] rd_done_latch;
    wire                        all_fetch_done = &rd_done_latch;

    assign unit_rd_done = all_fetch_done;

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            rd_done_latch <= {NUM_CMD_CHANNELS{1'b0}};
        else if (all_fetch_done)
            rd_done_latch <= {NUM_CMD_CHANNELS{1'b0}};
        else
            rd_done_latch <= rd_done_latch | cf_chunk_done;
    end

    // ================================================================
    // 4. Switch-Done Detection
    //    Detect ppbuf bank flip by falling edge of write_finished_out.
    //    ppbuf_switch_detect[c] assigned inside generate block.
    // ================================================================
    wire [NUM_CMD_CHANNELS-1:0] ppbuf_switch_detect;
    reg  [NUM_CMD_CHANNELS-1:0] switch_done_latch;
    // All ppbufs must complete the swap (do_ppbuf_switch is broadcast to all).
    // All DSPs sent read_finished for the previous circuit, so all ppbufs swap.
    wire                        all_switch_done = &switch_done_latch;

    // ctrl_state declared below (forward reference for latch gating)
    localparam [2:0] CTRL_IDLE       = 3'd0,
                     CTRL_POP_WAIT   = 3'd1,  // FIFO pop fires; staging regs updating
                     CTRL_POP_SETTLE = 3'd2,  // staging settled; init rd_chan
                     CTRL_FETCH      = 3'd3,
                     CTRL_SWITCH     = 3'd4;
    reg [2:0] ctrl_state;

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            switch_done_latch <= {NUM_CMD_CHANNELS{1'b0}};
        else if (ctrl_state == CTRL_SWITCH)
            switch_done_latch <= switch_done_latch | ppbuf_switch_detect;
        else
            switch_done_latch <= {NUM_CMD_CHANNELS{1'b0}};
    end

    // ================================================================
    // 5. Switch Request Counter
    //    +1 on trigger_switch, -1 when switch completes
    // ================================================================
    reg [7:0] switch_req_cnt;

    wire req_consumed = (ctrl_state == CTRL_SWITCH) && all_switch_done;

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            switch_req_cnt <= 8'd0;
        end else begin
            case ({trigger_switch, req_consumed})
                2'b10: switch_req_cnt <= switch_req_cnt + 8'd1;
                2'b01: begin
                    if (switch_req_cnt > 8'd0)
                        switch_req_cnt <= switch_req_cnt - 8'd1;
                end
                default: ;
            endcase
        end
    end

    // ================================================================
    // 6. Speculative Pre-Fetch / Switch Control + Read Sequencer
    // ================================================================
    reg        fetch_complete_reg;
    reg        switch_done_reg;
    reg        do_ppbuf_switch;
    reg        first_fetch_started;
    reg [CH_IDX_W-1:0] rd_chan;
    reg        rd_seq_active;
    // (did_fetch removed: shortcut path eliminated, CTRL_SWITCH always follows CTRL_FETCH)

    assign fetch_complete = fetch_complete_reg;
    assign switch_done    = switch_done_reg;

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            ctrl_state          <= CTRL_IDLE;
            fetch_complete_reg  <= 1'b0;
            switch_done_reg     <= 1'b0;
            do_ppbuf_switch     <= 1'b0;
            ctrl_nshots_pop     <= 1'b0;
            ctrl_nshots_apply   <= 1'b0;
            first_fetch_started <= 1'b0;
            rd_chan              <= {CH_IDX_W{1'b0}};
            rd_seq_active       <= 1'b0;
        end else begin
            do_ppbuf_switch   <= 1'b0;
            ctrl_nshots_pop   <= 1'b0;
            ctrl_nshots_apply <= 1'b0;

            case (ctrl_state)
                // --------------------------------------------------
                CTRL_IDLE: begin
                    // Fix A (Codex #77): a unit may only be fetched when its
                    // CONFIG PAIR is already present. Starting on cmd data
                    // alone popped an EMPTY config FIFO (ignored), and the
                    // bank switch then applied the STALE staging pair
                    // (power-on 0/0) to the DSPs - n_shots=0 caused
                    // unbounded production on the board (Phase 3C FAIL).
                    if (!ddr_fifo_empty && !nshots_fifo_empty && pop_credit_avail) begin   // FIX-A': credit, was global_start
                        first_fetch_started <= 1'b1;
                        fetch_complete_reg  <= 1'b0;
                        switch_done_reg     <= 1'b0;
                        ctrl_nshots_pop     <= 1'b1;
                        ctrl_state          <= CTRL_POP_WAIT;
                    end
                end

                // --------------------------------------------------
                // Pop pulse is high THIS cycle: sync_fifo_bram accepts it
                // (pointer moves; BRAM read registers internally).
                CTRL_POP_WAIT: begin
                    ctrl_state <= CTRL_POP_SETTLE;
                end

                // --------------------------------------------------
                // dout_valid pulses THIS cycle; staging regs capture at the
                // end of it (visible from CTRL_FETCH). The staged pair is
                // consumed only at ctrl_*_apply (CTRL_SWITCH completion).
                CTRL_POP_SETTLE: begin
                    rd_seq_active <= 1'b1;
                    rd_chan       <= {CH_IDX_W{1'b0}};
                    ctrl_state   <= CTRL_FETCH;
                end

                // --------------------------------------------------
                CTRL_FETCH: begin
                    if (rd_seq_active && cf_chunk_done[rd_chan]) begin
                        if (rd_chan == NUM_CMD_CHANNELS - 1) begin
                            rd_seq_active <= 1'b0;
                            rd_chan       <= {CH_IDX_W{1'b0}};
                        end else begin
                            rd_chan <= rd_chan + 1'b1;
                        end
                    end

                    if (all_fetch_done)
                        fetch_complete_reg <= 1'b1;

                    // With global_start prefill, no need to wait for trigger_switch.
                    // CTRL_SWITCH blocks on all_switch_done (DSP read_finished),
                    // which provides natural backpressure.
                    if (all_fetch_done || fetch_complete_reg) begin
                        do_ppbuf_switch <= 1'b1;
                        ctrl_state      <= CTRL_SWITCH;
                    end
                end

                // --------------------------------------------------
                CTRL_SWITCH: begin
                    if (all_switch_done) begin
                        switch_done_reg   <= 1'b1;
                        ctrl_nshots_apply <= 1'b1;
                        ctrl_state        <= CTRL_IDLE;
                    end
                end

                default: ctrl_state <= CTRL_IDLE;
            endcase
        end
    end

    // ================================================================
    // 7. AXI Read Sequencer Mux/Demux
    // ================================================================
    wire [AXI_ID_WIDTH-1:0]   cf_arid    [0:NUM_CMD_CHANNELS-1];
    wire [AXI_ADDR_WIDTH-1:0] cf_araddr  [0:NUM_CMD_CHANNELS-1];
    wire [7:0]                cf_arlen   [0:NUM_CMD_CHANNELS-1];
    wire [2:0]                cf_arsize  [0:NUM_CMD_CHANNELS-1];
    wire [1:0]                cf_arburst [0:NUM_CMD_CHANNELS-1];
    wire                      cf_arvalid [0:NUM_CMD_CHANNELS-1];
    wire                      cf_rready  [0:NUM_CMD_CHANNELS-1];

    reg                       cf_arready [0:NUM_CMD_CHANNELS-1];
    reg                       cf_rvalid  [0:NUM_CMD_CHANNELS-1];

    reg [AXI_ID_WIDTH-1:0]   seq_arid;
    reg [AXI_ADDR_WIDTH-1:0] seq_araddr;
    reg [7:0]                seq_arlen;
    reg [2:0]                seq_arsize;
    reg [1:0]                seq_arburst;
    reg                      seq_arvalid;
    reg                      seq_rready;

    assign m_axi_arid    = seq_arid;
    assign m_axi_araddr  = seq_araddr;
    assign m_axi_arlen   = seq_arlen;
    assign m_axi_arsize  = seq_arsize;
    assign m_axi_arburst = seq_arburst;
    assign m_axi_arvalid = seq_arvalid;
    assign m_axi_rready  = seq_rready;

    integer seq_i;
    always @(*) begin
        for (seq_i = 0; seq_i < NUM_CMD_CHANNELS; seq_i = seq_i + 1) begin
            cf_arready[seq_i] = 1'b0;
            cf_rvalid[seq_i]  = 1'b0;
        end

        seq_arid    = cf_arid[rd_chan];
        seq_araddr  = cf_araddr[rd_chan];
        seq_arlen   = cf_arlen[rd_chan];
        seq_arsize  = cf_arsize[rd_chan];
        seq_arburst = cf_arburst[rd_chan];
        seq_arvalid = rd_seq_active ? cf_arvalid[rd_chan] : 1'b0;
        seq_rready  = rd_seq_active ? cf_rready[rd_chan]  : 1'b0;

        cf_arready[rd_chan] = rd_seq_active ? m_axi_arready : 1'b0;
        cf_rvalid[rd_chan]  = rd_seq_active ? m_axi_rvalid  : 1'b0;
    end

    // ================================================================
    // 8. Per-Channel Generate Block
    //    4× chunk_fetcher + ping_pong_buffer
    //    (cmd_consumer/dsp is now external — ppbuf read-side is exposed)
    // ================================================================
    genvar c;
    generate
        for (c = 0; c < NUM_CMD_CHANNELS; c = c + 1) begin : gen_ch

            // Per-channel chunk read address
            wire [AXI_ADDR_WIDTH-1:0] rd_chunk_addr_c = rd_unit_addr + (c[AXI_ADDR_WIDTH-1:0] << PER_CH_OFFSET_LSB);

            // Fetcher enable: only when sequencer is active and it's this channel's turn
            wire fetcher_enable_c = rd_seq_active && (rd_chan == c[CH_IDX_W-1:0]);

            // ---- a. chunk_fetcher ----
            wire                      ppbuf_wr_en_c;
            wire [AXI_DATA_WIDTH-1:0] ppbuf_wr_data_c;
            wire                      cf_ppbuf_done_c;
            wire                      ppbuf_write_finished_c;
            wire                      ppbuf_write_almost_finished_c;

            chunk_fetcher #(
                .AXI_DATA_WIDTH  (AXI_DATA_WIDTH),
                .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
                .AXI_ID_WIDTH    (AXI_ID_WIDTH),
                .BEATS_PER_CHUNK (BEATS_PER_CHUNK),
                .MAX_BURST_LEN   (MAX_BURST_LEN),
                .FETCH_DELAY     (FETCH_DELAY),
                .SHORT_BEATS     (SHORT_BEATS)
            ) u_cf (
                .clk            (rd_clk),
                .rst_n          (rd_rst_n),
                .enable         (fetcher_enable_c),
                .short_chunk    (chmask_staged_rd[c]),   // [CE]
                .idle_addr      (IDLE_SLOT_ADDR),         // [CE]
                .chunk_addr     (rd_chunk_addr_c),
                .fifo_empty     (ddr_fifo_empty),
                .chunk_done     (cf_chunk_done[c]),
                .ppbuf_wr_en              (ppbuf_wr_en_c),
                .ppbuf_wr_data            (ppbuf_wr_data_c),
                .ppbuf_write_finished_ext (cf_ppbuf_done_c),
                .ppbuf_write_finished     (ppbuf_write_finished_c),
                .ppbuf_write_almost_finished (ppbuf_write_almost_finished_c),
                .m_axi_arid     (cf_arid[c]),
                .m_axi_araddr   (cf_araddr[c]),
                .m_axi_arlen    (cf_arlen[c]),
                .m_axi_arsize   (cf_arsize[c]),
                .m_axi_arburst  (cf_arburst[c]),
                .m_axi_arvalid  (cf_arvalid[c]),
                .m_axi_arready  (cf_arready[c]),
                .m_axi_rid      (m_axi_rid),
                .m_axi_rdata    (m_axi_rdata),
                .m_axi_rresp    (m_axi_rresp),
                .m_axi_rlast    (m_axi_rlast),
                .m_axi_rvalid   (cf_rvalid[c]),
                .m_axi_rready   (cf_rready[c])
            );

            // ---- b. ping_pong_buffer ----
            ping_pong_buffer #(
                .WR_DATA_WIDTH (AXI_DATA_WIDTH),
                .RD_DATA_WIDTH (CMD_WIDTH),
                .ADDR_WIDTH    (PPBUF_ADDR_WIDTH),
                .BOOTSTRAP_FIRST_READ (1'b1)   // v2-B: command banks need the first-bank bootstrap
            ) u_ppbuf (
                .wr_clk                   (rd_clk),
                .wr_rst_n                 (rd_rst_n),
                .rd_clk                   (wr_clk),
                .rd_rst_n                 (wr_rst_n),
                .wr_en                    (ppbuf_wr_en_c),
                .wr_data                  (ppbuf_wr_data_c),
                .write_finished_ext       (do_ppbuf_switch),
                .rd_en                    (ppbuf_rd_en[c]),
                .rd_addr                  (ppbuf_rd_addr[c*PPBUF_ADDR_WIDTH +: PPBUF_ADDR_WIDTH]),
                .read_finished            (ppbuf_read_finished[c]),
                .rd_data                  (ppbuf_rd_data[c*CMD_WIDTH +: CMD_WIDTH]),
                .wr_en_out                (),
                .write_finished_out       (ppbuf_write_finished_c),
                .write_almost_finished_out(ppbuf_write_almost_finished_c),
                .able_to_read_out         (ppbuf_able_to_read[c]),
                .rd_addr_valid_out        (ppbuf_rd_addr_valid[c*PPBUF_ADDR_WIDTH +: PPBUF_ADDR_WIDTH]),
                .rd_empty                 (ppbuf_rd_empty[c])
            );

            // ---- c. ppbuf switch detection ----
            reg ppbuf_wf_prev;
            always @(posedge rd_clk or negedge rd_rst_n) begin
                if (!rd_rst_n) ppbuf_wf_prev <= 1'b0;
                else           ppbuf_wf_prev <= ppbuf_write_finished_c;
            end
            assign ppbuf_switch_detect[c] = ppbuf_wf_prev & ~ppbuf_write_finished_c;

        end
    endgenerate

endmodule
