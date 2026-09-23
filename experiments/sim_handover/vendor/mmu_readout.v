// ============================================================================
// mmu_readout.v — Readout MMU (Flat Parameterized Version)
// Optimized for Vivado IP Integrator Compatibility
// ============================================================================

`timescale 1ns/1ps

module mmu_readout #(
    parameter integer NUM_CHANNELS    = 4,     
    parameter integer WR_DATA_WIDTH   = 64,    
    parameter integer AXI_DATA_WIDTH  = 256,   
    parameter integer AXI_ADDR_WIDTH  = 32,    
    parameter integer AXI_ID_WIDTH    = 4,
    parameter integer CBUF_ADDR_WIDTH = 4
)(
    // ===== Clocks & Resets =====
    input  wire                        wr_clk,
    input  wire                        wr_rst_n,
    input  wire                        rd_clk,
    input  wire                        rd_rst_n,

    // ===== Flat Write Channels (wr_clk domain) =====
    // Total width: NUM_CHANNELS bits
    input  wire [NUM_CHANNELS-1:0]     ch_wr_en,
    // Total width: NUM_CHANNELS * 64 bits
    input  wire [(NUM_CHANNELS*WR_DATA_WIDTH)-1:0] ch_wr_data,

    // Configurable bank size for circular_buffer3
    input  wire [CBUF_ADDR_WIDTH-1:0]  max_bank_size,

    // Control/Status
    input  wire                        N_shot_finished,
    input  wire [AXI_ADDR_WIDTH-1:0]   wr_base_addr,
    input  wire                        circuit_id_reset,  // wr_clk run-boundary pulse; doubles
                                                          // as the readout base reset (round 10)
    
    output wire [AXI_ADDR_WIDTH-1:0]   final_addr,
    output wire                        current_user_done,
    output wire [AXI_ADDR_WIDTH-1:0]   cur_axi_addr_out,

    // ===== Read-out control (rd_clk domain) =====
    input  wire                        rd_start,
    output wire                        rd_busy, 
    output wire                        rd_done, 

    // ===== AXI-Stream master out (rd_clk domain) =====
    output wire [AXI_DATA_WIDTH-1:0]   m_axis_tdata,
    output wire                        m_axis_tvalid,
    input  wire                        m_axis_tready,
    output wire                        m_axis_tlast,

    input  wire [AXI_ADDR_WIDTH-1:0]   rd_base_addr,
    input  wire [AXI_ADDR_WIDTH:0]     rd_size_bytes,

    // ===== AXI4-Full Master Interface =====
    output wire [AXI_ID_WIDTH-1:0]     m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]   m_axi_awaddr,
    output wire [7:0]                  m_axi_awlen,
    output wire [2:0]                  m_axi_awsize,
    output wire [1:0]                  m_axi_awburst,
    output wire                        m_axi_awvalid,
    input  wire                        m_axi_awready,

    output wire [AXI_DATA_WIDTH-1:0]   m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                        m_axi_wlast,
    output wire                        m_axi_wvalid,
    input  wire                        m_axi_wready,

    input  wire [AXI_ID_WIDTH-1:0]     m_axi_bid,
    input  wire [1:0]                  m_axi_bresp,
    input  wire                        m_axi_bvalid,
    output wire                        m_axi_bready,

    output wire [AXI_ID_WIDTH-1:0]     m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]   m_axi_araddr,
    output wire [7:0]                  m_axi_arlen,
    output wire [2:0]                  m_axi_arsize,
    output wire [1:0]                  m_axi_arburst,
    output wire                        m_axi_arvalid,
    input  wire                        m_axi_arready,

    input  wire [AXI_ID_WIDTH-1:0]     m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]   m_axi_rdata,
    input  wire [1:0]                  m_axi_rresp,
    input  wire                        m_axi_rlast,
    input  wire                        m_axi_rvalid,
    output wire                        m_axi_rready
);

    // Constant tie-off for AWID
    assign m_axi_awid = {AXI_ID_WIDTH{1'b0}};

    // ------------------- MMU_TAG (Parameterized) -----------------------
    // Round 10: CDC the wr_clk run-boundary pulse to rd_clk (the writer
    // domain) to drive the software base reset. Single deterministic pulse
    // (no able_to_read race) — issued by the host during run setup while
    // GLOBAL_START=0, so the writer is guaranteed quiescent on arrival.
    wire base_reset_rd;
    pulse_sync u_base_reset_sync (
        .src_clk   (wr_clk),
        .src_rst_n (wr_rst_n),
        .src_pulse (circuit_id_reset),
        .dst_clk   (rd_clk),
        .dst_rst_n (rd_rst_n),
        .dst_pulse (base_reset_rd)
    );

    mmu_para #(
        .NUM_CHANNELS    (NUM_CHANNELS),
        .WR_DATA_WIDTH   (WR_DATA_WIDTH),
        .RD_DATA_WIDTH   (AXI_DATA_WIDTH),
        .ADDR_WIDTH      (CBUF_ADDR_WIDTH),
        .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH)
    ) u_mmu_tag_w (
        .wr_clk           (wr_clk),
        .wr_rst_n         (wr_rst_n),
        .rd_clk           (rd_clk),
        .rd_rst_n         (rd_rst_n),

        // Pass flat vectors directly
        .ch_wr_en         (ch_wr_en),
        .ch_wr_data       (ch_wr_data),
        .max_bank_size    (max_bank_size),

        .N_shot_finished  (N_shot_finished),
        .base_addr        (wr_base_addr),
        .base_reset       (base_reset_rd),

        .final_addr       (final_addr),
        .current_user_done(current_user_done),
        .cur_axi_addr_out (cur_axi_addr_out),

        .m_axi_awaddr     (m_axi_awaddr),
        .m_axi_awlen      (m_axi_awlen),
        .m_axi_awsize     (m_axi_awsize),
        .m_axi_awburst    (m_axi_awburst),
        .m_axi_awvalid    (m_axi_awvalid),
        .m_axi_awready    (m_axi_awready),

        .m_axi_wdata      (m_axi_wdata),
        .m_axi_wstrb      (m_axi_wstrb),
        .m_axi_wlast      (m_axi_wlast),
        .m_axi_wvalid     (m_axi_wvalid),
        .m_axi_wready     (m_axi_wready),

        .m_axi_bresp      (m_axi_bresp),
        .m_axi_bvalid     (m_axi_bvalid),
        .m_axi_bready     (m_axi_bready)
    );

    // ------------------- mmu2 (Read Master) -------------------
    mmu2 #(
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ID_WIDTH   (AXI_ID_WIDTH),
        .FIFO_ADDR_BITS (4)
    ) u_mmu_r (
        .clk            (rd_clk),
        .rst_n          (rd_rst_n),
        .start          (rd_start),
        .busy           (rd_busy),
        .done           (rd_done),
        .base_addr      (rd_base_addr),
        .size_bytes     (rd_size_bytes),
        .arid           (m_axi_arid),
        .araddr         (m_axi_araddr),
        .arlen          (m_axi_arlen),
        .arsize         (m_axi_arsize),
        .arburst        (m_axi_arburst),
        .arvalid        (m_axi_arvalid),
        .arready        (m_axi_arready),
        .rid            (m_axi_rid),
        .rdata          (m_axi_rdata),
        .rresp          (m_axi_rresp),
        .rlast          (m_axi_rlast),
        .rvalid         (m_axi_rvalid),
        .rready         (m_axi_rready),
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tlast   (m_axis_tlast)
    );

endmodule
