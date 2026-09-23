`timescale 1ns/1ns

module axi_dpram #(
    parameter integer AXI_ADDR_WIDTH = 16,
    parameter integer AXI_DATA_WIDTH = 256,
    parameter integer AXI_ID_WIDTH   = 4,
    parameter integer MEM_AW         = 11,                 // words depth = 2**MEM_AW
    parameter integer MEM_DW         = AXI_DATA_WIDTH
)(
    input  wire                         aclk,
    input  wire                         aresetn,

    // Write Address
    input  wire [AXI_ID_WIDTH-1:0]      s_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]                   s_axi_awlen,
    input  wire [2:0]                   s_axi_awsize,
    input  wire [1:0]                   s_axi_awburst,
    input  wire                         s_axi_awvalid,
    output wire                         s_axi_awready,

    // Write Data
    input  wire [AXI_DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [AXI_DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input  wire                         s_axi_wlast,
    input  wire                         s_axi_wvalid,
    output wire                         s_axi_wready,

    // Write Response
    output reg  [AXI_ID_WIDTH-1:0]      s_axi_bid,
    output reg  [1:0]                   s_axi_bresp,
    output reg                          s_axi_bvalid,
    input  wire                         s_axi_bready,

    // Read Address
    input  wire [AXI_ID_WIDTH-1:0]      s_axi_arid,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [7:0]                   s_axi_arlen,
    input  wire [2:0]                   s_axi_arsize,
    input  wire [1:0]                   s_axi_arburst,
    input  wire                         s_axi_arvalid,
    output wire                         s_axi_arready,

    // Read Data
    output reg  [AXI_ID_WIDTH-1:0]      s_axi_rid,
    output wire [AXI_DATA_WIDTH-1:0]    s_axi_rdata,
    output reg  [1:0]                   s_axi_rresp,
    output reg                          s_axi_rlast,
    output reg                          s_axi_rvalid,
    input  wire                         s_axi_rready
);

    // ------------------------------------------------------------------------
    // Address conversion: AXI byte address -> word address
    // ------------------------------------------------------------------------
    localparam integer ADDR_LSB = (MEM_DW > 8) ? $clog2(MEM_DW/8) : 0;

    // ------------------------------------------------------------------------
    // DPRAM instance (port A: write, port B: read)
    // ------------------------------------------------------------------------
    wire [MEM_DW-1:0] ram_douta;
    wire [MEM_DW-1:0] ram_doutb;
    wire [MEM_DW-1:0] ram_doutb_comb;
    reg  [MEM_AW-1:0] ram_addra;
    reg  [MEM_AW-1:0] ram_addrb;
    reg  [MEM_DW-1:0] ram_dina;
    reg               ram_wena;

    dpram #(
        .aw(MEM_AW),
        .dw(MEM_DW)
    ) u_dpram (
        .clka  (aclk),
        .clkb  (aclk),
        .addra (ram_addra),
        .douta (ram_douta),
        .dina  (ram_dina),
        .wena  (ram_wena),
        .addrb (ram_addrb),
        .doutb (ram_doutb),
        .doutb_comb (ram_doutb_comb)
    );

    // RDATA tracks the CURRENT beat address combinationally.
    // BUG FIX (2026-06-09): the registered RAM output (ram_doutb) lags
    // ram_addrb by one cycle; with the R_BURST FSM advancing the address
    // only on each accepted beat, back-to-back reads (RREADY held high)
    // delivered [A, A, A+1, ..., A+N-2] — first beat duplicated, last
    // address never delivered. Using the combinational mirror makes
    // rdata == mem[ram_addrb] by construction: stall-stable (address
    // only advances on an accepted beat) and no prefetch bookkeeping.
    assign s_axi_rdata = ram_doutb_comb;

    // ------------------------------------------------------------------------
    // Write channel FSM
    // ------------------------------------------------------------------------
    localparam [1:0] W_IDLE  = 2'd0,
                     W_DATA  = 2'd1,
                     W_RESP  = 2'd2,
                     W_STALL = 2'd3;

    // Simulate DDR stall (e.g., refresh) after each burst
    `ifdef DDR_STALL_CYCLES
    localparam integer STALL_CYCLES = `DDR_STALL_CYCLES;
    `else
    localparam integer STALL_CYCLES = 0;
    `endif
    reg [15:0] stall_cnt;

    reg [1:0]              wstate;
    reg [AXI_ID_WIDTH-1:0] awid_r;
    reg [MEM_AW-1:0]       waddr;
    reg [7:0]              wlen_cnt;     // remaining beats (AWLEN)
    reg [1:0]              awburst_r;

    assign s_axi_awready = (wstate == W_IDLE);
    assign s_axi_wready  = (wstate == W_DATA);

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wstate       <= W_IDLE;
            awid_r       <= {AXI_ID_WIDTH{1'b0}};
            waddr        <= {MEM_AW{1'b0}};
            wlen_cnt     <= 8'd0;
            awburst_r    <= 2'b01;              // INCR
            s_axi_bid    <= {AXI_ID_WIDTH{1'b0}};
            s_axi_bresp  <= 2'b00;
            s_axi_bvalid <= 1'b0;
            ram_wena     <= 1'b0;
            ram_addra    <= {MEM_AW{1'b0}};
            ram_dina     <= {MEM_DW{1'b0}};
        end else begin
            // default
            ram_wena <= 1'b0;

            case (wstate)
                W_IDLE: begin
                    if (s_axi_awvalid && s_axi_awready) begin
                        awid_r       <= s_axi_awid;
                        s_axi_bid    <= s_axi_awid;
                        waddr        <= s_axi_awaddr[ADDR_LSB + MEM_AW - 1 : ADDR_LSB];
                        wlen_cnt     <= s_axi_awlen;        // beats-1
                        awburst_r    <= s_axi_awburst;
                        s_axi_bresp  <= 2'b00;              // OKAY
                        s_axi_bvalid <= 1'b0;
                        wstate       <= W_DATA;
                    end
                end

                W_DATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        // Full word write; ignore wstrb
                        ram_addra <= waddr;
                        ram_dina  <= s_axi_wdata;
                        ram_wena  <= 1'b1;

                        // next address if INCR burst
                        if (awburst_r == 2'b01) begin
                            waddr <= waddr + 1'b1;
                        end

                        // last beat?
                        if (s_axi_wlast || (wlen_cnt == 8'd0)) begin
                            s_axi_bvalid <= 1'b1;
                            wstate       <= W_RESP;
                        end else begin
                            wlen_cnt <= wlen_cnt - 1'b1;
                        end
                    end
                end

                W_RESP: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        if (STALL_CYCLES > 0) begin
                            stall_cnt <= 16'd0;
                            wstate    <= W_STALL;
                        end else begin
                            wstate    <= W_IDLE;
                        end
                    end
                end

                W_STALL: begin
                    if (stall_cnt >= STALL_CYCLES - 1)
                        wstate <= W_IDLE;
                    else
                        stall_cnt <= stall_cnt + 16'd1;
                end

                default: begin
                    wstate <= W_IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // Read channel FSM (1-cycle latency for synchronous RAM read)
    // ------------------------------------------------------------------------
    localparam [1:0] R_IDLE  = 2'd0,
                     R_BURST = 2'd1;

    reg [1:0]        rstate;
    reg [MEM_AW-1:0] raddr;
    reg [7:0]        rlen_cnt;        // remaining beats (ARLEN)
    reg [1:0]        arburst_r;

    assign s_axi_arready = (rstate == R_IDLE);

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rstate       <= R_IDLE;
            raddr        <= {MEM_AW{1'b0}};
            rlen_cnt     <= 8'd0;
            arburst_r    <= 2'b01;          // INCR

            s_axi_rid    <= {AXI_ID_WIDTH{1'b0}};
            s_axi_rresp  <= 2'b00;
            s_axi_rlast  <= 1'b0;
            s_axi_rvalid <= 1'b0;

            ram_addrb    <= {MEM_AW{1'b0}};
        end else begin
            case (rstate)
                R_IDLE: begin
                    s_axi_rvalid <= 1'b0;
                    s_axi_rlast  <= 1'b0;

                    if (s_axi_arvalid && s_axi_arready) begin
                        raddr       <= s_axi_araddr[ADDR_LSB + MEM_AW - 1 : ADDR_LSB];
                        ram_addrb   <= s_axi_araddr[ADDR_LSB + MEM_AW - 1 : ADDR_LSB];
                        rlen_cnt    <= s_axi_arlen;           // beats-1
                        arburst_r   <= s_axi_arburst;
                        s_axi_rid   <= s_axi_arid;
                        s_axi_rresp <= 2'b00;                 // OKAY

                        // rdata tracks ram_addrb combinationally (see fix note above)
                        rstate      <= R_BURST;
                    end
                end

                R_BURST: begin
                    // rdata = mem[ram_addrb] combinationally; ram_addrb is the
                    // address of the beat CURRENTLY presented and only advances
                    // when that beat is accepted.
                    // Back-to-back burst: keep rvalid high after initial assertion.
                    if (!s_axi_rvalid) begin
                        // First cycle: data just arrived from RAM, assert rvalid
                        s_axi_rvalid <= 1'b1;
                        s_axi_rlast  <= (rlen_cnt == 8'd0);
                    end else if (s_axi_rready) begin
                        // Handshake this beat
                        if (s_axi_rlast) begin
                            // Last beat of burst
                            s_axi_rvalid <= 1'b0;
                            s_axi_rlast  <= 1'b0;
                            rstate       <= R_IDLE;
                        end else begin
                            // Pipeline: advance address, keep rvalid high
                            if (arburst_r == 2'b01) begin  // INCR
                                raddr     <= raddr + 1'b1;
                                ram_addrb <= raddr + 1'b1;
                            end else begin                 // FIXED or others
                                ram_addrb <= raddr;
                            end
                            rlen_cnt    <= rlen_cnt - 1'b1;
                            s_axi_rlast <= (rlen_cnt == 8'd1); // pre-compute for next beat
                            // rvalid stays high (no deassert)
                        end
                    end
                    // else: rvalid=1 && rready=0 → stall, hold state
                end

                default: begin
                    rstate <= R_IDLE;
                end
            endcase
        end
    end

endmodule
