`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/24 18:23:36
// Design Name: 
// Module Name: timer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


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
