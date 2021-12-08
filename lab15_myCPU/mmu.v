`include "mycpu.h"

module mmu(
    // stages
    input   [31:0]  inst_vaddr      ,
    output  [31:0]  inst_paddr      ,
    input   [31:0]  data_vaddr      ,
    output  [31:0]  data_paddr      ,
    input           s0_op           ,
    input           s1_store        ,
    input           s1_load         ,    
    output          signal_PIL      ,
    output          signal_PIS      ,
    output          signal_PIF      ,
    output          signal_PME      ,
    output          signal_PPI1     ,
    output          signal_TLBR0    ,
    output          signal_TLBR1    ,
    output          signal_ADEF     ,
    output          signal_ADEM     ,

    // csr
    input           csr_crmd_da     ,
    input           csr_crmd_pg     ,
    input   [ 1:0]  csr_crmd_plv    ,
    input   [ 2:0]  csr_dmw0_vseg   ,
    input   [ 2:0]  csr_dmw0_pseg   ,
    input   [ 2:0]  csr_dmw1_vseg   ,
    input   [ 2:0]  csr_dmw1_pseg   ,

    // tlb
    input   [19:0]  s0_ppn          ,
    input   [19:0]  s1_ppn          ,
    input           tlb_PIL         ,
    input           tlb_PIS         ,
    input           tlb_PIF         ,
    input           tlb_PME         ,
    input           tlb_PPI1        ,
    input           tlb_TLBR0       ,
    input           tlb_TLBR1
);

wire mode_dir_trans     = csr_crmd_da & !csr_crmd_pg;
wire inst_dmw0_match    = !mode_dir_trans & inst_vaddr[31:29] == csr_dmw0_vseg;
wire inst_dmw1_match    = !mode_dir_trans & inst_vaddr[31:29] == csr_dmw1_vseg;
wire data_dmw0_match    = !mode_dir_trans & data_vaddr[31:29] == csr_dmw0_vseg;
wire data_dmw1_match    = !mode_dir_trans & data_vaddr[31:29] == csr_dmw1_vseg;
wire inst_dir_mapping   = inst_dmw0_match | inst_dmw1_match;
wire data_dir_mapping   = data_dmw0_match | data_dmw1_match;
wire inst_page_mapping  = !mode_dir_trans & !inst_dir_mapping;
wire data_page_mapping  = !mode_dir_trans & !data_dir_mapping;

assign inst_paddr = mode_dir_trans      ?   inst_vaddr  :
                    inst_dmw0_match     ?   {csr_dmw0_pseg, inst_vaddr[28:0]}   :
                    inst_dmw1_match     ?   {csr_dmw1_pseg, inst_vaddr[28:0]}   :
                                            {s0_ppn, inst_vaddr[11:0]};
assign data_paddr = mode_dir_trans      ?   data_vaddr  :
                    data_dmw0_match     ?   {csr_dmw0_pseg, data_vaddr[28:0]}   :
                    data_dmw1_match     ?   {csr_dmw1_pseg, data_vaddr[28:0]}   :
                                            {s1_ppn, data_vaddr[11:0]};

assign signal_PIL   = data_page_mapping & tlb_PIL  ;
assign signal_PIS   = data_page_mapping & tlb_PIS  ;
assign signal_PIF   = inst_page_mapping & tlb_PIF  ;
assign signal_PME   = data_page_mapping & tlb_PME  ;
//assign signal_PPI   = !_____dir_mapping & tlb_PPI  ;
assign signal_PPI1  = data_page_mapping & tlb_PPI1 ;
assign signal_TLBR0 = inst_page_mapping & tlb_TLBR0;
assign signal_TLBR1 = data_page_mapping & tlb_TLBR1;
assign signal_ADEF  = s0_op & ((inst_vaddr[1:0] != 2'b00) | inst_page_mapping & (csr_crmd_plv == 2'h3) & inst_vaddr[31]);
assign signal_ADEM  = (s1_load | s1_store) & data_page_mapping & csr_crmd_plv == 2'h3 & data_vaddr[31];

endmodule
