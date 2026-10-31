`timescale 1ns / 1ps



module simd_fpgatop(
    input  wire       clk,
    input  wire       rst_n,
    output wire [7:0] led,
    output wire       valid_led
);

    wire [63:0] vector_result;
    wire signed [19:0] dot_result;
    wire out_valid;

    simdcoreX uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(1'b1),
        .opcode(2'b11),       // DOT operation
        .A(32'h04030201),     // Lanes: 1, 2, 3, 4
        .B(32'h0E030201),     // Lanes: 1, 2, 3, 14

        .vector_result(vector_result),
        .dot_result(dot_result),
        .out_valid(out_valid)
    );

    assign led       = dot_result[7:0];
    assign valid_led = out_valid;

endmodule
    
