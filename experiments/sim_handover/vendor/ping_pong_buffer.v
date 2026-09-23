`timescale 1ns/1ps

// Ping-pong (dual-bank) buffer with CDC.
// Mirrors circular_buffer3.v architecture.
// Key difference: write side is WIDER than read side (uses asym_ram_sdp_write_wider).
// Write: 256-bit @ 333MHz, Read: 128-bit @ 500MHz.
// Uses pulse_sync for read_finished CDC (pulse may be shorter than dest clock period).
//
// Optimized read-side bank switch: instead of CDC'ing bank_sel_rd back from
// wr_clk to rd_clk (~12 cycle round-trip), we pre-sync write_finished into
// rd_clk and handle the read-bank switch locally (~3 cycles).

module ping_pong_buffer #(
    parameter WR_DATA_WIDTH = 256,
    parameter RD_DATA_WIDTH = 128,
    parameter ADDR_WIDTH    = 11,   // read-side address width (2048 x 128-bit per bank; 2026-06-10 expansion)
    // v2-B first-bank bootstrap (Codex round-2 showstopper + round-4 fix): reset puts read on bank1 (empty)
    // and write on bank0; the first fill into bank0 can't become readable without a read_finished, AND the
    // write side can't advance (write_finished never falls) without one either -> deadlock, and mmu_writedown's
    // config_valid_out (gated on the falling edge of ppbuf_write_finished) never fires. With
    // BOOTSTRAP_FIRST_READ=1, after the FIRST write completes ppbuf synthesizes ONE read_finished pulse fed
    // into BOTH the wr-domain pulse_sync (write side flips, write_finished falls) AND the rd-domain edge-detect
    // (read side flips to bank0). This breaks the deadlock and restores TRUE ping-pong overlap (write fills
    // bank1 while read consumes bank0). A read-side-only bootstrap is NOT enough (write side stays stalled).
    parameter BOOTSTRAP_FIRST_READ = 1'b0
)(
    input  wire                      wr_clk,
    input  wire                      wr_rst_n,
    input  wire                      rd_clk,
    input  wire                      rd_rst_n,
    input  wire                      wr_en,
    input  wire [WR_DATA_WIDTH-1:0]  wr_data,
    input  wire                      write_finished_ext,
    input  wire                      rd_en,
    input  wire [ADDR_WIDTH-1:0]     rd_addr,
    input  wire                      read_finished,
    output wire [RD_DATA_WIDTH-1:0]  rd_data,
    output wire                      wr_en_out,
    output wire                      write_finished_out,
    output wire                      write_almost_finished_out,
    output wire                      able_to_read_out,
    output wire [ADDR_WIDTH-1:0]     rd_addr_valid_out,
    output wire                      rd_empty
);

    // ----------------------------------------------------------------
    // Parameters — write side is wider, so WR_DEPTH < RD_DEPTH
    // ----------------------------------------------------------------
    localparam integer RATIO         = WR_DATA_WIDTH / RD_DATA_WIDTH;
    localparam integer RATIO_LG2     = (RATIO > 1) ? $clog2(RATIO) : 0;
    localparam integer RD_DEPTH      = (1 << ADDR_WIDTH);
    localparam integer WR_DEPTH      = RD_DEPTH / RATIO;
    localparam integer WR_ADDR_WIDTH = ADDR_WIDTH - RATIO_LG2;

    // ----------------------------------------------------------------
    // Registers — Write Domain
    // ----------------------------------------------------------------
    reg bank_sel_wr = 1'b0;
    reg [WR_ADDR_WIDTH-1:0] wr_addr;

    reg write_finished        = 1'b0;
    reg write_almost_finished = 1'b0;

    reg [ADDR_WIDTH-1:0] last_valid_addr [0:1];
    reg buffer_empty [0:1];

    reg read_finished_reg_wr;

    // ----------------------------------------------------------------
    // Registers — Read Domain
    // ----------------------------------------------------------------
    reg read_finished_d_rd, read_finished_reg_rd;
    reg rd_bank_local;          // local read-bank select (no CDC round-trip)
    reg write_ready_rd;         // write_finished seen in rd_clk domain
    reg bootstrapped;           // v2-B: the one-time first-bank bootstrap has fired
    reg boot_pulse;             // v2-B: 1-cycle synthesized read_finished (rd_clk) for the first-bank bootstrap

    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH-1:0] last_valid_addr_sync1 [0:1], last_valid_addr_sync2 [0:1];
    (* ASYNC_REG = "TRUE" *) reg buffer_empty_sync1 [0:1], buffer_empty_sync2 [0:1];

    // ----------------------------------------------------------------
    // Outputs
    // ----------------------------------------------------------------
    assign write_finished_out        = write_finished;
    assign write_almost_finished_out = write_almost_finished;
    assign wr_en_out                 = wr_en;

    wire wr_bank_sel = bank_sel_wr;

    assign rd_addr_valid_out = last_valid_addr_sync2[rd_bank_local];
    assign rd_empty          = buffer_empty_sync2[rd_bank_local];
    assign able_to_read_out  = !read_finished & !read_finished_d_rd & !read_finished_reg_rd;

    integer i, j;

    // ----------------------------------------------------------------
    // Pulse Sync: read_finished from rd_clk → wr_clk
    // Uses toggle-based synchronizer to safely cross clock domains
    // even when the source pulse is shorter than the destination period.
    // ----------------------------------------------------------------
    wire read_finished_synced;  // single-cycle pulse in wr_clk domain

    // v2-B bootstrap: the synthesized boot_pulse is OR'd into read_finished so ONE pulse drives BOTH the
    // wr-domain pulse_sync below (write side flips -> write_finished FALLS -> mmu_writedown all_switch_done /
    // config_valid_out) AND the rd-domain edge-detect (read side flips to the first-filled bank). True overlap.
    wire eff_read_finished = read_finished | boot_pulse;

    pulse_sync u_rf_sync (
        .src_clk    (rd_clk),
        .src_rst_n  (rd_rst_n),
        .src_pulse  (eff_read_finished),
        .dst_clk    (wr_clk),
        .dst_rst_n  (wr_rst_n),
        .dst_pulse  (read_finished_synced)
    );

    // ----------------------------------------------------------------
    // Pulse Sync: write_finished from wr_clk → rd_clk
    // Pre-syncs write_finished into rd_clk so the read-bank switch
    // can happen locally without a CDC round-trip.
    // ----------------------------------------------------------------
    wire write_finished_rd_pulse;  // single-cycle pulse in rd_clk domain

    pulse_sync u_wf_sync (
        .src_clk    (wr_clk),
        .src_rst_n  (wr_rst_n),
        .src_pulse  (write_finished),
        .dst_clk    (rd_clk),
        .dst_rst_n  (rd_rst_n),
        .dst_pulse  (write_finished_rd_pulse)
    );

    // ----------------------------------------------------------------
    // Write Domain Logic
    // ----------------------------------------------------------------
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_addr                        <= {WR_ADDR_WIDTH{1'b0}};
            bank_sel_wr                    <= 1'b0;
            write_finished                 <= 1'b0;
            write_almost_finished          <= 1'b0;

            read_finished_reg_wr           <= 1'b0;

            for (i = 0; i < 2; i = i + 1) begin
                last_valid_addr[i] <= {ADDR_WIDTH{1'b0}};
                buffer_empty[i]    <= 1'b1;
            end
        end else begin

            // 1. Capture synced read_finished pulse
            if (read_finished_synced) begin
                read_finished_reg_wr <= 1'b1;
            end

            // 2. Write Logic
            if (wr_en) begin

                buffer_empty[wr_bank_sel] <= 1'b0;
                // Each 256-bit write covers RATIO=2 read addresses.
                // Last valid read addr = {wr_addr, {RATIO_LG2{1'b1}}} = wr_addr*2 + 1
                last_valid_addr[wr_bank_sel] <= {wr_addr, {RATIO_LG2{1'b1}}};

                // --- Case A: End of Bank (wr_addr is MAX) ---
                // STALL — hold wr_addr at max. The bank switch is handled
                // entirely by the recovery path (write_finished_ext +
                // read_finished_reg_wr), ensuring exactly one bank flip
                // per chunk instead of the double-flip that the old
                // seamless-switch + recovery combo produced.
                if (wr_addr == (WR_DEPTH - 1)) begin
                    // hold state — wait for write_finished_ext + recovery
                end
                // --- Case B: Second to last ---
                else if (wr_addr == (WR_DEPTH - 2)) begin
                    wr_addr <= wr_addr + 1'b1;
                    write_almost_finished <= 1'b1;
                end
                // --- Case C: Normal ---
                else begin
                    wr_addr <= wr_addr + 1'b1;
                    write_almost_finished <= 1'b0;
                    write_finished        <= 1'b0;
                end
            end

            // External force finish (override)
            if (write_finished_ext && !write_finished) begin
                write_finished <= 1'b1;
            end

            // Recovery from Stall
            // Note: bank_sel_rd removed — read-side bank is managed locally
            // in rd_clk domain via rd_bank_local.
            if (write_finished && read_finished_reg_wr) begin
                if (!wr_en) begin
                    bank_sel_wr <= ~bank_sel_wr;
                    wr_addr     <= {WR_ADDR_WIDTH{1'b0}};

                    read_finished_reg_wr <= 1'b0;

                    write_finished        <= 1'b0;
                    write_almost_finished <= 1'b0;

                    buffer_empty[~bank_sel_wr]    <= 1'b1;
                    last_valid_addr[~bank_sel_wr] <= {ADDR_WIDTH{1'b0}};
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // Read Domain Logic
    //
    // Bank switch is now local: when both write_ready_rd (write side
    // finished its bank) and read_finished_reg_rd (read side finished
    // reading) are set, flip rd_bank_local and clear both flags.
    // This replaces the old CDC round-trip through bank_sel_rd.
    // ----------------------------------------------------------------
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            read_finished_d_rd   <= 1'b0;
            read_finished_reg_rd <= 1'b0;
            rd_bank_local        <= 1'b1;   // matches old ~bank_sel_rd reset = ~0 = 1
            write_ready_rd       <= 1'b0;
            bootstrapped         <= 1'b0;
            boot_pulse           <= 1'b0;
            for (j = 0; j < 2; j = j + 1) begin
                last_valid_addr_sync1[j] <= {ADDR_WIDTH{1'b0}};
                last_valid_addr_sync2[j] <= {ADDR_WIDTH{1'b0}};
                buffer_empty_sync1[j]    <= 1'b1;
                buffer_empty_sync2[j]    <= 1'b1;
            end
        end else begin
            // v2-B first-bank bootstrap: once the first bank fill has completed (write_ready_rd) but no real
            // circuit has run, synthesize ONE read_finished pulse. eff_read_finished feeds both the wr-domain
            // pulse_sync (write side flips, write_finished falls -> mmu config_valid_out) and the edge-detect
            // below (read side flips to bank0). One-shot, latched by `bootstrapped`.
            boot_pulse <= 1'b0;
            if (BOOTSTRAP_FIRST_READ && !bootstrapped && write_ready_rd) begin
                boot_pulse   <= 1'b1;
                bootstrapped <= 1'b1;
            end

            // Edge-detect read_finished (rising edge → set reg), incl. the bootstrap pulse via eff_read_finished
            read_finished_d_rd <= eff_read_finished;
            if (!read_finished_d_rd && eff_read_finished) read_finished_reg_rd <= 1'b1;

            // Capture write_finished pulse from wr_clk domain
            if (write_finished_rd_pulse)
                write_ready_rd <= 1'b1;

            // Local bank switch: both sides done → flip read bank (the bootstrap arrives here as read_finished_reg_rd)
            if (read_finished_reg_rd && write_ready_rd) begin
                rd_bank_local        <= ~rd_bank_local;
                read_finished_reg_rd <= 1'b0;
                write_ready_rd       <= 1'b0;
            end

            // 2-FF sync for last_valid_addr and buffer_empty (still needed)
            for (j = 0; j < 2; j = j + 1) begin
                last_valid_addr_sync1[j] <= last_valid_addr[j];
                last_valid_addr_sync2[j] <= last_valid_addr_sync1[j];
                buffer_empty_sync1[j]    <= buffer_empty[j];
                buffer_empty_sync2[j]    <= buffer_empty_sync1[j];
            end
        end
    end

    // ----------------------------------------------------------------
    // RAM — write-wider asymmetric
    // ----------------------------------------------------------------
    // v2-B: storage is the SYMMETRIC aligned_ram_write_wider (write-wide 256 / read-narrow 128) instead of
    // asym_ram_sdp_write_wider. This RAM's READ side mirrors qubic aligned_ram (READ_LATENCY=2) so the dsp's
    // command read timing is preserved by construction (vs the old 1-cycle asym_ram read). Bank MSB is carried
    // in the write/read address widths exactly as before ({bank, addr}).
    aligned_ram_write_wider #(
        .DOUT_WIDTH     (RD_DATA_WIDTH),        // 128 (narrow read = dsp command read)
        .N_DOUT_TO_DIN  (RATIO),                // 2 (256 write = 2*128)
        .WIN_ADDR_WIDTH (WR_ADDR_WIDTH + 1),    // +1 bank select bit (write words)
        .READ_LATENCY   (2)                     // match qubic aligned_ram
    ) u_ram (
        .wr_clk       (wr_clk),
        .rd_clk       (rd_clk),
        .write_enable (wr_en),
        .write_addr   ({bank_sel_wr, wr_addr}),
        .write_data   (wr_data),
        .read_addr    ({rd_bank_local, rd_addr}),
        .read_data    (rd_data)
    );

endmodule
