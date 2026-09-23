`timescale 1ns/1ps

// v2-B command-batch SEQUENCER (dsp clock domain) — RE-ARM FORK.
// Fork of top/zcu216_8_2/rbs/cmd_sequencer.v (basename-dedup in mk_filelist_v2b.py makes THIS win for the plsv
// sim; the rbs original + its signed-off gate testbenches stay untouched).
//
// CHANGE vs original: support N CONSECUTIVE batches back-to-back with NO external reset and NO re-pulsing
// global_start. After the last circuit of a batch the FSM no longer parks in a terminal S_DONE; instead it:
//   - pulses batch_done (now a 1-CYCLE PULSE, not a latched level — internal/observability/IRQ source only;
//     the HOST polls readout-side done via axi_lite, NOT this),
//   - enters S_REARM: resets circuit_id to 0 and pulses seq_circuit_id_reset (-> bundle.cid_count_reset in
//     plsv_v2b, which resets ONLY the bundle circuit_id counter; the readout DDR base is NOT touched here — the
//     AXI writer self-resets to base on its run's last burst, and software drains each batch before the next runs),
//   - returns to S_WAIT if global_start is still high (auto-continue next batch) else S_IDLE (clean stop).
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
    output reg                  batch_done            // 1-CYCLE PULSE per batch completion (internal only)
);
    wire all_ready = &(ppbuf_able_to_read & ~ppbuf_rd_empty);
    reg  all_ready_d;

    // S_WAITCLR (Codex round-4 fix): lastshotdone is a LATCHED LEVEL (dsp.sv:160/166), set on done and
    // cleared only when stb_start is observed. After pulsing stb_start we must first confirm lastshotdone
    // cleared (==0) before arming the rising-edge detect, else S_RUN would falsely fire on the PREVIOUS
    // circuit's still-high level (stb_start clears it one cycle later).
    localparam [2:0] S_IDLE=3'd0, S_WAIT=3'd1, S_START=3'd2, S_WAITCLR=3'd3, S_RUN=3'd4, S_FIN=3'd5, S_REARM=3'd6;
    reg [2:0] state;

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
        end else begin
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
                S_IDLE:  if (global_start) state <= S_WAIT;

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
                             state                <= global_start ? S_WAIT : S_IDLE;
                         end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
