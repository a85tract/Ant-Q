`timescale 1ns/1ps
// stop_ctrl — one guarded early-stop command for the ddr_streaming batch (dsp clock domain).
//
// The PS decides WHEN to stop (its own program on live readout data); this block only guards WHICH circuit:
// a command {stop_cid} arms once (stop_en pulse, already synced to clk); when the sequencer is in S_RUN for
// exactly that circuit, stopreq is raised and held until the dsp acknowledges by finishing the circuit
// (lastshotdone level). The dsp latches actualshots/stopped at DONE; one 4-word record is emitted per
// accepted command: FIRED / NATURAL (circuit finished on its own first) / DROPPED_PAST / DROPPED_BATCHEND.
// One command may be outstanding at a time (software contract); a stop_en while pending is ignored.
module stop_ctrl #(
    parameter integer CID_W = 16,
    parameter integer LAT_W = 48
)(
    input  wire             clk,
    input  wire             rst_n,
    // command (clk domain: stop_en is a 1-cycle pulse, stop_cid is stable at that pulse)
    input  wire             stop_en,
    input  wire [CID_W-1:0] stop_cid,
    // cmd_sequencer
    input  wire [CID_W-1:0] circuit_id,
    input  wire             in_run,           // S_RUN
    input  wire             batch_end,        // seq_circuit_id_reset pulse (S_REARM)
    // dsp
    input  wire             lastshotdone,
    input  wire [31:0]      actualshots,
    input  wire             stopped,
    output reg              stopreq,
    // record (one per accepted command; rec_strobe = 1-cycle pulse, words stable until the next record)
    output reg  [31:0]      rec_w0,
    output reg  [31:0]      rec_w1,
    output reg  [31:0]      rec_w2,
    output reg  [31:0]      rec_w3,
    output reg              rec_strobe
);
    localparam [3:0] K_FIRED = 4'd2, K_DROPPED_PAST = 4'd3, K_DROPPED_BATCHEND = 4'd4, K_NATURAL = 4'd6;

    reg             pending;
    reg [CID_W-1:0] target, fired_cid;
    reg [LAT_W-1:0] cyc, t_cmd;

    task push;
        input [3:0]       kind;
        input [CID_W-1:0] cid;
        input [31:0]      actual;
        input [LAT_W-1:0] lat;
        begin
            rec_w0     <= {kind, 12'b0, cid};
            rec_w1     <= actual;
            rec_w2     <= lat[31:0];
            rec_w3     <= {16'b0, lat[LAT_W-1:32]};
            rec_strobe <= 1'b1;
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 1'b0; stopreq <= 1'b0; target <= {CID_W{1'b0}}; fired_cid <= {CID_W{1'b0}};
            cyc <= {LAT_W{1'b0}}; t_cmd <= {LAT_W{1'b0}};
            rec_w0 <= 32'd0; rec_w1 <= 32'd0; rec_w2 <= 32'd0; rec_w3 <= 32'd0; rec_strobe <= 1'b0;
        end else begin
            cyc        <= cyc + 1'b1;
            rec_strobe <= 1'b0;
            if (stop_en && !pending) begin
                t_cmd <= cyc;
                if (stop_cid < circuit_id) push(K_DROPPED_PAST, stop_cid, 32'd0, {LAT_W{1'b0}});
                else begin pending <= 1'b1; target <= stop_cid; end
            end else if (pending && batch_end) begin
                pending <= 1'b0; stopreq <= 1'b0;
                push(K_DROPPED_BATCHEND, target, 32'd0, {LAT_W{1'b0}});
            end else if (stopreq && lastshotdone) begin
                // ack (level): the dsp finished the circuit; actualshots/stopped were latched >= 1 cycle ago
                stopreq <= 1'b0; pending <= 1'b0;
                push(stopped ? K_FIRED : K_NATURAL, fired_cid, actualshots, cyc - t_cmd);
            end else if (pending && !stopreq && in_run && (circuit_id == target)) begin
                stopreq   <= 1'b1;
                fired_cid <= circuit_id;
            end else if (pending && !stopreq && (circuit_id > target)) begin
                pending <= 1'b0;
                push(K_DROPPED_PAST, target, 32'd0, {LAT_W{1'b0}});
            end
        end
    end
endmodule
