`include "mycpu.h"

module csrfile(
    input          clock        ,
    input          reset        ,
    input  [`CSR_BUS_WD -1:0]  ws_to_csr_bus,
    output [31:0]  csr_rvalue   ,
    input  [ 7:0]  hw_int_in    ,
    input          ipi_int_in   ,
    output [31:0]  ex_entry     ,
    output         has_int      ,
    input          ertn_flush   ,
    input          wb_ex        ,
    input  [ 5:0]  wb_ecode     ,
    input  [ 8:0]  wb_esubcode  ,
    input  [31:0]  wb_pc        ,
    input  [31:0]  wb_vaddr     ,

    //tlb_opcode
    input  [2 :0]  tlb_opcode   ,   //TLBRD, TLBWR, TLBFILL
    input          tlbsrch      ,

    //tlb_read
    output [3 :0]  tlb_r_index  ,
    input          tlb_r_e      ,
    input  [18:0]  tlb_r_vppn   ,
    input  [ 5:0]  tlb_r_ps     ,
    input  [ 9:0]  tlb_r_asid   ,
    input          tlb_r_g      ,
    input  [19:0]  tlb_r_ppn0   ,
    input  [ 1:0]  tlb_r_plv0   ,
    input  [ 1:0]  tlb_r_mat0   ,
    input          tlb_r_d0     ,
    input          tlb_r_v0     ,
    input  [19:0]  tlb_r_ppn1   ,
    input  [ 1:0]  tlb_r_plv1   ,
    input  [ 1:0]  tlb_r_mat1   ,
    input          tlb_r_d1     ,
    input          tlb_r_v1     ,

    //tlb_write
    output           tlb_we, //w(rite) e(nable)
    output   [ 3:0]  tlb_w_index,
    output           tlb_w_e    ,
    output   [18:0]  tlb_w_vppn ,
    output   [ 5:0]  tlb_w_ps   ,
    output   [ 9:0]  tlb_w_asid ,
    output           tlb_w_g    ,
    output   [19:0]  tlb_w_ppn0 ,
    output   [ 1:0]  tlb_w_plv0 ,
    output   [ 1:0]  tlb_w_mat0 ,
    output           tlb_w_d0   ,
    output           tlb_w_v0   ,
    output   [19:0]  tlb_w_ppn1 ,
    output   [ 1:0]  tlb_w_plv1 ,
    output   [ 1:0]  tlb_w_mat1 ,
    output           tlb_w_d1   ,
    output           tlb_w_v1   ,

    //tlb search
    output   [18:0]  tlb_s1_vppn,
    output           tlb_s1_va_bit12,
    output   [ 9:0]  tlb_s1_asid,
    input            tlb_s1_found,
    input    [ 3:0]  tlb_s1_index,

    // to_tlb
    output   [ 1:0] mmu_crmd_plv ,
    output          mmu_crmd_da  ,
    output          mmu_crmd_pg  ,
    output   [ 2:0] mmu_dmw0_vseg,
    output   [ 2:0] mmu_dmw0_pseg,
    output   [ 2:0] mmu_dmw1_vseg,
    output   [ 2:0] mmu_dmw1_pseg
);

wire   [8  :0]  csr_num;
wire            csr_we;
wire   [31 :0]  csr_wmask;
wire   [31 :0]  csr_wvalue;

assign {csr_num,            //73:65
        csr_we,             //64:64
        csr_wmask,          //63:32
        csr_wvalue          //31:0
        } = ws_to_csr_bus;

reg  [1  :0] csr_crmd_plv;
reg          csr_crmd_ie;
reg          csr_crmd_da;
reg          csr_crmd_pg;
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
reg  [25 :0] csr_tlbrentry_pa;
reg  [3  :0] csr_tlbidx_index;
reg  [5  :0] csr_tlbidx_ps;
reg          csr_tlbidx_ne;
reg  [18 :0] csr_tlbehi_vppn;
reg  [31 :0] csr_tlbelo0;
reg  [31 :0] csr_tlbelo1;
reg  [9  :0] csr_asid_asid;
reg  [7  :0] csr_asid_asidbits;
reg  [3  :0] csr_tlbfill_number;

