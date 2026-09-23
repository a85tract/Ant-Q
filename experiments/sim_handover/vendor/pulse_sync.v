// ============================================================================
// pulse_sync.v
//
// Robust Pulse Synchronizer (Rising Edge Triggered)
//
// Mechanism:
// 1. Source: Detects RISING EDGE of input pulse.
// 2. Source: Flips a toggle bit only on that rising edge.
// 3. Dest:   Synchronizes the toggle level (double-flop).
// 4. Dest:   Detects the toggle edge to generate a single-cycle output pulse.
// ============================================================================

`timescale 1ns/1ps

module pulse_sync (
    // Source Domain
    input  wire src_clk,
    input  wire src_rst_n,
    input  wire src_pulse,

    // Destination Domain
    input  wire dst_clk,
    input  wire dst_rst_n,
    output wire dst_pulse
);

    // ========================================================================
    // 1. Source Domain: Edge Detection & Toggle Generation
    // ========================================================================
    reg src_pulse_d; // Delayed version for edge detection
    reg src_toggle;  // The signal that crosses the domain

    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_pulse_d <= 1'b0;
            src_toggle  <= 1'b0;
        end else begin
            src_pulse_d <= src_pulse;

            // RISING EDGE DETECT: 
            // Only toggle if current is 1 AND previous was 0.
            // This prevents "machine gunning" pulses if src_pulse is wide.
            if (src_pulse && !src_pulse_d) begin
                src_toggle <= ~src_toggle;
            end
        end
    end

    // ========================================================================
    // 2. Destination Domain: Synchronization
    // ========================================================================
    // We use a 3-bit shift register:
    // [0] = Capture (Meta)
    // [1] = Stable
    // [2] = Delayed (For edge detection)
    reg [2:0] dst_sync;

    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync <= 3'b000;
        end else begin
            // Shift in the toggle signal from source
            dst_sync <= {dst_sync[1:0], src_toggle};
        end
    end

    // ========================================================================
    // 3. Destination Domain: Pulse Reconstruction
    // ========================================================================
    // If the stable bit (bit 1) differs from the delayed bit (bit 2), 
    // a toggle occurred in the source domain.
    assign dst_pulse = dst_sync[2] ^ dst_sync[1];

endmodule
