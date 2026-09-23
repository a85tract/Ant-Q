`timescale 1ns / 1ns

module dpram #(
    parameter aw = 8,
    parameter dw = 8
)(
    clka, clkb,
    addra, douta, dina, wena,
    addrb, doutb, doutb_comb
);

    // derived depth parameter
    parameter sz = (32'b1 << aw) - 1;

    input                  clka, clkb, wena;
    input      [aw-1:0]    addra, addrb;
    input      [dw-1:0]    dina;
    output reg [dw-1:0]    douta, doutb;
    // Combinational read mirror of port B (behavioral-model convenience:
    // tracks addrb with zero latency; not a synthesis-style port)
    output wire [dw-1:0]   doutb_comb;

    reg [dw-1:0] mem [sz:0];

    assign doutb_comb = mem[addrb];

    integer k;
    initial begin
        for (k = 0; k < sz+1; k = k + 1) begin
            mem[k] = {dw{1'b0}};
        end
    end

    // Port A: synchronous write + synchronous read
    always @(posedge clka) begin
        if (wena)
            mem[addra] <= dina;
        douta <= mem[addra];    // sync read
    end

    // Port B: synchronous read
    always @(posedge clkb) begin
        doutb <= mem[addrb];    // sync read
    end

endmodule