reg  [2  :0] csr_dmw0_vseg;
reg  [2  :0] csr_dmw0_pseg;
reg  [1  :0] csr_dmw0_mat ;
reg          csr_dmw0_plv3;
reg          csr_dmw0_plv0;
reg  [2  :0] csr_dmw1_vseg;
reg  [2  :0] csr_dmw1_pseg;
reg  [1  :0] csr_dmw1_mat ;
reg          csr_dmw1_plv3;
reg          csr_dmw1_plv0;
assign mmu_crmd_plv  = csr_crmd_plv ;
assign mmu_crmd_da   = csr_crmd_da  ;
assign mmu_crmd_pg   = csr_crmd_pg  ;
assign mmu_dmw0_vseg = csr_dmw0_vseg;
assign mmu_dmw0_pseg = csr_dmw0_pseg;
assign mmu_dmw1_vseg = csr_dmw1_vseg;
assign mmu_dmw1_pseg = csr_dmw1_pseg;

wire tlbsrch_op = tlbsrch;
wire tlbrd_op   = tlb_opcode[2];
wire tlbwr_op   = tlb_opcode[1];
wire tlbfill_op = tlb_opcode[0];

assign has_int  = ((csr_estat_is[11:0] & csr_ecfg_lie[11:0]) != 12'b0) && (csr_crmd_ie == 1'b1);
assign ex_entry = (wb_ecode==`ECODE_TLBR)? {csr_tlbrentry_pa, 6'b0} : {csr_eentry_va, 6'b0};

wire ex_TLBR = wb_ecode == `ECODE_TLBR  ;
wire ex_ADE  = wb_ecode == `ECODE_ADE   ; 
wire ex_ALE  = wb_ecode == `ECODE_ALE   ; 
wire ex_PIL  = wb_ecode == `ECODE_PIL   ; 
wire ex_PIS  = wb_ecode == `ECODE_PIS   ; 
wire ex_PIF  = wb_ecode == `ECODE_PIF   ; 
wire ex_PME  = wb_ecode == `ECODE_PME   ; 
wire ex_PPI  = wb_ecode == `ECODE_PPI   ;

// CRMD_PLV 
always @(posedge clock) begin 
    if (reset)
        csr_crmd_plv <= 2'b0;
    else if (wb_ex) 
        csr_crmd_plv <= 2'b0;
    else if (ertn_flush) 
        csr_crmd_plv <= csr_prmd_pplv;
    else if (csr_we && csr_num == `CSR_CRMD) 
        csr_crmd_plv <= csr_wmask[`CSR_CRMD_PLV] & csr_wvalue[`CSR_CRMD_PLV] | ~csr_wmask[`CSR_CRMD_PLV] & csr_crmd_plv;
end

// CRMD_IE
always @(posedge clock) begin 
    if (reset)
        csr_crmd_ie <= 1'b0;
    else if (wb_ex) 
        csr_crmd_ie <= 1'b0;
    else if (ertn_flush) 
        csr_crmd_ie <= csr_prmd_pie;
    else if (csr_we && csr_num == `CSR_CRMD)
        csr_crmd_ie <= csr_wmask[`CSR_CRMD_IE] & csr_wvalue[`CSR_CRMD_IE] | ~csr_wmask[`CSR_CRMD_IE] & csr_crmd_ie;
end

// CRMD_DA & CRMD_PG
always @(posedge clock) begin 
    if (reset) begin
        csr_crmd_da <= 1'b1;
        csr_crmd_pg <= 1'b0;
    end
    else if (csr_we && csr_num == `CSR_CRMD) begin
        csr_crmd_da <= csr_wmask[`CSR_CRMD_DA] & csr_wvalue[`CSR_CRMD_DA] | ~csr_wmask[`CSR_CRMD_DA] & csr_crmd_da;
        csr_crmd_pg <= csr_wmask[`CSR_CRMD_PG] & csr_wvalue[`CSR_CRMD_PG] | ~csr_wmask[`CSR_CRMD_PG] & csr_crmd_pg;
    end
    else if (ex_TLBR) begin
        csr_crmd_da <= 1'b1;
        csr_crmd_pg <= 1'b0;
    end
    else if (ertn_flush & csr_estat_ecode == 6'h3F) begin
        csr_crmd_da <= 1'b0;
        csr_crmd_pg <= 1'b1;
    end
end


//3.PRMD_PPLV/PIE
always @(posedge clock) begin 
    if (wb_ex) begin 
        csr_prmd_pplv <= csr_crmd_plv; 
        csr_prmd_pie <= csr_crmd_ie;
    end 
    else if (csr_we && csr_num == `CSR_PRMD) begin 
        csr_prmd_pplv <= csr_wmask[`CSR_PRMD_PPLV] & csr_wvalue[`CSR_PRMD_PPLV] | ~csr_wmask[`CSR_PRMD_PPLV] & csr_prmd_pplv;
        csr_prmd_pie <= csr_wmask[`CSR_PRMD_PIE] & csr_wvalue[`CSR_PRMD_PIE] | ~csr_wmask[`CSR_PRMD_PIE] & csr_prmd_pie;
    end 
end

//4.ECFG_LIE
always @(posedge clock) begin 
    if (reset)
        csr_ecfg_lie <= 13'b0;
    else if (csr_we && csr_num == `CSR_ECFG) 
        csr_ecfg_lie <= csr_wmask[`CSR_ECFG_LIE] & csr_wvalue[`CSR_ECFG_LIE] | ~csr_wmask[`CSR_ECFG_LIE] & csr_ecfg_lie;
end

//5.ESTAT_IS
always @(posedge clock) begin 
    if (reset)
        csr_estat_is[1:0] <= 2'b0;
    else if (csr_we && csr_num == `CSR_ESTAT) 
        csr_estat_is[1:0] <= csr_wmask[`CSR_ESTAT_IS10] & csr_wvalue[`CSR_ESTAT_IS10] | ~csr_wmask[`CSR_ESTAT_IS10] & csr_estat_is[1:0];
    
    csr_estat_is[9:2] <= hw_int_in[7:0];  

    csr_estat_is[10] <= 1'b0;

    if (timer_cnt[31:0] == 32'b0) 
        csr_estat_is[11] <= 1'b1;
    else if (csr_we && csr_num == `CSR_TICLR && csr_wmask[`CSR_TICLR_CLR] && csr_wvalue[`CSR_TICLR_CLR])
        csr_estat_is[11] <= 1'b0; 

    csr_estat_is[12] <= ipi_int_in; 
end

//6.ESTAT_Ecode/EsubCode
always @(posedge clock) begin 
    if (wb_ex) begin 
        csr_estat_ecode <= wb_ecode; 
        csr_estat_esubcode <= wb_esubcode;
    end 
end

//7.ERA_PC
always @(posedge clock) begin 
    if (wb_ex)
        csr_era_pc <= wb_pc;
    else if (csr_we && csr_num == `CSR_ERA) 
        csr_era_pc <= csr_wmask[`CSR_ERA_PC] & csr_wvalue[`CSR_ERA_PC] | ~csr_wmask[`CSR_ERA_PC] & csr_era_pc;
end

//8.BADV_VAddr
assign wb_ex_addr_err = ex_TLBR | ex_ADE | ex_ALE | ex_PIL | ex_PIS |ex_PIF | ex_PME | ex_PPI;
always @(posedge clock) begin 
    if (wb_ex && wb_ex_addr_err) 
        csr_badv_vaddr <= (wb_ecode == `ECODE_ADE && wb_esubcode == `ESUBCODE_ADEF || ex_PIF) ? wb_pc : wb_vaddr;
end

//9.EENTRY_VA
always @(posedge clock) begin 
    if (csr_we && csr_num == `CSR_EENTRY) 
        csr_eentry_va <= csr_wmask[`CSR_EENTRY_VA] & csr_wvalue[`CSR_EENTRY_VA] | ~csr_wmask[`CSR_EENTRY_VA] & csr_eentry_va;
end

//10.SAVE0~3
always @(posedge clock) begin 
    if (csr_we && csr_num == `CSR_SAVE0) 
        csr_save0_data <= csr_wmask[`CSR_SAVE_DATA] & csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA] & csr_save0_data;
    if (csr_we && csr_num == `CSR_SAVE1) 
        csr_save1_data <= csr_wmask[`CSR_SAVE_DATA] & csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA] & csr_save1_data;
    if (csr_we && csr_num == `CSR_SAVE2) 
        csr_save2_data <= csr_wmask[`CSR_SAVE_DATA] & csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA] & csr_save2_data;
    if (csr_we && csr_num == `CSR_SAVE3) 
        csr_save3_data <= csr_wmask[`CSR_SAVE_DATA] & csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA] & csr_save3_data;
