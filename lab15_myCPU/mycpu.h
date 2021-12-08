`ifndef MYCPU_H
    `define MYCPU_H

    `define BR_BUS_WD       33
    `define FS_TO_DS_BUS_WD 64
    `define DS_TO_ES_BUS_WD 164
    `define ES_TO_MS_BUS_WD 80
    `define MS_TO_WS_BUS_WD 71
    `define WS_TO_RF_BUS_WD 38
    `define DS_TO_MD_BUS_WD 71
    `define MS_FORWARD      41
    `define CSR_BUS_WD      97

    `define CSR_BUS_TLBR    97
    `define CSR_BUS_TLBSRCH 96
    `define CSR_BUS_TLBRD   95
    `define CSR_BUS_TLBWR   94
    `define CSR_BUS_TLBFILL 93
    `define CSR_BUS_INVTLB  92
    `define CSR_BUS_TLB_OP  96:92 
    `define CSR_BUS_ERTN    91   
    `define CSR_BUS_EX      90
    `define CSR_BUS_ECODE   89:84
    `define CSR_BUS_OP      74
    `define CSR_BUS_NUM     73:65
    `define CSR_BUS_WE      64

    `define CSR_CRMD        9'h0
    `define CSR_PRMD        9'h1
    `define CSR_ECFG        9'h4
    `define CSR_ESTAT       9'h5
    `define CSR_ERA         9'h6
    `define CSR_BADV        9'h7
    `define CSR_EENTRY      9'hc
    `define CSR_SAVE0       9'h30
    `define CSR_SAVE1       9'h31
    `define CSR_SAVE2       9'h32
    `define CSR_SAVE3       9'h33
    `define CSR_TID         9'h40
    `define CSR_TCFG        9'h41
    `define CSR_TICLR       9'h44
    `define CSR_TLBIDX      9'h10
    `define CSR_TLBEHI      9'h11
    `define CSR_TLBELO0     9'h12
    `define CSR_TLBELO1     9'h13
    `define CSR_ASID        9'h18
    `define CSR_TLBRENTRY   9'h88
    `define CSR_DMW0        9'h180
    `define CSR_DMW1        9'h181

    `define CSR_CRMD_PLV        1:0
    `define CSR_CRMD_IE         2
    `define CSR_CRMD_DA         3
    `define CSR_CRMD_PG         4
    `define CSR_PRMD_PPLV       1:0
    `define CSR_PRMD_PIE        2
    `define CSR_ECFG_LIE        12:0
    `define CSR_ESTAT_IS10      1:0
    `define CSR_TICLR_CLR       0
    `define CSR_ERA_PC          31:0
    `define CSR_EENTRY_VA       31:6
    `define CSR_SAVE_DATA       31:0
    `define CSR_TID_TID         31:0
    `define CSR_TCFG_EN         0
    `define CSR_TCFG_PERIOD     1
    `define CSR_TCFG_INITVAL    31:2
    `define CSR_TLBIDX_INDEX    3:0
    `define CSR_TLBIDX_PS       29:24
    `define CSR_TLBIDX_NE       31
    `define CSR_TLBEHI_VPPN     31:13
    `define CSR_TLBELO0_ALL     31:0
    `define CSR_TLBELO1_ALL     31:0
    `define CSR_ASID_ASID       9:0
    `define CSR_ASID_ASIDBITS   23:16
    `define CSR_TLBRENTRY_PA    31:6
    `define CSR_TLBELO_PPN      31:8
    `define CSR_TLBELO_PPN_20b  27:8
    `define CSR_TLBELO_G        6
    `define CSR_TLBELO_MAT      5:4
    `define CSR_TLBELO_PLV      3:2
    `define CSR_TLBELO_D        1
    `define CSR_TLBELO_V        0
    `define CSR_DMW_VSEG        31:29
    `define CSR_DMW_PSEG        27:25
    `define CSR_DMW_MAT         5:4
    `define CSR_DMW_PLV3        3
    `define CSR_DMW_PLV0        0

    `define ECODE_TLBR          6'h3f    
    `define ECODE_ADE           6'h8
    `define ECODE_ALE           6'h9
    `define ECODE_PIL           6'h1
    `define ECODE_PIS           6'h2
    `define ECODE_PIF           6'h3
    `define ECODE_PME           6'h4
    `define ECODE_PPI           6'h7
    `define ECODE_INE           6'hd
    `define ESUBCODE_ADEF       9'h0
    `define ESUBCODE_ADEM       9'h1
    
    
`endif
