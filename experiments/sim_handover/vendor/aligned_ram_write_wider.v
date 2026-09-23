`timescale 1ns/1ps
/**
* SYMMETRIC counterpart of dsp/aligned_ram.v.
*
* aligned_ram: write-NARROW (DIN) / read-WIDE (N*DIN), single clock.
* this module: write-WIDE (N*DOUT) / read-NARROW (DOUT), DUAL clock.
*
* One wide write (N*DOUT bits) lands as one wide word; a narrow read returns one DOUT
* slice of the addressed wide word, READ_LATENCY (=2) cycles after the address is presented
* (IDENTICAL latency to dsp/aligned_ram so a consumer timed for aligned_ram is unchanged).
*
* DUAL-CLOCK: wide write @ wr_clk (DDR/fill, ~333MHz), narrow read @ rd_clk (dsp, ~500MHz).
* For 256b->128b commands: DOUT_WIDTH=128, N_DOUT_TO_DIN=2, READ_LATENCY=2. Used inside
* ping_pong_buffer in place of asym_ram_sdp_write_wider; ppbuf's bank-select MSB is carried
* in the address widths (instantiate with +1).
*
*  2x128 example (N_DOUT_TO_DIN=2):
*   w_addr | w_data[255:0]
*     0    | {word1_128, word0_128}  -> r_addr 0 = word0_128, r_addr 1 = word1_128
*
* BOARD-SYNTH RAM STRUCTURE: a simple-dual-port BRAM (wide-word storage, one single wide
* write, REGISTERED read) — NOT the combinational-lookup form of dsp/aligned_ram. At this
* size (2**WIN_ADDR_WIDTH * N*DOUT bits, x NUM_CH instances) a combinational/async read
* cannot map to block RAM ("Unsupported RAM template"); a registered read infers SDP BRAM.
* Latency is preserved: addr@T -> BRAM word reg @T+1 -> narrow-slice reg @T+2 == READ_LATENCY 2.
* This is cycle-accurate to the previous address-pipeline + combinational-lookup form for any
* consumer that samples read_data at or after T+READ_LATENCY (which ppbuf does).
* NOTE: structured for READ_LATENCY==2 (the only instantiation); assert below guards misuse.
*/
module aligned_ram_write_wider #(
    parameter DOUT_WIDTH     = 128,            // narrow READ width (= dsp command read)
    parameter N_DOUT_TO_DIN  = 2,              // wide WRITE = N * narrow read (256 = 2*128)
    parameter WIN_ADDR_WIDTH = 10,             // wide-WRITE address width (one addr per N*DOUT write)
    parameter READ_LATENCY   = 2)(
    input                                              wr_clk,
    input                                              rd_clk,
    input  [N_DOUT_TO_DIN*DOUT_WIDTH-1:0]              write_data,   // wide (256b)
    input  [WIN_ADDR_WIDTH-1:0]                        write_addr,   // wide-write word addr
    input                                              write_enable,
    input  [WIN_ADDR_WIDTH + $clog2(N_DOUT_TO_DIN)-1:0] read_addr,   // narrow-read word addr (more addrs)
    output [DOUT_WIDTH-1:0]                            read_data);   // narrow (128b)

    localparam LOG     = $clog2(N_DOUT_TO_DIN);
    localparam RADDR_W = WIN_ADDR_WIDTH + LOG;
    // NARROW-word storage, WIDE write as N narrow writes in a loop (UG901 "asymmetric port RAM, write
    // wider"): Vivado infers block RAM with NATIVE width conversion, so the read path is BRAM -> register
    // with no fabric mux and no cascade (2026-08-29 timing closure: the previous wide-word + LUT slice mux was
    // the worst path class of the 14_2 C3 build, -0.277 ns at 500 MHz). Latency unchanged: addr@T -> BRAM
    // output @T+1 -> output register @T+2 (== READ_LATENCY 2); the second register is absorbed into the
    // BRAM's own output register (DOB_REG) because nothing sits between them.
    (* ram_style = "block" *)
    reg [DOUT_WIDTH-1:0] data [0:(2**WIN_ADDR_WIDTH)*N_DOUT_TO_DIN-1];
    integer i;
    always @(posedge wr_clk)
        if (write_enable)
            for (i = 0; i < N_DOUT_TO_DIN; i = i + 1)
                data[{write_addr, i[LOG-1:0]}] <= write_data[i*DOUT_WIDTH +: DOUT_WIDTH];
    reg [DOUT_WIDTH-1:0] rd_q;        // BRAM read register (T+1)
    reg [DOUT_WIDTH-1:0] read_data_q; // output register (T+2), absorbed into DOB_REG
    always @(posedge rd_clk) begin
        rd_q        <= data[read_addr];
        read_data_q <= rd_q;
    end
    assign read_data = read_data_q;
    // synthesis translate_off
    initial if (READ_LATENCY != 2)
        $error("aligned_ram_write_wider: this implementation is structured for READ_LATENCY==2");
    // synthesis translate_on

endmodule
