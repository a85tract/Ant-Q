generate
if (DEBUG=="true") begin
    iladsp iladsp(.clk(dspif.clk)
,.probe0(dspif.addr_rdrvenv[0])  // WIDTH 16
,.probe1(dspif.data_rdrvenv[0])  // WIDTH 32
,.probe2(dspif.addr_rdrvenv[1])  // WIDTH 16
,.probe3(dspif.data_rdrvenv[1])  // WIDTH 32
,.probe4(dspif.addr_rdrvenv[2])  // WIDTH 16
,.probe5(dspif.data_rdrvenv[2])  // WIDTH 32
,.probe6(dspif.addr_rdrvenv[3])  // WIDTH 16
,.probe7(dspif.data_rdrvenv[3])  // WIDTH 32
,.probe8(dspif.stb_start)  // WIDTH 1
,.probe9(state)  // WIDTH 4
,.probe10(nextstate)  // WIDTH 4
,.probe11(procreset)  // WIDTH 1
,.probe12(state_dbg[0])  // WIDTH 4
,.probe13(state_dbg[3])  // WIDTH 4
,.probe14(state_dbg[6])  // WIDTH 4
,.probe15(state_dbg[9])  // WIDTH 4
,.probe16(nextstate_dbg[0])  // WIDTH 4
,.probe17(nextstate_dbg[2])  // WIDTH 4
,.probe18(nextstate_dbg[4])  // WIDTH 4
,.probe19(nextstate_dbg[13])  // WIDTH 4
,.probe20(procdone)  // WIDTH 16
,.probe21(mixbb1)  // WIDTH 64
,.probe22(mixbb2)  // WIDTH 64
,.probe23(dspif.shift)  // WIDTH 5
    );
end
endgenerate
