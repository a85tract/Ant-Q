module dc_offset#(
    parameter NBITS=16,
    parameter DELAY=8,
    parameter SAMPLES_PER_CLK=16)(
    input clk,
    input reset,
    input enable,
    input[NBITS-1:0] amplitude,
    output [NBITS*SAMPLES_PER_CLK-1:0] dc_out);

    reg[NBITS*SAMPLES_PER_CLK-1:0] dc_reg;

    always @(posedge clk) begin
        if(reset)
            dc_reg <= 0;
        else if(enable)
            dc_reg <= {SAMPLES_PER_CLK{amplitude}};
    end

    reg_delay1 #(.DW(NBITS*SAMPLES_PER_CLK), .LEN(DELAY)) delay(
        .clk(clk), .reset(reset), .gate(1),
        .din(dc_reg), .dout(dc_out));

endmodule
