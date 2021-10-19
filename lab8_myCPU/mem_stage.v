`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    //from data-sram
    input  [31                 :0] data_sram_rdata,
    
    output [38                 :0] ms_forward,
    output [ 9                 :0] ms_csr_forward,
    output        ms_csr_reg,

    input [`CSR_BUS_WD -1:0] es_to_ms_csr_bus,
    output [`CSR_BUS_WD -1:0] ms_to_ws_csr_bus,
    output ms_ertn_flush,
    output mem_ex
);

reg         ms_valid;
wire        ms_ready_go;

reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire [ 4:0] ms_res_from_mem;
wire        ms_gr_we;
wire [ 4:0] ms_dest;
wire [31:0] ms_alu_result;
wire [31:0] ms_pc;
assign {ms_res_from_mem,  //74:70
        ms_gr_we       ,  //69:69
        ms_dest        ,  //68:64
        ms_alu_result  ,  //63:32
        ms_pc             //31:0
       } = es_to_ms_bus_r;

wire [31:0] mem_result_w;
wire [31:0] mem_result_b;
wire [31:0] mem_result_bu;
wire [31:0] mem_result_h;
wire [31:0] mem_result_hu;
wire [31:0] ms_final_result;

reg [`CSR_BUS_WD -1:0] es_to_ms_csr_bus_r;

assign ms_to_ws_bus = {ms_gr_we       ,  //69:69
                       ms_dest        ,  //68:64
                       ms_final_result,  //63:32
                       ms_pc             //31:0
                      };

assign ms_ready_go    = 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  <= es_to_ms_bus;
    end
    
    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_csr_bus_r <= es_to_ms_csr_bus;
    end
end

assign ms_addr_last_00 = (ms_alu_result[1:0] == 2'b00);
assign ms_addr_last_01 = (ms_alu_result[1:0] == 2'b01);
assign ms_addr_last_10 = (ms_alu_result[1:0] == 2'b10);
assign ms_addr_last_11 = (ms_alu_result[1:0] == 2'b11);
assign mem_result_w    = data_sram_rdata;
assign mem_result_h    = ms_addr_last_00 ? {{17{data_sram_rdata[15]}}, data_sram_rdata[14:0]} :
                                           {{17{data_sram_rdata[31]}}, data_sram_rdata[30:16]};
assign mem_result_hu   = ms_addr_last_00 ? {16'b0, data_sram_rdata[15:0]}                     :
                                           {16'b0, data_sram_rdata[31:16]}                    ;
assign mem_result_b    = ms_addr_last_00 ? {{25{data_sram_rdata[7]}}, data_sram_rdata[6:0]}   :
                         ms_addr_last_01 ? {{25{data_sram_rdata[15]}}, data_sram_rdata[14:8]} :
                         ms_addr_last_10 ? {{25{data_sram_rdata[23]}}, data_sram_rdata[22:16]}:
                                           {{25{data_sram_rdata[31]}}, data_sram_rdata[30:24]};
assign mem_result_bu   = ms_addr_last_00 ? {24'b0, data_sram_rdata[7:0]}                      :
                         ms_addr_last_01 ? {24'b0, data_sram_rdata[15:8]}                     :
                         ms_addr_last_10 ? {24'b0, data_sram_rdata[23:16]}                    :
                                           {24'b0, data_sram_rdata[31:24]}                    ;

//assign load_op = {inst_ld_w, inst_ld_b, inst_ld_bu, inst_ld_h, inst_ld_hu};

assign ms_final_result = ms_res_from_mem[4] ? mem_result_w  :
                         ms_res_from_mem[3] ? mem_result_b  :
                         ms_res_from_mem[2] ? mem_result_bu :
                         ms_res_from_mem[1] ? mem_result_h  :
                         ms_res_from_mem[0] ? mem_result_hu :
                                               ms_alu_result;

//csr
assign ms_to_ws_csr_bus = es_to_ms_csr_bus_r;
assign ms_ertn_flush    = ms_valid & es_to_ms_csr_bus_r[`CSR_BUS_ERTN];
assign mem_ex           = ms_valid & es_to_ms_csr_bus_r[`CSR_BUS_EX];

//forward
assign ms_forward =    {ms_valid        ,  //38:38
                        ms_gr_we        ,  //37:37
                        ms_dest         ,  //36:32
                        ms_final_result     //31:0
                        };
assign ms_csr_forward = {   es_to_ms_csr_bus_r[`CSR_BUS_WE],     // csr_we
                            es_to_ms_csr_bus_r[`CSR_BUS_NUM]   // csr_num
                         };
assign ms_csr_reg = es_to_ms_csr_bus_r[`CSR_BUS_OP] & ms_gr_we;
endmodule
