`include "mycpu.h"

module multiplier(
    input   [31:0]  src1,
    input   [31:0]  src2,
    input   [ 2:0]  mul_inst,   // 1:mul.w 2:mulh.w 3:mulh.wu
    output  [31:0]  mul_result
);

wire [63:0] unsigned_prod, signed_prod;

assign unsigned_prod = src1 * src2;
assign   signed_prod = $signed(src1) * $signed(src2);
    
assign mul_result = mul_inst[2] ? signed_prod[31: 0] :
                    mul_inst[1] ? signed_prod[63:32] :
                                unsigned_prod[63:32];

endmodule
