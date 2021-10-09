`include "mycpu.h"

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ms_allowin    ,
    output                         es_allowin    ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //from da to mul
    input  [`DS_TO_MD_BUS_WD -1:0] ds_to_md_bus ,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    // data sram interface
    output        data_sram_en   ,
    output [ 3:0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    
    output [39:0] es_forward
);

reg         es_valid      ;
wire        es_ready_go   ;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
wire [11:0] es_alu_op     ;
wire        es_src1_is_pc ;
wire        es_src2_is_imm; 
wire        es_gr_we      ;
wire        es_mem_we     ;
wire [ 4:0] es_dest       ;
wire [31:0] es_imm        ;
wire [31:0] es_rj_value   ;
wire [31:0] es_rkd_value  ;
wire [31:0] es_pc         ;

wire        es_res_from_mem;

assign {es_alu_op      ,  //149:138
        es_res_from_mem,  //137:137
        es_src1_is_pc  ,  //136:136
        es_src2_is_imm ,  //135:135
        es_gr_we       ,  //134:134
        es_mem_we      ,  //133:133
        es_dest        ,  //132:128
        es_imm         ,  //127:96
        es_rj_value    ,  //95 :64
        es_rkd_value   ,  //63 :32
        es_pc             //31 :0
       } = ds_to_es_bus_r;

wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_alu_result ;

reg  [`DS_TO_MD_BUS_WD -1:0] ds_to_md_bus_r;
wire [31:0] mul_src1;
wire [31:0] mul_src2;
wire [31:0] div_src1;
wire [31:0] div_src2;
wire [ 2:0] mul_inst;
wire [ 2:0] mul_inst_r;
wire [ 3:0] div_inst;
wire [ 3:0] div_inst_r;
wire [31:0] mul_result;

wire dv_ready1;
wire dv_ready2;
wire dv_valid;
wire dd_ready1;
wire dd_ready2;
wire dd_valid;
wire [63:0] div_out1;
wire [63:0] div_out2;
wire div_valid1;
wire div_valid2;
wire div_valid;
wire [31:0] div_result;
reg [2:0] mul_status;

wire [31:0] es_op_result;

//assign es_res_from_mem = es_load_op;
assign es_op_result = mul_inst_r ? mul_result : 
                      div_inst_r ? div_result :
                                   es_alu_result;
assign es_to_ms_bus = {es_res_from_mem,  //70:70
                       es_gr_we       ,  //69:69
                       es_dest        ,  //68:64
                       es_op_result  ,  //63:32
                       es_pc             //31:0 
                      };

assign es_ready_go    = (!es_valid | !div_inst_r | div_valid) & mul_status[0];
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid =  es_valid && es_ready_go;
always @(posedge clk) begin
    if (reset) begin     
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin 
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
end

assign es_alu_src1 = es_src1_is_pc  ? es_pc[31:0] : 
                                      es_rj_value;
                                      
assign es_alu_src2 = es_src2_is_imm ? es_imm : 
                                      es_rkd_value;

alu u_alu(
    .alu_op     (es_alu_op    ),
    .alu_src1   (es_alu_src1  ),
    .alu_src2   (es_alu_src2  ),
    .alu_result (es_alu_result)
    );

//mul & div
/*
assign {    mul_src1,   //70:39
            mul_src2,   //38:7
            mul_inst,    // 6:4
            div_inst
        } = ds_to_md_bus;*/
assign {    div_src1,   //70:39
            div_src2,    //38:7
            mul_inst_r,   // 6:4
            div_inst_r    // 3:0
        } = ds_to_md_bus_r;


always @(posedge clk) begin
    if(mul_inst) begin
        mul_status <= 3'b010;
    end
    else if(mul_status[1]) begin
        mul_status <= 3'b100;
    end
    else if(mul_status[2]) begin
        mul_status <= 3'b001;
    end
    else begin
        mul_status <= 3'b001;
    end
end

multiplier u_multiplier(
    .src1(div_src1),
    .src2(div_src2),
    .mul_inst(mul_inst_r),
    .mul_result(mul_result)
);        

wire div_res_signed;
wire div_res_unsigned;

assign div_res_signed   =   div_inst_r[3] | div_inst_r[2];
assign div_res_unsigned =   div_inst_r[1] | div_inst_r[0];

assign div_result = div_inst_r[3] ? div_out1[63:32] :
                    div_inst_r[2] ? div_out1[31: 0] :
                    div_inst_r[1] ? div_out2[63:32] :
                /*div_inst_r[0]*/   div_out2[31: 0] ;

reg [2:0] div_status;

always @(posedge clk) begin
    if(es_ready_go) begin
        div_status <= 3'b001;
    end
    else if(div_status[0] & !es_ready_go & div_inst_r != 0) begin
        div_status <= 3'b010;
    end
    else if(div_status[1] & ((div_res_signed & dd_ready1) | (div_res_unsigned & dd_ready2))) begin
        div_status <= 3'b100;
    end
    else if(div_status[2] & div_valid) begin
        div_status <= 3'b001;
    end
end

assign dv_valid = div_status[1];
assign dd_valid = div_status[1];

always @(posedge clk) begin    
    if (ds_to_es_valid && es_allowin) begin
        ds_to_md_bus_r <= ds_to_md_bus;
    end    
end

assign div_valid =(div_res_signed   & div_valid1) |
                  (div_res_unsigned & div_valid2);

div1 div1(
    .aclk(clk),
    .s_axis_divisor_tdata(div_src2),
    .s_axis_divisor_tready(dv_ready1),
    .s_axis_divisor_tvalid(dv_valid),
    .s_axis_dividend_tdata(div_src1),
    .s_axis_dividend_tready(dd_ready1),
    .s_axis_dividend_tvalid(dd_valid),
    .m_axis_dout_tdata(div_out1),
    .m_axis_dout_tvalid(div_valid1)
);

div2 div2(
    .aclk(clk),
    .s_axis_divisor_tdata(div_src2),
    .s_axis_divisor_tready(dv_ready2),
    .s_axis_divisor_tvalid(dv_valid),
    .s_axis_dividend_tdata(div_src1),
    .s_axis_dividend_tready(dd_ready2),
    .s_axis_dividend_tvalid(dd_valid),
    .m_axis_dout_tdata(div_out2),
    .m_axis_dout_tvalid(div_valid2)
);


// data_sram
assign data_sram_en    = (es_res_from_mem || es_mem_we) && es_valid;
assign data_sram_wen   = es_mem_we ? 4'hf : 4'h0;
assign data_sram_addr  = es_alu_result;
assign data_sram_wdata = es_rkd_value;

//forward
assign es_forward =    { es_valid       ,  //39:39    
                         es_res_from_mem,  //38:38
                         es_gr_we       ,  //37:37
                         es_dest        ,  //36:32
                         es_alu_result     //31:0
                        };

endmodule
