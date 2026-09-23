generate
if (DEBUG=="true") begin
    ilaauto ilaauto(.clk(dspclk)
,.probe0(dac20axis.cnt)  // WIDTH 32
,.probe1(dac20axis.valid)  // WIDTH 1
,.probe2(dac20axis.ready)  // WIDTH 1
,.probe3(dac20axis.data)  // WIDTH 256
,.probe4(dac30axis.cnt)  // WIDTH 32
,.probe5(dac30axis.valid)  // WIDTH 1
,.probe6(dac30axis.ready)  // WIDTH 1
,.probe7(dac30axis.data)  // WIDTH 256
    );
end
endgenerate
