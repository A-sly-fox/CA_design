module tlb 
#(
    parameter TLBNUM = 16
)
(
    input clk,

    // search port 0 (for fetch)
    input   [18:0]  s0_vppn,
    input           s0_va_bit12,
    input   [ 9:0]  s0_asid,
    output          s0_found,
    output  [$clog2(TLBNUM)-1:0] s0_index,
    output  [19:0]  s0_ppn,
    output  [ 5:0]  s0_ps,
    output  [ 1:0]  s0_plv,
    output  [ 1:0]  s0_mat,
    output          s0_d,
    output          s0_v,

    // search port 1 (for load/store)
    input   [18:0]  s1_vppn,
    input           s1_va_bit12,
    input   [ 9:0]  s1_asid,
    output          s1_found,
    output  [$clog2(TLBNUM)-1:0] s1_index,
    output  [19:0]  s1_ppn,
    output  [ 5:0]  s1_ps,
    output  [ 1:0]  s1_plv,
    output  [ 1:0]  s1_mat,
    output          s1_d,
    output          s1_v,

    // invtlb opcode
    input   [ 4:0]  invtlb_opcode,
    input           invtlb_valid,
    input   [18:0]  reg_vppn,
    input   [ 9:0]  reg_asid,

    // write port
    input we, //w(rite) e(nable)
    input [$clog2(TLBNUM)-1:0] w_index,
    input           w_e,
    input   [18:0]  w_vppn,
    input   [ 5:0]  w_ps,
    input   [ 9:0]  w_asid,
    input           w_g,
    input   [19:0]  w_ppn0,
    input   [ 1:0]  w_plv0,
    input   [ 1:0]  w_mat0,
    input           w_d0,
    input           w_v0,
    input   [19:0]  w_ppn1,
    input   [ 1:0]  w_plv1,
    input   [ 1:0]  w_mat1,
    input           w_d1,
    input           w_v1,

    // read port
    input   [$clog2(TLBNUM)-1:0] r_index,
    output          r_e,
    output  [18:0]  r_vppn,
    output  [ 5:0]  r_ps,
    output  [ 9:0]  r_asid,
    output          r_g,
    output  [19:0]  r_ppn0,
    output  [ 1:0]  r_plv0,
    output  [ 1:0]  r_mat0,
    output          r_d0,
    output          r_v0,
    output  [19:0]  r_ppn1,
    output  [ 1:0]  r_plv1,
    output  [ 1:0]  r_mat1,
    output          r_d1,
    output          r_v1
);

reg [TLBNUM-1:0] tlb_e;
reg [TLBNUM-1:0] tlb_ps4MB; //pagesize 1:4MB, 0:4KB
reg [18:0]  tlb_vppn    [TLBNUM-1:0];
reg [ 9:0]  tlb_asid    [TLBNUM-1:0];
reg         tlb_g       [TLBNUM-1:0];
reg [19:0]  tlb_ppn0    [TLBNUM-1:0];
reg [ 1:0]  tlb_plv0    [TLBNUM-1:0];
reg [ 1:0]  tlb_mat0    [TLBNUM-1:0];
reg         tlb_d0      [TLBNUM-1:0];
reg         tlb_v0      [TLBNUM-1:0];
reg [19:0]  tlb_ppn1    [TLBNUM-1:0];
reg [ 1:0]  tlb_plv1    [TLBNUM-1:0];
reg [ 1:0]  tlb_mat1    [TLBNUM-1:0];
reg         tlb_d1      [TLBNUM-1:0];
reg         tlb_v1      [TLBNUM-1:0];

wire [TLBNUM-1:0] match0;
wire [TLBNUM-1:0] match1;

wire [18:0] vppn_cmp0 ;
wire [18:0] vppn_cmp1 ;
wire [18:0] vppn_cmp2 ;
wire [18:0] vppn_cmp3 ;
wire [18:0] vppn_cmp4 ;
wire [18:0] vppn_cmp5 ;
wire [18:0] vppn_cmp6 ;
wire [18:0] vppn_cmp7 ;
wire [18:0] vppn_cmp8 ;
wire [18:0] vppn_cmp9 ;
wire [18:0] vppn_cmp10;
wire [18:0] vppn_cmp11;
wire [18:0] vppn_cmp12;
wire [18:0] vppn_cmp13;
wire [18:0] vppn_cmp14;
wire [18:0] vppn_cmp15;
wire [ 6:0] opcode;
wire [TLBNUM-1:0] match_asid;
wire [TLBNUM-1:0] match_vppn;
wire [TLBNUM-1:0] inv_match;

