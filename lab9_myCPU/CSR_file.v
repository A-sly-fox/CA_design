`include "mycpu.h"

module csrfile(
    input            clock,
    input            reset,
    //指令访问接口，统一编码
    input   [`CSR_BUS_WD -1:0]  ws_to_csr_bus,
    //与硬件电路逻辑直接交互的接口信号，无需统一编码
    output  [31 :0]  csr_rvalue,
    input   [7  :0]  hw_int_in,                 //硬件中断输入引脚
    input            ipi_int_in,                //核间中断输入引脚
    output  [31 :0]  ex_entry,                  //送往预取指 （pre-IF）流水级的异常处理入口地址
    output           has_int,                   //送往译码流水级的中断有效信号
    input            ertn_flush,                //来自写回流水级的 ertn 指令执行的有效信号
    input            wb_ex,                     //来自写回流水级的异常处理触发信号
    input   [5  :0]  wb_ecode,                  //异常ecode
    input   [8  :0]  wb_esubcode,               //异常esubcode
    input   [31 :0]  wb_pc,                     //写回级PC
    input   [31 :0]  wb_vaddr                   //虚地址
);

wire            csr_re;//异步读，始终为1
wire   [8  :0]  csr_num;
wire            csr_we;
wire   [31 :0]  csr_wmask;
wire   [31 :0]  csr_wvalue;

assign csr_re = 1'b1;
assign {csr_num,            //73:65
        csr_we,             //64:64
        csr_wmask,          //63:32
        csr_wvalue          //31:0
        } = ws_to_csr_bus;

reg  [1  :0] csr_crmd_plv;
reg          csr_crmd_ie;
reg          csr_crmd_da;
reg  [1  :0] csr_prmd_pplv;
reg          csr_prmd_pie;
reg  [12 :0] csr_ecfg_lie;
reg  [12 :0] csr_estat_is;
reg  [5  :0] csr_estat_ecode;
reg  [8  :0] csr_estat_esubcode;
reg  [31 :0] csr_era_pc;
reg  [31 :0] csr_badv_vaddr;
wire         wb_ex_addr_err;
reg  [25 :0] csr_eentry_va;
reg  [31 :0] csr_save0_data;
reg  [31 :0] csr_save1_data;
reg  [31 :0] csr_save2_data;
reg  [31 :0] csr_save3_data;
reg  [31 :0] csr_tid_tid;
reg          csr_tcfg_en;
reg          csr_tcfg_periodic;
reg  [29 :0] csr_tcfg_initval; 
wire [31 :0] tcfg_next_value; 
wire [31 :0] csr_tval; 
reg  [31 :0] timer_cnt;
reg          csr_ticlr_clr;
reg  [31 :0] csr_tlbrentry;
reg  [25 :0] csr_tlbrentry_pa;

assign has_int  = ((csr_estat_is[11:0] & csr_ecfg_lie[11:0]) != 12'b0) && (csr_crmd_ie == 1'b1);
assign ex_entry = (wb_ecode==`ECODE_TLBR)? {csr_tlbrentry_pa, 6'b0} : {csr_eentry_va, 6'b0};

//1.CRMD 的 PLV 域
always @(posedge clock) begin 
    if (reset)
        csr_crmd_plv <= 2'b0;
    else if (wb_ex) 
        csr_crmd_plv <= 2'b0;
    else if (ertn_flush) 
        csr_crmd_plv <= csr_prmd_pplv;
    else if (csr_we && csr_num==`CSR_CRMD) 
        csr_crmd_plv <= csr_wmask[`CSR_CRMD_PLV]&csr_wvalue[`CSR_CRMD_PLV] | ~csr_wmask[`CSR_CRMD_PLV]&csr_crmd_plv;
end

//2.CRMD 的 IE 域
always @(posedge clock) begin 
    if (reset)
        csr_crmd_ie <= 1'b0;
    else if (wb_ex) 
        csr_crmd_ie <= 1'b0;
    else if (ertn_flush) 
        csr_crmd_ie <= csr_prmd_pie;
    else if (csr_we && csr_num==`CSR_CRMD)
        csr_crmd_ie <= csr_wmask[`CSR_CRMD_IE]&csr_wvalue[`CSR_CRMD_IE] | ~csr_wmask[`CSR_CRMD_IE]&csr_crmd_ie;
end

//3.PRMD 的 PPLV、PIE 域
always @(posedge clock) begin 
    if (wb_ex) begin 
        csr_prmd_pplv <= csr_crmd_plv; 
        csr_prmd_pie <= csr_crmd_ie;
    end 
    else if (csr_we && csr_num==`CSR_PRMD) begin 
        csr_prmd_pplv <= csr_wmask[`CSR_PRMD_PPLV]&csr_wvalue[`CSR_PRMD_PPLV] | ~csr_wmask[`CSR_PRMD_PPLV]&csr_prmd_pplv;
        csr_prmd_pie <= csr_wmask[`CSR_PRMD_PIE]&csr_wvalue[`CSR_PRMD_PIE] | ~csr_wmask[`CSR_PRMD_PIE]&csr_prmd_pie;
    end 
