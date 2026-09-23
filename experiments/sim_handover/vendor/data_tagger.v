// ============================================================================
// data_tagger.v
// 
// Converts 64-bit IQ data from inc_data_gen into a tagged format.
//
// Input  format (64 bits):
//   [63:32] = real      (32 bits)
//   [31:0]  = imaginary (32 bits)
//
// Output format (64 bits):
//   [63:56] = TAG       (8 bits, user-configurable parameter)
//   [55:28] = imaginary (28 bits, upper 28 of original 32-bit imag)
//   [27:0]  = real      (28 bits, upper 28 of original 32-bit real)
//
// Truncation: drops the 4 LSBs of each 32-bit field, so the modified
// values are less precise by at most 2^4.
// ============================================================================

module data_tagger #(
    parameter [7:0] TAG = 8'h00   // 8-bit tag value, set by user
)
(
    input  wire        clk,
    input  wire        rst_n,

    // Input from inc_data_gen
    input  wire [63:0] data_in,
    input  wire        data_in_en,

    // Tagged output
    output reg  [63:0] data_out,
    output reg         data_out_en
);

    // Extract the original 32-bit fields
    wire [31:0] real_full = data_in[31:0];
    wire [31:0] imag_full = data_in[63:32];

    // Truncate to upper 28 bits (drop 4 LSBs)
    wire [27:0] real_trunc = real_full[31:4];
    wire [27:0] imag_trunc = imag_full[31:4];

    // Pack into tagged 64-bit format:
    //   [63:56] = TAG
    //   [55:28] = imag_trunc
    //   [27:0]  = real_trunc
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out    <= 64'd0;
            data_out_en <= 1'b0;
        end else begin
            data_out    <= {TAG, imag_trunc, real_trunc};
            data_out_en <= data_in_en;
        end
    end

endmodule