assign vppn_cmp0  = tlb_vppn[ 0];
assign vppn_cmp1  = tlb_vppn[ 1];
assign vppn_cmp2  = tlb_vppn[ 2];
assign vppn_cmp3  = tlb_vppn[ 3];
assign vppn_cmp4  = tlb_vppn[ 4];
assign vppn_cmp5  = tlb_vppn[ 5];
assign vppn_cmp6  = tlb_vppn[ 6];
assign vppn_cmp7  = tlb_vppn[ 7];
assign vppn_cmp8  = tlb_vppn[ 8];
assign vppn_cmp9  = tlb_vppn[ 9];
assign vppn_cmp10 = tlb_vppn[10];
assign vppn_cmp11 = tlb_vppn[11];
assign vppn_cmp12 = tlb_vppn[12];
assign vppn_cmp13 = tlb_vppn[13];
assign vppn_cmp14 = tlb_vppn[14];
assign vppn_cmp15 = tlb_vppn[15];
assign opcode[0]  = invtlb_opcode == 6'h00 && invtlb_valid;
assign opcode[1]  = invtlb_opcode == 6'h01 && invtlb_valid;
assign opcode[2]  = invtlb_opcode == 6'h02 && invtlb_valid;
assign opcode[3]  = invtlb_opcode == 6'h03 && invtlb_valid;
assign opcode[4]  = invtlb_opcode == 6'h04 && invtlb_valid;
assign opcode[5]  = invtlb_opcode == 6'h05 && invtlb_valid;
assign opcode[6]  = invtlb_opcode == 6'h06 && invtlb_valid;

// Search Port
assign match0[ 0] = tlb_e[ 0] && (s0_vppn[18:10]==vppn_cmp0 [18:10]) && (tlb_ps4MB[ 0] || s0_vppn[9:0]==vppn_cmp0 [9:0]) && ((s0_asid==tlb_asid[ 0]) || tlb_g[ 0]);
assign match0[ 1] = tlb_e[ 1] && (s0_vppn[18:10]==vppn_cmp1 [18:10]) && (tlb_ps4MB[ 1] || s0_vppn[9:0]==vppn_cmp1 [9:0]) && ((s0_asid==tlb_asid[ 1]) || tlb_g[ 1]);
assign match0[ 2] = tlb_e[ 2] && (s0_vppn[18:10]==vppn_cmp2 [18:10]) && (tlb_ps4MB[ 2] || s0_vppn[9:0]==vppn_cmp2 [9:0]) && ((s0_asid==tlb_asid[ 2]) || tlb_g[ 2]);
assign match0[ 3] = tlb_e[ 3] && (s0_vppn[18:10]==vppn_cmp3 [18:10]) && (tlb_ps4MB[ 3] || s0_vppn[9:0]==vppn_cmp3 [9:0]) && ((s0_asid==tlb_asid[ 3]) || tlb_g[ 3]);
assign match0[ 4] = tlb_e[ 4] && (s0_vppn[18:10]==vppn_cmp4 [18:10]) && (tlb_ps4MB[ 4] || s0_vppn[9:0]==vppn_cmp4 [9:0]) && ((s0_asid==tlb_asid[ 4]) || tlb_g[ 4]);
assign match0[ 5] = tlb_e[ 5] && (s0_vppn[18:10]==vppn_cmp5 [18:10]) && (tlb_ps4MB[ 5] || s0_vppn[9:0]==vppn_cmp5 [9:0]) && ((s0_asid==tlb_asid[ 5]) || tlb_g[ 5]);
assign match0[ 6] = tlb_e[ 6] && (s0_vppn[18:10]==vppn_cmp6 [18:10]) && (tlb_ps4MB[ 6] || s0_vppn[9:0]==vppn_cmp6 [9:0]) && ((s0_asid==tlb_asid[ 6]) || tlb_g[ 6]);
assign match0[ 7] = tlb_e[ 7] && (s0_vppn[18:10]==vppn_cmp7 [18:10]) && (tlb_ps4MB[ 7] || s0_vppn[9:0]==vppn_cmp7 [9:0]) && ((s0_asid==tlb_asid[ 7]) || tlb_g[ 7]);
assign match0[ 8] = tlb_e[ 8] && (s0_vppn[18:10]==vppn_cmp8 [18:10]) && (tlb_ps4MB[ 8] || s0_vppn[9:0]==vppn_cmp8 [9:0]) && ((s0_asid==tlb_asid[ 8]) || tlb_g[ 8]);
assign match0[ 9] = tlb_e[ 9] && (s0_vppn[18:10]==vppn_cmp9 [18:10]) && (tlb_ps4MB[ 9] || s0_vppn[9:0]==vppn_cmp9 [9:0]) && ((s0_asid==tlb_asid[ 9]) || tlb_g[ 9]);
assign match0[10] = tlb_e[10] && (s0_vppn[18:10]==vppn_cmp10[18:10]) && (tlb_ps4MB[10] || s0_vppn[9:0]==vppn_cmp10[9:0]) && ((s0_asid==tlb_asid[10]) || tlb_g[10]);
assign match0[11] = tlb_e[11] && (s0_vppn[18:10]==vppn_cmp11[18:10]) && (tlb_ps4MB[11] || s0_vppn[9:0]==vppn_cmp11[9:0]) && ((s0_asid==tlb_asid[11]) || tlb_g[11]);
assign match0[12] = tlb_e[12] && (s0_vppn[18:10]==vppn_cmp12[18:10]) && (tlb_ps4MB[12] || s0_vppn[9:0]==vppn_cmp12[9:0]) && ((s0_asid==tlb_asid[12]) || tlb_g[12]);
assign match0[13] = tlb_e[13] && (s0_vppn[18:10]==vppn_cmp13[18:10]) && (tlb_ps4MB[13] || s0_vppn[9:0]==vppn_cmp13[9:0]) && ((s0_asid==tlb_asid[13]) || tlb_g[13]);
assign match0[14] = tlb_e[14] && (s0_vppn[18:10]==vppn_cmp14[18:10]) && (tlb_ps4MB[14] || s0_vppn[9:0]==vppn_cmp14[9:0]) && ((s0_asid==tlb_asid[14]) || tlb_g[14]);
assign match0[15] = tlb_e[15] && (s0_vppn[18:10]==vppn_cmp15[18:10]) && (tlb_ps4MB[15] || s0_vppn[9:0]==vppn_cmp15[9:0]) && ((s0_asid==tlb_asid[15]) || tlb_g[15]);

