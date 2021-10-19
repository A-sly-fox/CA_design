`ifndef MYCPU_H
    `define MYCPU_H

    `define BR_BUS_WD       33
    `define FS_TO_DS_BUS_WD 64
    `define DS_TO_ES_BUS_WD 156
    `define ES_TO_MS_BUS_WD 75
    `define MS_TO_WS_BUS_WD 70
    `define WS_TO_RF_BUS_WD 38
    `define DS_TO_MD_BUS_WD 71
    `define CSR_BUS_WD 92
    
    `define CSR_BUS_ERTN    91   
    `define CSR_BUS_EX      90
    `define CSR_BUS_OP      74
    `define CSR_BUS_NUM     73:65
    `define CSR_BUS_WE      64

    `define CSR_CRMD        9'h0
    `define CSR_PRMD        9'h1
    `define CSR_ECFG        9'h4
    `define CSR_ESTAT       9'h5
    `define CSR_ERA         9'h6
    `define CSR_EENTRY      9'hc
    `define CSR_SAVE0       9'h30
    `define CSR_SAVE1       9'h31
    `define CSR_SAVE2       9'h32
    `define CSR_SAVE3       9'h33
    `define CSR_TID         9'h40
    `define CSR_TCFG        9'h41
    `define CSR_TICLR       9'h44

    `define CSR_CRMD_PLV        1:0
    `define CSR_CRMD_IE         2
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

    `define ECODE_ADE           6'h8
    `define ECODE_ALE           6'h9
    `define ECODE_TLBR          6'h3f
    `define ESUBCODE_ADEF       9'h0
    `define ESUBCODE_ADEM       9'h1
    
    
`endif
