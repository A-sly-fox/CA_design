module mycpu_top(
    input         clk,
    input         resetn,
    // inst sram interface
    output        inst_sram_req,
    output        inst_sram_wr,
    output [ 1:0] inst_sram_size,
    output [ 3:0] inst_sram_wstrb,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input         inst_sram_addr_ok,
    input         inst_sram_data_ok,
    input  [31:0] inst_sram_rdata,
    // data sram interface
    output        data_sram_req,
    output        data_sram_wr,
    output [ 1:0] data_sram_size,
    output [ 3:0] data_sram_wstrb,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input         data_sram_addr_ok,
    input         data_sram_data_ok,
    input  [31:0] data_sram_rdata,
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn; 

wire         ds_allowin;
wire         es_allowin;
wire         ms_allowin;
wire         ws_allowin;
wire         fs_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_ms_valid;
wire         ms_to_ws_valid;
wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;
wire [`BR_BUS_WD       -1:0] br_bus;
wire [`DS_TO_MD_BUS_WD -1:0] ds_to_md_bus;
wire [`CSR_BUS_WD -1:0] ds_to_es_csr_bus;
wire [`CSR_BUS_WD -1:0] es_to_ms_csr_bus;
wire [`CSR_BUS_WD -1:0] ms_to_ws_csr_bus;
wire [`CSR_BUS_WD -1:0] ws_to_csr_bus;

wire [31:0] csr_rvalue;
wire [ 7:0] hw_int_in;
wire        ipi_int_in;
wire [31:0] ex_entry;
wire        has_int;
wire        es_ertn_flush;
wire        ms_ertn_flush;
wire        ertn_flush;
wire        wb_ex;
wire [ 5:0] wb_ecode;
wire [ 8:0] wb_esubcode;
wire [31:0] wb_pc;
wire [31:0] wb_vaddr;

wire [39:0] es_forward;
wire [11:0] es_csr_forward;
wire [`MS_FORWARD -1:0] ms_forward;
wire [11:0] ms_csr_forward;
wire        es_csr_op;
wire        ms_csr_op;
wire        reg_rlv;
wire        signal_ADEF;
wire        signal_ALE;

// IF stage
if_stage if_stage(
    .clk              (clk              ),
    .reset            (reset            ),
    //allowin
    .ds_allowin       (ds_allowin       ),
    //brbus
    .br_bus           (br_bus           ),
    //outputs
    .fs_to_ds_valid   (fs_to_ds_valid   ),
    .fs_to_ds_bus     (fs_to_ds_bus     ),
    // inst sram interface
    .inst_sram_req    (inst_sram_req    ),
    .inst_sram_wr     (inst_sram_wr     ),
    .inst_sram_size   (inst_sram_size   ),
    .inst_sram_wstrb  (inst_sram_wstrb  ),
    .inst_sram_addr   (inst_sram_addr   ),
    .inst_sram_wdata  (inst_sram_wdata  ),
    .inst_sram_addr_ok(inst_sram_addr_ok),
    .inst_sram_data_ok(inst_sram_data_ok),
    .inst_sram_rdata  (inst_sram_rdata  ),

    .ex_entry         (ex_entry         ),
    .csr_rvalue       (csr_rvalue       ),
    .ds_ertn_flush    (ds_ertn_flush    ),
    .es_ertn_flush    (es_ertn_flush    ),
    .ms_ertn_flush    (ms_ertn_flush    ),
    .ws_ertn_flush    (ertn_flush       ),
    .id_ex            (id_ex            ),
    .exe_ex           (exe_ex           ),
    .mem_ex           (mem_ex           ),
    .wb_ex            (wb_ex            ),
    .reg_rlv          (reg_rlv          ),
    .fs_signal_ADEF   (signal_ADEF      ),
    .fs_signal_ALE    (signal_ALE       )
);
// ID stage
id_stage id_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .es_allowin     (es_allowin     ),
    .ds_allowin     (ds_allowin     ),
    //from fs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    //to es
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to fs
    .br_bus         (br_bus         ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    .ds_to_md_bus   (ds_to_md_bus   ),
    
    .es_forward     (es_forward     ),
    .ms_forward     (ms_forward     ),
    .es_csr_forward (es_csr_forward ),
    .ms_csr_forward (ms_csr_forward ),
    .es_csr_reg     (es_csr_op      ),
    .ms_csr_reg     (ms_csr_op      ),

    .ds_to_es_csr_bus(ds_to_es_csr_bus),
    .has_int         (has_int         ),
    .csr_rvalue      (csr_rvalue      ),
    .ds_ertn_flush   (ds_ertn_flush   ),
    .id_ex           (id_ex           ),
    .reg_rlv         (reg_rlv         ),
    .ds_signal_ADEF  (signal_ADEF     )
);

// EXE stage
exe_stage exe_stage(
    .clk              (clk              ),
    .reset            (reset            ),
    //allowin
    .ms_allowin       (ms_allowin       ),
    .es_allowin       (es_allowin       ),
    //from ds
    .ds_to_es_valid   (ds_to_es_valid   ),
    .ds_to_es_bus     (ds_to_es_bus     ),
    //from da to mul or div
    .ds_to_md_bus     (ds_to_md_bus     ),    
    //to ms
    .es_to_ms_valid   (es_to_ms_valid   ),
    .es_to_ms_bus     (es_to_ms_bus     ),
    // data sram interface
    .data_sram_req    (data_sram_req    ),
    .data_sram_wr     (data_sram_wr     ),
    .data_sram_size   (data_sram_size   ),
    .data_sram_wstrb  (data_sram_wstrb  ),
    .data_sram_addr   (data_sram_addr   ),
    .data_sram_wdata  (data_sram_wdata  ),
    .data_sram_addr_ok(data_sram_addr_ok),
    
    .es_forward       (es_forward       ),
    .es_csr_forward   (es_csr_forward   ),
    .es_csr_reg       (es_csr_op        ),

    .ds_to_es_csr_bus (ds_to_es_csr_bus ),
    .es_to_ms_csr_bus (es_to_ms_csr_bus ),
    .es_ertn_flush    (es_ertn_flush    ),
    .exe_ex           (exe_ex           ),
    .es_signal_ALE    (signal_ALE       )
);
// MEM stage
mem_stage mem_stage(
    .clk             (clk             ),
    .reset           (reset           ),
    //allowin
    .ws_allowin      (ws_allowin      ),
    .ms_allowin      (ms_allowin      ),
    //from es
    .es_to_ms_valid  (es_to_ms_valid  ),
    .es_to_ms_bus    (es_to_ms_bus    ),
    //to ws
    .ms_to_ws_valid  (ms_to_ws_valid  ),
    .ms_to_ws_bus    (ms_to_ws_bus    ),
    //from data-sram
    .data_sram_rdata (data_sram_rdata ),
    .data_sram_data_ok(data_sram_data_ok),
    
    .ms_forward      (ms_forward      ),
    .ms_csr_forward  (ms_csr_forward  ),
    .ms_csr_reg      (ms_csr_op       ),

    .es_to_ms_csr_bus(es_to_ms_csr_bus),
    .ms_to_ws_csr_bus(ms_to_ws_csr_bus),
    .ms_ertn_flush   (ms_ertn_flush   ),
    .mem_ex          (mem_ex          )
);
// WB stage
wb_stage wb_stage(
    .clk              (clk              ),
    .reset            (reset            ),
    //allowin
    .ws_allowin       (ws_allowin       ),
    //from ms
    .ms_to_ws_valid   (ms_to_ws_valid   ),
    .ms_to_ws_bus     (ms_to_ws_bus     ),
    //to rf: for write back
    .ws_to_rf_bus     (ws_to_rf_bus     ),
    //trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),

    .hw_int_in        (hw_int_in        ),
    .ipi_int_in       (ipi_int_in       ),
    .wb_ertn_flush    (ertn_flush       ),
    .wb_ex            (wb_ex            ),
    .wb_ecode         (wb_ecode         ),
    .wb_esubcode      (wb_esubcode      ),
    .wb_pc            (wb_pc            ),
    .wb_vaddr         (wb_vaddr         ),
    .ms_to_ws_csr_bus (ms_to_ws_csr_bus ),
    .ws_to_csr_bus    (ws_to_csr_bus    ),
    .csr_rvalue       (csr_rvalue       )
);

csrfile u_csrfile(
    .clock          (clk            ),
    .reset          (reset          ),
    .ws_to_csr_bus  (ws_to_csr_bus  ),
    .csr_rvalue     (csr_rvalue     ),
    .hw_int_in      (hw_int_in      ),
    .ipi_int_in     (ipi_int_in     ),
    .ex_entry       (ex_entry       ),
    .has_int        (has_int        ),
    .ertn_flush     (ertn_flush     ),
    .wb_ex          (wb_ex          ),
    .wb_ecode       (wb_ecode       ),
    .wb_esubcode    (wb_esubcode    ),
    .wb_pc          (wb_pc          ),
    .wb_vaddr       (wb_vaddr       )
);


endmodule
