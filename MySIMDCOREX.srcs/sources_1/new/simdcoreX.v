`timescale 1ns / 1ps



module simdcoreX(
    input wire clk,
    input wire rst_n,
    input wire in_valid,
    input wire [1:0] opcode,
    input wire [31:0] A,
    input wire [31:0] B,

    output reg [63:0] vector_result,
    output reg signed [19:0] dot_result,
    output reg out_valid
);

    // Opcode definitions
    localparam VADD = 2'b00;
    localparam VSUB = 2'b01;
    localparam VMUL = 2'b10;
    localparam DOT  = 2'b11;

    // Stage 1: Input registers
    reg [31:0] A_q, B_q;
    reg [1:0] opcode_q;
    reg valid_q;

    // Signed input lanes
    wire signed [7:0] a0 = A_q[7:0];
    wire signed [7:0] a1 = A_q[15:8];
    wire signed [7:0] a2 = A_q[23:16];
    wire signed [7:0] a3 = A_q[31:24];

    wire signed [7:0] b0 = B_q[7:0];
    wire signed [7:0] b1 = B_q[15:8];
    wire signed [7:0] b2 = B_q[23:16];
    wire signed [7:0] b3 = B_q[31:24];

    // Four parallel signed multipliers
    wire signed [15:0] p0 = a0 * b0;
    wire signed [15:0] p1 = a1 * b1;
    wire signed [15:0] p2 = a2 * b2;
    wire signed [15:0] p3 = a3 * b3;

    // Signed 20-bit dot-product reduction
    wire signed [19:0] dot_sum =
          {{4{p0[15]}}, p0}
        + {{4{p1[15]}}, p1}
        + {{4{p2[15]}}, p2}
        + {{4{p3[15]}}, p3};

    // Stage 1: Capture input operands and opcode
    always @(posedge clk) begin
        if (!rst_n) begin
            A_q      <= 32'b0;
            B_q      <= 32'b0;
            opcode_q <= VADD;
            valid_q  <= 1'b0;
        end
        else begin
            valid_q <= in_valid;

            if (in_valid) begin
                A_q      <= A;
                B_q      <= B;
                opcode_q <= opcode;
            end
        end
    end

    // Stage 2: Execute and register outputs
    always @(posedge clk) begin
        if (!rst_n) begin
            vector_result <= 64'b0;
            dot_result    <= 20'sd0;
            out_valid     <= 1'b0;
        end
        else begin
            out_valid <= valid_q;

            if (valid_q) begin
                case (opcode_q)

                    VADD: begin
                        vector_result <= {
                            (a3 + b3),
                            (a2 + b2),
                            (a1 + b1),
                            (a0 + b0)
                        };
                        dot_result <= 20'sd0;
                    end

                    VSUB: begin
                        vector_result <= {
                            (a3 - b3),
                            (a2 - b2),
                            (a1 - b1),
                            (a0 - b0)
                        };
                        dot_result <= 20'sd0;
                    end

                    VMUL: begin
                        vector_result <= {
                            p3, p2, p1, p0
                        };
                        dot_result <= 20'sd0;
                    end

                    DOT: begin
                        vector_result <= 64'b0;
                        dot_result <= dot_sum;
                    end

                    default: begin
                        vector_result <= 64'b0;
                        dot_result <= 20'sd0;
                    end

                endcase
            end
        end
    end

endmodule

    

