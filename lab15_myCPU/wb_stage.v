`include "mycpu.h"

module wb_stage(
    input                           clk           ,
    input                           reset         ,
    //allowin
    output                          ws_allowin    ,
    //from ms
    input                           ms_to_ws_valid,
    input  [`MS_TO_WS_BUS_WD -1:0]  ms_to_ws_bus  ,
    input                           ms_tlb_rlv  ,
    //to rf: for write back
    output [`WS_TO_RF_BUS_WD -1:0]  ws_to_rf_bus  ,
    //trace debug interface
    output [31 :0]  debug_wb_pc     ,
    output [3  :0]  debug_wb_rf_wen ,
    output [4  :0]  debug_wb_rf_wnum,
    output [31 :0]  debug_wb_rf_wdata,

    output [7  :0]  hw_int_in,
    output          ipi_int_in,

    output          wb_ertn_flush,
    output          wb_ex,
    output [5  :0]  wb_ecode,
    output [8  :0]  wb_esubcode,
    output [31 :0]  wb_pc,
    output [31 :0]  wb_vaddr,
    output          ws_tlb_rlv,

    input  [`CSR_BUS_WD -1:0] ms_to_ws_csr_bus,
    output [`CSR_BUS_WD -1:0] ws_to_csr_bus,
    input  [31 :0]  csr_rvalue,
    output [2  :0]  tlb_opcode,
    output          ws_tlb_TLBR
);

wire        ws_csr_op;
wire [ 8:0] ws_csr_num;
wire        ws_csr_we;
wire [31:0] ws_csr_wmask;
wire [31:0] ws_csr_wvalue;
reg  [`CSR_BUS_WD -1:0] ms_to_ws_csr_bus_r;
wire [ 4:0] ws_tlb_opcode;

reg         ws_valid;
wire        ws_ready_go;

reg [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus_r;
wire        ws_gr_we;
wire [ 4:0] ws_dest;
wire [31:0] ws_final_result;
wire [31:0] ws_pc;
wire        ws_meaningful_inst;
assign {ws_meaningful_inst, //70:70
        ws_gr_we       ,  //69:69
        ws_dest        ,  //68:64
        ws_final_result,  //63:32
        ws_pc             //31:0
       } = ms_to_ws_bus_r;

wire        rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;
assign ws_to_rf_bus = {rf_we   ,  //37:37
                       rf_waddr,  //36:32
                       rf_wdata   //31:0
                      };

assign ws_ready_go = 1'b1;
assign ws_allowin  = !ws_valid || ws_ready_go;

reg ws_tlb_rlv_r;
assign ws_tlb_rlv = ws_valid & ws_tlb_rlv_r;

always @(posedge clk) begin
    if (reset) begin
        ws_valid <= 1'b0;
        ws_tlb_rlv_r <= 1'b0;
    end
    else if (ws_allowin) begin
        ws_valid <= ms_to_ws_valid;
    end

    if (ms_to_ws_valid && ws_allowin) begin
        ms_to_ws_bus_r      <= ms_to_ws_bus;
        ms_to_ws_csr_bus_r  <= ms_to_ws_csr_bus;
        ws_tlb_rlv_r        <= ms_tlb_rlv;
    end
end

assign rf_we    = ws_gr_we && ws_valid && !wb_ex;
assign rf_waddr = ws_dest;
assign rf_wdata = (ws_csr_op) ? csr_rvalue : ws_final_result;

// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_wen   = {4{rf_we}};
assign debug_wb_rf_wnum  = ws_dest;
assign debug_wb_rf_wdata = (ws_csr_op) ? csr_rvalue : ws_final_result;

// csr
assign hw_int_in = 8'h0;
assign ipi_int_in = 1'h0;

wire ertn_flush;
wire ex;

assign wb_pc = ws_pc;
assign wb_ertn_flush = ws_valid & ertn_flush;
assign wb_ex = ws_valid & ex;
assign wb_vaddr = ws_final_result;

assign {ws_tlb_opcode,         //96:92
        ertn_flush,            //91:91
        ex,                    //90:90
        wb_ecode,              //89:84
        wb_esubcode,           //83:75
        ws_csr_op,             //74:74
        ws_csr_num,            //73:65
        ws_csr_we,             //64:64
        ws_csr_wmask,          //63:32
        ws_csr_wvalue          //31:0
        } = ws_to_csr_bus;
assign ws_to_csr_bus = ms_to_ws_csr_bus_r;
assign tlb_opcode = ws_tlb_opcode[3:1];

endmodule
