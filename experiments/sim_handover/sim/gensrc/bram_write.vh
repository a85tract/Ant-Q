
bram_cfg acqbuf0_W_cfg(.bram(acqbuf0_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(ACQBUF_W_ADDRWIDTH),.DATA_WIDTH(ACQBUF_W_DATAWIDTH))
acqbuf0_W_write(.bram(acqbuf0_W),.addr(dspif.addr_acqbuf[0]),.data(dspif.data_acqbuf[0]),.we(dspif.we_acqbuf[0]));

bram_cfg acqbuf1_W_cfg(.bram(acqbuf1_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(ACQBUF_W_ADDRWIDTH),.DATA_WIDTH(ACQBUF_W_DATAWIDTH))
acqbuf1_W_write(.bram(acqbuf1_W),.addr(dspif.addr_acqbuf[1]),.data(dspif.data_acqbuf[1]),.we(dspif.we_acqbuf[1]));

bram_cfg dacmon0_W_cfg(.bram(dacmon0_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(DACMON_W_ADDRWIDTH),.DATA_WIDTH(DACMON_W_DATAWIDTH))
dacmon0_W_write(.bram(dacmon0_W),.addr(dspif.addr_dacmon[0]),.data(dspif.data_dacmon[0]),.we(dspif.we_dacmon[0]));

bram_cfg dacmon1_W_cfg(.bram(dacmon1_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(DACMON_W_ADDRWIDTH),.DATA_WIDTH(DACMON_W_DATAWIDTH))
dacmon1_W_write(.bram(dacmon1_W),.addr(dspif.addr_dacmon[1]),.data(dspif.data_dacmon[1]),.we(dspif.we_dacmon[1]));

bram_cfg dacmon2_W_cfg(.bram(dacmon2_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(DACMON_W_ADDRWIDTH),.DATA_WIDTH(DACMON_W_DATAWIDTH))
dacmon2_W_write(.bram(dacmon2_W),.addr(dspif.addr_dacmon[2]),.data(dspif.data_dacmon[2]),.we(dspif.we_dacmon[2]));

bram_cfg dacmon3_W_cfg(.bram(dacmon3_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(DACMON_W_ADDRWIDTH),.DATA_WIDTH(DACMON_W_DATAWIDTH))
dacmon3_W_write(.bram(dacmon3_W),.addr(dspif.addr_dacmon[3]),.data(dspif.data_dacmon[3]),.we(dspif.we_dacmon[3]));

bram_cfg qubit_accbuf0_W_cfg(.bram(qubit_accbuf0_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH))
qubit_accbuf0_W_write(.bram(qubit_accbuf0_W),.addr(dspif.addr_qubit_accbuf[0]),.data(dspif.data_qubit_accbuf[0]),.we(dspif.we_qubit_accbuf[0]));

bram_cfg qubit_accbuf1_W_cfg(.bram(qubit_accbuf1_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH))
qubit_accbuf1_W_write(.bram(qubit_accbuf1_W),.addr(dspif.addr_qubit_accbuf[1]),.data(dspif.data_qubit_accbuf[1]),.we(dspif.we_qubit_accbuf[1]));

bram_cfg qubit_accbuf2_W_cfg(.bram(qubit_accbuf2_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH))
qubit_accbuf2_W_write(.bram(qubit_accbuf2_W),.addr(dspif.addr_qubit_accbuf[2]),.data(dspif.data_qubit_accbuf[2]),.we(dspif.we_qubit_accbuf[2]));

bram_cfg qubit_accbuf3_W_cfg(.bram(qubit_accbuf3_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH))
qubit_accbuf3_W_write(.bram(qubit_accbuf3_W),.addr(dspif.addr_qubit_accbuf[3]),.data(dspif.data_qubit_accbuf[3]),.we(dspif.we_qubit_accbuf[3]));

bram_cfg qubit_accbuf4_W_cfg(.bram(qubit_accbuf4_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH))
qubit_accbuf4_W_write(.bram(qubit_accbuf4_W),.addr(dspif.addr_qubit_accbuf[4]),.data(dspif.data_qubit_accbuf[4]),.we(dspif.we_qubit_accbuf[4]));

bram_cfg qubit_accbuf5_W_cfg(.bram(qubit_accbuf5_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH))
qubit_accbuf5_W_write(.bram(qubit_accbuf5_W),.addr(dspif.addr_qubit_accbuf[5]),.data(dspif.data_qubit_accbuf[5]),.we(dspif.we_qubit_accbuf[5]));

bram_cfg qubit_accbuf6_W_cfg(.bram(qubit_accbuf6_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH))
qubit_accbuf6_W_write(.bram(qubit_accbuf6_W),.addr(dspif.addr_qubit_accbuf[6]),.data(dspif.data_qubit_accbuf[6]),.we(dspif.we_qubit_accbuf[6]));

bram_cfg qubit_accbuf7_W_cfg(.bram(qubit_accbuf7_W),.clk(dspclk),.rst(1'b0),.en(1'b1));
bram_write#(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH))
qubit_accbuf7_W_write(.bram(qubit_accbuf7_W),.addr(dspif.addr_qubit_accbuf[7]),.data(dspif.data_qubit_accbuf[7]),.we(dspif.we_qubit_accbuf[7]));
