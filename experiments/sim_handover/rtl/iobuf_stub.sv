`timescale 1ns/1ps
// Simulatable stub for the Xilinx IOBUF primitive. Used only by boardcfg's copper board-to-board
// sync (UNUSED in a single-board baseline). O follows IO; IO driven by I when ~T.
module IOBUF (input IO, input I, output O, input T);
  // copper sync unused: IO made an input (not inout) so Verilator does not treat hw.dacio as a
  // tristate net (VARXREF tristate is unsupported); O just buffers I.
  assign O = I;
endmodule
