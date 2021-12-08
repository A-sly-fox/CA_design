`include "mycpu.h"

module exe_stage(
    input                          clk              ,
    input                          reset            ,
    //allowin
    input                          ms_allowin       ,
    output                         es_allowin       ,
    //from ds
    input                          ds_to_es_valid   ,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus     ,
    input                          ds_tlb_rlv     ,
    //from da to mul
    input  [`DS_TO_MD_BUS_WD -1:0] ds_to_md_bus     ,
    //to ms
    output                         es_to_ms_valid   ,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus     ,
    // data sram interface
    output                         data_sram_req    ,
    output                         data_sram_wr     ,
    output [1                  :0] data_sram_size   ,
    output [3                  :0] data_sram_wstrb  ,
    output [31                 :0] data_sram_addr   ,
    output [31                 :0] data_sram_wdata  ,
    input                          data_sram_addr_ok,
    
    output [39                 :0] es_forward       ,
    output [11                 :0] es_csr_forward   ,

    input  [`CSR_BUS_WD -1     :0] ds_to_es_csr_bus ,
    output [`CSR_BUS_WD -1     :0] es_to_ms_csr_bus ,
    output                         es_ertn_flush    ,
    output                         es_tlb_rlv     ,
    output                         exe_ex           ,
    output                         es_signal_ALE    ,
    output                         es_tlbsrch_op    ,
    output                         es_invtlb_op     ,
    output [4                  :0] es_invtlb_opcode ,
    output [18                 :0] es_reg_vppn      ,
    output [9                  :0] es_reg_asid      ,
    input                          ms_tlb_hazard    ,
    
    output                         load_forward     ,
    output                         store_forward    ,
    input                          signal_PIL       ,
    input                          signal_PIS       ,
    input                          signal_PME       ,
    input                          signal_TLBR      ,
    input                          signal_PPI       ,
    input                          signal_ADEM
);

reg         es_valid      ;
wire        es_ready_go   ;
wire        es_ld_st_ready_go;
wire        es_tlbsrch_ready_go;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
wire [11:0] es_alu_op     ;
wire        es_src1_is_pc ;
wire        es_src2_is_imm; 
wire        es_gr_we      ;
wire [ 2:0] es_mem_we     ;
wire [ 4:0] es_dest       ;
wire [31:0] es_imm        ;
wire [31:0] es_rj_value   ;
wire [31:0] es_rkd_value  ;
wire [31:0] es_pc         ;

wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_alu_result ;

wire [ 4:0] es_res_from_mem;
wire [ 1:0] es_timer_type;
wire        es_ld_st_op;

//csr
wire [ 4:0] es_tlb_opcode;
wire        ertn_flush;
wire        ex;
wire [ 5:0] ecode;
wire [ 8:0] esubcode;
wire        csr_op;
wire [ 8:0] csr_num;
wire        csr_we;
wire [31:0] csr_wmask;
wire [31:0] csr_wvalue;

wire [ 5:0] es_csr_ecode;
wire [ 8:0] es_csr_esubcode;
wire [ 8:0] es_csr_num;
wire        es_csr_we;
wire [31:0] es_csr_wmask;
wire [31:0] es_csr_wvalue;
wire [ 4:0] invtlb_opcode;

