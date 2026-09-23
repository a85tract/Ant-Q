module data_buffer #(
    parameter DATA_WIDTH = 64
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire                  rd_en,
    output wire                  data_valid,   // now wire
    output reg  [DATA_WIDTH-1:0] data
);

    reg valid_q;  // internal registered flag

    // Sequential state updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data    <= {DATA_WIDTH{1'b0}};
            valid_q <= 1'b0;
        end else begin
            // Write has priority over clearing
            if (wr_en) begin
                data    <= wr_data;
                valid_q <= 1'b1;
            end else if (rd_en) begin
                valid_q <= 1'b0;
            end
        end
    end

    // Combinational visibility:
    // as soon as rd_en=1, data_valid goes low in that same cycle
    assign data_valid = valid_q;

endmodule