assign match1[ 0] = tlb_e[ 0] && (s1_vppn[18:10]==vppn_cmp0 [18:10]) && (tlb_ps4MB[ 0] || s1_vppn[9:0]==vppn_cmp0 [9:0]) && ((s1_asid==tlb_asid[ 0]) || tlb_g[ 0]);
assign match1[ 1] = tlb_e[ 1] && (s1_vppn[18:10]==vppn_cmp1 [18:10]) && (tlb_ps4MB[ 1] || s1_vppn[9:0]==vppn_cmp1 [9:0]) && ((s1_asid==tlb_asid[ 1]) || tlb_g[ 1]);
assign match1[ 2] = tlb_e[ 2] && (s1_vppn[18:10]==vppn_cmp2 [18:10]) && (tlb_ps4MB[ 2] || s1_vppn[9:0]==vppn_cmp2 [9:0]) && ((s1_asid==tlb_asid[ 2]) || tlb_g[ 2]);
assign match1[ 3] = tlb_e[ 3] && (s1_vppn[18:10]==vppn_cmp3 [18:10]) && (tlb_ps4MB[ 3] || s1_vppn[9:0]==vppn_cmp3 [9:0]) && ((s1_asid==tlb_asid[ 3]) || tlb_g[ 3]);
assign match1[ 4] = tlb_e[ 4] && (s1_vppn[18:10]==vppn_cmp4 [18:10]) && (tlb_ps4MB[ 4] || s1_vppn[9:0]==vppn_cmp4 [9:0]) && ((s1_asid==tlb_asid[ 4]) || tlb_g[ 4]);
assign match1[ 5] = tlb_e[ 5] && (s1_vppn[18:10]==vppn_cmp5 [18:10]) && (tlb_ps4MB[ 5] || s1_vppn[9:0]==vppn_cmp5 [9:0]) && ((s1_asid==tlb_asid[ 5]) || tlb_g[ 5]);
assign match1[ 6] = tlb_e[ 6] && (s1_vppn[18:10]==vppn_cmp6 [18:10]) && (tlb_ps4MB[ 6] || s1_vppn[9:0]==vppn_cmp6 [9:0]) && ((s1_asid==tlb_asid[ 6]) || tlb_g[ 6]);
assign match1[ 7] = tlb_e[ 7] && (s1_vppn[18:10]==vppn_cmp7 [18:10]) && (tlb_ps4MB[ 7] || s1_vppn[9:0]==vppn_cmp7 [9:0]) && ((s1_asid==tlb_asid[ 7]) || tlb_g[ 7]);
assign match1[ 8] = tlb_e[ 8] && (s1_vppn[18:10]==vppn_cmp8 [18:10]) && (tlb_ps4MB[ 8] || s1_vppn[9:0]==vppn_cmp8 [9:0]) && ((s1_asid==tlb_asid[ 8]) || tlb_g[ 8]);
assign match1[ 9] = tlb_e[ 9] && (s1_vppn[18:10]==vppn_cmp9 [18:10]) && (tlb_ps4MB[ 9] || s1_vppn[9:0]==vppn_cmp9 [9:0]) && ((s1_asid==tlb_asid[ 9]) || tlb_g[ 9]);
assign match1[10] = tlb_e[10] && (s1_vppn[18:10]==vppn_cmp10[18:10]) && (tlb_ps4MB[10] || s1_vppn[9:0]==vppn_cmp10[9:0]) && ((s1_asid==tlb_asid[10]) || tlb_g[10]);
assign match1[11] = tlb_e[11] && (s1_vppn[18:10]==vppn_cmp11[18:10]) && (tlb_ps4MB[11] || s1_vppn[9:0]==vppn_cmp11[9:0]) && ((s1_asid==tlb_asid[11]) || tlb_g[11]);
assign match1[12] = tlb_e[12] && (s1_vppn[18:10]==vppn_cmp12[18:10]) && (tlb_ps4MB[12] || s1_vppn[9:0]==vppn_cmp12[9:0]) && ((s1_asid==tlb_asid[12]) || tlb_g[12]);
assign match1[13] = tlb_e[13] && (s1_vppn[18:10]==vppn_cmp13[18:10]) && (tlb_ps4MB[13] || s1_vppn[9:0]==vppn_cmp13[9:0]) && ((s1_asid==tlb_asid[13]) || tlb_g[13]);
assign match1[14] = tlb_e[14] && (s1_vppn[18:10]==vppn_cmp14[18:10]) && (tlb_ps4MB[14] || s1_vppn[9:0]==vppn_cmp14[9:0]) && ((s1_asid==tlb_asid[14]) || tlb_g[14]);
assign match1[15] = tlb_e[15] && (s1_vppn[18:10]==vppn_cmp15[18:10]) && (tlb_ps4MB[15] || s1_vppn[9:0]==vppn_cmp15[9:0]) && ((s1_asid==tlb_asid[15]) || tlb_g[15]);

