// ============================================================================
// data_tagger_top.v
//
// Parameterized top-level wrapper that instantiates N data_tagger modules.
// Each channel gets its own 8-bit TAG value from the TAG_ARRAY parameter.
//
// Default behaviour (TAG_ARRAY left at all-zeros):
//   Incremental tags are assigned automatically:
//     ch0 = 0x00, ch1 = 0x01, ch2 = 0x02, ...
//   Override TAG_ARRAY to supply custom per-channel tags.
//
// Ports use flat (packed) vectors:
//   data_in  / data_out  : N*64 bits wide
//   data_in_en / data_out_en : N bits wide
//
// Channel mapping (little-endian):
//   Channel 0 : data_in[63:0],     data_in_en[0]
//   Channel 1 : data_in[127:64],   data_in_en[1]
//   ...
//   Channel k : data_in[k*64 +: 64], data_in_en[k]
// ============================================================================

module data_tagger_top #(
    parameter integer            NUM_CH    = 4,                   // number of channels
    parameter [NUM_CH*8-1:0]     TAG_ARRAY = {NUM_CH*8{1'b0}}    // all-zero = use incremental default
)
(
    input  wire                   clk,
    input  wire                   rst_n,

    // Flat input bus from N inc_data_gen instances
    input  wire [NUM_CH*64-1:0]   data_in,
    input  wire [NUM_CH-1:0]      data_in_en,

    // Flat tagged output bus
    output wire [NUM_CH*64-1:0]   data_out,
    output wire [NUM_CH-1:0]      data_out_en
);

    // ---- Generate incremental tag array: ch0=0x00, ch1=0x01, ... ----
    function [NUM_CH*8-1:0] inc_tags;
        input integer dummy;
        integer k;
        begin
            inc_tags = {NUM_CH*8{1'b0}};
            for (k = 0; k < NUM_CH; k = k + 1)
                inc_tags[k*8 +: 8] = k[7:0];
        end
    endfunction

    // If user left TAG_ARRAY at all-zeros, substitute incremental tags
    localparam [NUM_CH*8-1:0] TAGS_USED =
        (TAG_ARRAY == {NUM_CH*8{1'b0}}) ? inc_tags(0) : TAG_ARRAY;

    genvar i;
    generate
        for (i = 0; i < NUM_CH; i = i + 1) begin : gen_tagger
            data_tagger #(
                .TAG  (TAGS_USED[i*8 +: 8])
            ) u_tagger (
                .clk         (clk),
                .rst_n       (rst_n),
                .data_in     (data_in [i*64 +: 64]),
                .data_in_en  (data_in_en[i]),
                .data_out    (data_out[i*64 +: 64]),
                .data_out_en (data_out_en[i])
            );
        end
    endgenerate

endmodule
