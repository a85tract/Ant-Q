axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac00axis();
    axi4stream_clkrst dac00axisclkrst(.axi4(dac00axis.clkrst),.clk(DAC00_M_AXIS_ACLK),.resetn(DAC00_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac00axismap(.axis(dac00axis),.ready(DAC00_M_AXIS_TREADY),.valid(DAC00_M_AXIS_TVALID),.data(DAC00_M_AXIS_TDATA),.strb(DAC00_M_AXIS_TSTRB),.last(DAC00_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac01axis();
    axi4stream_clkrst dac01axisclkrst(.axi4(dac01axis.clkrst),.clk(DAC01_M_AXIS_ACLK),.resetn(DAC01_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac01axismap(.axis(dac01axis),.ready(DAC01_M_AXIS_TREADY),.valid(DAC01_M_AXIS_TVALID),.data(DAC01_M_AXIS_TDATA),.strb(DAC01_M_AXIS_TSTRB),.last(DAC01_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac02axis();
    axi4stream_clkrst dac02axisclkrst(.axi4(dac02axis.clkrst),.clk(DAC02_M_AXIS_ACLK),.resetn(DAC02_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac02axismap(.axis(dac02axis),.ready(DAC02_M_AXIS_TREADY),.valid(DAC02_M_AXIS_TVALID),.data(DAC02_M_AXIS_TDATA),.strb(DAC02_M_AXIS_TSTRB),.last(DAC02_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac03axis();
    axi4stream_clkrst dac03axisclkrst(.axi4(dac03axis.clkrst),.clk(DAC03_M_AXIS_ACLK),.resetn(DAC03_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac03axismap(.axis(dac03axis),.ready(DAC03_M_AXIS_TREADY),.valid(DAC03_M_AXIS_TVALID),.data(DAC03_M_AXIS_TDATA),.strb(DAC03_M_AXIS_TSTRB),.last(DAC03_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac10axis();
    axi4stream_clkrst dac10axisclkrst(.axi4(dac10axis.clkrst),.clk(DAC10_M_AXIS_ACLK),.resetn(DAC10_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac10axismap(.axis(dac10axis),.ready(DAC10_M_AXIS_TREADY),.valid(DAC10_M_AXIS_TVALID),.data(DAC10_M_AXIS_TDATA),.strb(DAC10_M_AXIS_TSTRB),.last(DAC10_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac11axis();
    axi4stream_clkrst dac11axisclkrst(.axi4(dac11axis.clkrst),.clk(DAC11_M_AXIS_ACLK),.resetn(DAC11_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac11axismap(.axis(dac11axis),.ready(DAC11_M_AXIS_TREADY),.valid(DAC11_M_AXIS_TVALID),.data(DAC11_M_AXIS_TDATA),.strb(DAC11_M_AXIS_TSTRB),.last(DAC11_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac12axis();
    axi4stream_clkrst dac12axisclkrst(.axi4(dac12axis.clkrst),.clk(DAC12_M_AXIS_ACLK),.resetn(DAC12_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac12axismap(.axis(dac12axis),.ready(DAC12_M_AXIS_TREADY),.valid(DAC12_M_AXIS_TVALID),.data(DAC12_M_AXIS_TDATA),.strb(DAC12_M_AXIS_TSTRB),.last(DAC12_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac13axis();
    axi4stream_clkrst dac13axisclkrst(.axi4(dac13axis.clkrst),.clk(DAC13_M_AXIS_ACLK),.resetn(DAC13_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac13axismap(.axis(dac13axis),.ready(DAC13_M_AXIS_TREADY),.valid(DAC13_M_AXIS_TVALID),.data(DAC13_M_AXIS_TDATA),.strb(DAC13_M_AXIS_TSTRB),.last(DAC13_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac20axis();
    axi4stream_clkrst dac20axisclkrst(.axi4(dac20axis.clkrst),.clk(DAC20_M_AXIS_ACLK),.resetn(DAC20_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac20axismap(.axis(dac20axis),.ready(DAC20_M_AXIS_TREADY),.valid(DAC20_M_AXIS_TVALID),.data(DAC20_M_AXIS_TDATA),.strb(DAC20_M_AXIS_TSTRB),.last(DAC20_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac21axis();
    axi4stream_clkrst dac21axisclkrst(.axi4(dac21axis.clkrst),.clk(DAC21_M_AXIS_ACLK),.resetn(DAC21_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac21axismap(.axis(dac21axis),.ready(DAC21_M_AXIS_TREADY),.valid(DAC21_M_AXIS_TVALID),.data(DAC21_M_AXIS_TDATA),.strb(DAC21_M_AXIS_TSTRB),.last(DAC21_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac22axis();
    axi4stream_clkrst dac22axisclkrst(.axi4(dac22axis.clkrst),.clk(DAC22_M_AXIS_ACLK),.resetn(DAC22_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac22axismap(.axis(dac22axis),.ready(DAC22_M_AXIS_TREADY),.valid(DAC22_M_AXIS_TVALID),.data(DAC22_M_AXIS_TDATA),.strb(DAC22_M_AXIS_TSTRB),.last(DAC22_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac23axis();
    axi4stream_clkrst dac23axisclkrst(.axi4(dac23axis.clkrst),.clk(DAC23_M_AXIS_ACLK),.resetn(DAC23_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac23axismap(.axis(dac23axis),.ready(DAC23_M_AXIS_TREADY),.valid(DAC23_M_AXIS_TVALID),.data(DAC23_M_AXIS_TDATA),.strb(DAC23_M_AXIS_TSTRB),.last(DAC23_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac30axis();
    axi4stream_clkrst dac30axisclkrst(.axi4(dac30axis.clkrst),.clk(DAC30_M_AXIS_ACLK),.resetn(DAC30_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac30axismap(.axis(dac30axis),.ready(DAC30_M_AXIS_TREADY),.valid(DAC30_M_AXIS_TVALID),.data(DAC30_M_AXIS_TDATA),.strb(DAC30_M_AXIS_TSTRB),.last(DAC30_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac31axis();
    axi4stream_clkrst dac31axisclkrst(.axi4(dac31axis.clkrst),.clk(DAC31_M_AXIS_ACLK),.resetn(DAC31_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac31axismap(.axis(dac31axis),.ready(DAC31_M_AXIS_TREADY),.valid(DAC31_M_AXIS_TVALID),.data(DAC31_M_AXIS_TDATA),.strb(DAC31_M_AXIS_TSTRB),.last(DAC31_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac32axis();
    axi4stream_clkrst dac32axisclkrst(.axi4(dac32axis.clkrst),.clk(DAC32_M_AXIS_ACLK),.resetn(DAC32_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac32axismap(.axis(dac32axis),.ready(DAC32_M_AXIS_TREADY),.valid(DAC32_M_AXIS_TVALID),.data(DAC32_M_AXIS_TDATA),.strb(DAC32_M_AXIS_TSTRB),.last(DAC32_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))   dac33axis();
    axi4stream_clkrst dac33axisclkrst(.axi4(dac33axis.clkrst),.clk(DAC33_M_AXIS_ACLK),.resetn(DAC33_M_AXIS_ARESETN));
    axi4stream_master_map #(.DATA_WIDTH(DAC_AXIS_DATAWIDTH))
    dac33axismap(.axis(dac33axis),.ready(DAC33_M_AXIS_TREADY),.valid(DAC33_M_AXIS_TVALID),.data(DAC33_M_AXIS_TDATA),.strb(DAC33_M_AXIS_TSTRB),.last(DAC33_M_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc00axis();
    axi4stream_clkrst adc00axisclkrst(.axi4(adc00axis.clkrst),.clk(ADC00_S_AXIS_ACLK),.resetn(ADC00_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc00axismap(.axis(adc00axis),.ready(ADC00_S_AXIS_TREADY),.valid(ADC00_S_AXIS_TVALID),.data(ADC00_S_AXIS_TDATA),.strb(ADC00_S_AXIS_TSTRB),.last(ADC00_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc01axis();
    axi4stream_clkrst adc01axisclkrst(.axi4(adc01axis.clkrst),.clk(ADC01_S_AXIS_ACLK),.resetn(ADC01_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc01axismap(.axis(adc01axis),.ready(ADC01_S_AXIS_TREADY),.valid(ADC01_S_AXIS_TVALID),.data(ADC01_S_AXIS_TDATA),.strb(ADC01_S_AXIS_TSTRB),.last(ADC01_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc02axis();
    axi4stream_clkrst adc02axisclkrst(.axi4(adc02axis.clkrst),.clk(ADC02_S_AXIS_ACLK),.resetn(ADC02_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc02axismap(.axis(adc02axis),.ready(ADC02_S_AXIS_TREADY),.valid(ADC02_S_AXIS_TVALID),.data(ADC02_S_AXIS_TDATA),.strb(ADC02_S_AXIS_TSTRB),.last(ADC02_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc03axis();
    axi4stream_clkrst adc03axisclkrst(.axi4(adc03axis.clkrst),.clk(ADC03_S_AXIS_ACLK),.resetn(ADC03_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc03axismap(.axis(adc03axis),.ready(ADC03_S_AXIS_TREADY),.valid(ADC03_S_AXIS_TVALID),.data(ADC03_S_AXIS_TDATA),.strb(ADC03_S_AXIS_TSTRB),.last(ADC03_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc10axis();
    axi4stream_clkrst adc10axisclkrst(.axi4(adc10axis.clkrst),.clk(ADC10_S_AXIS_ACLK),.resetn(ADC10_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc10axismap(.axis(adc10axis),.ready(ADC10_S_AXIS_TREADY),.valid(ADC10_S_AXIS_TVALID),.data(ADC10_S_AXIS_TDATA),.strb(ADC10_S_AXIS_TSTRB),.last(ADC10_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc11axis();
    axi4stream_clkrst adc11axisclkrst(.axi4(adc11axis.clkrst),.clk(ADC11_S_AXIS_ACLK),.resetn(ADC11_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc11axismap(.axis(adc11axis),.ready(ADC11_S_AXIS_TREADY),.valid(ADC11_S_AXIS_TVALID),.data(ADC11_S_AXIS_TDATA),.strb(ADC11_S_AXIS_TSTRB),.last(ADC11_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc12axis();
    axi4stream_clkrst adc12axisclkrst(.axi4(adc12axis.clkrst),.clk(ADC12_S_AXIS_ACLK),.resetn(ADC12_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc12axismap(.axis(adc12axis),.ready(ADC12_S_AXIS_TREADY),.valid(ADC12_S_AXIS_TVALID),.data(ADC12_S_AXIS_TDATA),.strb(ADC12_S_AXIS_TSTRB),.last(ADC12_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc13axis();
    axi4stream_clkrst adc13axisclkrst(.axi4(adc13axis.clkrst),.clk(ADC13_S_AXIS_ACLK),.resetn(ADC13_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc13axismap(.axis(adc13axis),.ready(ADC13_S_AXIS_TREADY),.valid(ADC13_S_AXIS_TVALID),.data(ADC13_S_AXIS_TDATA),.strb(ADC13_S_AXIS_TSTRB),.last(ADC13_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc20axis();
    axi4stream_clkrst adc20axisclkrst(.axi4(adc20axis.clkrst),.clk(ADC20_S_AXIS_ACLK),.resetn(ADC20_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc20axismap(.axis(adc20axis),.ready(ADC20_S_AXIS_TREADY),.valid(ADC20_S_AXIS_TVALID),.data(ADC20_S_AXIS_TDATA),.strb(ADC20_S_AXIS_TSTRB),.last(ADC20_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc21axis();
    axi4stream_clkrst adc21axisclkrst(.axi4(adc21axis.clkrst),.clk(ADC21_S_AXIS_ACLK),.resetn(ADC21_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc21axismap(.axis(adc21axis),.ready(ADC21_S_AXIS_TREADY),.valid(ADC21_S_AXIS_TVALID),.data(ADC21_S_AXIS_TDATA),.strb(ADC21_S_AXIS_TSTRB),.last(ADC21_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc22axis();
    axi4stream_clkrst adc22axisclkrst(.axi4(adc22axis.clkrst),.clk(ADC22_S_AXIS_ACLK),.resetn(ADC22_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc22axismap(.axis(adc22axis),.ready(ADC22_S_AXIS_TREADY),.valid(ADC22_S_AXIS_TVALID),.data(ADC22_S_AXIS_TDATA),.strb(ADC22_S_AXIS_TSTRB),.last(ADC22_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc23axis();
    axi4stream_clkrst adc23axisclkrst(.axi4(adc23axis.clkrst),.clk(ADC23_S_AXIS_ACLK),.resetn(ADC23_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc23axismap(.axis(adc23axis),.ready(ADC23_S_AXIS_TREADY),.valid(ADC23_S_AXIS_TVALID),.data(ADC23_S_AXIS_TDATA),.strb(ADC23_S_AXIS_TSTRB),.last(ADC23_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc30axis();
    axi4stream_clkrst adc30axisclkrst(.axi4(adc30axis.clkrst),.clk(ADC30_S_AXIS_ACLK),.resetn(ADC30_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc30axismap(.axis(adc30axis),.ready(ADC30_S_AXIS_TREADY),.valid(ADC30_S_AXIS_TVALID),.data(ADC30_S_AXIS_TDATA),.strb(ADC30_S_AXIS_TSTRB),.last(ADC30_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc31axis();
    axi4stream_clkrst adc31axisclkrst(.axi4(adc31axis.clkrst),.clk(ADC31_S_AXIS_ACLK),.resetn(ADC31_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc31axismap(.axis(adc31axis),.ready(ADC31_S_AXIS_TREADY),.valid(ADC31_S_AXIS_TVALID),.data(ADC31_S_AXIS_TDATA),.strb(ADC31_S_AXIS_TSTRB),.last(ADC31_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc32axis();
    axi4stream_clkrst adc32axisclkrst(.axi4(adc32axis.clkrst),.clk(ADC32_S_AXIS_ACLK),.resetn(ADC32_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc32axismap(.axis(adc32axis),.ready(ADC32_S_AXIS_TREADY),.valid(ADC32_S_AXIS_TVALID),.data(ADC32_S_AXIS_TDATA),.strb(ADC32_S_AXIS_TSTRB),.last(ADC32_S_AXIS_TLAST));
    
axi4stream #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))   adc33axis();
    axi4stream_clkrst adc33axisclkrst(.axi4(adc33axis.clkrst),.clk(ADC33_S_AXIS_ACLK),.resetn(ADC33_S_AXIS_ARESETN));
    axi4stream_slave_map #(.DATA_WIDTH(ADC_AXIS_DATAWIDTH))
    adc33axismap(.axis(adc33axis),.ready(ADC33_S_AXIS_TREADY),.valid(ADC33_S_AXIS_TVALID),.data(ADC33_S_AXIS_TDATA),.strb(ADC33_S_AXIS_TSTRB),.last(ADC33_S_AXIS_TLAST));
    