assign s0_found = match0[0] || match0[1] || match0[2] || match0[3] || match0[4] || match0[5] || match0[6] || match0[7] || match0[8] || match0[9] || match0[10] || match0[11] || match0[12] || match0[13] || match0[14] || match0[15];
assign s1_found = match1[0] || match1[1] || match1[2] || match1[3] || match1[4] || match1[5] || match1[6] || match1[7] || match1[8] || match1[9] || match1[10] || match1[11] || match1[12] || match1[13] || match1[14] || match1[15];

assign s0_index =   match0[ 0] ?   0 :
                    match0[ 1] ?   1 :
                    match0[ 2] ?   2 :
                    match0[ 3] ?   3 :
                    match0[ 4] ?   4 :
                    match0[ 5] ?   5 :
                    match0[ 6] ?   6 :
                    match0[ 7] ?   7 :
                    match0[ 8] ?   8 :
                    match0[ 9] ?   9 :
                    match0[10] ?  10 :
                    match0[11] ?  11 :
                    match0[12] ?  12 :
                    match0[13] ?  13 :
                    match0[14] ?  14 :
                  /*match0[15]*/  15 ;
assign s1_index =   match1[ 0] ?   0 :
                    match1[ 1] ?   1 :
                    match1[ 2] ?   2 :
                    match1[ 3] ?   3 :
                    match1[ 4] ?   4 :
                    match1[ 5] ?   5 :
                    match1[ 6] ?   6 :
                    match1[ 7] ?   7 :
                    match1[ 8] ?   8 :
                    match1[ 9] ?   9 :
                    match1[10] ?  10 :
                    match1[11] ?  11 :
                    match1[12] ?  12 :
                    match1[13] ?  13 :
                    match1[14] ?  14 :
                  /*match1[15]*/  15 ;
