`timescale 1ns/1ps

// AXI Read Master: fetches a chunk from DDR (2x256-beat bursts)
// and writes 256-bit data directly to the ping-pong buffer.

module chunk_fetcher #(
    parameter integer SHORT_BEATS     = 8,     // [CE] beats fetched for a masked channel (one burst; 8 x 32 B = 16 instructions)
    parameter integer AXI_DATA_WIDTH  = 256,
    parameter integer AXI_ADDR_WIDTH  = 32,
    parameter integer AXI_ID_WIDTH    = 4,
    parameter integer BEATS_PER_CHUNK = 1024,
    parameter integer MAX_BURST_LEN   = 256,
    parameter integer FETCH_DELAY     = 0
)(
    input  wire                          clk,
    input  wire                          rst_n,

    // Control
    input  wire                          enable,     // start fetching when high
    input  wire                          short_chunk, // [CE] 1 = unused channel: fetch SHORT_BEATS beats from idle_addr (the batch's idle program)
    input  wire [AXI_ADDR_WIDTH-1:0]     idle_addr,   // [CE] DDR address of the idle program slot

    // Chunk address from ddr_chunk_fifo_ctrl
    input  wire [AXI_ADDR_WIDTH-1:0]     chunk_addr,
    input  wire                          fifo_empty, // DDR FIFO empty flag

    // Chunk done pulse to ddr_chunk_fifo_ctrl
    output reg                           chunk_done,

    // Interface to ping_pong_buffer (write side)
    output reg                           ppbuf_wr_en,
    output reg  [AXI_DATA_WIDTH-1:0]     ppbuf_wr_data,
    output reg                           ppbuf_write_finished_ext,
    input  wire                          ppbuf_write_finished,
    input  wire                          ppbuf_write_almost_finished,

    // AXI4-Full Read Address Channel
    output reg  [AXI_ID_WIDTH-1:0]       m_axi_arid,
    output reg  [AXI_ADDR_WIDTH-1:0]     m_axi_araddr,
    output reg  [7:0]                    m_axi_arlen,
    output reg  [2:0]                    m_axi_arsize,
    output reg  [1:0]                    m_axi_arburst,
    output reg                           m_axi_arvalid,
    input  wire                          m_axi_arready,

    // AXI4-Full Read Data Channel
    input  wire [AXI_ID_WIDTH-1:0]       m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]     m_axi_rdata,
    input  wire [1:0]                    m_axi_rresp,
    input  wire                          m_axi_rlast,
    input  wire                          m_axi_rvalid,
    output wire                          m_axi_rready
);

    // ----------------------------------------------------------------
    // Local parameters
    // ----------------------------------------------------------------
    localparam integer AXI_SIZE        = $clog2(AXI_DATA_WIDTH / 8);
    localparam integer BYTES_PER_BEAT  = AXI_DATA_WIDTH / 8;
    localparam integer BURSTS_PER_CHUNK = BEATS_PER_CHUNK / MAX_BURST_LEN;

    // FSM states
    localparam [2:0] ST_IDLE       = 3'd0,
                     ST_WAIT_PPBUF = 3'd1,
                     ST_AR         = 3'd2,
                     ST_READ       = 3'd3,
                     ST_BURST_DONE = 3'd4,
                     ST_COOLDOWN   = 3'd5,
                     ST_DELAY      = 3'd6;

    // ----------------------------------------------------------------
    // Registers
    // ----------------------------------------------------------------
    reg [2:0]  state;
    reg [8:0]  beat_count;       // beats received within current burst
    // widths derived from BEATS_PER_CHUNK (Codex #79 / 2048 expansion):
    // the old hardwired [0:0]/[9:0] silently wrapped at 4 bursts / 1024
    // beats and locked the fetch FSM.
    localparam integer BURST_IDX_W = (BURSTS_PER_CHUNK > 1) ? $clog2(BURSTS_PER_CHUNK) : 1;
    localparam integer TB_W        = $clog2(BEATS_PER_CHUNK) + 1;
    reg [BURST_IDX_W-1:0] burst_idx;
    reg [TB_W-1:0]        total_beats; // total beats written to ppbuf in this chunk
    reg [AXI_ADDR_WIDTH-1:0] latched_addr;
    reg        short_latched;    // [CE] short_chunk sampled with chunk_addr at ST_IDLE
    reg [15:0] delay_cnt;

    // Accept read data when not backpressured by ppbuf
    assign m_axi_rready = (state == ST_READ);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= ST_IDLE;
            beat_count     <= 9'd0;
            burst_idx      <= {BURST_IDX_W{1'b0}};
            total_beats    <= {TB_W{1'b0}};
            latched_addr   <= {AXI_ADDR_WIDTH{1'b0}};
            short_latched  <= 1'b0;
            chunk_done     <= 1'b0;

            ppbuf_wr_en              <= 1'b0;
            ppbuf_wr_data            <= {AXI_DATA_WIDTH{1'b0}};
            ppbuf_write_finished_ext <= 1'b0;

            m_axi_arid     <= {AXI_ID_WIDTH{1'b0}};
            m_axi_araddr   <= {AXI_ADDR_WIDTH{1'b0}};
            m_axi_arlen    <= 8'd0;
            m_axi_arsize   <= AXI_SIZE[2:0];
            m_axi_arburst  <= 2'b01;
            m_axi_arvalid  <= 1'b0;
        end else begin
            // Defaults
            chunk_done               <= 1'b0;
            ppbuf_wr_en              <= 1'b0;
            ppbuf_write_finished_ext <= 1'b0;

            case (state)
                // --------------------------------------------------------
                ST_IDLE: begin
                    m_axi_arvalid <= 1'b0;

                    if (enable && !fifo_empty) begin
                        latched_addr <= short_chunk ? idle_addr : chunk_addr;   // [CE]
                        short_latched <= short_chunk;
                        burst_idx    <= {BURST_IDX_W{1'b0}};
                        total_beats  <= {TB_W{1'b0}};
                        if (FETCH_DELAY > 0) begin
                            delay_cnt <= 16'd0;
                            state     <= ST_DELAY;
                        end else begin
                            state     <= ST_WAIT_PPBUF;
                        end
                    end
                end

                // --------------------------------------------------------
                // Wait for ppbuf to be ready (not finished writing = bank available)
                ST_WAIT_PPBUF: begin
                    if (!ppbuf_write_finished) begin
                        // Issue AR for current burst
                        m_axi_araddr  <= latched_addr + (burst_idx * MAX_BURST_LEN * BYTES_PER_BEAT);
                        m_axi_arlen   <= short_latched ? (SHORT_BEATS - 1) : (MAX_BURST_LEN - 1);  // [CE] SHORT_BEATS or 256 beats
                        m_axi_arsize  <= AXI_SIZE[2:0];
                        m_axi_arburst <= 2'b01;
                        m_axi_arvalid <= 1'b1;

                        beat_count <= 9'd0;
                        state      <= ST_AR;
                    end
                end

                // --------------------------------------------------------
                ST_AR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        state         <= ST_READ;
                    end
                end

                // --------------------------------------------------------
                ST_READ: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        // Write received data to ppbuf
                        ppbuf_wr_en   <= 1'b1;
                        ppbuf_wr_data <= m_axi_rdata;

                        beat_count  <= beat_count + 1'b1;
                        total_beats <= total_beats + 1'b1;

                        if (m_axi_rlast || (beat_count == MAX_BURST_LEN - 1)) begin
                            state <= ST_BURST_DONE;
                        end
                    end
                end

                // --------------------------------------------------------
                ST_BURST_DONE: begin
                    if (short_latched || (burst_idx == BURSTS_PER_CHUNK[BURST_IDX_W-1:0] - 1'b1)) begin   // [CE]
                        // All bursts done — signal ppbuf and fifo_ctrl
                        ppbuf_write_finished_ext <= 1'b1;
                        chunk_done               <= 1'b1;
                        burst_idx                <= {BURST_IDX_W{1'b0}};
                        // Wait one cycle for fifo_ctrl to update rd_ptr
                        // before re-entering ST_IDLE (which latches chunk_addr)
                        state                    <= ST_COOLDOWN;
                    end else begin
                        burst_idx <= burst_idx + 1'b1;
                        state     <= ST_WAIT_PPBUF;
                    end
                end

                // --------------------------------------------------------
                // One-cycle cooldown: lets fifo_ctrl register the
                // chunk_done pulse and update rd_ptr / count before
                // ST_IDLE re-checks fifo_empty / chunk_addr.
                ST_COOLDOWN: begin
                    state <= ST_IDLE;
                end

                // --------------------------------------------------------
                // Optional delay before fetching (parameterised by FETCH_DELAY)
                ST_DELAY: begin
                    if (delay_cnt >= FETCH_DELAY - 1) begin
                        state <= ST_WAIT_PPBUF;
                    end else begin
                        delay_cnt <= delay_cnt + 16'd1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
