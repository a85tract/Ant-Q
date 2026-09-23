localparam ACQBUF_R_ADDRPERDATA=$clog2(ACQBUF_R_DATAWIDTH)-3;localparam ACQBUF_W_ADDRPERDATA=$clog2(ACQBUF_W_DATAWIDTH)-3;
localparam QUBIT_COMMAND_R_ADDRPERDATA=$clog2(QUBIT_COMMAND_R_DATAWIDTH)-3;localparam QUBIT_COMMAND_W_ADDRPERDATA=$clog2(QUBIT_COMMAND_W_DATAWIDTH)-3;
localparam DACMON_R_ADDRPERDATA=$clog2(DACMON_R_DATAWIDTH)-3;localparam DACMON_W_ADDRPERDATA=$clog2(DACMON_W_DATAWIDTH)-3;
localparam QUBIT_QDRV_ENV_R_ADDRPERDATA=$clog2(QUBIT_QDRV_ENV_R_DATAWIDTH)-3;localparam QUBIT_QDRV_ENV_W_ADDRPERDATA=$clog2(QUBIT_QDRV_ENV_W_DATAWIDTH)-3;
localparam QUBIT_QDRV_FREQ_R_ADDRPERDATA=$clog2(QUBIT_QDRV_FREQ_R_DATAWIDTH)-3;localparam QUBIT_QDRV_FREQ_W_ADDRPERDATA=$clog2(QUBIT_QDRV_FREQ_W_DATAWIDTH)-3;
localparam QUBIT_RDLO_ENV_R_ADDRPERDATA=$clog2(QUBIT_RDLO_ENV_R_DATAWIDTH)-3;localparam QUBIT_RDLO_ENV_W_ADDRPERDATA=$clog2(QUBIT_RDLO_ENV_W_DATAWIDTH)-3;
localparam QUBIT_RDLO_FREQ_R_ADDRPERDATA=$clog2(QUBIT_RDLO_FREQ_R_DATAWIDTH)-3;localparam QUBIT_RDLO_FREQ_W_ADDRPERDATA=$clog2(QUBIT_RDLO_FREQ_W_DATAWIDTH)-3;
localparam QUBIT_RDRV_ENV_R_ADDRPERDATA=$clog2(QUBIT_RDRV_ENV_R_DATAWIDTH)-3;localparam QUBIT_RDRV_ENV_W_ADDRPERDATA=$clog2(QUBIT_RDRV_ENV_W_DATAWIDTH)-3;
localparam QUBIT_RDRV_FREQ_R_ADDRPERDATA=$clog2(QUBIT_RDRV_FREQ_R_DATAWIDTH)-3;localparam QUBIT_RDRV_FREQ_W_ADDRPERDATA=$clog2(QUBIT_RDRV_FREQ_W_DATAWIDTH)-3;
localparam QUBIT_ACCBUF_R_ADDRPERDATA=$clog2(QUBIT_ACCBUF_R_DATAWIDTH)-3;localparam QUBIT_ACCBUF_W_ADDRPERDATA=$clog2(QUBIT_ACCBUF_W_DATAWIDTH)-3;

ifbram #(.ADDR_WIDTH(ACQBUF_W_ADDRWIDTH),.DATA_WIDTH(ACQBUF_W_DATAWIDTH)) acqbuf0_W();
ifbram #(.ADDR_WIDTH(ACQBUF_R_ADDRWIDTH),.DATA_WIDTH(ACQBUF_R_DATAWIDTH)) acqbuf0_R();
bram_cfg acqbuf0_R_cfg(.bram(acqbuf0_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_acqbuf0),.DATAWIDTHA(ACQBUF_W_DATAWIDTH),.ADDRWIDTHA(ACQBUF_W_ADDRWIDTH),.SIZEA(ACQBUF_W_DEPTH),.DATAWIDTHB(ACQBUF_R_DATAWIDTH),.ADDRWIDTHB(ACQBUF_R_ADDRWIDTH),.SIZEB(ACQBUF_R_DEPTH))
acqbuf0_mem(.clkA(acqbuf0_W.clk),.weA(acqbuf0_W.we),.addrA(acqbuf0_W.addr),.diA(acqbuf0_W.din),.clkB(acqbuf0_R.clk),.addrB(acqbuf0_R.addr),.doB(acqbuf0_R.dout));

ifbram #(.ADDR_WIDTH(ACQBUF_W_ADDRWIDTH),.DATA_WIDTH(ACQBUF_W_DATAWIDTH)) acqbuf1_W();
ifbram #(.ADDR_WIDTH(ACQBUF_R_ADDRWIDTH),.DATA_WIDTH(ACQBUF_R_DATAWIDTH)) acqbuf1_R();
bram_cfg acqbuf1_R_cfg(.bram(acqbuf1_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_acqbuf1),.DATAWIDTHA(ACQBUF_W_DATAWIDTH),.ADDRWIDTHA(ACQBUF_W_ADDRWIDTH),.SIZEA(ACQBUF_W_DEPTH),.DATAWIDTHB(ACQBUF_R_DATAWIDTH),.ADDRWIDTHB(ACQBUF_R_ADDRWIDTH),.SIZEB(ACQBUF_R_DEPTH))
acqbuf1_mem(.clkA(acqbuf1_W.clk),.weA(acqbuf1_W.we),.addrA(acqbuf1_W.addr),.diA(acqbuf1_W.din),.clkB(acqbuf1_R.clk),.addrB(acqbuf1_R.addr),.doB(acqbuf1_R.dout));

ifbram #(.ADDR_WIDTH(DACMON_W_ADDRWIDTH),.DATA_WIDTH(DACMON_W_DATAWIDTH)) dacmon0_W();
ifbram #(.ADDR_WIDTH(DACMON_R_ADDRWIDTH),.DATA_WIDTH(DACMON_R_DATAWIDTH)) dacmon0_R();
bram_cfg dacmon0_R_cfg(.bram(dacmon0_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_dacmon0),.DATAWIDTHA(DACMON_W_DATAWIDTH),.ADDRWIDTHA(DACMON_W_ADDRWIDTH),.SIZEA(DACMON_W_DEPTH),.DATAWIDTHB(DACMON_R_DATAWIDTH),.ADDRWIDTHB(DACMON_R_ADDRWIDTH),.SIZEB(DACMON_R_DEPTH))
dacmon0_mem(.clkA(dacmon0_W.clk),.weA(dacmon0_W.we),.addrA(dacmon0_W.addr),.diA(dacmon0_W.din),.clkB(dacmon0_R.clk),.addrB(dacmon0_R.addr),.doB(dacmon0_R.dout));

ifbram #(.ADDR_WIDTH(DACMON_W_ADDRWIDTH),.DATA_WIDTH(DACMON_W_DATAWIDTH)) dacmon1_W();
ifbram #(.ADDR_WIDTH(DACMON_R_ADDRWIDTH),.DATA_WIDTH(DACMON_R_DATAWIDTH)) dacmon1_R();
bram_cfg dacmon1_R_cfg(.bram(dacmon1_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_dacmon1),.DATAWIDTHA(DACMON_W_DATAWIDTH),.ADDRWIDTHA(DACMON_W_ADDRWIDTH),.SIZEA(DACMON_W_DEPTH),.DATAWIDTHB(DACMON_R_DATAWIDTH),.ADDRWIDTHB(DACMON_R_ADDRWIDTH),.SIZEB(DACMON_R_DEPTH))
dacmon1_mem(.clkA(dacmon1_W.clk),.weA(dacmon1_W.we),.addrA(dacmon1_W.addr),.diA(dacmon1_W.din),.clkB(dacmon1_R.clk),.addrB(dacmon1_R.addr),.doB(dacmon1_R.dout));

