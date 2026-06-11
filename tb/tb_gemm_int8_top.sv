// SPDX-License-Identifier: MIT
// Testbench for gemm_int8_top: signed INT8 2x2 GEMM with clear PASS/FAIL.

`timescale 1ns/1ps

module tb_gemm_int8_top;
    localparam int M = 2;
    localparam int N = 2;
    localparam int K = 2;
    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH = 32;

    logic clk;
    logic rst_n;
    logic start;
    logic signed [(M*K*DATA_WIDTH)-1:0] a_matrix;
    logic signed [(K*N*DATA_WIDTH)-1:0] b_matrix;
    logic busy;
    logic done;
    logic signed [(M*N*ACC_WIDTH)-1:0] c_matrix;

    int errors;

    gemm_int8_top #(
        .M(M),
        .N(N),
        .K(K),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a_matrix(a_matrix),
        .b_matrix(b_matrix),
        .busy(busy),
        .done(done),
        .c_matrix(c_matrix)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic set_a(input int row, input int col, input logic signed [DATA_WIDTH-1:0] value);
        a_matrix[((row*K + col)*DATA_WIDTH) +: DATA_WIDTH] = value;
    endtask

    task automatic set_b(input int row, input int col, input logic signed [DATA_WIDTH-1:0] value);
        b_matrix[((row*N + col)*DATA_WIDTH) +: DATA_WIDTH] = value;
    endtask

    function automatic logic signed [ACC_WIDTH-1:0] get_c(input int row, input int col);
        get_c = c_matrix[((row*N + col)*ACC_WIDTH) +: ACC_WIDTH];
    endfunction

    task automatic expect_c(
        input int row,
        input int col,
        input logic signed [ACC_WIDTH-1:0] expected
    );
        logic signed [ACC_WIDTH-1:0] actual;
        begin
            actual = get_c(row, col);
            if (actual !== expected) begin
                $display("FAIL: C[%0d,%0d] expected %0d got %0d", row, col, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS_CHECK: C[%0d,%0d] = %0d", row, col, actual);
            end
        end
    endtask

    initial begin
        $dumpfile("build/tb_gemm_int8_top.vcd");
        $dumpvars(0, tb_gemm_int8_top);

        errors = 0;
        rst_n = 1'b0;
        start = 1'b0;
        a_matrix = '0;
        b_matrix = '0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        // A = [[1, 2], [3, 4]]
        set_a(0, 0, 8'sd1);
        set_a(0, 1, 8'sd2);
        set_a(1, 0, 8'sd3);
        set_a(1, 1, 8'sd4);

        // B = [[5, -1], [6, 2]]
        set_b(0, 0, 8'sd5);
        set_b(0, 1, -8'sd1);
        set_b(1, 0, 8'sd6);
        set_b(1, 1, 8'sd2);

        @(negedge clk);
        start = 1'b1;
        @(posedge clk);
        @(negedge clk);
        if (busy !== 1'b1) begin
            $display("FAIL: busy should be asserted after start");
            errors = errors + 1;
        end
        start = 1'b0;

        wait (done === 1'b1);
        @(posedge clk);

        // Expected C = A*B = [[17, 3], [39, 5]]
        expect_c(0, 0, 32'sd17);
        expect_c(0, 1, 32'sd3);
        expect_c(1, 0, 32'sd39);
        expect_c(1, 1, 32'sd5);

        if (errors == 0) begin
            $display("PASS: tb_gemm_int8_top completed successfully");
        end else begin
            $display("FAIL: tb_gemm_int8_top found %0d error(s)", errors);
        end

        $finish;
    end
endmodule
