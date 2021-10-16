`include "mycpu.h"

module wb_stage(
    input                           clk           ,
    input                           reset         ,
    //allowin
    output                          ws_allowin    ,
    //from ms
    input                           ms_to_ws_valid,
    input  [`MS_TO_WS_BUS_WD -1:0]  ms_to_ws_bus  ,
    //to rf: for write back
    output [`WS_TO_RF_BUS_WD -1:0]  ws_to_rf_bus  ,
    //trace debug interface
    output [31:0] debug_wb_pc     ,
    output [ 3:0] debug_wb_rf_wen ,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,

    output   [7  :0]  hw_int_in,
    output            ipi_int_in,

    output            ertn_flush,
    output            wb_ex,
    output   [5  :0]  wb_ecode,
    output   [8  :0]  wb_esubcode,
    output   [31 :0]  wb_pc,
    output   [31 :0]  wb_vaddr,

    input [`CSR_BUS_WD -1:0] ms_to_ws_csr_bus,
    output [`CSR_BUS_WD -1:0] ws_to_csr_bus,
    input  [31:0] csr_rvalue
);
/*
*
*
*
*/
wire ws_csr_op;
wire [8:0] ws_csr_num;
wire ws_csr_we;
wire [31:0] ws_csr_wmask;
wire [31:0] ws_csr_wvalue;
/*
*
*
*
*
*/

reg         ws_valid;
wire        ws_ready_go;

reg [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus_r;
wire        ws_gr_we;
wire [ 4:0] ws_dest;
wire [31:0] ws_final_result;
wire [31:0] ws_pc;
assign {ws_gr_we       ,  //69:69
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
always @(posedge clk) begin
    if (reset) begin
        ws_valid <= 1'b0;
    end
    else if (ws_allowin) begin
        ws_valid <= ms_to_ws_valid;
    end

    if (ms_to_ws_valid && ws_allowin) begin
        ms_to_ws_bus_r <= ms_to_ws_bus;
    end
end

assign rf_we    = ws_gr_we&&ws_valid;
assign rf_waddr = ws_dest;
assign rf_wdata = (ws_csr_op)?csr_rvalue: ws_final_result;

// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_wen   = {4{rf_we}};
assign debug_wb_rf_wnum  = ws_dest;
assign debug_wb_rf_wdata = (ws_csr_op)?csr_rvalue: ws_final_result;


/*
*
*
*
*
*/
assign hw_int_in = 8'h0;
assign ipi_int_in = 1'h0;


assign {ws_csr_op,             //74:74
        ws_csr_num,            //73:65
        ws_csr_we,             //64:64
        ws_csr_wmask,          //63:32
        ws_csr_wvalue          //31:0
        } = ws_to_csr_bus;

reg [`CSR_BUS_WD -1:0] ms_to_ws_csr_bus_r;
always @(posedge clk) begin
    ms_to_ws_csr_bus_r <= ms_to_ws_csr_bus;
end
assign ws_to_csr_bus = ms_to_ws_csr_bus_r;

endmodule
