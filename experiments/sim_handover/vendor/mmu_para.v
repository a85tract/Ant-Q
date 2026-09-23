`timescale 1ns/1ps

module mmu_para #(
    parameter integer NUM_CHANNELS    = 4,
    parameter integer WR_DATA_WIDTH   = 64,
    parameter integer RD_DATA_WIDTH   = 256,
    parameter integer ADDR_WIDTH      = 4,
    parameter integer AXI_ADDR_WIDTH  = 32
)(
    input  wire                       wr_clk,
    input  wire                       wr_rst_n,
    input  wire                       rd_clk,
    input  wire                       rd_rst_n,
    
    // Parameterized Flat Interfaces
    input  wire [NUM_CHANNELS-1:0]    ch_wr_en,
    input  wire [(NUM_CHANNELS*WR_DATA_WIDTH)-1:0] ch_wr_data,

    input  wire                       N_shot_finished,
    input  wire [ADDR_WIDTH-1:0]      max_bank_size,
    input  wire [AXI_ADDR_WIDTH-1:0]  base_addr,
    input  wire                       base_reset,   // rd_clk; software run-boundary base reset (round 10)

    output wire [AXI_ADDR_WIDTH-1:0]  final_addr,
    output wire                       current_user_done,
    output wire [AXI_ADDR_WIDTH-1:0]  cur_axi_addr_out,

    // AXI4-Full Write Master
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output wire [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output wire                       m_axi_awvalid,
    input  wire                       m_axi_awready,

    output wire [RD_DATA_WIDTH-1:0]   m_axi_wdata,
    output wire [RD_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                       m_axi_wlast,
    output wire                       m_axi_wvalid,
    input  wire                       m_axi_wready,

    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output wire                       m_axi_bready
);

    // ----------------------------------------------------------------
    // Internal signals for generated buffers
    // ----------------------------------------------------------------
    wire [(NUM_CHANNELS*WR_DATA_WIDTH)-1:0] all_buf_data;
    wire [NUM_CHANNELS-1:0]                 all_buf_valid;
    wire [NUM_CHANNELS-1:0]                 buf_rd_en;

    // ----------------------------------------------------------------
    // Data Buffers Generation
    // ----------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : gen_buffers
            data_buffer #(
                .DATA_WIDTH(WR_DATA_WIDTH)
            ) u_buf (
                .clk        (wr_clk),
                .rst_n      (wr_rst_n),
                .wr_en      (ch_wr_en[i]),
                .wr_data    (ch_wr_data[i*WR_DATA_WIDTH +: WR_DATA_WIDTH]),
                .rd_en      (buf_rd_en[i]),
                .data_valid (all_buf_valid[i]),
                .data       (all_buf_data[i*WR_DATA_WIDTH +: WR_DATA_WIDTH])
            );
        end
    endgenerate

    // ----------------------------------------------------------------
    // CDC for max_bank_size (rd_clk → wr_clk, multi-bit, slow-changing)
    // ----------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] max_bank_size_sync1, max_bank_size_sync2;
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            max_bank_size_sync1 <= {ADDR_WIDTH{1'b0}};
            max_bank_size_sync2 <= {ADDR_WIDTH{1'b0}};
        end else begin
            max_bank_size_sync1 <= max_bank_size;
            max_bank_size_sync2 <= max_bank_size_sync1;
        end
    end

    // ----------------------------------------------------------------
    // Poller, Circular Buffer, and AXI Writer
    // ----------------------------------------------------------------
    wire                      wr_en;
    wire [WR_DATA_WIDTH-1:0]  wr_data;
    wire                      write_finished_ext;
    wire                      write_almost_finished;
    wire                      able_to_read;
    wire                      rd_empty;
    wire [ADDR_WIDTH-1:0]     rd_addr_valid;
    wire [ADDR_WIDTH-1:0]     rd_addr;
    wire                      rd_en;
    wire [RD_DATA_WIDTH-1:0]  rd_data;
    wire                      read_finished;
    wire                      write_finished_ext_sync;

    roll_poll_reader2 #(
        .NUM_CH     (NUM_CHANNELS),
        .DATA_WIDTH (WR_DATA_WIDTH)
    ) u_rr (
        .clk                     (wr_clk),
        .rst_n                   (wr_rst_n),
        .data_valid              (all_buf_valid),
        .data_in                 (all_buf_data),
        .write_almost_finished   (write_almost_finished),
        .N_shot_finished         (N_shot_finished),
        .wr_en                   (wr_en),
        .wr_data                 (wr_data),
        .rd_en                   (buf_rd_en),
        .write_finished_external (write_finished_ext)
    );

    circular_buffer3 #(
        .WR_DATA_WIDTH (WR_DATA_WIDTH),
        .RD_DATA_WIDTH (RD_DATA_WIDTH),
        .ADDR_WIDTH    (ADDR_WIDTH)
    ) u_cbuf (
        .wr_clk                    (wr_clk),
        .wr_rst_n                  (wr_rst_n),
        .rd_clk                    (rd_clk),
        .rd_rst_n                  (rd_rst_n),
        .wr_en                     (wr_en),
        .wr_data                   (wr_data),
        .write_finished_ext        (write_finished_ext),
        .write_almost_finished_out (write_almost_finished),
        .wr_en_out                 (),
        .write_finished_out        (),
        .rd_en                     (rd_en),
        .rd_addr                   (rd_addr),
        .read_finished             (read_finished),
        .rd_data                   (rd_data),
        .able_to_read_out          (able_to_read),
        .rd_addr_valid_out         (rd_addr_valid),
        .rd_empty                  (rd_empty)
    );

    pulse_sync u_sync_wr_fin (
        .src_clk   (wr_clk),
        .src_rst_n (wr_rst_n),
        .src_pulse (write_finished_ext),
        .dst_clk   (rd_clk),
        .dst_rst_n (rd_rst_n),
        .dst_pulse (write_finished_ext_sync)
    );

    circular_buffer_axi_writer #(
        .RD_DATA_WIDTH  (RD_DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH)
    ) u_axi_writer (
        .clk               (rd_clk),
        .rst_n             (rd_rst_n),
        .base_addr         (base_addr),
        .base_reset        (base_reset),
        .able_to_read      (able_to_read),
        .rd_empty          (rd_empty),
        .rd_addr_valid     (rd_addr_valid),
        .rd_data           (rd_data),
        .write_finished_ext(write_finished_ext_sync),
        .rd_addr           (rd_addr),
        .rd_en             (rd_en),
        .read_finished     (read_finished),
        .final_addr        (final_addr),
        .cur_axi_addr_out  (cur_axi_addr_out),
        .current_user_done (current_user_done),
        .m_axi_awaddr      (m_axi_awaddr),
        .m_axi_awlen       (m_axi_awlen),
        .m_axi_awsize      (m_axi_awsize),
        .m_axi_awburst     (m_axi_awburst),
        .m_axi_awvalid     (m_axi_awvalid),
        .m_axi_awready     (m_axi_awready),
        .m_axi_wdata       (m_axi_wdata),
        .m_axi_wstrb       (m_axi_wstrb),
        .m_axi_wlast       (m_axi_wlast),
        .m_axi_wvalid      (m_axi_wvalid),
        .m_axi_wready      (m_axi_wready),
        .m_axi_bresp       (m_axi_bresp),
        .m_axi_bvalid      (m_axi_bvalid),
        .m_axi_bready      (m_axi_bready)
    );

endmodule
