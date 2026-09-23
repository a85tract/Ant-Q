`timescale 1ns/1ps

// v2-B command-batch SEQUENCER (dsp clock domain) — PULSE-TRIGGERED (was RE-ARM FORK).
// Fork of top/zcu216_8_2/rbs/cmd_sequencer.v (basename-dedup in mk_filelist_v2b.py makes THIS win for the plsv
// sim; the rbs original + its signed-off gate testbenches stay untouched).
//
// DESIGN (2026-06-30, codex-xhigh reviewed FIX-A'): global_start is a single-cycle PULSE. ONE rising edge (2-FF
// synced + edge-detected) => run EXACTLY ONE batch (last_circuit_id+1 circuits) to completion, then park in
// S_IDLE and wait for the NEXT pulse. NO auto-rearm (level-held global_start = exactly one batch). This gives the
// host clean per-batch gating that a LEVEL global_start could not (it auto-ran every prefilled batch, and the
// S_REARM window was un-hittable by PS->PL timing). The DDR->ppbuf prefill is decoupled from global_start
// (mmu_writedown pops config unconditionally for the first circuit, then one stb_start "credit" per subsequent
// pop — see mmu_writedown pop_credit); back-pressure via read_finished at CTRL_SWITCH.
// After the last circuit of a batch the FSM:
//   - pulses batch_done (1-CYCLE PULSE — internal/observability/IRQ only; the HOST polls readout-side done),
//   - enters S_REARM: resets circuit_id to 0 and pulses seq_circuit_id_reset (-> bundle.cid_count_reset in
//     plsv_v2b, which resets ONLY the bundle circuit_id counter; the readout DDR base is NOT touched here — the
//     AXI writer self-resets to base on its run's last burst, and software drains each batch before the next runs),
//   - returns to S_IDLE (wait for next global_start pulse).
// seq_circuit_id_reset is pulsed ONE cycle AFTER the S_FIN flush so the last batch's bundle last_circuit_done
// (= N_shot_finished & circuit_id==last_circuit_id, combinational, wr_clk) is not disturbed by the reset.
//
// Per circuit (unchanged): wait ALL command ppbufs bank-ready (able && !empty) -> at that RISING edge latch
// nshots_staged (Codex GATE3 single-sample of the quasi-static bus) -> pulse stb_start -> wait dsp lastshotdone
// (S_WAITCLR first confirms the previous circuit's latched lastshotdone cleared) -> pulse ppbuf_read_finished
// for ALL channels -> advance circuit_id. The first circuit relies on the ppbuf write-side bootstrap.

module cmd_sequencer #(
    parameter integer NUM_CH  = 8,
    parameter integer NSHOT_W = 32,
    parameter integer CID_W   = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 global_start,
    input  wire [CID_W-1:0]     last_circuit_id,

    // mmu ppbuf read-side status (dsp clock)
    input  wire [NUM_CH-1:0]    ppbuf_able_to_read,
    input  wire [NUM_CH-1:0]    ppbuf_rd_empty,
    input  wire [NSHOT_W-1:0]   nshots_staged,        // quasi-static O1b staged bus

    // to/from the real dsp
    output reg                  stb_start,
    output reg  [NSHOT_W-1:0]   nshot,
    input  wire                 lastshotdone,         // dspif.lastshotdone (per-circuit done)

    // to mmu ppbuf read-side
    output reg  [NUM_CH-1:0]    ppbuf_read_finished,

    // re-arm: 1-cycle pulse -> bundle.cid_count_reset in plsv_v2b (resets ONLY bundle circuit_id, NOT readout base)
    output reg                  seq_circuit_id_reset,

    // status / observability
    output reg  [CID_W-1:0]     circuit_id,
    output reg                  batch_done,           // 1-CYCLE PULSE per batch completion (internal only)
    output wire                 run_active,           // HIGH while a batch is in flight (state != S_IDLE); for cnr_detector
    output wire                 in_run                // [stop] HIGH in S_RUN (between stb_start and lastshotdone); for stop_ctrl
);
    wire all_ready = &(ppbuf_able_to_read & ~ppbuf_rd_empty);
    reg  all_ready_d;

    // PULSE-TRIGGERED redesign (was: LEVEL global_start + auto-rearm). global_start is now a single-cycle PULSE
    // (or held-high legacy = one rising edge): ONE rising edge => run EXACTLY ONE batch to completion, then park
    // in S_IDLE and wait for the NEXT pulse. 2-FF synchronizer for board CDC (harmless in sim); edge-detect the
    // synced level. A PS-written pulse (write 1 then 0 over axi_lite, µs apart) is many clk cycles wide -> sampled
    // exactly once. Mid-batch pulses are IGNORED (only S_IDLE consumes start_pulse) — software contract: pulse
    // only when idle.
    reg  gstart_s1, gstart_s2, gstart_d;
    wire start_pulse = gstart_s2 & ~gstart_d;

    // S_WAITCLR (Codex round-4 fix): lastshotdone is a LATCHED LEVEL (dsp.sv:160/166), set on done and
    // cleared only when stb_start is observed. After pulsing stb_start we must first confirm lastshotdone
    // cleared (==0) before arming the rising-edge detect, else S_RUN would falsely fire on the PREVIOUS
    // circuit's still-high level (stb_start clears it one cycle later).
    localparam [2:0] S_IDLE=3'd0, S_WAIT=3'd1, S_START=3'd2, S_WAITCLR=3'd3, S_RUN=3'd4, S_FIN=3'd5, S_REARM=3'd6;
    reg [2:0] state;

    assign run_active = (state != S_IDLE);
    assign in_run     = (state == S_RUN);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state                <= S_IDLE;
            stb_start            <= 1'b0;
            nshot                <= {NSHOT_W{1'b0}};
            ppbuf_read_finished  <= {NUM_CH{1'b0}};
            circuit_id           <= {CID_W{1'b0}};
            batch_done           <= 1'b0;
            seq_circuit_id_reset <= 1'b0;
            all_ready_d          <= 1'b0;
            gstart_s1            <= 1'b0;
            gstart_s2            <= 1'b0;
            gstart_d             <= 1'b0;
        end else begin
            // global_start 2-FF sync + edge-detect history (unconditional every clock)
            gstart_s1 <= global_start;
            gstart_s2 <= gstart_s1;
            gstart_d  <= gstart_s2;
            stb_start            <= 1'b0;             // default 1-cycle pulses
            ppbuf_read_finished  <= {NUM_CH{1'b0}};
            batch_done           <= 1'b0;             // CHANGED: batch_done is now a 1-cycle pulse
            seq_circuit_id_reset <= 1'b0;             // NEW: 1-cycle pulse
            // all_ready_d: edge history is reset to 0 OUTSIDE S_WAIT so that an ALREADY-HIGH all_ready on
            // (re)entry to S_WAIT — e.g. a pre-filled batch-2 bank after S_REARM, or a pre-fetched next bank
            // mid-batch — is seen as a rising edge and NOT missed (Codex re-arm review #1). Within S_WAIT it
            // tracks normally, preserving the GATE3 single-sample-at-bank-ready-edge latch of nshots_staged.
            all_ready_d          <= (state == S_WAIT) ? all_ready : 1'b0;

            case (state)
                S_IDLE:  if (start_pulse) state <= S_WAIT;   // CHANGED: edge (pulse), was level global_start

                // Wait for the RISING edge of all-ready (bank ready for THIS circuit). Latch the staged
                // nshots at exactly that edge (single sample of the quasi-static bus).
                S_WAIT:  if (all_ready && !all_ready_d) begin
                             nshot <= nshots_staged;
                             state <= S_START;
                         end

                S_START:   begin stb_start <= 1'b1; state <= S_WAITCLR; end

                // Wait until stb_start has cleared the previous lastshotdone level before arming completion.
                S_WAITCLR: if (!lastshotdone) state <= S_RUN;

                S_RUN:     if (lastshotdone) state <= S_FIN;   // genuine rising edge for THIS circuit

                S_FIN:   begin
                             ppbuf_read_finished <= {NUM_CH{1'b1}};   // per-circuit done -> flip all banks
                                                                      // (at last circuit this N_shot_finished
                                                                      //  also drives bundle last_circuit_done flush)
                             if (circuit_id == last_circuit_id) begin
                                 batch_done <= 1'b1;          // 1-cycle pulse: batch complete
                                 state      <= S_REARM;       // CHANGED: was terminal S_DONE
                             end else begin
                                 circuit_id <= circuit_id + 1'b1;
                                 state      <= S_WAIT;
                             end
                         end

                // RE-ARM (1 cycle after the S_FIN flush): reset sequencer circuit_id + pulse the bundle reset,
                // then auto-continue the next batch if still enabled, else stop cleanly. No external reset needed.
                S_REARM: begin
                             circuit_id           <= {CID_W{1'b0}};
                             seq_circuit_id_reset <= 1'b1;            // -> bundle cid_count_reset (circuit_id ONLY)
                             state                <= S_IDLE;          // CHANGED: NO auto-rearm; wait for next global_start PULSE
                         end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
