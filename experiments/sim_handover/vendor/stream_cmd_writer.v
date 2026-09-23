`timescale 1ns/1ps

// AXI-Stream CMD Writer: receives a 256-bit AXI-Stream of packed commands,
// buffers in a FIFO, and bursts to DDR. Writes ALL NUM_CHANNELS channels
// sequentially (0..NUM_CHANNELS-1), BURSTS_PER_CHUNK bursts of
// MAX_BURST_LEN beats per channel (BEATS_PER_CHUNK beats per chunk =
// 2*BEATS_PER_CHUNK 128-bit cmds). Fires unit_done after all chunks written.
//
// Simplified version (ring_buffer_simple): no channel enable — the host
// must supply exactly NUM_CHANNELS x BEATS_PER_CHUNK beats per unit
// (unused channels filled with zeros).

module stream_cmd_writer #(
    parameter integer AXI_DATA_WIDTH  = 256,
    parameter integer AXI_ADDR_WIDTH  = 32,
    parameter integer AXI_ID_WIDTH    = 4,
    parameter integer NUM_CHANNELS    = 4,
    parameter integer BEATS_PER_CHUNK = 1024,
    parameter integer MAX_BURST_LEN   = 256,
    parameter integer SHORT_BEATS     = 8       // [CE] beats of the idle program (== chunk_fetcher SHORT_BEATS)
)(
    input  wire                          clk,
    input  wire                          rst_n,

    // AXI-Stream slave input (256-bit, 2 cmds per beat)
    input  wire [AXI_DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire                         s_axis_tvalid,
    output wire                         s_axis_tready,

    // DDR FIFO control
    input  wire [AXI_ADDR_WIDTH-1:0]    unit_addr,
    input  wire                         fifo_full,    // DDR FIFO full flag
    input  wire [NUM_CHANNELS-1:0]      ch_mask,      // [CE] mask of the unit about to be / being written (1 = channel NOT uploaded, skipped)
    input  wire                         mask_ready,   // [CE] ch_mask is valid for the next unit (gates the unit's first burst)
    input  wire                         idle_load,    // [CE] level: the next SHORT_BEATS beats are the batch's idle program -> idle_addr
    input  wire [AXI_ADDR_WIDTH-1:0]    idle_addr,    // [CE] DDR address of the idle program slot (outside the unit ring)
    output reg                          idle_done,    // [CE] 1-cycle pulse: idle program written
    output reg                          unit_done,    // pulse: all chunks written

    // AXI4-Full Write Address Channel
    output reg  [AXI_ID_WIDTH-1:0]      m_axi_awid,
    output reg  [AXI_ADDR_WIDTH-1:0]    m_axi_awaddr,
    output reg  [7:0]                   m_axi_awlen,
    output reg  [2:0]                   m_axi_awsize,
    output reg  [1:0]                   m_axi_awburst,
    output reg                          m_axi_awvalid,
    input  wire                         m_axi_awready,

    // AXI4-Full Write Data Channel
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_wdata,
    output reg  [AXI_DATA_WIDTH/8-1:0]  m_axi_wstrb,
    output reg                          m_axi_wlast,
    output reg                          m_axi_wvalid,
    input  wire                         m_axi_wready,

    // AXI4-Full Write Response Channel
    input  wire [AXI_ID_WIDTH-1:0]      m_axi_bid,
    input  wire [1:0]                   m_axi_bresp,
    input  wire                         m_axi_bvalid,
    output reg                          m_axi_bready
);

    // ----------------------------------------------------------------
    // Local parameters
    // ----------------------------------------------------------------
    localparam integer AXI_SIZE          = $clog2(AXI_DATA_WIDTH / 8);  // 5 for 256-bit
    localparam integer BYTES_PER_BEAT    = AXI_DATA_WIDTH / 8;          // 32
    // derived (Codex #79): = $clog2(BEATS_PER_CHUNK * bytes/beat); never hardcode
    localparam integer PER_CH_OFFSET_LSB = $clog2(BEATS_PER_CHUNK * (AXI_DATA_WIDTH / 8));
    localparam integer BURSTS_PER_CHUNK  = BEATS_PER_CHUNK / MAX_BURST_LEN; // derived
    localparam integer FIFO_DEPTH        = 512;
    localparam integer CH_IDX_W          = (NUM_CHANNELS > 1) ? $clog2(NUM_CHANNELS) : 1;

    // FSM states
    localparam [2:0] ST_IDLE      = 3'd0,
                     ST_AW        = 3'd1,
                     ST_WRITE     = 3'd2,
                     ST_WAIT_B    = 3'd3,
                     ST_COOLDOWN  = 3'd4,  // cycle 1: DDR FIFO ptr advances
                     ST_COOLDOWN2 = 3'd5;  // cycle 2: reset cur_channel for next unit

    // ----------------------------------------------------------------
    // Internal FIFO (single-clock, 256-bit x 512)
    // ----------------------------------------------------------------
    wire                      fifo_wr_en;
    wire [AXI_DATA_WIDTH-1:0] fifo_wr_data;
    wire                      fifo_rd_en;
    wire [AXI_DATA_WIDTH-1:0] fifo_rd_data;
    wire                      fifo_empty;
    wire                      fifo_full_int;
    wire                      fifo_almost_full;

    // Accept AXI-Stream when internal FIFO not full and DDR FIFO not full
    assign s_axis_tready = !fifo_full_int && !fifo_full;
    assign fifo_wr_en    = s_axis_tvalid && s_axis_tready;
    assign fifo_wr_data  = s_axis_tdata;

    async_fifo_same #(
        .DW    (AXI_DATA_WIDTH),
        .DEPTH (FIFO_DEPTH)
    ) u_fifo (
        .clk     (clk),
        .rstn    (rst_n),
        .wr_en   (fifo_wr_en),
        .wr_data (fifo_wr_data),
        .full    (fifo_full_int),
        .almost_full (fifo_almost_full),
        .rd_en   (fifo_rd_en),
        .rd_data (fifo_rd_data),
        .empty   (fifo_empty)
    );

    // ----------------------------------------------------------------
    // FIFO level counter
    // ----------------------------------------------------------------
    reg [9:0] fifo_level;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_level <= 10'd0;
        end else begin
            case ({fifo_wr_en && !fifo_full_int, fifo_rd_en && !fifo_empty})
                2'b10:   fifo_level <= fifo_level + 1'b1;
                2'b01:   fifo_level <= fifo_level - 1'b1;
                default: ;
            endcase
        end
    end

    // ----------------------------------------------------------------
    // AXI Burst Engine FSM
    // ----------------------------------------------------------------
    reg [2:0]  state;
    reg [8:0]  beat_count;     // 0..255 within burst
    reg [CH_IDX_W-1:0] cur_channel;
    // burst index within the per-channel chunk: generalized from the old
    // hardwired 2-burst (1-bit) structure so it scales with BEATS_PER_CHUNK
    // (Codex #79 / 2048-cmd expansion: 1024 beats = 4 bursts of 256).
    localparam integer BURST_IDX_W = (BURSTS_PER_CHUNK > 1) ? $clog2(BURSTS_PER_CHUNK) : 1;
    reg [BURST_IDX_W-1:0] burst_idx;
    reg        in_unit;    // set at the unit's first burst/skip, cleared at unit_done
    reg        idle_burst; // [CE] the burst in flight is the idle-program write
    wire       cur_masked = ch_mask[cur_channel];
    wire [8:0] cur_blen   = idle_burst ? SHORT_BEATS[8:0] : MAX_BURST_LEN[8:0];

    assign m_axi_wdata = fifo_rd_data;

    wire w_handshake = m_axi_wvalid && m_axi_wready;
    assign fifo_rd_en = (state == ST_WRITE) && w_handshake;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= ST_IDLE;
            beat_count   <= 9'd0;
            cur_channel  <= {CH_IDX_W{1'b0}};
            burst_idx    <= {BURST_IDX_W{1'b0}};
            unit_done    <= 1'b0;
            in_unit      <= 1'b0;
            idle_burst   <= 1'b0;
            idle_done    <= 1'b0;

            m_axi_awid    <= {AXI_ID_WIDTH{1'b0}};
            m_axi_awaddr  <= {AXI_ADDR_WIDTH{1'b0}};
            m_axi_awlen   <= 8'd0;
            m_axi_awsize  <= AXI_SIZE[2:0];
            m_axi_awburst <= 2'b01;
            m_axi_awvalid <= 1'b0;

            m_axi_wstrb  <= {AXI_DATA_WIDTH/8{1'b0}};
            m_axi_wlast  <= 1'b0;
            m_axi_wvalid <= 1'b0;

            m_axi_bready <= 1'b0;
        end else begin
            unit_done    <= 1'b0;
            idle_done    <= 1'b0;
            m_axi_bready <= 1'b1;

            case (state)
                // --------------------------------------------------------
                ST_IDLE: begin
                    m_axi_awvalid <= 1'b0;
                    m_axi_wvalid  <= 1'b0;
                    m_axi_wlast   <= 1'b0;

                    // Start burst when FIFO has a full burst and DDR FIFO not full.
                    // cur_channel is 0 after reset and after each unit (COOLDOWN2).
                    if (idle_load && !in_unit) begin
                        // [CE] idle-program upload: one burst of SHORT_BEATS beats to the idle slot
                        if (fifo_level >= SHORT_BEATS) begin
                            idle_burst    <= 1'b1;
                            m_axi_awaddr  <= idle_addr;
                            m_axi_awlen   <= SHORT_BEATS - 1;
                            m_axi_awsize  <= AXI_SIZE[2:0];
                            m_axi_awburst <= 2'b01;
                            m_axi_awvalid <= 1'b1;
                            beat_count <= 9'd0;
                            state      <= ST_AW;
                        end
                    end else if ((in_unit || mask_ready) && cur_masked) begin
                        // [CE] masked channel: nothing was uploaded for it -> skip without a burst
                        // (an all-masked unit ends with unit_done and no data at all)
                        in_unit <= 1'b1;
                        if (cur_channel == NUM_CHANNELS - 1) begin
                            unit_done <= 1'b1; in_unit <= 1'b0; state <= ST_COOLDOWN;
                        end else begin
                            cur_channel <= cur_channel + 1'b1;
                        end
                    end else if (fifo_level >= MAX_BURST_LEN && !fifo_full && (in_unit || mask_ready)) begin
                        in_unit       <= 1'b1;
                        m_axi_awaddr  <= unit_addr
                                       + ({{(AXI_ADDR_WIDTH-CH_IDX_W){1'b0}}, cur_channel} << PER_CH_OFFSET_LSB)
                                       + (burst_idx * MAX_BURST_LEN * BYTES_PER_BEAT);
                        m_axi_awlen   <= MAX_BURST_LEN - 1;  // 255
                        m_axi_awsize  <= AXI_SIZE[2:0];
                        m_axi_awburst <= 2'b01;
                        m_axi_awvalid <= 1'b1;
                        beat_count <= 9'd0;
                        state      <= ST_AW;
                    end
                end

                // --------------------------------------------------------
                ST_AW: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wstrb   <= {AXI_DATA_WIDTH/8{1'b1}};
                        m_axi_wvalid  <= 1'b1;
                        m_axi_wlast   <= 1'b0;
                        state         <= ST_WRITE;
                    end
                end

                // --------------------------------------------------------
                ST_WRITE: begin
                    if (w_handshake) begin
                        beat_count <= beat_count + 1'b1;

                        if (beat_count == cur_blen - 2) begin
                            m_axi_wlast <= 1'b1;
                        end

                        if (beat_count == cur_blen - 1) begin
                            m_axi_wvalid <= 1'b0;
                            m_axi_wlast  <= 1'b0;
                            state        <= ST_WAIT_B;
                        end
                    end
                end

                // --------------------------------------------------------
                ST_WAIT_B: begin
                    m_axi_wvalid <= 1'b0;

                    if (m_axi_bvalid && idle_burst) begin
                        idle_burst <= 1'b0; idle_done <= 1'b1;      // [CE] idle program landed
                        state <= ST_IDLE;
                    end else if (m_axi_bvalid) begin
                        if (burst_idx != BURSTS_PER_CHUNK[BURST_IDX_W-1:0] - 1'b1) begin
                            // More bursts remain in this channel's chunk
                            burst_idx <= burst_idx + 1'b1;
                            state <= ST_IDLE;
                        end else begin
                            // Last burst of channel done
                            burst_idx <= {BURST_IDX_W{1'b0}};
                            if (cur_channel == NUM_CHANNELS - 1) begin
                                // Last channel -> unit complete
                                unit_done    <= 1'b1;
                                in_unit      <= 1'b0;
                                // Cooldown: wait 1 cycle for FIFO write pointer
                                // to advance before latching next unit_addr
                                state <= ST_COOLDOWN;
                            end else begin
                                cur_channel <= cur_channel + 1'b1;
                                state <= ST_IDLE;
                            end
                        end
                    end
                end

                // --------------------------------------------------------
                ST_COOLDOWN: begin
                    // Cycle 1: DDR FIFO ptr has advanced.
                    state <= ST_COOLDOWN2;
                end

                ST_COOLDOWN2: begin
                    // Cycle 2: reset cur_channel for the next unit.
                    cur_channel <= {CH_IDX_W{1'b0}};
                    state <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
