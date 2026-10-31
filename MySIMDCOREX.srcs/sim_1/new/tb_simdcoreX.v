`timescale 1ns / 1ps



module tb_simdcoreX;

    reg clk;
    reg rst_n;
    reg in_valid;
    reg [1:0] opcode;
    reg [31:0] A;
    reg [31:0] B;

    wire [63:0] vector_result;
    wire signed [19:0] dot_result;
    wire out_valid;

    // Device Under Test
    simdcoreX uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .opcode(opcode),
        .A(A),
        .B(B),
        .vector_result(vector_result),
        .dot_result(dot_result),
        .out_valid(out_valid)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Apply stimulus and verify outputs
    task check_operation;
        input [1:0] op;
        input [31:0] input_A;
        input [31:0] input_B;
        input [63:0] expected_vector;
        input signed [19:0] expected_dot;

        begin
            // Drive inputs away from the rising clock edge
            @(negedge clk);
            opcode   = op;
            A        = input_A;
            B        = input_B;
            in_valid = 1'b1;

            // Stage 1: Capture input
            @(posedge clk);
            #1;
            in_valid = 1'b0;

            // Stage 2: Execute and register output
            @(posedge clk);
            #1;

            if (out_valid !== 1'b1) begin
                $display("FAIL: opcode=%b, out_valid=%b",
                         op, out_valid);
                $fatal(1, "Output valid check failed");
            end

            if ((vector_result !== expected_vector) ||
                (dot_result !== expected_dot)) begin

                $display("FAIL: opcode=%b", op);
                $display("Expected vector = %h", expected_vector);
                $display("Actual vector   = %h", vector_result);
                $display("Expected dot    = %0d", expected_dot);
                $display("Actual dot      = %0d", dot_result);

                $fatal(1, "SIMD output mismatch");
            end
            else begin
                $display("PASS: opcode=%b", op);
                $display("Vector result = %h", vector_result);
                $display("Dot result    = %0d", dot_result);
            end
        end
    endtask

    initial begin
        // Initialize inputs
        clk      = 1'b0;
        rst_n    = 1'b0;
        in_valid = 1'b0;
        opcode   = 2'b00;
        A        = 32'b0;
        B        = 32'b0;

        // Apply synchronous active-low reset
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // Lane 3 = 4, lane 2 = 3,
        // lane 1 = 2, lane 0 = 1
        // A = {4,3,2,1}
        // B = {14,3,2,1}

        // Test 1: VADD
        check_operation(
            2'b00,
            32'h04030201,
            32'h0E030201,
            64'h0000000012060402,
            20'sd0
        );

        // Test 2: VSUB
        check_operation(
            2'b01,
            32'h04030201,
            32'h0E030201,
            64'h00000000F6000000,
            20'sd0
        );

        // Test 3: VMUL
        check_operation(
            2'b10,
            32'h04030201,
            32'h0E030201,
            64'h0038000900040001,
            20'sd0
        );

        // Test 4: DOT
        // 1*1 + 2*2 + 3*3 + 4*14 = 70
        check_operation(
            2'b11,
            32'h04030201,
            32'h0E030201,
            64'h0000000000000000,
            20'sd70
        );

        $display("================================");
        $display("ALL SIMD-COREX TESTS PASSED");
        $display("================================");

        $finish;
    end

endmodule

   
