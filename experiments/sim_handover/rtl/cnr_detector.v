`timescale 1ns/1ps
// circuit_not_ready (CNR) detector — STANDALONE, OUTSIDE the real qubic dsp AND the signed-off cmd_sequencer.
//
// Detects when two circuits did NOT run continuously: at a circuit boundary the next command bank was NOT
// pre-filled in time, so the cmd_sequencer had to wait (in S_WAIT) before it could start the next circuit.
//
// DESIGN (revised after codex/cursor review — race-free, no all_ready edge-detect):
//   The cmd_sequencer FSM is S_FIN(read_finished) -> S_WAIT(wait all_ready rising) -> S_START(stb_start).
//   We OBSERVE the two clean single-cycle pulses it emits and measure the gap:
//     * `circuit_boundary` = |ppbuf_read_finished  (S_FIN: circuit N done, banks flip, sequencer enters S_WAIT)
//     * `next_start`       = stb_start             (S_START: the sequencer starts circuit N+1)
//   While armed the sequencer sits in S_WAIT; `bank_ready` (= all_ready) is LOW while the next bank isn't ready.
//   wait_counter counts the LOW cycles. The flag asserts the moment wait_counter exceeds SWITCH_LATENCY (a LEVEL
//   test, NOT gated by stb_start), and `next_start` (stb_start) only DISARMS to close the window for the
//   continuous case.
//
// Why this is robust (addresses BOTH review rounds):
//   - No rising-edge detect on bank_ready (the v1 fragility): we just COUNT not-ready cycles by level, so there
//     is no same-cycle arm/edge race and no missed-edge poisoning.
//   - PERMANENT stall covered (v2 codex): the flag is driven by wait_counter crossing the threshold, so even if
//     the next bank NEVER becomes ready (stb_start never fires), circuit_not_ready still asserts.
//   - cnr_reset never silently drops a stall: detection is independent of cnr_reset (the level test is always
//     computed); the host's explicit clear takes precedence for the LATCH, and a still-ongoing stall re-latches
//     at the next circuit boundary (re-arm), so nothing is permanently lost.
//   - No NBA off-by-one: wait_counter and the compare are both registered values of the same cycle.
//   - cnr_reset is HOST-DOMINANT: one cycle clears the flag AND disarms AND zeros the counter (clean recovery
//     even mid-stall — no second pulse needed).
//
// Suppression: FIRST circuit's fill is excluded (no read_finished precedes it; cmd_sequencer.v:13). LAST circuit
// excluded (circuit_id == last_circuit_id -> S_FIN goes to S_DONE, no next stb_start; circuit_id is still the
// finishing circuit at S_FIN, cmd_sequencer.v:84-89). Single flag (the sequencer waits for ALL channels).
module cnr_detector #(
    parameter integer SWITCH_LATENCY = 8,    // normal "not ready" ~2-3 cyc + CDC-jitter margin; stall is ~100s -> huge gap
    parameter integer WAIT_W         = 16,
    parameter integer CID_W          = 16
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             run_active,         // global_start (the batch is running)
    input  wire             circuit_boundary,   // |ppbuf_read_finished (S_FIN)
    input  wire             bank_ready,         // all_ready = &(ppbuf_able_to_read & ~ppbuf_rd_empty)
    input  wire             next_start,          // cmd_sequencer stb_start (S_START): circuit N+1 starts
    input  wire [CID_W-1:0] circuit_id,         // cmd_sequencer.circuit_id (current circuit being finished)
    input  wire [CID_W-1:0] last_circuit_id,
    input  wire             cnr_reset,          // PS clear
    output reg              circuit_not_ready,  // sticky: a non-last circuit boundary stalled (not continuous)
    output reg [WAIT_W-1:0] wait_counter        // cycles the next bank was NOT ready at the boundary being measured
);
    reg armed;
    // Registered compare off the arm path (timing closure): circuit_id is set at the circuit's own
    // S_START and last_circuit_id is a PS config register, so both are stable for the entire circuit
    // before the S_FIN boundary where arm_ev fires — the 1-cycle-stale compare is exact by construction.
    reg cid_not_last;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) cid_not_last <= 1'b0;
        else        cid_not_last <= (circuit_id != last_circuit_id);
    wire arm_ev  = circuit_boundary && run_active && cid_not_last;
    // STALL = while armed, the next bank was NOT ready for longer than SWITCH_LATENCY. Evaluated on the LEVEL of
    // wait_counter (NOT gated by next_start / cnr_reset), so it covers the PERMANENT stall too: if the next bank
    // never becomes ready (stb_start never fires) the flag still asserts. next_start (stb_start) is used ONLY to
    // disarm — closing the [read_finished, stb_start) window for the continuous case so the next boundary re-arms.
    wire stall_detected = armed && (wait_counter > SWITCH_LATENCY[WAIT_W-1:0]);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            armed             <= 1'b0;
            wait_counter      <= {WAIT_W{1'b0}};
            circuit_not_ready <= 1'b0;
        end else if (cnr_reset) begin
            // HOST-DOMINANT soft clear: ONE cycle returns the detector to idle (disarm + zero counter + clear
            // flag), overriding ANY coincident arm_ev / stall / next_start. Detection is not suppressed (it is a
            // level test computed every cycle); a genuinely still-ongoing stall simply re-latches at the next
            // circuit boundary (re-arm), so nothing is permanently lost.
            armed             <= 1'b0;
            wait_counter      <= {WAIT_W{1'b0}};
            circuit_not_ready <= 1'b0;
        end else begin
            // wait_counter: reset at each boundary; else count cycles the next bank was NOT ready (in the armed window)
            if (arm_ev)
                wait_counter <= {WAIT_W{1'b0}};
            else if (armed && !bank_ready && wait_counter != {WAIT_W{1'b1}})
                wait_counter <= wait_counter + 1'b1;

            // armed window: set on a non-last boundary; cleared at the next-circuit start (stb_start)
            if (arm_ev)
                armed <= 1'b1;
            else if (next_start)
                armed <= 1'b0;

            // circuit_not_ready: latch (sticky) on a stall; held until a cnr_reset clears it (handled above)
            if (stall_detected)
                circuit_not_ready <= 1'b1;
        end
    end
endmodule