reg  [`CSR_BUS_WD -1:0] ds_to_es_csr_bus_r;
wire es_meaningful_inst;
wire ds_meaningful_inst;

assign es_signal_ALE          = (es_res_from_mem[4] & (es_alu_result[1] | es_alu_result[0]) ) | 
                             (es_res_from_mem[1] &  es_alu_result[0]                     ) |
                             (es_res_from_mem[0] &  es_alu_result[0]                     ) |
                             (      es_mem_we[2] & (es_alu_result[1] | es_alu_result[0]) ) |
                             (      es_mem_we[1] &  es_alu_result[0]                     ) ;

assign {es_tlb_opcode,      //96:92
        ertn_flush,         //91:91
        ex,                 //90:90
        ecode,              //89:84
        esubcode,           //83:75
        csr_op,             //74:74
        csr_num,            //73:65
        csr_we,             //64:64
        csr_wmask,          //63:32
        csr_wvalue          //31:0
        } = ds_to_es_csr_bus_r;
        
assign es_meaningful_inst  = ~exe_ex & ds_meaningful_inst;
assign es_ertn_flush       = es_valid & ertn_flush;

wire es_new_ex = es_valid & ~ex & (es_signal_ALE | signal_PIL | signal_PIS | signal_PME | signal_TLBR | signal_PPI | signal_ADEM); 

assign exe_ex        =  ~es_valid ? 1'b0         :
                        es_new_ex ? 1'b1         : 
                                    ex        ;
assign es_csr_ecode  =  es_new_ex & es_signal_ALE   ?   `ECODE_ALE  : 
                        es_new_ex & signal_TLBR     ?   `ECODE_TLBR :
                        es_new_ex & signal_PPI      ?   `ECODE_PPI  :
                        es_new_ex & signal_PIL      ?   `ECODE_PIL  :
                        es_new_ex & signal_PIS      ?   `ECODE_PIS  : 
                        es_new_ex & signal_PME      ?   `ECODE_PME  :
                        es_new_ex & signal_ADEM     ?   `ECODE_ADE  :
                                                        ecode   ;
assign es_csr_esubcode = es_new_ex & signal_ADEM ? `ESUBCODE_ADEM : esubcode;
assign es_csr_num    =  es_new_ex ? `CSR_ERA     : csr_num   ;
assign es_csr_we     =  ~es_valid ? 1'b0         :
                        es_new_ex ? 1'b1         : csr_we  ;
assign es_csr_wmask  =  es_new_ex ? 32'hffffffff : csr_wmask ;
assign es_csr_wvalue =  es_new_ex ? es_pc        : csr_wvalue;

assign es_to_ms_csr_bus = {es_tlb_opcode,         //96:92
                           ertn_flush,            //91:91
                           exe_ex,                //90:90
                           es_csr_ecode,          //89:84
                           es_csr_esubcode,       //83:75
                           csr_op,                //74:74
                           es_csr_num,            //73:65
                           es_csr_we,             //64:64
                           es_csr_wmask,          //63:32
                           es_csr_wvalue          //31:0
                           };

assign {invtlb_opcode     ,   //163:159
        es_timer_type     ,   //158:157
        ds_meaningful_inst,   //156:156
        es_alu_op         ,   //155:144
        es_res_from_mem   ,   //143:139
        es_src1_is_pc     ,   //138:138
        es_src2_is_imm    ,   //137:137
        es_gr_we          ,   //136:136
        es_mem_we         ,   //135:133
        es_dest           ,   //132:128
        es_imm            ,   //127:96
        es_rj_value       ,   //95 :64
        es_rkd_value      ,   //63 :32
        es_pc                 //31 :0
       } = ds_to_es_bus_r;

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
reg  [2:0] mul_status;

wire [31:0] es_op_result;
wire [31:0] es_timer_value;

assign es_op_result = mul_inst_r ? mul_result : 
                      div_inst_r ? div_result :
                      es_timer_type ? es_timer_value :
                                   es_alu_result;
assign es_to_ms_bus = {es_signal_ALE  ,  //79:79
                       es_meaningful_inst, //78:78
                       es_mem_we      ,  //77:75
                       es_res_from_mem,  //74:70
                       es_gr_we       ,  //69:69
                       es_dest        ,  //68:64
                       es_op_result  ,  //63:32
                       es_pc             //31:0 
                      };

assign es_ld_st_op         = load_forward | store_forward;
assign es_ld_st_ready_go   = ~es_ld_st_op | (es_ld_st_op & (data_sram_addr_ok & data_sram_req | es_signal_ALE));
assign es_tlbsrch_ready_go = ~(es_tlbsrch_op & ms_tlb_hazard);
assign es_ready_go    = (~es_valid | !div_inst_r | div_valid) & mul_status[0] & es_ld_st_ready_go & es_tlbsrch_ready_go | exe_ex;
assign es_allowin     = ~es_valid | es_ready_go & ms_allowin;
assign es_to_ms_valid =  es_valid & es_ready_go;

reg es_tlb_rlv_r;
assign es_tlb_rlv = es_valid & es_tlb_rlv_r;

always @(posedge clk) begin
    if (reset) begin     
        es_valid <= 1'b0;
        es_tlb_rlv_r <= 1'b0;
    end
    else if (es_allowin) begin 
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r      <= ds_to_es_bus;
        ds_to_md_bus_r      <= ds_to_md_bus;
        ds_to_es_csr_bus_r  <= ds_to_es_csr_bus;
        es_tlb_rlv_r        <= ds_tlb_rlv;
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

assign div_result       = div_inst_r[3] ? div_out1[63:32] :
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

assign div_valid = (div_res_signed   & div_valid1) |
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

timer u_timer(
    .timer_type(es_timer_type),
    .clk(clk),
    .reset(reset),
    .timer_value(es_timer_value)
);

// data_sram
wire es_addr_last_00;
wire es_addr_last_01;
wire es_addr_last_10;
wire es_addr_last_11;

assign es_addr_last_00 = (es_op_result[1:0] == 2'b00);
assign es_addr_last_01 = (es_op_result[1:0] == 2'b01);
assign es_addr_last_10 = (es_op_result[1:0] == 2'b10);
assign es_addr_last_11 = (es_op_result[1:0] == 2'b11);
assign load_forward    = (es_res_from_mem != 4'h0);
assign store_forward   = (es_mem_we != 3'h0);
assign data_sram_req   = (load_forward | store_forward) & es_valid & ms_allowin & ~exe_ex;
assign data_sram_wr    = store_forward;
assign data_sram_wstrb = es_mem_we[2] ? 4'hf :
                        (es_mem_we[1] & es_addr_last_00) ? 4'h3 :
                        (es_mem_we[1] & es_addr_last_10) ? 4'hc :
                        (es_mem_we[0] & es_addr_last_00) ? 4'h1 :
                        (es_mem_we[0] & es_addr_last_01) ? 4'h2 :
                        (es_mem_we[0] & es_addr_last_10) ? 4'h4 :
                        (es_mem_we[0] & es_addr_last_11) ? 4'h8 :
                                                            4'h0 ;
assign data_sram_addr  = es_alu_result;
assign data_sram_wdata = es_rkd_value;
assign data_sram_size  = (es_res_from_mem[4] | es_mem_we[2])                      ? 2'h2 :
                         (es_res_from_mem[0] | es_res_from_mem[1] | es_mem_we[1]) ? 2'h1 :
                                                                                    2'h0 ;
//assign load_op = {inst_ld_w, inst_ld_b, inst_ld_bu, inst_ld_h,  inst_ld_hu};
//assign mem_we        = {inst_st_w, inst_st_h, inst_st_b};

//forward
assign es_forward =     {es_valid       ,  //39:39    
                         load_forward   ,  //38:38
                         es_gr_we       ,  //37:37
                         es_dest        ,  //36:32
                         es_op_result     //31:0
                        };
assign es_csr_forward = {   exe_ex,
                            ds_to_es_csr_bus_r[`CSR_BUS_WE],     // csr_we
                            ds_to_es_csr_bus_r[`CSR_BUS_NUM]     // csr_num
                         };
assign es_tlbsrch_op    = es_tlb_opcode[4];
assign es_invtlb_op     = es_tlb_opcode[0];
assign es_invtlb_opcode = invtlb_opcode;
assign es_reg_vppn      = es_rkd_value[31:13];
assign es_reg_asid      = es_rj_value[9:0];

endmodule
