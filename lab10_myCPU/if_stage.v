`include "mycpu.h"

module if_stage(
    input                          clk              ,
    input                          reset            ,
    //allwoin
    input                          ds_allowin       ,
    //brbus
    input  [`BR_BUS_WD       -1:0] br_bus           ,
    //to ds
    output                         fs_to_ds_valid   ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus     ,
    // inst sram interface
    output                         inst_sram_req    ,
    output                         inst_sram_wr     ,
    output [1                  :0] inst_sram_size   ,
    output [3                  :0] inst_sram_wstrb  ,
    output [31                 :0] inst_sram_addr   ,
    output [31                 :0] inst_sram_wdata  ,
    input                          inst_sram_addr_ok,
    input                          inst_sram_data_ok,
    input  [31                 :0] inst_sram_rdata  ,

    input  [31                 :0] ex_entry         ,
    input  [31                 :0] csr_rvalue       ,
    input                          ds_ertn_flush    ,
    input                          es_ertn_flush    ,
    input                          ms_ertn_flush    ,
    input                          ws_ertn_flush    ,
    input                          id_ex            ,
    input                          exe_ex           ,
    input                          mem_ex           ,
    input                          wb_ex            ,
    input                          reg_rlv          ,
    output                         fs_signal_ADEF   ,
    input                          fs_signal_ALE
);

reg         fs_valid;
wire        fs_ready_go;
wire        fs_allowin;
wire        to_fs_valid;
wire        pfs_ready_go;
wire        pfs_allowin;

wire [31:0] seq_pc;
wire [31:0] nextpc;

reg  [32:0] br_bus_r; 
wire        br_taken;
wire [31:0] br_target;
assign {br_taken,br_target} = br_bus;
always @(posedge clk) begin
    if(reset) begin
        br_bus_r <= 33'b0;
    end
    else if(fs_allowin & pfs_ready_go) begin
        br_bus_r <= 33'b0;
    end
    else if(br_taken) begin
        br_bus_r <= br_bus;
    end
end

reg  [32:0] ertn_flush_r;
always @(posedge clk) begin
    if(reset) begin
        ertn_flush_r <= 33'b0;
    end
    else if(fs_allowin & pfs_ready_go) begin
        ertn_flush_r <= 33'b0;
    end
    else if(ws_ertn_flush) begin
        ertn_flush_r <= {ws_ertn_flush,csr_rvalue};
    end
end

reg  [32:0] ex_r;
always @(posedge clk) begin
    if(reset) begin
        ex_r <= 33'b0;
    end
    else if(fs_allowin & pfs_ready_go) begin
        ex_r <= 33'b0;
    end
    else if(wb_ex) begin
        ex_r <= {wb_ex,ex_entry};
    end
end

reg count;
always @(posedge clk) begin
    if(reset) begin
        count <= 1'b0;
    end
    else if(inst_sram_data_ok) begin
        count <= 1'b0;
    end
    else if(inst_sram_addr_ok & inst_sram_req) begin
        count <= 1'b1;
    end
    else if(br_taken) begin
        count <= 1'b0;
    end
end

reg ALE_meaningful_inst;
always @(posedge clk) begin
    if(reset) begin
        ALE_meaningful_inst <= 1'b1;
    end
    else if(inst_sram_addr_ok & inst_sram_req) begin
        ALE_meaningful_inst <= 1'b1;
    end
    else if(exe_ex & fs_signal_ALE) begin
        ALE_meaningful_inst <= 1'b0;
    end
end

wire [31:0] fs_inst;
reg  [31:0] fs_pc;
assign fs_to_ds_bus = {fs_inst ,
                       fs_pc   };

// pre-IF stage
assign pfs_ready_go = inst_sram_req & inst_sram_addr_ok & fs_allowin;
assign to_fs_valid  = ~reset;

assign seq_pc       = fs_pc + 3'h4;
assign nextpc       = ws_ertn_flush ? csr_rvalue:
                      ertn_flush_r[32] ? ertn_flush_r[31:0]:
                      wb_ex         ? ex_entry  :
                      ex_r[32]      ? ex_r[31:0]:
                      br_taken      ? br_target :
                      br_bus_r[32]  ? br_bus_r[31:0]:
                                      seq_pc; 

reg [32:0] fs_inst_r;
always @(posedge clk) begin
    if (reset) begin
        fs_inst_r <= 32'b0;
    end
    else if(fs_to_ds_valid & ds_allowin) begin
        fs_inst_r <= 32'b0;
    end
    else if(~ALE_meaningful_inst) begin
        fs_inst_r <= 32'b0;
    end
    else if(inst_sram_data_ok & ALE_meaningful_inst & count) begin
        fs_inst_r <= {1'b1,inst_sram_rdata};
    end
end

// IF stage
assign fs_ready_go    = ~id_ex & (inst_sram_data_ok | fs_inst_r[32]) & ALE_meaningful_inst;
assign fs_allowin     = (!fs_valid | fs_ready_go & ds_allowin)
                        & !(ds_ertn_flush | es_ertn_flush | ms_ertn_flush | id_ex | exe_ex | mem_ex);
assign fs_to_ds_valid =  fs_valid & fs_ready_go;
always @(posedge clk) begin
    if (reset) begin
        fs_valid <= 1'b0;
    end
    else if (fs_allowin) begin
        fs_valid <= pfs_ready_go;
    end
    else if (br_taken | ds_ertn_flush | es_ertn_flush | ms_ertn_flush | ws_ertn_flush | id_ex | exe_ex | mem_ex | wb_ex) begin
        fs_valid <= 1'b0;
    end

    if (reset) begin
        fs_pc <= 32'h1bfffffc;  //trick: to make nextpc be 0x1c000000 during reset 
    end
    else if (fs_allowin & pfs_ready_go) begin
        fs_pc <= nextpc;
    end
    else begin
        fs_pc <= fs_pc;
    end
end

assign inst_sram_req   = to_fs_valid & fs_allowin & ~count & ~reset;
assign inst_sram_wr    = 4'h0;
assign inst_sram_size  = 2'b10;
assign inst_sram_wstrb = 4'b0;
assign inst_sram_addr  = nextpc;
assign inst_sram_wdata = 32'b0;

assign fs_inst         = (inst_sram_data_ok & count)? inst_sram_rdata :
                                              fs_inst_r[31:0];

reg fs_signal_ADEF_r;
always @(posedge clk) begin
    if (reset)
        fs_signal_ADEF_r <= 1'b0;
    else if( nextpc[1:0] != 2'b00)
        fs_signal_ADEF_r <= 1'b1;
    else
        fs_signal_ADEF_r <= 1'b0;
end
assign fs_signal_ADEF = fs_signal_ADEF_r;

endmodule
