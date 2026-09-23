`timescale 1ns/1ps

module ring_buffer_4chunk_ddr #(
    parameter integer CHUNK_PTR_WIDTH = 17,     // log2(131072) for 2GiB / 16KiB
    parameter integer AXI_ADDR_WIDTH  = 32,
    parameter integer CHUNK_ADDR_LSB  = 14      // each chunk = 16KiB = 2^14 bytes
)(
    input  wire                          clk,
    input  wire                          rst_n,

    // Write side: pulse when a chunk has been fully written to DDR
    input  wire                          wr_chunk_done,

    // Read side: pulse when a chunk has been fully read from DDR
    input  wire                          rd_chunk_done,

    // Base address for the DDR region
    input  wire [AXI_ADDR_WIDTH-1:0]     base_addr,

    // Outputs
    output wire [AXI_ADDR_WIDTH-1:0]     wr_chunk_addr,   // byte address for next write chunk
    output wire [AXI_ADDR_WIDTH-1:0]     rd_chunk_addr,   // byte address for next read chunk
    output wire                          fifo_empty,
    output wire                          fifo_full
);

    // ----------------------------------------------------------------
    // Registers
    // ----------------------------------------------------------------
    reg [CHUNK_PTR_WIDTH-1:0] wr_ptr;
    reg [CHUNK_PTR_WIDTH-1:0] rd_ptr;
    reg [CHUNK_PTR_WIDTH:0]   count;      // one bit wider for full detection

    // ----------------------------------------------------------------
    // Combinational outputs
    // ----------------------------------------------------------------
    assign wr_chunk_addr = base_addr + ({wr_ptr, {CHUNK_ADDR_LSB{1'b0}}});
    assign rd_chunk_addr = base_addr + ({rd_ptr, {CHUNK_ADDR_LSB{1'b0}}});
    assign fifo_empty    = (count == 0);
    assign fifo_full     = (count == (1 << CHUNK_PTR_WIDTH));

    // ----------------------------------------------------------------
    // Sequential logic
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {CHUNK_PTR_WIDTH{1'b0}};
            rd_ptr <= {CHUNK_PTR_WIDTH{1'b0}};
            count  <= {(CHUNK_PTR_WIDTH+1){1'b0}};
        end else begin
            case ({wr_chunk_done && !fifo_full, rd_chunk_done && !fifo_empty})
                2'b10: begin
                    wr_ptr <= wr_ptr + 1'b1;
                    count  <= count + 1'b1;
                end
                2'b01: begin
                    rd_ptr <= rd_ptr + 1'b1;
                    count  <= count - 1'b1;
                end
                2'b11: begin
                    wr_ptr <= wr_ptr + 1'b1;
                    rd_ptr <= rd_ptr + 1'b1;
                    // count stays the same
                end
                default: ;
            endcase
        end
    end

endmodule