end

//4.ECFG 的 LIE 域
always @(posedge clock) begin 
    if (reset)
        csr_ecfg_lie <= 13'b0;
    else if (csr_we && csr_num==`CSR_ECFG) 
        csr_ecfg_lie <= csr_wmask[`CSR_ECFG_LIE]&csr_wvalue[`CSR_ECFG_LIE] | ~csr_wmask[`CSR_ECFG_LIE]&csr_ecfg_lie;
end

//5.ESTAT 的 IS 域
always @(posedge clock) begin 
    if (reset)
        csr_estat_is[1:0] <= 2'b0;
    else if (csr_we && csr_num==`CSR_ESTAT) 
        csr_estat_is[1:0] <= csr_wmask[`CSR_ESTAT_IS10]&csr_wvalue[`CSR_ESTAT_IS10] | ~csr_wmask[`CSR_ESTAT_IS10]&csr_estat_is[1:0];
    
    csr_estat_is[9:2] <= hw_int_in[7:0];  

    csr_estat_is[10] <= 1'b0;

    if (timer_cnt[31:0]==32'b0) 
        csr_estat_is[11] <= 1'b1;
    else if (csr_we && csr_num==`CSR_TICLR && csr_wmask[`CSR_TICLR_CLR] && csr_wvalue[`CSR_TICLR_CLR])
        csr_estat_is[11] <= 1'b0; 

    csr_estat_is[12] <= ipi_int_in; 
end

//6.ESTAT 的 Ecode 和 EsubCode 域
always @(posedge clock) begin 
    if (wb_ex) begin 
        csr_estat_ecode <= wb_ecode; 
        csr_estat_esubcode <= wb_esubcode;
    end 
end

//7.ERA 的 PC 域
always @(posedge clock) begin 
    if (wb_ex)
        csr_era_pc <= wb_pc;
    else if (csr_we && csr_num==`CSR_ERA) 
        csr_era_pc <= csr_wmask[`CSR_ERA_PC]&csr_wvalue[`CSR_ERA_PC] | ~csr_wmask[`CSR_ERA_PC]&csr_era_pc;
end

//8.BADV 的 VAddr 域
assign wb_ex_addr_err = wb_ecode==`ECODE_ADE || wb_ecode==`ECODE_ALE;

always @(posedge clock) begin 
    if (wb_ex && wb_ex_addr_err) 
        csr_badv_vaddr <= (wb_ecode==`ECODE_ADE && wb_esubcode==`ESUBCODE_ADEF) ? wb_pc : wb_vaddr;
end


//9.EENTRY 的 VA 域
always @(posedge clock) begin 
    if (csr_we && csr_num==`CSR_EENTRY) 
        csr_eentry_va <= csr_wmask[`CSR_EENTRY_VA]&csr_wvalue[`CSR_EENTRY_VA] | ~csr_wmask[`CSR_EENTRY_VA]&csr_eentry_va;
end


//10.SAVE0~3
always @(posedge clock) begin 
    if (csr_we && csr_num==`CSR_SAVE0) 
        csr_save0_data <= csr_wmask[`CSR_SAVE_DATA]&csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save0_data;
    if (csr_we && csr_num==`CSR_SAVE1) 
        csr_save1_data <= csr_wmask[`CSR_SAVE_DATA]&csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save1_data;
    if (csr_we && csr_num==`CSR_SAVE2) 
        csr_save2_data <= csr_wmask[`CSR_SAVE_DATA]&csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save2_data;
    if (csr_we && csr_num==`CSR_SAVE3) 
        csr_save3_data <= csr_wmask[`CSR_SAVE_DATA]&csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save3_data;
end



//11.TID
always @(posedge clock) begin 
    if (reset)
        //csr_tid_tid <= coreid_in;
        csr_tid_tid <= 32'h0;
    else if (csr_we && csr_num==`CSR_TID) 
        csr_tid_tid <= csr_wmask[`CSR_TID_TID]&csr_wvalue[`CSR_TID_TID] | ~csr_wmask[`CSR_TID_TID]&csr_tid_tid;
end


//12.TCFG 的 En、Periodic 和 InitVal 域
always @(posedge clock) begin 
    if (reset)
        csr_tcfg_en <= 1'b0;
    else if (csr_we && csr_num==`CSR_TCFG) 
        csr_tcfg_en <= csr_wmask[`CSR_TCFG_EN]&csr_wvalue[`CSR_TCFG_EN] | ~csr_wmask[`CSR_TCFG_EN]&csr_tcfg_en;

    if (csr_we && csr_num==`CSR_TCFG) begin 
        csr_tcfg_periodic <= csr_wmask[`CSR_TCFG_PERIOD]&csr_wvalue[`CSR_TCFG_PERIOD] | ~csr_wmask[`CSR_TCFG_PERIOD]&csr_tcfg_periodic;
        csr_tcfg_initval <= csr_wmask[`CSR_TCFG_INITVAL]&csr_wvalue[`CSR_TCFG_INITVAL] | ~csr_wmask[`CSR_TCFG_INITVAL]&csr_tcfg_initval;
    end 
end

//13.TVAL 的 TimeVal 域
assign tcfg_next_value = csr_wmask[31:0]&csr_wvalue[31:0] | ~csr_wmask[31:0]&{csr_tcfg_initval, csr_tcfg_periodic, csr_tcfg_en};

always @(posedge clock) begin 
    if (reset)
        timer_cnt <= 32'hffffffff;
    else if (csr_we && csr_num==`CSR_TCFG && tcfg_next_value[`CSR_TCFG_EN]) 
        timer_cnt <= {tcfg_next_value[`CSR_TCFG_INITVAL], 2'b0};
    else if (csr_tcfg_en && timer_cnt!=32'hffffffff) begin 
        if (timer_cnt[31:0]==32'b0 && csr_tcfg_periodic) 
            timer_cnt <= {csr_tcfg_initval, 2'b0};
        else 
            timer_cnt <= timer_cnt - 1'b1; 
    end
end

assign csr_tval = timer_cnt[31:0];


//14.TICLR 的 CLR 域
always @(posedge clock) begin 
    if (reset)
        csr_ticlr_clr <= 1'b0;
    else if (csr_we && csr_num==`CSR_TICLR) 
        csr_ticlr_clr <= csr_wmask[`CSR_TICLR_CLR]&csr_wvalue[`CSR_TICLR_CLR] | ~csr_wmask[`CSR_TICLR_CLR]&csr_ticlr_clr;
end

//16. CRMD 的 DA 域
always @(posedge clock) begin 
    if (reset)
        csr_crmd_da <= 1'b1;
    else if (csr_we && csr_num==`CSR_CRMD) 
        csr_crmd_da <= csr_wmask[`CSR_CRMD_DA]&csr_wvalue[`CSR_CRMD_DA] | ~csr_wmask[`CSR_CRMD_DA]&csr_crmd_da;
end

//15.CSR 的读出逻辑
wire [31:0] csr_crmd_rvalue   = {28'b0, csr_crmd_da, csr_crmd_ie, csr_crmd_plv}; 
wire [31:0] csr_prmd_rvalue   = {29'b0, csr_prmd_pie, csr_prmd_pplv}; 
wire [31:0] csr_ecfg_rvalue   = {19'b0, csr_ecfg_lie};
wire [31:0] csr_estat_rvalue  = {1'b0, csr_estat_esubcode, csr_estat_ecode, 3'b0, csr_estat_is};
wire [31:0] csr_era_rvalue    = csr_era_pc;
wire [31:0] csr_eentry_rvalue = {csr_eentry_va, 6'b0};
wire [31:0] csr_save0_rvalue  = csr_save0_data;
wire [31:0] csr_save1_rvalue  = csr_save1_data;
wire [31:0] csr_save2_rvalue  = csr_save2_data;
wire [31:0] csr_save3_rvalue  = csr_save3_data;
wire [31:0] csr_ticlr_rvalue  = 32'b0;
wire [31:0] csr_badv_rvalue   = csr_badv_vaddr;
wire [31:0] csr_tid_rvalue    = csr_tid_tid;

assign csr_rvalue =   {32{csr_num==`CSR_CRMD}}   & csr_crmd_rvalue 
                    | {32{csr_num==`CSR_PRMD}}   & csr_prmd_rvalue 
                    | {32{csr_num==`CSR_ECFG}}   & csr_ecfg_rvalue
                    | {32{csr_num==`CSR_ESTAT}}  & csr_estat_rvalue
                    | {32{csr_num==`CSR_ERA}}    & csr_era_rvalue
                    | {32{csr_num==`CSR_BADV}}   & csr_badv_rvalue
                    | {32{csr_num==`CSR_EENTRY}} & csr_eentry_rvalue
                    | {32{csr_num==`CSR_SAVE0}}  & csr_save0_rvalue
                    | {32{csr_num==`CSR_SAVE1}}  & csr_save1_rvalue
                    | {32{csr_num==`CSR_SAVE2}}  & csr_save2_rvalue
                    | {32{csr_num==`CSR_SAVE3}}  & csr_save3_rvalue
                    | {32{csr_num==`CSR_TID}}    & csr_tid_rvalue
                    ;
                    
endmodule
