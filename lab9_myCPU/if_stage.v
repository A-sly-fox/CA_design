`include "mycpu.h"

module if_stage(
    input                          clk            ,
    input                          reset          ,
    //allwoin
    input                          ds_allowin     ,
    //brbus
    input  [`BR_BUS_WD       -1:0] br_bus         ,
    //to ds
    output                         fs_to_ds_valid ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus   ,
    // inst sram interface
    output        inst_sram_en   ,
    output [ 3:0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,

    input  [31:0] ex_entry,
    input  [31:0] csr_rvalue,
    input         ds_ertn_flush,
    input         es_ertn_flush,
    input         ms_ertn_flush,
    input         ws_ertn_flush,
    input         id_ex,
    input         exe_ex,
    input         mem_ex,
    input         wb_ex,
    input         reg_rlv,
    output        fs_signal_ADEF
);

reg         fs_valid;
wire        fs_ready_go;
wire        fs_allowin;
wire        to_fs_valid;

wire [31:0] seq_pc;
wire [31:0] nextpc;

wire         br_taken;
wire [ 31:0] br_target;
assign {br_taken,br_target} = br_bus;

wire [31:0] fs_inst;
reg  [31:0] fs_pc;
assign fs_to_ds_bus = {fs_inst ,
                       fs_pc   };

// pre-IF stage
assign to_fs_valid  = ~reset;
assign seq_pc       = fs_pc + 3'h4;
assign nextpc       = br_taken      ? br_target :
                      ws_ertn_flush ? csr_rvalue:
                      wb_ex         ? ex_entry  :
                                      seq_pc; 

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

// IF stage
assign fs_ready_go    = ~id_ex;
assign fs_allowin     = (!fs_valid | fs_ready_go & ds_allowin) 
                        & !(ds_ertn_flush | es_ertn_flush | ms_ertn_flush | id_ex | exe_ex | mem_ex);
assign fs_to_ds_valid =  fs_valid && fs_ready_go;
always @(posedge clk) begin
    if (reset) begin
        fs_valid <= 1'b0;
    end
    else if (fs_allowin) begin
        fs_valid <= to_fs_valid;
    end
    else if (br_taken | ds_ertn_flush | es_ertn_flush | ms_ertn_flush | ws_ertn_flush | id_ex | exe_ex | mem_ex | wb_ex) begin
        fs_valid <= 1'b0;
    end

    if (reset) begin
        fs_pc <= 32'h1bfffffc;  //trick: to make nextpc be 0x1c000000 during reset 
    end
    else if (to_fs_valid && fs_allowin) begin
        fs_pc <= nextpc;
    end
end

assign inst_sram_en    = to_fs_valid && fs_allowin;
assign inst_sram_wen   = 4'h0;
assign inst_sram_addr  = nextpc;
assign inst_sram_wdata = 32'b0;

assign fs_inst         = inst_sram_rdata;


endmodule
