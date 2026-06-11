// SPDX-License-Identifier: MIT
// Testbench for gemm_int8_top: signed INT8 GEMM with clear per-test PASS/FAIL.

`timescale 1ns/1ps

module tb_gemm_int8_top;
    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH = 32;

    localparam int M2 = 2;
    localparam int N2 = 2;
    localparam int K2 = 2;

    localparam int M4 = 4;
    localparam int N4 = 4;
    localparam int K4 = 4;

    logic clk;
    logic rst_n;

    logic start_2x2;
    logic signed [(M2*K2*DATA_WIDTH)-1:0] a_matrix_2x2;
    logic signed [(K2*N2*DATA_WIDTH)-1:0] b_matrix_2x2;
    logic busy_2x2;
    logic done_2x2;
    logic signed [(M2*N2*ACC_WIDTH)-1:0] c_matrix_2x2;

    logic start_4x4;
    logic signed [(M4*K4*DATA_WIDTH)-1:0] a_matrix_4x4;
    logic signed [(K4*N4*DATA_WIDTH)-1:0] b_matrix_4x4;
    logic busy_4x4;
    logic done_4x4;
    logic signed [(M4*N4*ACC_WIDTH)-1:0] c_matrix_4x4;

    int total_errors;
    int test_errors;

    gemm_int8_top #(
        .M(M2),
        .N(N2),
        .K(K2),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut_2x2 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_2x2),
        .a_matrix(a_matrix_2x2),
        .b_matrix(b_matrix_2x2),
        .busy(busy_2x2),
        .done(done_2x2),
        .c_matrix(c_matrix_2x2)
    );

    gemm_int8_top #(
        .M(M4),
        .N(N4),
        .K(K4),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut_4x4 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_4x4),
        .a_matrix(a_matrix_4x4),
        .b_matrix(b_matrix_4x4),
        .busy(busy_4x4),
        .done(done_4x4),
        .c_matrix(c_matrix_4x4)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic set_a2(input int row, input int col, input logic signed [DATA_WIDTH-1:0] value);
        a_matrix_2x2[((row*K2 + col)*DATA_WIDTH) +: DATA_WIDTH] = value;
    endtask

    task automatic set_b2(input int row, input int col, input logic signed [DATA_WIDTH-1:0] value);
        b_matrix_2x2[((row*N2 + col)*DATA_WIDTH) +: DATA_WIDTH] = value;
    endtask

    task automatic set_a4(input int row, input int col, input logic signed [DATA_WIDTH-1:0] value);
        a_matrix_4x4[((row*K4 + col)*DATA_WIDTH) +: DATA_WIDTH] = value;
    endtask

    task automatic set_b4(input int row, input int col, input logic signed [DATA_WIDTH-1:0] value);
        b_matrix_4x4[((row*N4 + col)*DATA_WIDTH) +: DATA_WIDTH] = value;
    endtask

    function automatic logic signed [ACC_WIDTH-1:0] get_c2(input int row, input int col);
        get_c2 = c_matrix_2x2[((row*N2 + col)*ACC_WIDTH) +: ACC_WIDTH];
    endfunction

    function automatic logic signed [ACC_WIDTH-1:0] get_c4(input int row, input int col);
        get_c4 = c_matrix_4x4[((row*N4 + col)*ACC_WIDTH) +: ACC_WIDTH];
    endfunction

    task automatic clear_inputs_2x2;
        begin
            a_matrix_2x2 = '0;
            b_matrix_2x2 = '0;
        end
    endtask

    task automatic clear_inputs_4x4;
        begin
            a_matrix_4x4 = '0;
            b_matrix_4x4 = '0;
        end
    endtask

    task automatic start_test(input string test_name);
        begin
            test_errors = 0;
            $display("TEST_START: %s", test_name);
        end
    endtask

    task automatic finish_test(input string test_name);
        begin
            if (test_errors == 0) begin
                $display("TEST_PASS: %s", test_name);
            end else begin
                $display("TEST_FAIL: %s errors=%0d", test_name, test_errors);
                total_errors = total_errors + test_errors;
            end
        end
    endtask

    task automatic pulse_start_2x2(input string test_name);
        begin
            @(negedge clk);
            start_2x2 = 1'b1;
            @(posedge clk);
            @(negedge clk);
            if (busy_2x2 !== 1'b1) begin
                $display("FAIL: %s busy_2x2 should be asserted after start", test_name);
                test_errors = test_errors + 1;
            end
            start_2x2 = 1'b0;
            wait (done_2x2 === 1'b1);
            @(posedge clk);
            if (busy_2x2 !== 1'b0) begin
                $display("FAIL: %s busy_2x2 should be low when done is high", test_name);
                test_errors = test_errors + 1;
            end
            @(posedge clk);
        end
    endtask

    task automatic pulse_start_4x4(input string test_name);
        begin
            @(negedge clk);
            start_4x4 = 1'b1;
            @(posedge clk);
            @(negedge clk);
            if (busy_4x4 !== 1'b1) begin
                $display("FAIL: %s busy_4x4 should be asserted after start", test_name);
                test_errors = test_errors + 1;
            end
            start_4x4 = 1'b0;
            wait (done_4x4 === 1'b1);
            @(posedge clk);
            if (busy_4x4 !== 1'b0) begin
                $display("FAIL: %s busy_4x4 should be low when done is high", test_name);
                test_errors = test_errors + 1;
            end
            @(posedge clk);
        end
    endtask

    task automatic expect_c2(
        input string test_name,
        input int row,
        input int col,
        input logic signed [ACC_WIDTH-1:0] expected
    );
        logic signed [ACC_WIDTH-1:0] actual;
        begin
            actual = get_c2(row, col);
            if (actual !== expected) begin
                $display("FAIL: %s C2[%0d,%0d] expected %0d got %0d", test_name, row, col, expected, actual);
                test_errors = test_errors + 1;
            end else begin
                $display("PASS_CHECK: %s C2[%0d,%0d] = %0d", test_name, row, col, actual);
            end
        end
    endtask

    task automatic expect_c4(
        input string test_name,
        input int row,
        input int col,
        input logic signed [ACC_WIDTH-1:0] expected
    );
        logic signed [ACC_WIDTH-1:0] actual;
        begin
            actual = get_c4(row, col);
            if (actual !== expected) begin
                $display("FAIL: %s C4[%0d,%0d] expected %0d got %0d", test_name, row, col, expected, actual);
                test_errors = test_errors + 1;
            end else begin
                $display("PASS_CHECK: %s C4[%0d,%0d] = %0d", test_name, row, col, actual);
            end
        end
    endtask

    task automatic run_2x2_original;
        string test_name;
        begin
            test_name = "2x2_original_mixed_sign";
            start_test(test_name);
            clear_inputs_2x2();
            set_a2(0, 0, 8'sd1);  set_a2(0, 1, 8'sd2);
            set_a2(1, 0, 8'sd3);  set_a2(1, 1, 8'sd4);
            set_b2(0, 0, 8'sd5);  set_b2(0, 1, -8'sd1);
            set_b2(1, 0, 8'sd6);  set_b2(1, 1, 8'sd2);
            pulse_start_2x2(test_name);
            expect_c2(test_name, 0, 0, 32'sd17);
            expect_c2(test_name, 0, 1, 32'sd3);
            expect_c2(test_name, 1, 0, 32'sd39);
            expect_c2(test_name, 1, 1, 32'sd5);
            finish_test(test_name);
        end
    endtask

    task automatic run_2x2_negative;
        string test_name;
        begin
            test_name = "2x2_negative_int8";
            start_test(test_name);
            clear_inputs_2x2();
            set_a2(0, 0, -8'sd1); set_a2(0, 1, -8'sd2);
            set_a2(1, 0, -8'sd3); set_a2(1, 1, -8'sd4);
            set_b2(0, 0, 8'sd1);  set_b2(0, 1, -8'sd1);
            set_b2(1, 0, 8'sd2);  set_b2(1, 1, -8'sd2);
            pulse_start_2x2(test_name);
            expect_c2(test_name, 0, 0, -32'sd5);
            expect_c2(test_name, 0, 1, 32'sd5);
            expect_c2(test_name, 1, 0, -32'sd11);
            expect_c2(test_name, 1, 1, 32'sd11);
            finish_test(test_name);
        end
    endtask

    task automatic run_2x2_zero;
        string test_name;
        begin
            test_name = "2x2_zero_matrix";
            start_test(test_name);
            clear_inputs_2x2();
            set_b2(0, 0, 8'sd7);   set_b2(0, 1, -8'sd8);
            set_b2(1, 0, -8'sd9);  set_b2(1, 1, 8'sd10);
            pulse_start_2x2(test_name);
            expect_c2(test_name, 0, 0, 32'sd0);
            expect_c2(test_name, 0, 1, 32'sd0);
            expect_c2(test_name, 1, 0, 32'sd0);
            expect_c2(test_name, 1, 1, 32'sd0);
            finish_test(test_name);
        end
    endtask

    task automatic run_2x2_identity;
        string test_name;
        begin
            test_name = "2x2_identity_matrix";
            start_test(test_name);
            clear_inputs_2x2();
            set_a2(0, 0, 8'sd12);  set_a2(0, 1, -8'sd3);
            set_a2(1, 0, 8'sd4);   set_a2(1, 1, 8'sd5);
            set_b2(0, 0, 8'sd1);   set_b2(0, 1, 8'sd0);
            set_b2(1, 0, 8'sd0);   set_b2(1, 1, 8'sd1);
            pulse_start_2x2(test_name);
            expect_c2(test_name, 0, 0, 32'sd12);
            expect_c2(test_name, 0, 1, -32'sd3);
            expect_c2(test_name, 1, 0, 32'sd4);
            expect_c2(test_name, 1, 1, 32'sd5);
            finish_test(test_name);
        end
    endtask

    task automatic run_4x4_identity;
        string test_name;
        int row;
        int col;
        begin
            test_name = "4x4_identity_matrix";
            start_test(test_name);
            clear_inputs_4x4();

            set_a4(0, 0, 8'sd2);  set_a4(0, 1, -8'sd4); set_a4(0, 2, -8'sd5); set_a4(0, 3, -8'sd6);
            set_a4(1, 0, 8'sd1);  set_a4(1, 1, 8'sd3);  set_a4(1, 2, -8'sd1); set_a4(1, 3, -8'sd2);
            set_a4(2, 0, 8'sd5);  set_a4(2, 1, 8'sd4);  set_a4(2, 2, 8'sd4);  set_a4(2, 3, 8'sd2);
            set_a4(3, 0, 8'sd9);  set_a4(3, 1, 8'sd8);  set_a4(3, 2, 8'sd7);  set_a4(3, 3, 8'sd5);

            for (row = 0; row < K4; row = row + 1) begin
                for (col = 0; col < N4; col = col + 1) begin
                    set_b4(row, col, (row == col) ? 8'sd1 : 8'sd0);
                end
            end

            pulse_start_4x4(test_name);
            expect_c4(test_name, 0, 0, 32'sd2);  expect_c4(test_name, 0, 1, -32'sd4); expect_c4(test_name, 0, 2, -32'sd5); expect_c4(test_name, 0, 3, -32'sd6);
            expect_c4(test_name, 1, 0, 32'sd1);  expect_c4(test_name, 1, 1, 32'sd3);  expect_c4(test_name, 1, 2, -32'sd1); expect_c4(test_name, 1, 3, -32'sd2);
            expect_c4(test_name, 2, 0, 32'sd5);  expect_c4(test_name, 2, 1, 32'sd4);  expect_c4(test_name, 2, 2, 32'sd4);  expect_c4(test_name, 2, 3, 32'sd2);
            expect_c4(test_name, 3, 0, 32'sd9);  expect_c4(test_name, 3, 1, 32'sd8);  expect_c4(test_name, 3, 2, 32'sd7);  expect_c4(test_name, 3, 3, 32'sd5);
            finish_test(test_name);
        end
    endtask

    initial begin
        $dumpfile("build/tb_gemm_int8_top.vcd");
        $dumpvars(0, tb_gemm_int8_top);

        total_errors = 0;
        test_errors = 0;
        rst_n = 1'b0;
        start_2x2 = 1'b0;
        start_4x4 = 1'b0;
        a_matrix_2x2 = '0;
        b_matrix_2x2 = '0;
        a_matrix_4x4 = '0;
        b_matrix_4x4 = '0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        run_2x2_original();
        run_2x2_negative();
        run_2x2_zero();
        run_2x2_identity();
        run_4x4_identity();

        if (total_errors == 0) begin
            $display("PASS: tb_gemm_int8_top completed all tests successfully");
        end else begin
            $display("FAIL: tb_gemm_int8_top found %0d total error(s)", total_errors);
        end

        $finish;
    end
endmodule