ifbram #(.ADDR_WIDTH(DACMON_W_ADDRWIDTH),.DATA_WIDTH(DACMON_W_DATAWIDTH)) dacmon2_W();
ifbram #(.ADDR_WIDTH(DACMON_R_ADDRWIDTH),.DATA_WIDTH(DACMON_R_DATAWIDTH)) dacmon2_R();
bram_cfg dacmon2_R_cfg(.bram(dacmon2_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_dacmon2),.DATAWIDTHA(DACMON_W_DATAWIDTH),.ADDRWIDTHA(DACMON_W_ADDRWIDTH),.SIZEA(DACMON_W_DEPTH),.DATAWIDTHB(DACMON_R_DATAWIDTH),.ADDRWIDTHB(DACMON_R_ADDRWIDTH),.SIZEB(DACMON_R_DEPTH))
dacmon2_mem(.clkA(dacmon2_W.clk),.weA(dacmon2_W.we),.addrA(dacmon2_W.addr),.diA(dacmon2_W.din),.clkB(dacmon2_R.clk),.addrB(dacmon2_R.addr),.doB(dacmon2_R.dout));

ifbram #(.ADDR_WIDTH(DACMON_W_ADDRWIDTH),.DATA_WIDTH(DACMON_W_DATAWIDTH)) dacmon3_W();
ifbram #(.ADDR_WIDTH(DACMON_R_ADDRWIDTH),.DATA_WIDTH(DACMON_R_DATAWIDTH)) dacmon3_R();
bram_cfg dacmon3_R_cfg(.bram(dacmon3_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_dacmon3),.DATAWIDTHA(DACMON_W_DATAWIDTH),.ADDRWIDTHA(DACMON_W_ADDRWIDTH),.SIZEA(DACMON_W_DEPTH),.DATAWIDTHB(DACMON_R_DATAWIDTH),.ADDRWIDTHB(DACMON_R_ADDRWIDTH),.SIZEB(DACMON_R_DEPTH))
dacmon3_mem(.clkA(dacmon3_W.clk),.weA(dacmon3_W.we),.addrA(dacmon3_W.addr),.diA(dacmon3_W.din),.clkB(dacmon3_R.clk),.addrB(dacmon3_R.addr),.doB(dacmon3_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH)) qubit_accbuf0_W();
ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_R_DATAWIDTH)) qubit_accbuf0_R();
bram_cfg qubit_accbuf0_R_cfg(.bram(qubit_accbuf0_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_qubit_accbuf0),.DATAWIDTHA(QUBIT_ACCBUF_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_ACCBUF_W_ADDRWIDTH),.SIZEA(QUBIT_ACCBUF_W_DEPTH),.DATAWIDTHB(QUBIT_ACCBUF_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_ACCBUF_R_ADDRWIDTH),.SIZEB(QUBIT_ACCBUF_R_DEPTH))
qubit_accbuf0_mem(.clkA(qubit_accbuf0_W.clk),.weA(qubit_accbuf0_W.we),.addrA(qubit_accbuf0_W.addr),.diA(qubit_accbuf0_W.din),.clkB(qubit_accbuf0_R.clk),.addrB(qubit_accbuf0_R.addr),.doB(qubit_accbuf0_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH)) qubit_accbuf1_W();
ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_R_DATAWIDTH)) qubit_accbuf1_R();
bram_cfg qubit_accbuf1_R_cfg(.bram(qubit_accbuf1_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_qubit_accbuf1),.DATAWIDTHA(QUBIT_ACCBUF_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_ACCBUF_W_ADDRWIDTH),.SIZEA(QUBIT_ACCBUF_W_DEPTH),.DATAWIDTHB(QUBIT_ACCBUF_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_ACCBUF_R_ADDRWIDTH),.SIZEB(QUBIT_ACCBUF_R_DEPTH))
qubit_accbuf1_mem(.clkA(qubit_accbuf1_W.clk),.weA(qubit_accbuf1_W.we),.addrA(qubit_accbuf1_W.addr),.diA(qubit_accbuf1_W.din),.clkB(qubit_accbuf1_R.clk),.addrB(qubit_accbuf1_R.addr),.doB(qubit_accbuf1_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH)) qubit_accbuf2_W();
ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_R_DATAWIDTH)) qubit_accbuf2_R();
bram_cfg qubit_accbuf2_R_cfg(.bram(qubit_accbuf2_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_qubit_accbuf2),.DATAWIDTHA(QUBIT_ACCBUF_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_ACCBUF_W_ADDRWIDTH),.SIZEA(QUBIT_ACCBUF_W_DEPTH),.DATAWIDTHB(QUBIT_ACCBUF_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_ACCBUF_R_ADDRWIDTH),.SIZEB(QUBIT_ACCBUF_R_DEPTH))
qubit_accbuf2_mem(.clkA(qubit_accbuf2_W.clk),.weA(qubit_accbuf2_W.we),.addrA(qubit_accbuf2_W.addr),.diA(qubit_accbuf2_W.din),.clkB(qubit_accbuf2_R.clk),.addrB(qubit_accbuf2_R.addr),.doB(qubit_accbuf2_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH)) qubit_accbuf3_W();
ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_R_DATAWIDTH)) qubit_accbuf3_R();
bram_cfg qubit_accbuf3_R_cfg(.bram(qubit_accbuf3_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_qubit_accbuf3),.DATAWIDTHA(QUBIT_ACCBUF_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_ACCBUF_W_ADDRWIDTH),.SIZEA(QUBIT_ACCBUF_W_DEPTH),.DATAWIDTHB(QUBIT_ACCBUF_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_ACCBUF_R_ADDRWIDTH),.SIZEB(QUBIT_ACCBUF_R_DEPTH))
qubit_accbuf3_mem(.clkA(qubit_accbuf3_W.clk),.weA(qubit_accbuf3_W.we),.addrA(qubit_accbuf3_W.addr),.diA(qubit_accbuf3_W.din),.clkB(qubit_accbuf3_R.clk),.addrB(qubit_accbuf3_R.addr),.doB(qubit_accbuf3_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH)) qubit_accbuf4_W();
ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_R_DATAWIDTH)) qubit_accbuf4_R();
bram_cfg qubit_accbuf4_R_cfg(.bram(qubit_accbuf4_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_qubit_accbuf4),.DATAWIDTHA(QUBIT_ACCBUF_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_ACCBUF_W_ADDRWIDTH),.SIZEA(QUBIT_ACCBUF_W_DEPTH),.DATAWIDTHB(QUBIT_ACCBUF_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_ACCBUF_R_ADDRWIDTH),.SIZEB(QUBIT_ACCBUF_R_DEPTH))
qubit_accbuf4_mem(.clkA(qubit_accbuf4_W.clk),.weA(qubit_accbuf4_W.we),.addrA(qubit_accbuf4_W.addr),.diA(qubit_accbuf4_W.din),.clkB(qubit_accbuf4_R.clk),.addrB(qubit_accbuf4_R.addr),.doB(qubit_accbuf4_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH)) qubit_accbuf5_W();
ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_R_DATAWIDTH)) qubit_accbuf5_R();
bram_cfg qubit_accbuf5_R_cfg(.bram(qubit_accbuf5_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_qubit_accbuf5),.DATAWIDTHA(QUBIT_ACCBUF_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_ACCBUF_W_ADDRWIDTH),.SIZEA(QUBIT_ACCBUF_W_DEPTH),.DATAWIDTHB(QUBIT_ACCBUF_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_ACCBUF_R_ADDRWIDTH),.SIZEB(QUBIT_ACCBUF_R_DEPTH))
qubit_accbuf5_mem(.clkA(qubit_accbuf5_W.clk),.weA(qubit_accbuf5_W.we),.addrA(qubit_accbuf5_W.addr),.diA(qubit_accbuf5_W.din),.clkB(qubit_accbuf5_R.clk),.addrB(qubit_accbuf5_R.addr),.doB(qubit_accbuf5_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH)) qubit_accbuf6_W();
ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_R_DATAWIDTH)) qubit_accbuf6_R();
bram_cfg qubit_accbuf6_R_cfg(.bram(qubit_accbuf6_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_qubit_accbuf6),.DATAWIDTHA(QUBIT_ACCBUF_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_ACCBUF_W_ADDRWIDTH),.SIZEA(QUBIT_ACCBUF_W_DEPTH),.DATAWIDTHB(QUBIT_ACCBUF_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_ACCBUF_R_ADDRWIDTH),.SIZEB(QUBIT_ACCBUF_R_DEPTH))
qubit_accbuf6_mem(.clkA(qubit_accbuf6_W.clk),.weA(qubit_accbuf6_W.we),.addrA(qubit_accbuf6_W.addr),.diA(qubit_accbuf6_W.din),.clkB(qubit_accbuf6_R.clk),.addrB(qubit_accbuf6_R.addr),.doB(qubit_accbuf6_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_W_DATAWIDTH)) qubit_accbuf7_W();
ifbram #(.ADDR_WIDTH(QUBIT_ACCBUF_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_ACCBUF_R_DATAWIDTH)) qubit_accbuf7_R();
bram_cfg qubit_accbuf7_R_cfg(.bram(qubit_accbuf7_R),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_write_wider #(.INIT_FILE(INIT_qubit_accbuf7),.DATAWIDTHA(QUBIT_ACCBUF_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_ACCBUF_W_ADDRWIDTH),.SIZEA(QUBIT_ACCBUF_W_DEPTH),.DATAWIDTHB(QUBIT_ACCBUF_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_ACCBUF_R_ADDRWIDTH),.SIZEB(QUBIT_ACCBUF_R_DEPTH))
qubit_accbuf7_mem(.clkA(qubit_accbuf7_W.clk),.weA(qubit_accbuf7_W.we),.addrA(qubit_accbuf7_W.addr),.diA(qubit_accbuf7_W.din),.clkB(qubit_accbuf7_R.clk),.addrB(qubit_accbuf7_R.addr),.doB(qubit_accbuf7_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_W_DATAWIDTH)) qubit_command0_W();
ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH)) qubit_command0_R();
bram_cfg qubit_command0_W_cfg(.bram(qubit_command0_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_command0),.DATAWIDTHA(QUBIT_COMMAND_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_COMMAND_W_ADDRWIDTH),.SIZEA(QUBIT_COMMAND_W_DEPTH),.DATAWIDTHB(QUBIT_COMMAND_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_COMMAND_R_ADDRWIDTH),.SIZEB(QUBIT_COMMAND_R_DEPTH),.RAM_STYLE("block"))
qubit_command0_mem(.clkA(qubit_command0_W.clk),.weA(qubit_command0_W.we),.addrA(qubit_command0_W.addr),.diA(qubit_command0_W.din),.clkB(qubit_command0_R.clk),.addrB(qubit_command0_R.addr),.doB(qubit_command0_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_W_DATAWIDTH)) qubit_command1_W();
ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH)) qubit_command1_R();
bram_cfg qubit_command1_W_cfg(.bram(qubit_command1_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_command1),.DATAWIDTHA(QUBIT_COMMAND_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_COMMAND_W_ADDRWIDTH),.SIZEA(QUBIT_COMMAND_W_DEPTH),.DATAWIDTHB(QUBIT_COMMAND_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_COMMAND_R_ADDRWIDTH),.SIZEB(QUBIT_COMMAND_R_DEPTH),.RAM_STYLE("block"))
qubit_command1_mem(.clkA(qubit_command1_W.clk),.weA(qubit_command1_W.we),.addrA(qubit_command1_W.addr),.diA(qubit_command1_W.din),.clkB(qubit_command1_R.clk),.addrB(qubit_command1_R.addr),.doB(qubit_command1_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_W_DATAWIDTH)) qubit_command2_W();
ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH)) qubit_command2_R();
bram_cfg qubit_command2_W_cfg(.bram(qubit_command2_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_command2),.DATAWIDTHA(QUBIT_COMMAND_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_COMMAND_W_ADDRWIDTH),.SIZEA(QUBIT_COMMAND_W_DEPTH),.DATAWIDTHB(QUBIT_COMMAND_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_COMMAND_R_ADDRWIDTH),.SIZEB(QUBIT_COMMAND_R_DEPTH),.RAM_STYLE("block"))
qubit_command2_mem(.clkA(qubit_command2_W.clk),.weA(qubit_command2_W.we),.addrA(qubit_command2_W.addr),.diA(qubit_command2_W.din),.clkB(qubit_command2_R.clk),.addrB(qubit_command2_R.addr),.doB(qubit_command2_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_W_DATAWIDTH)) qubit_command3_W();
ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH)) qubit_command3_R();
bram_cfg qubit_command3_W_cfg(.bram(qubit_command3_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_command3),.DATAWIDTHA(QUBIT_COMMAND_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_COMMAND_W_ADDRWIDTH),.SIZEA(QUBIT_COMMAND_W_DEPTH),.DATAWIDTHB(QUBIT_COMMAND_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_COMMAND_R_ADDRWIDTH),.SIZEB(QUBIT_COMMAND_R_DEPTH),.RAM_STYLE("block"))
qubit_command3_mem(.clkA(qubit_command3_W.clk),.weA(qubit_command3_W.we),.addrA(qubit_command3_W.addr),.diA(qubit_command3_W.din),.clkB(qubit_command3_R.clk),.addrB(qubit_command3_R.addr),.doB(qubit_command3_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_W_DATAWIDTH)) qubit_command4_W();
ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH)) qubit_command4_R();
bram_cfg qubit_command4_W_cfg(.bram(qubit_command4_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_command4),.DATAWIDTHA(QUBIT_COMMAND_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_COMMAND_W_ADDRWIDTH),.SIZEA(QUBIT_COMMAND_W_DEPTH),.DATAWIDTHB(QUBIT_COMMAND_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_COMMAND_R_ADDRWIDTH),.SIZEB(QUBIT_COMMAND_R_DEPTH),.RAM_STYLE("block"))
qubit_command4_mem(.clkA(qubit_command4_W.clk),.weA(qubit_command4_W.we),.addrA(qubit_command4_W.addr),.diA(qubit_command4_W.din),.clkB(qubit_command4_R.clk),.addrB(qubit_command4_R.addr),.doB(qubit_command4_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_W_DATAWIDTH)) qubit_command5_W();
ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH)) qubit_command5_R();
bram_cfg qubit_command5_W_cfg(.bram(qubit_command5_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_command5),.DATAWIDTHA(QUBIT_COMMAND_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_COMMAND_W_ADDRWIDTH),.SIZEA(QUBIT_COMMAND_W_DEPTH),.DATAWIDTHB(QUBIT_COMMAND_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_COMMAND_R_ADDRWIDTH),.SIZEB(QUBIT_COMMAND_R_DEPTH),.RAM_STYLE("block"))
qubit_command5_mem(.clkA(qubit_command5_W.clk),.weA(qubit_command5_W.we),.addrA(qubit_command5_W.addr),.diA(qubit_command5_W.din),.clkB(qubit_command5_R.clk),.addrB(qubit_command5_R.addr),.doB(qubit_command5_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_W_DATAWIDTH)) qubit_command6_W();
ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH)) qubit_command6_R();
bram_cfg qubit_command6_W_cfg(.bram(qubit_command6_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_command6),.DATAWIDTHA(QUBIT_COMMAND_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_COMMAND_W_ADDRWIDTH),.SIZEA(QUBIT_COMMAND_W_DEPTH),.DATAWIDTHB(QUBIT_COMMAND_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_COMMAND_R_ADDRWIDTH),.SIZEB(QUBIT_COMMAND_R_DEPTH),.RAM_STYLE("block"))
qubit_command6_mem(.clkA(qubit_command6_W.clk),.weA(qubit_command6_W.we),.addrA(qubit_command6_W.addr),.diA(qubit_command6_W.din),.clkB(qubit_command6_R.clk),.addrB(qubit_command6_R.addr),.doB(qubit_command6_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_W_DATAWIDTH)) qubit_command7_W();
ifbram #(.ADDR_WIDTH(QUBIT_COMMAND_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_COMMAND_R_DATAWIDTH)) qubit_command7_R();
bram_cfg qubit_command7_W_cfg(.bram(qubit_command7_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_command7),.DATAWIDTHA(QUBIT_COMMAND_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_COMMAND_W_ADDRWIDTH),.SIZEA(QUBIT_COMMAND_W_DEPTH),.DATAWIDTHB(QUBIT_COMMAND_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_COMMAND_R_ADDRWIDTH),.SIZEB(QUBIT_COMMAND_R_DEPTH),.RAM_STYLE("block"))
qubit_command7_mem(.clkA(qubit_command7_W.clk),.weA(qubit_command7_W.we),.addrA(qubit_command7_W.addr),.diA(qubit_command7_W.din),.clkB(qubit_command7_R.clk),.addrB(qubit_command7_R.addr),.doB(qubit_command7_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_W_DATAWIDTH)) qubit_qdrv_env0_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH)) qubit_qdrv_env0_R();
bram_cfg qubit_qdrv_env0_W_cfg(.bram(qubit_qdrv_env0_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_env0),.DATAWIDTHA(QUBIT_QDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_env0_mem(.clkA(qubit_qdrv_env0_W.clk),.weA(qubit_qdrv_env0_W.we),.addrA(qubit_qdrv_env0_W.addr),.diA(qubit_qdrv_env0_W.din),.clkB(qubit_qdrv_env0_R.clk),.addrB(qubit_qdrv_env0_R.addr),.doB(qubit_qdrv_env0_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_W_DATAWIDTH)) qubit_qdrv_env1_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH)) qubit_qdrv_env1_R();
bram_cfg qubit_qdrv_env1_W_cfg(.bram(qubit_qdrv_env1_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_env1),.DATAWIDTHA(QUBIT_QDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_env1_mem(.clkA(qubit_qdrv_env1_W.clk),.weA(qubit_qdrv_env1_W.we),.addrA(qubit_qdrv_env1_W.addr),.diA(qubit_qdrv_env1_W.din),.clkB(qubit_qdrv_env1_R.clk),.addrB(qubit_qdrv_env1_R.addr),.doB(qubit_qdrv_env1_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_W_DATAWIDTH)) qubit_qdrv_env2_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH)) qubit_qdrv_env2_R();
bram_cfg qubit_qdrv_env2_W_cfg(.bram(qubit_qdrv_env2_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_env2),.DATAWIDTHA(QUBIT_QDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_env2_mem(.clkA(qubit_qdrv_env2_W.clk),.weA(qubit_qdrv_env2_W.we),.addrA(qubit_qdrv_env2_W.addr),.diA(qubit_qdrv_env2_W.din),.clkB(qubit_qdrv_env2_R.clk),.addrB(qubit_qdrv_env2_R.addr),.doB(qubit_qdrv_env2_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_W_DATAWIDTH)) qubit_qdrv_env3_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH)) qubit_qdrv_env3_R();
bram_cfg qubit_qdrv_env3_W_cfg(.bram(qubit_qdrv_env3_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_env3),.DATAWIDTHA(QUBIT_QDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_env3_mem(.clkA(qubit_qdrv_env3_W.clk),.weA(qubit_qdrv_env3_W.we),.addrA(qubit_qdrv_env3_W.addr),.diA(qubit_qdrv_env3_W.din),.clkB(qubit_qdrv_env3_R.clk),.addrB(qubit_qdrv_env3_R.addr),.doB(qubit_qdrv_env3_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_W_DATAWIDTH)) qubit_qdrv_env4_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH)) qubit_qdrv_env4_R();
bram_cfg qubit_qdrv_env4_W_cfg(.bram(qubit_qdrv_env4_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_env4),.DATAWIDTHA(QUBIT_QDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_env4_mem(.clkA(qubit_qdrv_env4_W.clk),.weA(qubit_qdrv_env4_W.we),.addrA(qubit_qdrv_env4_W.addr),.diA(qubit_qdrv_env4_W.din),.clkB(qubit_qdrv_env4_R.clk),.addrB(qubit_qdrv_env4_R.addr),.doB(qubit_qdrv_env4_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_W_DATAWIDTH)) qubit_qdrv_env5_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH)) qubit_qdrv_env5_R();
bram_cfg qubit_qdrv_env5_W_cfg(.bram(qubit_qdrv_env5_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_env5),.DATAWIDTHA(QUBIT_QDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_env5_mem(.clkA(qubit_qdrv_env5_W.clk),.weA(qubit_qdrv_env5_W.we),.addrA(qubit_qdrv_env5_W.addr),.diA(qubit_qdrv_env5_W.din),.clkB(qubit_qdrv_env5_R.clk),.addrB(qubit_qdrv_env5_R.addr),.doB(qubit_qdrv_env5_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_W_DATAWIDTH)) qubit_qdrv_env6_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH)) qubit_qdrv_env6_R();
bram_cfg qubit_qdrv_env6_W_cfg(.bram(qubit_qdrv_env6_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_env6),.DATAWIDTHA(QUBIT_QDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_env6_mem(.clkA(qubit_qdrv_env6_W.clk),.weA(qubit_qdrv_env6_W.we),.addrA(qubit_qdrv_env6_W.addr),.diA(qubit_qdrv_env6_W.din),.clkB(qubit_qdrv_env6_R.clk),.addrB(qubit_qdrv_env6_R.addr),.doB(qubit_qdrv_env6_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_W_DATAWIDTH)) qubit_qdrv_env7_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_ENV_R_DATAWIDTH)) qubit_qdrv_env7_R();
bram_cfg qubit_qdrv_env7_W_cfg(.bram(qubit_qdrv_env7_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_env7),.DATAWIDTHA(QUBIT_QDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_env7_mem(.clkA(qubit_qdrv_env7_W.clk),.weA(qubit_qdrv_env7_W.we),.addrA(qubit_qdrv_env7_W.addr),.diA(qubit_qdrv_env7_W.din),.clkB(qubit_qdrv_env7_R.clk),.addrB(qubit_qdrv_env7_R.addr),.doB(qubit_qdrv_env7_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_W_DATAWIDTH)) qubit_qdrv_freq0_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH)) qubit_qdrv_freq0_R();
bram_cfg qubit_qdrv_freq0_W_cfg(.bram(qubit_qdrv_freq0_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_freq0),.DATAWIDTHA(QUBIT_QDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_freq0_mem(.clkA(qubit_qdrv_freq0_W.clk),.weA(qubit_qdrv_freq0_W.we),.addrA(qubit_qdrv_freq0_W.addr),.diA(qubit_qdrv_freq0_W.din),.clkB(qubit_qdrv_freq0_R.clk),.addrB(qubit_qdrv_freq0_R.addr),.doB(qubit_qdrv_freq0_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_W_DATAWIDTH)) qubit_qdrv_freq1_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH)) qubit_qdrv_freq1_R();
bram_cfg qubit_qdrv_freq1_W_cfg(.bram(qubit_qdrv_freq1_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_freq1),.DATAWIDTHA(QUBIT_QDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_freq1_mem(.clkA(qubit_qdrv_freq1_W.clk),.weA(qubit_qdrv_freq1_W.we),.addrA(qubit_qdrv_freq1_W.addr),.diA(qubit_qdrv_freq1_W.din),.clkB(qubit_qdrv_freq1_R.clk),.addrB(qubit_qdrv_freq1_R.addr),.doB(qubit_qdrv_freq1_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_W_DATAWIDTH)) qubit_qdrv_freq2_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH)) qubit_qdrv_freq2_R();
bram_cfg qubit_qdrv_freq2_W_cfg(.bram(qubit_qdrv_freq2_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_freq2),.DATAWIDTHA(QUBIT_QDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_freq2_mem(.clkA(qubit_qdrv_freq2_W.clk),.weA(qubit_qdrv_freq2_W.we),.addrA(qubit_qdrv_freq2_W.addr),.diA(qubit_qdrv_freq2_W.din),.clkB(qubit_qdrv_freq2_R.clk),.addrB(qubit_qdrv_freq2_R.addr),.doB(qubit_qdrv_freq2_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_W_DATAWIDTH)) qubit_qdrv_freq3_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH)) qubit_qdrv_freq3_R();
bram_cfg qubit_qdrv_freq3_W_cfg(.bram(qubit_qdrv_freq3_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_freq3),.DATAWIDTHA(QUBIT_QDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_freq3_mem(.clkA(qubit_qdrv_freq3_W.clk),.weA(qubit_qdrv_freq3_W.we),.addrA(qubit_qdrv_freq3_W.addr),.diA(qubit_qdrv_freq3_W.din),.clkB(qubit_qdrv_freq3_R.clk),.addrB(qubit_qdrv_freq3_R.addr),.doB(qubit_qdrv_freq3_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_W_DATAWIDTH)) qubit_qdrv_freq4_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH)) qubit_qdrv_freq4_R();
bram_cfg qubit_qdrv_freq4_W_cfg(.bram(qubit_qdrv_freq4_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_freq4),.DATAWIDTHA(QUBIT_QDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_freq4_mem(.clkA(qubit_qdrv_freq4_W.clk),.weA(qubit_qdrv_freq4_W.we),.addrA(qubit_qdrv_freq4_W.addr),.diA(qubit_qdrv_freq4_W.din),.clkB(qubit_qdrv_freq4_R.clk),.addrB(qubit_qdrv_freq4_R.addr),.doB(qubit_qdrv_freq4_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_W_DATAWIDTH)) qubit_qdrv_freq5_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH)) qubit_qdrv_freq5_R();
bram_cfg qubit_qdrv_freq5_W_cfg(.bram(qubit_qdrv_freq5_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_freq5),.DATAWIDTHA(QUBIT_QDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_freq5_mem(.clkA(qubit_qdrv_freq5_W.clk),.weA(qubit_qdrv_freq5_W.we),.addrA(qubit_qdrv_freq5_W.addr),.diA(qubit_qdrv_freq5_W.din),.clkB(qubit_qdrv_freq5_R.clk),.addrB(qubit_qdrv_freq5_R.addr),.doB(qubit_qdrv_freq5_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_W_DATAWIDTH)) qubit_qdrv_freq6_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH)) qubit_qdrv_freq6_R();
bram_cfg qubit_qdrv_freq6_W_cfg(.bram(qubit_qdrv_freq6_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_freq6),.DATAWIDTHA(QUBIT_QDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_freq6_mem(.clkA(qubit_qdrv_freq6_W.clk),.weA(qubit_qdrv_freq6_W.we),.addrA(qubit_qdrv_freq6_W.addr),.diA(qubit_qdrv_freq6_W.din),.clkB(qubit_qdrv_freq6_R.clk),.addrB(qubit_qdrv_freq6_R.addr),.doB(qubit_qdrv_freq6_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_W_DATAWIDTH)) qubit_qdrv_freq7_W();
ifbram #(.ADDR_WIDTH(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_QDRV_FREQ_R_DATAWIDTH)) qubit_qdrv_freq7_R();
bram_cfg qubit_qdrv_freq7_W_cfg(.bram(qubit_qdrv_freq7_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_qdrv_freq7),.DATAWIDTHA(QUBIT_QDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_QDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_QDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_QDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_QDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_QDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_qdrv_freq7_mem(.clkA(qubit_qdrv_freq7_W.clk),.weA(qubit_qdrv_freq7_W.we),.addrA(qubit_qdrv_freq7_W.addr),.diA(qubit_qdrv_freq7_W.din),.clkB(qubit_qdrv_freq7_R.clk),.addrB(qubit_qdrv_freq7_R.addr),.doB(qubit_qdrv_freq7_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_W_DATAWIDTH)) qubit_rdlo_env0_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH)) qubit_rdlo_env0_R();
bram_cfg qubit_rdlo_env0_W_cfg(.bram(qubit_rdlo_env0_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_env0),.DATAWIDTHA(QUBIT_RDLO_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_env0_mem(.clkA(qubit_rdlo_env0_W.clk),.weA(qubit_rdlo_env0_W.we),.addrA(qubit_rdlo_env0_W.addr),.diA(qubit_rdlo_env0_W.din),.clkB(qubit_rdlo_env0_R.clk),.addrB(qubit_rdlo_env0_R.addr),.doB(qubit_rdlo_env0_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_W_DATAWIDTH)) qubit_rdlo_env1_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH)) qubit_rdlo_env1_R();
bram_cfg qubit_rdlo_env1_W_cfg(.bram(qubit_rdlo_env1_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_env1),.DATAWIDTHA(QUBIT_RDLO_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_env1_mem(.clkA(qubit_rdlo_env1_W.clk),.weA(qubit_rdlo_env1_W.we),.addrA(qubit_rdlo_env1_W.addr),.diA(qubit_rdlo_env1_W.din),.clkB(qubit_rdlo_env1_R.clk),.addrB(qubit_rdlo_env1_R.addr),.doB(qubit_rdlo_env1_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_W_DATAWIDTH)) qubit_rdlo_env2_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH)) qubit_rdlo_env2_R();
bram_cfg qubit_rdlo_env2_W_cfg(.bram(qubit_rdlo_env2_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_env2),.DATAWIDTHA(QUBIT_RDLO_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_env2_mem(.clkA(qubit_rdlo_env2_W.clk),.weA(qubit_rdlo_env2_W.we),.addrA(qubit_rdlo_env2_W.addr),.diA(qubit_rdlo_env2_W.din),.clkB(qubit_rdlo_env2_R.clk),.addrB(qubit_rdlo_env2_R.addr),.doB(qubit_rdlo_env2_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_W_DATAWIDTH)) qubit_rdlo_env3_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH)) qubit_rdlo_env3_R();
bram_cfg qubit_rdlo_env3_W_cfg(.bram(qubit_rdlo_env3_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_env3),.DATAWIDTHA(QUBIT_RDLO_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_env3_mem(.clkA(qubit_rdlo_env3_W.clk),.weA(qubit_rdlo_env3_W.we),.addrA(qubit_rdlo_env3_W.addr),.diA(qubit_rdlo_env3_W.din),.clkB(qubit_rdlo_env3_R.clk),.addrB(qubit_rdlo_env3_R.addr),.doB(qubit_rdlo_env3_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_W_DATAWIDTH)) qubit_rdlo_env4_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH)) qubit_rdlo_env4_R();
bram_cfg qubit_rdlo_env4_W_cfg(.bram(qubit_rdlo_env4_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_env4),.DATAWIDTHA(QUBIT_RDLO_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_env4_mem(.clkA(qubit_rdlo_env4_W.clk),.weA(qubit_rdlo_env4_W.we),.addrA(qubit_rdlo_env4_W.addr),.diA(qubit_rdlo_env4_W.din),.clkB(qubit_rdlo_env4_R.clk),.addrB(qubit_rdlo_env4_R.addr),.doB(qubit_rdlo_env4_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_W_DATAWIDTH)) qubit_rdlo_env5_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH)) qubit_rdlo_env5_R();
bram_cfg qubit_rdlo_env5_W_cfg(.bram(qubit_rdlo_env5_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_env5),.DATAWIDTHA(QUBIT_RDLO_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_env5_mem(.clkA(qubit_rdlo_env5_W.clk),.weA(qubit_rdlo_env5_W.we),.addrA(qubit_rdlo_env5_W.addr),.diA(qubit_rdlo_env5_W.din),.clkB(qubit_rdlo_env5_R.clk),.addrB(qubit_rdlo_env5_R.addr),.doB(qubit_rdlo_env5_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_W_DATAWIDTH)) qubit_rdlo_env6_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH)) qubit_rdlo_env6_R();
bram_cfg qubit_rdlo_env6_W_cfg(.bram(qubit_rdlo_env6_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_env6),.DATAWIDTHA(QUBIT_RDLO_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_env6_mem(.clkA(qubit_rdlo_env6_W.clk),.weA(qubit_rdlo_env6_W.we),.addrA(qubit_rdlo_env6_W.addr),.diA(qubit_rdlo_env6_W.din),.clkB(qubit_rdlo_env6_R.clk),.addrB(qubit_rdlo_env6_R.addr),.doB(qubit_rdlo_env6_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_W_DATAWIDTH)) qubit_rdlo_env7_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_ENV_R_DATAWIDTH)) qubit_rdlo_env7_R();
bram_cfg qubit_rdlo_env7_W_cfg(.bram(qubit_rdlo_env7_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_env7),.DATAWIDTHA(QUBIT_RDLO_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_env7_mem(.clkA(qubit_rdlo_env7_W.clk),.weA(qubit_rdlo_env7_W.we),.addrA(qubit_rdlo_env7_W.addr),.diA(qubit_rdlo_env7_W.din),.clkB(qubit_rdlo_env7_R.clk),.addrB(qubit_rdlo_env7_R.addr),.doB(qubit_rdlo_env7_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_W_DATAWIDTH)) qubit_rdlo_freq0_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH)) qubit_rdlo_freq0_R();
bram_cfg qubit_rdlo_freq0_W_cfg(.bram(qubit_rdlo_freq0_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_freq0),.DATAWIDTHA(QUBIT_RDLO_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_freq0_mem(.clkA(qubit_rdlo_freq0_W.clk),.weA(qubit_rdlo_freq0_W.we),.addrA(qubit_rdlo_freq0_W.addr),.diA(qubit_rdlo_freq0_W.din),.clkB(qubit_rdlo_freq0_R.clk),.addrB(qubit_rdlo_freq0_R.addr),.doB(qubit_rdlo_freq0_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_W_DATAWIDTH)) qubit_rdlo_freq1_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH)) qubit_rdlo_freq1_R();
bram_cfg qubit_rdlo_freq1_W_cfg(.bram(qubit_rdlo_freq1_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_freq1),.DATAWIDTHA(QUBIT_RDLO_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_freq1_mem(.clkA(qubit_rdlo_freq1_W.clk),.weA(qubit_rdlo_freq1_W.we),.addrA(qubit_rdlo_freq1_W.addr),.diA(qubit_rdlo_freq1_W.din),.clkB(qubit_rdlo_freq1_R.clk),.addrB(qubit_rdlo_freq1_R.addr),.doB(qubit_rdlo_freq1_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_W_DATAWIDTH)) qubit_rdlo_freq2_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH)) qubit_rdlo_freq2_R();
bram_cfg qubit_rdlo_freq2_W_cfg(.bram(qubit_rdlo_freq2_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_freq2),.DATAWIDTHA(QUBIT_RDLO_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_freq2_mem(.clkA(qubit_rdlo_freq2_W.clk),.weA(qubit_rdlo_freq2_W.we),.addrA(qubit_rdlo_freq2_W.addr),.diA(qubit_rdlo_freq2_W.din),.clkB(qubit_rdlo_freq2_R.clk),.addrB(qubit_rdlo_freq2_R.addr),.doB(qubit_rdlo_freq2_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_W_DATAWIDTH)) qubit_rdlo_freq3_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH)) qubit_rdlo_freq3_R();
bram_cfg qubit_rdlo_freq3_W_cfg(.bram(qubit_rdlo_freq3_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_freq3),.DATAWIDTHA(QUBIT_RDLO_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_freq3_mem(.clkA(qubit_rdlo_freq3_W.clk),.weA(qubit_rdlo_freq3_W.we),.addrA(qubit_rdlo_freq3_W.addr),.diA(qubit_rdlo_freq3_W.din),.clkB(qubit_rdlo_freq3_R.clk),.addrB(qubit_rdlo_freq3_R.addr),.doB(qubit_rdlo_freq3_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_W_DATAWIDTH)) qubit_rdlo_freq4_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH)) qubit_rdlo_freq4_R();
bram_cfg qubit_rdlo_freq4_W_cfg(.bram(qubit_rdlo_freq4_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_freq4),.DATAWIDTHA(QUBIT_RDLO_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_freq4_mem(.clkA(qubit_rdlo_freq4_W.clk),.weA(qubit_rdlo_freq4_W.we),.addrA(qubit_rdlo_freq4_W.addr),.diA(qubit_rdlo_freq4_W.din),.clkB(qubit_rdlo_freq4_R.clk),.addrB(qubit_rdlo_freq4_R.addr),.doB(qubit_rdlo_freq4_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_W_DATAWIDTH)) qubit_rdlo_freq5_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH)) qubit_rdlo_freq5_R();
bram_cfg qubit_rdlo_freq5_W_cfg(.bram(qubit_rdlo_freq5_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_freq5),.DATAWIDTHA(QUBIT_RDLO_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_freq5_mem(.clkA(qubit_rdlo_freq5_W.clk),.weA(qubit_rdlo_freq5_W.we),.addrA(qubit_rdlo_freq5_W.addr),.diA(qubit_rdlo_freq5_W.din),.clkB(qubit_rdlo_freq5_R.clk),.addrB(qubit_rdlo_freq5_R.addr),.doB(qubit_rdlo_freq5_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_W_DATAWIDTH)) qubit_rdlo_freq6_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH)) qubit_rdlo_freq6_R();
bram_cfg qubit_rdlo_freq6_W_cfg(.bram(qubit_rdlo_freq6_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_freq6),.DATAWIDTHA(QUBIT_RDLO_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_freq6_mem(.clkA(qubit_rdlo_freq6_W.clk),.weA(qubit_rdlo_freq6_W.we),.addrA(qubit_rdlo_freq6_W.addr),.diA(qubit_rdlo_freq6_W.din),.clkB(qubit_rdlo_freq6_R.clk),.addrB(qubit_rdlo_freq6_R.addr),.doB(qubit_rdlo_freq6_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_W_DATAWIDTH)) qubit_rdlo_freq7_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDLO_FREQ_R_DATAWIDTH)) qubit_rdlo_freq7_R();
bram_cfg qubit_rdlo_freq7_W_cfg(.bram(qubit_rdlo_freq7_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdlo_freq7),.DATAWIDTHA(QUBIT_RDLO_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDLO_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDLO_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDLO_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDLO_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDLO_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdlo_freq7_mem(.clkA(qubit_rdlo_freq7_W.clk),.weA(qubit_rdlo_freq7_W.we),.addrA(qubit_rdlo_freq7_W.addr),.diA(qubit_rdlo_freq7_W.din),.clkB(qubit_rdlo_freq7_R.clk),.addrB(qubit_rdlo_freq7_R.addr),.doB(qubit_rdlo_freq7_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_W_DATAWIDTH)) qubit_rdrv_env0_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH)) qubit_rdrv_env0_R();
bram_cfg qubit_rdrv_env0_W_cfg(.bram(qubit_rdrv_env0_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_env0),.DATAWIDTHA(QUBIT_RDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_env0_mem(.clkA(qubit_rdrv_env0_W.clk),.weA(qubit_rdrv_env0_W.we),.addrA(qubit_rdrv_env0_W.addr),.diA(qubit_rdrv_env0_W.din),.clkB(qubit_rdrv_env0_R.clk),.addrB(qubit_rdrv_env0_R.addr),.doB(qubit_rdrv_env0_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_W_DATAWIDTH)) qubit_rdrv_env1_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH)) qubit_rdrv_env1_R();
bram_cfg qubit_rdrv_env1_W_cfg(.bram(qubit_rdrv_env1_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_env1),.DATAWIDTHA(QUBIT_RDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_env1_mem(.clkA(qubit_rdrv_env1_W.clk),.weA(qubit_rdrv_env1_W.we),.addrA(qubit_rdrv_env1_W.addr),.diA(qubit_rdrv_env1_W.din),.clkB(qubit_rdrv_env1_R.clk),.addrB(qubit_rdrv_env1_R.addr),.doB(qubit_rdrv_env1_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_W_DATAWIDTH)) qubit_rdrv_env2_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH)) qubit_rdrv_env2_R();
bram_cfg qubit_rdrv_env2_W_cfg(.bram(qubit_rdrv_env2_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_env2),.DATAWIDTHA(QUBIT_RDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_env2_mem(.clkA(qubit_rdrv_env2_W.clk),.weA(qubit_rdrv_env2_W.we),.addrA(qubit_rdrv_env2_W.addr),.diA(qubit_rdrv_env2_W.din),.clkB(qubit_rdrv_env2_R.clk),.addrB(qubit_rdrv_env2_R.addr),.doB(qubit_rdrv_env2_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_W_DATAWIDTH)) qubit_rdrv_env3_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH)) qubit_rdrv_env3_R();
bram_cfg qubit_rdrv_env3_W_cfg(.bram(qubit_rdrv_env3_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_env3),.DATAWIDTHA(QUBIT_RDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_env3_mem(.clkA(qubit_rdrv_env3_W.clk),.weA(qubit_rdrv_env3_W.we),.addrA(qubit_rdrv_env3_W.addr),.diA(qubit_rdrv_env3_W.din),.clkB(qubit_rdrv_env3_R.clk),.addrB(qubit_rdrv_env3_R.addr),.doB(qubit_rdrv_env3_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_W_DATAWIDTH)) qubit_rdrv_env4_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH)) qubit_rdrv_env4_R();
bram_cfg qubit_rdrv_env4_W_cfg(.bram(qubit_rdrv_env4_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_env4),.DATAWIDTHA(QUBIT_RDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_env4_mem(.clkA(qubit_rdrv_env4_W.clk),.weA(qubit_rdrv_env4_W.we),.addrA(qubit_rdrv_env4_W.addr),.diA(qubit_rdrv_env4_W.din),.clkB(qubit_rdrv_env4_R.clk),.addrB(qubit_rdrv_env4_R.addr),.doB(qubit_rdrv_env4_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_W_DATAWIDTH)) qubit_rdrv_env5_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH)) qubit_rdrv_env5_R();
bram_cfg qubit_rdrv_env5_W_cfg(.bram(qubit_rdrv_env5_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_env5),.DATAWIDTHA(QUBIT_RDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_env5_mem(.clkA(qubit_rdrv_env5_W.clk),.weA(qubit_rdrv_env5_W.we),.addrA(qubit_rdrv_env5_W.addr),.diA(qubit_rdrv_env5_W.din),.clkB(qubit_rdrv_env5_R.clk),.addrB(qubit_rdrv_env5_R.addr),.doB(qubit_rdrv_env5_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_W_DATAWIDTH)) qubit_rdrv_env6_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH)) qubit_rdrv_env6_R();
bram_cfg qubit_rdrv_env6_W_cfg(.bram(qubit_rdrv_env6_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_env6),.DATAWIDTHA(QUBIT_RDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_env6_mem(.clkA(qubit_rdrv_env6_W.clk),.weA(qubit_rdrv_env6_W.we),.addrA(qubit_rdrv_env6_W.addr),.diA(qubit_rdrv_env6_W.din),.clkB(qubit_rdrv_env6_R.clk),.addrB(qubit_rdrv_env6_R.addr),.doB(qubit_rdrv_env6_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_W_DATAWIDTH)) qubit_rdrv_env7_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_ENV_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_ENV_R_DATAWIDTH)) qubit_rdrv_env7_R();
bram_cfg qubit_rdrv_env7_W_cfg(.bram(qubit_rdrv_env7_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_env7),.DATAWIDTHA(QUBIT_RDRV_ENV_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_ENV_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_ENV_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_ENV_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_ENV_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_ENV_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_env7_mem(.clkA(qubit_rdrv_env7_W.clk),.weA(qubit_rdrv_env7_W.we),.addrA(qubit_rdrv_env7_W.addr),.diA(qubit_rdrv_env7_W.din),.clkB(qubit_rdrv_env7_R.clk),.addrB(qubit_rdrv_env7_R.addr),.doB(qubit_rdrv_env7_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_W_DATAWIDTH)) qubit_rdrv_freq0_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH)) qubit_rdrv_freq0_R();
bram_cfg qubit_rdrv_freq0_W_cfg(.bram(qubit_rdrv_freq0_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_freq0),.DATAWIDTHA(QUBIT_RDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_freq0_mem(.clkA(qubit_rdrv_freq0_W.clk),.weA(qubit_rdrv_freq0_W.we),.addrA(qubit_rdrv_freq0_W.addr),.diA(qubit_rdrv_freq0_W.din),.clkB(qubit_rdrv_freq0_R.clk),.addrB(qubit_rdrv_freq0_R.addr),.doB(qubit_rdrv_freq0_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_W_DATAWIDTH)) qubit_rdrv_freq1_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH)) qubit_rdrv_freq1_R();
bram_cfg qubit_rdrv_freq1_W_cfg(.bram(qubit_rdrv_freq1_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_freq1),.DATAWIDTHA(QUBIT_RDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_freq1_mem(.clkA(qubit_rdrv_freq1_W.clk),.weA(qubit_rdrv_freq1_W.we),.addrA(qubit_rdrv_freq1_W.addr),.diA(qubit_rdrv_freq1_W.din),.clkB(qubit_rdrv_freq1_R.clk),.addrB(qubit_rdrv_freq1_R.addr),.doB(qubit_rdrv_freq1_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_W_DATAWIDTH)) qubit_rdrv_freq2_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH)) qubit_rdrv_freq2_R();
bram_cfg qubit_rdrv_freq2_W_cfg(.bram(qubit_rdrv_freq2_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_freq2),.DATAWIDTHA(QUBIT_RDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_freq2_mem(.clkA(qubit_rdrv_freq2_W.clk),.weA(qubit_rdrv_freq2_W.we),.addrA(qubit_rdrv_freq2_W.addr),.diA(qubit_rdrv_freq2_W.din),.clkB(qubit_rdrv_freq2_R.clk),.addrB(qubit_rdrv_freq2_R.addr),.doB(qubit_rdrv_freq2_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_W_DATAWIDTH)) qubit_rdrv_freq3_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH)) qubit_rdrv_freq3_R();
bram_cfg qubit_rdrv_freq3_W_cfg(.bram(qubit_rdrv_freq3_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_freq3),.DATAWIDTHA(QUBIT_RDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_freq3_mem(.clkA(qubit_rdrv_freq3_W.clk),.weA(qubit_rdrv_freq3_W.we),.addrA(qubit_rdrv_freq3_W.addr),.diA(qubit_rdrv_freq3_W.din),.clkB(qubit_rdrv_freq3_R.clk),.addrB(qubit_rdrv_freq3_R.addr),.doB(qubit_rdrv_freq3_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_W_DATAWIDTH)) qubit_rdrv_freq4_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH)) qubit_rdrv_freq4_R();
bram_cfg qubit_rdrv_freq4_W_cfg(.bram(qubit_rdrv_freq4_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_freq4),.DATAWIDTHA(QUBIT_RDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_freq4_mem(.clkA(qubit_rdrv_freq4_W.clk),.weA(qubit_rdrv_freq4_W.we),.addrA(qubit_rdrv_freq4_W.addr),.diA(qubit_rdrv_freq4_W.din),.clkB(qubit_rdrv_freq4_R.clk),.addrB(qubit_rdrv_freq4_R.addr),.doB(qubit_rdrv_freq4_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_W_DATAWIDTH)) qubit_rdrv_freq5_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH)) qubit_rdrv_freq5_R();
bram_cfg qubit_rdrv_freq5_W_cfg(.bram(qubit_rdrv_freq5_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_freq5),.DATAWIDTHA(QUBIT_RDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_freq5_mem(.clkA(qubit_rdrv_freq5_W.clk),.weA(qubit_rdrv_freq5_W.we),.addrA(qubit_rdrv_freq5_W.addr),.diA(qubit_rdrv_freq5_W.din),.clkB(qubit_rdrv_freq5_R.clk),.addrB(qubit_rdrv_freq5_R.addr),.doB(qubit_rdrv_freq5_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_W_DATAWIDTH)) qubit_rdrv_freq6_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH)) qubit_rdrv_freq6_R();
bram_cfg qubit_rdrv_freq6_W_cfg(.bram(qubit_rdrv_freq6_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_freq6),.DATAWIDTHA(QUBIT_RDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_freq6_mem(.clkA(qubit_rdrv_freq6_W.clk),.weA(qubit_rdrv_freq6_W.we),.addrA(qubit_rdrv_freq6_W.addr),.diA(qubit_rdrv_freq6_W.din),.clkB(qubit_rdrv_freq6_R.clk),.addrB(qubit_rdrv_freq6_R.addr),.doB(qubit_rdrv_freq6_R.dout));

ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_W_DATAWIDTH)) qubit_rdrv_freq7_W();
ifbram #(.ADDR_WIDTH(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.DATA_WIDTH(QUBIT_RDRV_FREQ_R_DATAWIDTH)) qubit_rdrv_freq7_R();
bram_cfg qubit_rdrv_freq7_W_cfg(.bram(qubit_rdrv_freq7_W),.clk(lb3_clk),.rst(1'b0),.en(1'b1));
asym_ram_sdp_read_wider #(.INIT_FILE(INIT_qubit_rdrv_freq7),.DATAWIDTHA(QUBIT_RDRV_FREQ_W_DATAWIDTH),.ADDRWIDTHA(QUBIT_RDRV_FREQ_W_ADDRWIDTH),.SIZEA(QUBIT_RDRV_FREQ_W_DEPTH),.DATAWIDTHB(QUBIT_RDRV_FREQ_R_DATAWIDTH),.ADDRWIDTHB(QUBIT_RDRV_FREQ_R_ADDRWIDTH),.SIZEB(QUBIT_RDRV_FREQ_R_DEPTH),.RAM_STYLE("block"))
qubit_rdrv_freq7_mem(.clkA(qubit_rdrv_freq7_W.clk),.weA(qubit_rdrv_freq7_W.we),.addrA(qubit_rdrv_freq7_W.addr),.diA(qubit_rdrv_freq7_W.din),.clkB(qubit_rdrv_freq7_R.clk),.addrB(qubit_rdrv_freq7_R.addr),.doB(qubit_rdrv_freq7_R.dout));
