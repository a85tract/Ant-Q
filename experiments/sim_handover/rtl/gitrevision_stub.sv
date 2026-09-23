`timescale 1ns/1ps
// Sim stub for the generated gitrevision module (boardcfg.sv:40 -> cfgregs.gitrevision, 32b).
// The real build emits the actual git hash here; behaviorally irrelevant to the dsp datapath.
module gitrevision(output [32-1:0] gitrevision);
  assign gitrevision = 32'h0BADF00D;
endmodule