wire sel_ppn0;
wire sel_ppn1;
assign sel_ppn0 = tlb_ps4MB[s0_index] ? s0_vppn[9] :
                                        s0_va_bit12;
assign sel_ppn1 = tlb_ps4MB[s1_index] ? s1_vppn[9] :
                                        s1_va_bit12; 
assign s0_ppn   = sel_ppn0 ? tlb_ppn1[s0_index] : tlb_ppn0[s0_index];
assign s1_ppn   = sel_ppn1 ? tlb_ppn1[s1_index] : tlb_ppn0[s1_index];
assign s0_plv   = sel_ppn0 ? tlb_plv1[s0_index] : tlb_plv0[s0_index];
assign s1_plv   = sel_ppn1 ? tlb_plv1[s1_index] : tlb_plv0[s1_index];
assign s0_ps    = tlb_ps4MB[s0_index] ? 22 : 12;
assign s1_ps    = tlb_ps4MB[s1_index] ? 22 : 12;
assign s0_mat   = sel_ppn0 ? tlb_mat1[s0_index] : tlb_mat0[s0_index];
assign s1_mat   = sel_ppn1 ? tlb_mat1[s1_index] : tlb_mat0[s1_index];
assign s0_d     = sel_ppn0 ? tlb_d1  [s0_index] : tlb_d0  [s0_index];
assign s1_d     = sel_ppn1 ? tlb_d1  [s1_index] : tlb_d0  [s1_index];
assign s0_v     = sel_ppn0 ? tlb_v1  [s0_index] : tlb_v0  [s0_index];
assign s1_v     = sel_ppn1 ? tlb_v1  [s1_index] : tlb_v0  [s1_index];

// Write Port
always @(posedge clk) begin
    if(we) begin
        tlb_e   [w_index] <= w_e    ;
        tlb_ps4MB[w_index] <= w_ps == 22;
        tlb_vppn[w_index] <= w_vppn ;
        tlb_asid[w_index] <= w_asid ;
        tlb_g   [w_index] <= w_g    ;
        tlb_ppn0[w_index] <= w_ppn0 ;
        tlb_plv0[w_index] <= w_plv0 ;
        tlb_mat0[w_index] <= w_mat0 ;
        tlb_d0  [w_index] <= w_d0   ;
        tlb_v0  [w_index] <= w_v0   ;
        tlb_ppn1[w_index] <= w_ppn1 ;
        tlb_plv1[w_index] <= w_plv1 ;
        tlb_mat1[w_index] <= w_mat1 ;.
        tlb_d1  [w_index] <= w_d1   ;
        tlb_v1  [w_index] <= w_v1   ;
    end
    else begin
        tlb_e <= ~inv_match & tlb_e;
    end
end

// Read Port
assign r_e    = tlb_e   [r_index];
assign r_vppn = tlb_vppn[r_index];
assign r_ps   = tlb_ps4MB[r_index] ? 6'd22 : 6'd12;
assign r_asid = tlb_asid[r_index];
assign r_g    = tlb_g   [r_index];
assign r_ppn0 = tlb_ppn0[r_index];
assign r_plv0 = tlb_plv0[r_index];
assign r_mat0 = tlb_mat0[r_index];
assign r_d0   = tlb_d0  [r_index];
assign r_v0   = tlb_v0  [r_index];
assign r_ppn1 = tlb_ppn1[r_index];
assign r_plv1 = tlb_plv1[r_index];
assign r_mat1 = tlb_mat1[r_index];
assign r_d1   = tlb_d1  [r_index];
assign r_v1   = tlb_v1  [r_index];

// Invtlb Part
genvar i;
generate
    for (i = 0; i < TLBNUM; i = i + 1) begin : a
        assign match_vppn[i] = tlb_vppn[i] == reg_vppn;
        assign match_asid[i] = tlb_asid[i] == reg_asid;
    end
    for (i = 0; i < TLBNUM; i = i + 1) begin : b
        assign inv_match[i] = opcode[0] | opcode[1] | 
                              (opcode[2] & tlb_g[i]) | 
                              (opcode[3] & ~tlb_g[i]) | 
                              (opcode[4] & ~tlb_g[i] & match_asid[i]) | 
                              (opcode[5] & ~tlb_g[i] & match_asid[i] & match_vppn[i]) | 
                              (opcode[6] & (tlb_g[i] | match_asid[i]) & match_vppn[i]);
    end
endgenerate

endmodule