end

//11.TID
always @(posedge clock) begin 
    if (reset)
        csr_tid_tid <= 32'h0;
    else if (csr_we && csr_num == `CSR_TID) 
        csr_tid_tid <= csr_wmask[`CSR_TID_TID] & csr_wvalue[`CSR_TID_TID] | ~csr_wmask[`CSR_TID_TID] & csr_tid_tid;
end


//12.TCFG_En/Periodic/InitVal
always @(posedge clock) begin 
    if (reset)
        csr_tcfg_en <= 1'b0;
    else if (csr_we && csr_num == `CSR_TCFG) 
        csr_tcfg_en <= csr_wmask[`CSR_TCFG_EN] & csr_wvalue[`CSR_TCFG_EN] | ~csr_wmask[`CSR_TCFG_EN] & csr_tcfg_en;

    if (csr_we && csr_num == `CSR_TCFG) begin 
        csr_tcfg_periodic <= csr_wmask[`CSR_TCFG_PERIOD] & csr_wvalue[`CSR_TCFG_PERIOD] | ~csr_wmask[`CSR_TCFG_PERIOD] & csr_tcfg_periodic;
        csr_tcfg_initval <= csr_wmask[`CSR_TCFG_INITVAL] & csr_wvalue[`CSR_TCFG_INITVAL] | ~csr_wmask[`CSR_TCFG_INITVAL] & csr_tcfg_initval;
    end 
end

//13.TVAL_TimeVal
assign tcfg_next_value = csr_wmask[31:0] & csr_wvalue[31:0] | ~csr_wmask[31:0] & {csr_tcfg_initval, csr_tcfg_periodic, csr_tcfg_en};

always @(posedge clock) begin 
    if (reset)
        timer_cnt <= 32'hffffffff;
    else if (csr_we && csr_num == `CSR_TCFG && tcfg_next_value[`CSR_TCFG_EN]) 
        timer_cnt <= {tcfg_next_value[`CSR_TCFG_INITVAL], 2'b0};
    else if (csr_tcfg_en && timer_cnt != 32'hffffffff) begin 
        if (timer_cnt[31:0] == 32'b0 && csr_tcfg_periodic) 
            timer_cnt <= {csr_tcfg_initval, 2'b0};
        else 
            timer_cnt <= timer_cnt - 1'b1; 
    end
end

assign csr_tval = timer_cnt[31:0];


//14.TICLR_CLR
always @(posedge clock) begin 
    if (reset)
        csr_ticlr_clr <= 1'b0;
    else if (csr_we && csr_num == `CSR_TICLR) 
        csr_ticlr_clr <= csr_wmask[`CSR_TICLR_CLR] & csr_wvalue[`CSR_TICLR_CLR] | ~csr_wmask[`CSR_TICLR_CLR] & csr_ticlr_clr;
end

//TLBIDX_INDEX
always @(posedge clock) begin 
    if (reset)
        csr_tlbidx_index <= 4'b0;
    else if (csr_we && csr_num == `CSR_TLBIDX) 
        csr_tlbidx_index <= csr_wmask[`CSR_TLBIDX_INDEX] & csr_wvalue[`CSR_TLBIDX_INDEX] | ~csr_wmask[`CSR_TLBIDX_INDEX] & csr_tlbidx_index;
    else if(tlbsrch_op & tlb_s1_found)
        csr_tlbidx_index <= tlb_s1_index;
end

//TLBIDX_PS
always @(posedge clock) begin 
    if (reset)
        csr_tlbidx_ps <= 6'b0;
    else if (csr_we && csr_num == `CSR_TLBIDX) 
        csr_tlbidx_ps <= csr_wmask[`CSR_TLBIDX_PS] & csr_wvalue[`CSR_TLBIDX_PS] | ~csr_wmask[`CSR_TLBIDX_PS] & csr_tlbidx_ps;
    else if(tlbrd_op & tlb_r_e)
        csr_tlbidx_ps <= tlb_r_ps;
end

//TLBIDX_NE
always @(posedge clock) begin 
    if (reset)
        csr_tlbidx_ne <= 1'b0;
    else if (csr_we && csr_num == `CSR_TLBIDX) 
        csr_tlbidx_ne <= csr_wmask[`CSR_TLBIDX_NE] & csr_wvalue[`CSR_TLBIDX_NE] | ~csr_wmask[`CSR_TLBIDX_NE] & csr_tlbidx_ne;
    else if(tlbrd_op)
        csr_tlbidx_ne <= ~tlb_r_e;
    else if(tlbsrch_op & tlb_s1_found)
        csr_tlbidx_ne <= 1'b0;
    else if(tlbsrch_op & ~tlb_s1_found)
        csr_tlbidx_ne <= 1'b1;
end

//TLBEHI_VPPN
wire wb_ex_data = ex_TLBR | ex_PIL | ex_PIS | ex_PME | ex_PPI;
wire wb_ex_inst = ex_PIF;
always @(posedge clock) begin 
    if (reset)
        csr_tlbehi_vppn <= 19'b0;
    else if (csr_we && csr_num == `CSR_TLBEHI) 
        csr_tlbehi_vppn <= csr_wmask[`CSR_TLBEHI_VPPN] & csr_wvalue[`CSR_TLBEHI_VPPN] | ~csr_wmask[`CSR_TLBEHI_VPPN] & csr_tlbehi_vppn;
    else if(tlbrd_op & tlb_r_e)
        csr_tlbehi_vppn <= tlb_r_vppn;
    else if(wb_ex_data)
        csr_tlbehi_vppn <= wb_vaddr[31:13];
    else if(wb_ex_inst)
        csr_tlbehi_vppn <= wb_pc[31:13];
end

//TLBELO0
always @(posedge clock) begin 
    if (reset)
        csr_tlbelo0 <= 32'b0;
    else if (csr_we && csr_num == `CSR_TLBELO0) 
        csr_tlbelo0 <= csr_wmask[`CSR_TLBELO0_ALL] & csr_wvalue[`CSR_TLBELO0_ALL] | ~csr_wmask[`CSR_TLBELO0_ALL] & csr_tlbelo0;
    else if(tlbrd_op & tlb_r_e) begin
        csr_tlbelo0[`CSR_TLBELO_PPN] <= {4'b0, tlb_r_ppn0};
        csr_tlbelo0[`CSR_TLBELO_G  ] <= tlb_r_g;
        csr_tlbelo0[`CSR_TLBELO_MAT] <= tlb_r_mat0;
        csr_tlbelo0[`CSR_TLBELO_PLV] <= tlb_r_plv0;
        csr_tlbelo0[`CSR_TLBELO_D  ] <= tlb_r_d0;
        csr_tlbelo0[`CSR_TLBELO_V  ] <= tlb_r_v0;
    end
end

//TLBELO1
always @(posedge clock) begin 
    if (reset)
        csr_tlbelo1 <= 32'b0;
    else if (csr_we && csr_num == `CSR_TLBELO1) 
        csr_tlbelo1 <= csr_wmask[`CSR_TLBELO1_ALL] & csr_wvalue[`CSR_TLBELO1_ALL] | ~csr_wmask[`CSR_TLBELO1_ALL] & csr_tlbelo1;
    else if(tlbrd_op & tlb_r_e) begin
        csr_tlbelo1[`CSR_TLBELO_PPN] <= {4'b0, tlb_r_ppn1};
        csr_tlbelo1[`CSR_TLBELO_G  ] <= tlb_r_g;
        csr_tlbelo1[`CSR_TLBELO_MAT] <= tlb_r_mat1;
        csr_tlbelo1[`CSR_TLBELO_PLV] <= tlb_r_plv1;
        csr_tlbelo1[`CSR_TLBELO_D  ] <= tlb_r_d1;
        csr_tlbelo1[`CSR_TLBELO_V  ] <= tlb_r_v1;
    end
end

//ASID_ASID
always @(posedge clock) begin 
    if (reset)
        csr_asid_asid <= 10'b0;
    else if (csr_we && csr_num == `CSR_ASID) 
        csr_asid_asid <= csr_wmask[`CSR_ASID_ASID] & csr_wvalue[`CSR_ASID_ASID] | ~csr_wmask[`CSR_ASID_ASID] & csr_asid_asid;
    else if(tlbrd_op & tlb_r_e)
        csr_asid_asid <= tlb_r_asid;
end

//ASID_ASIDBITS
always @(posedge clock) begin 
    if (reset)
        csr_asid_asidbits <= 8'h0a;
end

//TLBRENTRY_PA
always @(posedge clock) begin 
    if (reset)
        csr_tlbrentry_pa <= 26'b0;
    else if (csr_we && csr_num == `CSR_TLBRENTRY) 
        csr_tlbrentry_pa <= csr_wmask[`CSR_TLBRENTRY_PA] & csr_wvalue[`CSR_TLBRENTRY_PA] | ~csr_wmask[`CSR_TLBRENTRY_PA] & csr_tlbrentry_pa;
end

// DMW0~DMW1
always @(posedge clock) begin 
    if (reset) begin
        csr_dmw0_vseg <= 3'b0;
        csr_dmw0_pseg <= 3'b0;
        csr_dmw0_mat  <= 2'b0;
        csr_dmw0_plv3 <= 1'b0;
        csr_dmw0_plv0 <= 1'b0;
        csr_dmw1_vseg <= 3'b0;
        csr_dmw1_pseg <= 3'b0;
        csr_dmw1_mat  <= 2'b0;
        csr_dmw1_plv3 <= 1'b0;
        csr_dmw1_plv0 <= 1'b0;
    end
    else if (csr_we && csr_num == `CSR_DMW0) begin
        csr_dmw0_vseg <= csr_wvalue[`CSR_DMW_VSEG];
        csr_dmw0_pseg <= csr_wvalue[`CSR_DMW_PSEG];
        csr_dmw0_mat  <= csr_wvalue[`CSR_DMW_MAT ];
        csr_dmw0_plv3 <= csr_wvalue[`CSR_DMW_PLV3];
        csr_dmw0_plv0 <= csr_wvalue[`CSR_DMW_PLV0];
    end
    else if (csr_we && csr_num == `CSR_DMW1) begin
        csr_dmw1_vseg <= csr_wvalue[`CSR_DMW_VSEG];
        csr_dmw1_pseg <= csr_wvalue[`CSR_DMW_PSEG];
        csr_dmw1_mat  <= csr_wvalue[`CSR_DMW_MAT ];
        csr_dmw1_plv3 <= csr_wvalue[`CSR_DMW_PLV3];
        csr_dmw1_plv0 <= csr_wvalue[`CSR_DMW_PLV0];
    end
end

//TLBFILL_number
always @(posedge clock) begin 
    if (reset)
        csr_tlbfill_number <= 5'b0;
    else if(tlbfill_op)
        csr_tlbfill_number <= csr_tlbfill_number + 1'b1;
end

//tlb_write_part
assign tlb_we      = tlbwr_op | tlbfill_op;
assign tlb_w_index = (tlbwr_op) ? csr_tlbidx_index : csr_tlbfill_number;
assign tlb_w_e     = (csr_estat_ecode == 6'h3f) ? 1'b1 : ~csr_tlbidx_ne;
assign tlb_w_vppn  = csr_tlbehi_vppn;
assign tlb_w_ps    = csr_tlbidx_ps;
assign tlb_w_asid  = csr_asid_asid;
assign tlb_w_g     = csr_tlbelo0[`CSR_TLBELO_G] & csr_tlbelo1[`CSR_TLBELO_G];
assign tlb_w_ppn0  = csr_tlbelo0[`CSR_TLBELO_PPN_20b];
assign tlb_w_plv0  = csr_tlbelo0[`CSR_TLBELO_PLV];
assign tlb_w_mat0  = csr_tlbelo0[`CSR_TLBELO_MAT];
assign tlb_w_d0    = csr_tlbelo0[`CSR_TLBELO_D];
assign tlb_w_v0    = csr_tlbelo0[`CSR_TLBELO_V];
assign tlb_w_ppn1  = csr_tlbelo1[`CSR_TLBELO_PPN_20b];
assign tlb_w_plv1  = csr_tlbelo1[`CSR_TLBELO_PLV];
assign tlb_w_mat1  = csr_tlbelo1[`CSR_TLBELO_MAT];
assign tlb_w_d1    = csr_tlbelo1[`CSR_TLBELO_D];
assign tlb_w_v1    = csr_tlbelo1[`CSR_TLBELO_V];

//tlb_read_part
assign tlb_r_index = csr_tlbidx_index;

//tlb_search_part
assign tlb_s1_vppn = csr_tlbehi_vppn;
assign tlb_s1_asid = csr_asid_asid;
// assign tlb_s1_va_bit12 = 1'b0;

// CSR_read_value
wire [31:0] csr_crmd_rvalue       = {27'b0, csr_crmd_pg, csr_crmd_da, csr_crmd_ie, csr_crmd_plv}; 
wire [31:0] csr_prmd_rvalue       = {29'b0, csr_prmd_pie, csr_prmd_pplv}; 
wire [31:0] csr_ecfg_rvalue       = {19'b0, csr_ecfg_lie};
wire [31:0] csr_estat_rvalue      = {1'b0, csr_estat_esubcode, csr_estat_ecode, 3'b0, csr_estat_is};
wire [31:0] csr_era_rvalue        = csr_era_pc;
wire [31:0] csr_eentry_rvalue     = {csr_eentry_va, 6'b0};
wire [31:0] csr_save0_rvalue      = csr_save0_data;
wire [31:0] csr_save1_rvalue      = csr_save1_data;
wire [31:0] csr_save2_rvalue      = csr_save2_data;
wire [31:0] csr_save3_rvalue      = csr_save3_data;
wire [31:0] csr_ticlr_rvalue      = 32'b0;
wire [31:0] csr_badv_rvalue       = csr_badv_vaddr;
wire [31:0] csr_tid_rvalue        = csr_tid_tid;
wire [31:0] csr_tlbrentry_rvalue  = {csr_tlbrentry_pa, 6'b0};
wire [31:0] csr_tlbidx_rvalue     = {csr_tlbidx_ne, 1'b0, csr_tlbidx_ps, 20'b0, csr_tlbidx_index};
wire [31:0] csr_tlbehi_rvalue     = {csr_tlbehi_vppn, 13'b0};
wire [31:0] csr_tlbelo0_rvalue    = csr_tlbelo0;
wire [31:0] csr_tlbelo1_rvalue    = csr_tlbelo1;
wire [31:0] csr_asid_rvalue       = {8'b0, csr_asid_asidbits, 6'b0, csr_asid_asid};
wire [31:0] csr_dmw0_rvalue       = {csr_dmw0_vseg, 1'b0, csr_dmw0_pseg, 19'b0, csr_dmw0_mat, csr_dmw0_plv3, 2'b0, csr_dmw0_plv0};
wire [31:0] csr_dmw1_rvalue       = {csr_dmw1_vseg, 1'b0, csr_dmw1_pseg, 19'b0, csr_dmw1_mat, csr_dmw1_plv3, 2'b0, csr_dmw1_plv0};

assign csr_rvalue =   {32{csr_num == `CSR_CRMD}}       & csr_crmd_rvalue 
                    | {32{csr_num == `CSR_PRMD}}       & csr_prmd_rvalue 
                    | {32{csr_num == `CSR_ECFG}}       & csr_ecfg_rvalue
                    | {32{csr_num == `CSR_ESTAT}}      & csr_estat_rvalue
                    | {32{csr_num == `CSR_ERA}}        & csr_era_rvalue
                    | {32{csr_num == `CSR_BADV}}       & csr_badv_rvalue
                    | {32{csr_num == `CSR_EENTRY}}     & csr_eentry_rvalue
                    | {32{csr_num == `CSR_SAVE0}}      & csr_save0_rvalue
                    | {32{csr_num == `CSR_SAVE1}}      & csr_save1_rvalue
                    | {32{csr_num == `CSR_SAVE2}}      & csr_save2_rvalue
                    | {32{csr_num == `CSR_SAVE3}}      & csr_save3_rvalue
                    | {32{csr_num == `CSR_TID}}        & csr_tid_rvalue
                    | {32{csr_num == `CSR_TLBRENTRY}}  & csr_tlbrentry_rvalue
                    | {32{csr_num == `CSR_TLBIDX}}     & csr_tlbidx_rvalue
                    | {32{csr_num == `CSR_TLBEHI}}     & csr_tlbehi_rvalue
                    | {32{csr_num == `CSR_TLBELO0}}    & csr_tlbelo0_rvalue
                    | {32{csr_num == `CSR_TLBELO1}}    & csr_tlbelo1_rvalue
                    | {32{csr_num == `CSR_ASID}}       & csr_asid_rvalue
                    | {32{csr_num == `CSR_DMW0}}       & csr_dmw0_rvalue
                    | {32{csr_num == `CSR_DMW1}}       & csr_dmw1_rvalue
                    ;
endmodule
