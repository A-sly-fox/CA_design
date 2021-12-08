`timescale 1ns / 1ps
module timer(
    input       [ 1:0] timer_type,
    input              clk,
    input              reset,
    output      [31:0] timer_value
);

reg [63:0] timer_value_r;
always @(posedge clk) begin
    if(reset)begin
        timer_value_r <= 1'b0;
    end
    else begin
        timer_value_r <= timer_value_r + 1'b1;
    end
end
assign timer_value = (timer_type[0]) ? timer_value_r[31:0] : timer_value_r[63:32];

endmodule
