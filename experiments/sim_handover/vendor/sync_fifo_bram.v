`timescale 1ns/1ps
// Synchronous-read FIFO with BRAM-inferable storage (Codex #51, round 6b-1).
//
// Why this module exists: the previous config FIFOs in mmu_writedown.v used
// a register array with a COMBINATIONAL read (`wire rdata = mem[rd_ptr]`).
// At depth 8 that is harmless; at depth 1024 synthesis produced ~2x1024x32
// discrete flip-flops plus a 1024:1 read mux and a huge write-decode fanout,
// failing rd_clk (333 MHz) timing across ~85k endpoints (round 6a evidence).
//
// Contract (single clock domain):
//   - push: accepted only when !full (a push while full is DROPPED -
//     caller must check full; this matches the old write-side guard).
//     A push in the same cycle as an accepting pop is still blocked when
//     full (conservative: full is evaluated on current pointers).
//   - pop: accepted only when !empty (a pop while empty is IGNORED:
//     no pointer move, no dout_valid - caller sees nothing happen).
//   - dout/dout_valid: when a pop is ACCEPTED in cycle N, dout holds the
//     popped word from cycle N+1 on (until the next accepted pop) and
//     dout_valid pulses high exactly in cycle N+1.   <-- +1 cycle vs the
//     old combinational read; consumers must capture on dout_valid.
//   - push+pop same cycle (different slots): both proceed independently.
//     Same-slot collision is impossible: wp==rp means empty, pop blocked.
//   - DEPTH must be a power of two (full/empty use the extra-MSB pointer
//     wrap trick, same as the original inline FIFOs).
//
// dout intentionally has NO reset (BRAM read-port template); it is
// undefined until the first accepted pop - consumers must qualify with
// dout_valid (mmu_writedown captures into staging regs on dout_valid).
module sync_fifo_bram #(
    parameter integer WIDTH = 32,
    parameter integer DEPTH = 1024,
    parameter integer PTRW  = 10          // $clog2(DEPTH)
)(
    input  wire             clk,
    input  wire             rst_n,

    input  wire             push,
    input  wire [WIDTH-1:0] din,

    input  wire             pop,
    output reg  [WIDTH-1:0] dout,
    output reg              dout_valid,

    output wire             empty,
    output wire             full
);

    (* ram_style = "block" *) reg [WIDTH-1:0] mem [0:DEPTH-1];

    reg [PTRW:0] wp;   // extra MSB for full/empty disambiguation
    reg [PTRW:0] rp;

    assign empty = (wp == rp);
    assign full  = (wp[PTRW] != rp[PTRW]) && (wp[PTRW-1:0] == rp[PTRW-1:0]);

    wire push_ok = push && !full;
    wire pop_ok  = pop  && !empty;

    // write port (no reset on mem - BRAM template)
    always @(posedge clk) begin
        if (push_ok)
            mem[wp[PTRW-1:0]] <= din;
    end

    // synchronous read port (no reset on dout - BRAM template)
    always @(posedge clk) begin
        if (pop_ok)
            dout <= mem[rp[PTRW-1:0]];
    end

    // pointers + dout_valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wp         <= {(PTRW+1){1'b0}};
            rp         <= {(PTRW+1){1'b0}};
            dout_valid <= 1'b0;
        end else begin
            dout_valid <= pop_ok;
            if (push_ok) wp <= wp + 1'b1;
            if (pop_ok)  rp <= rp + 1'b1;
        end
    end

endmodule
