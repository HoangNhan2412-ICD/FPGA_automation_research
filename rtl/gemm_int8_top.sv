`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
// Simple, simulation-friendly signed INT8 GEMM top module.
// Data layout is row-major and flattened into packed vectors.

module gemm_int8_top #(
    parameter int M = 2,
    parameter int N = 2,
    parameter int K = 2,
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH = 32
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic signed [(M*K*DATA_WIDTH)-1:0] a_matrix,
    input  logic signed [(K*N*DATA_WIDTH)-1:0] b_matrix,
    output logic busy,
    output logic done,
    output logic signed [(M*N*ACC_WIDTH)-1:0] c_matrix
);

    typedef enum logic [1:0] {
        S_IDLE    = 2'd0,
        S_COMPUTE = 2'd1,
        S_DONE    = 2'd2
    } state_t;

    state_t state_q;

    int unsigned m_idx_q;
    int unsigned n_idx_q;
    int unsigned k_idx_q;
    int unsigned clear_idx;

    localparam int C_ELEMENTS = M * N;
    localparam int C_ELEM_INDEX_WIDTH = (C_ELEMENTS <= 1) ? 1 : $clog2(C_ELEMENTS);
    localparam int PRODUCT_WIDTH = 2 * DATA_WIDTH;

    logic signed [DATA_WIDTH-1:0] a_value;
    logic signed [DATA_WIDTH-1:0] b_value;
    logic signed [PRODUCT_WIDTH-1:0] product_wide;
    logic signed [ACC_WIDTH-1:0] product_value;
    logic [C_ELEM_INDEX_WIDTH-1:0] c_elem_index;

    function automatic logic signed [DATA_WIDTH-1:0] get_a_value(
        input int unsigned row,
        input int unsigned col
    );
        get_a_value = a_matrix[((row*K + col)*DATA_WIDTH) +: DATA_WIDTH];
    endfunction

    function automatic logic signed [DATA_WIDTH-1:0] get_b_value(
        input int unsigned row,
        input int unsigned col
    );
        get_b_value = b_matrix[((row*N + col)*DATA_WIDTH) +: DATA_WIDTH];
    endfunction

    always_comb begin
        a_value = get_a_value(m_idx_q, k_idx_q);
        b_value = get_b_value(k_idx_q, n_idx_q);
        product_wide = $signed(a_value) * $signed(b_value);
        c_elem_index = C_ELEM_INDEX_WIDTH'(m_idx_q*N + n_idx_q);
    end

    generate
        if (ACC_WIDTH >= PRODUCT_WIDTH) begin : gen_product_sign_extend
            assign product_value = {{(ACC_WIDTH-PRODUCT_WIDTH){product_wide[PRODUCT_WIDTH-1]}}, product_wide};
        end else begin : gen_product_truncate
            assign product_value = product_wide[ACC_WIDTH-1:0];
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_IDLE;
            m_idx_q <= 0;
            n_idx_q <= 0;
            k_idx_q <= 0;
            busy <= 1'b0;
            done <= 1'b0;
            c_matrix <= '0;
        end else begin
            case (state_q)
                S_IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                    m_idx_q <= 0;
                    n_idx_q <= 0;
                    k_idx_q <= 0;

                    if (start) begin
                        for (clear_idx = 0; clear_idx < M*N; clear_idx = clear_idx + 1) begin
                            c_matrix[(clear_idx*ACC_WIDTH) +: ACC_WIDTH] <= '0;
                        end
                        busy <= 1'b1;
                        state_q <= S_COMPUTE;
                    end
                end

                S_COMPUTE: begin
                    busy <= 1'b1;
                    done <= 1'b0;
                    c_matrix[(c_elem_index*ACC_WIDTH) +: ACC_WIDTH] <=
                        $signed(c_matrix[(c_elem_index*ACC_WIDTH) +: ACC_WIDTH]) + product_value;

                    if (k_idx_q == K-1) begin
                        k_idx_q <= 0;
                        if (n_idx_q == N-1) begin
                            n_idx_q <= 0;
                            if (m_idx_q == M-1) begin
                                m_idx_q <= 0;
                                state_q <= S_DONE;
                            end else begin
                                m_idx_q <= m_idx_q + 1;
                            end
                        end else begin
                            n_idx_q <= n_idx_q + 1;
                        end
                    end else begin
                        k_idx_q <= k_idx_q + 1;
                    end
                end

                S_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    if (!start) begin
                        state_q <= S_IDLE;
                    end
                end

                default: begin
                    state_q <= S_IDLE;
                    busy <= 1'b0;
                    done <= 1'b0;
                    m_idx_q <= 0;
                    n_idx_q <= 0;
                    k_idx_q <= 0;
                end
            endcase
        end
    end

    initial begin
        if (M <= 0 || N <= 0 || K <= 0) begin
            $error("M, N, and K must be positive");
        end
        if (DATA_WIDTH <= 0 || ACC_WIDTH <= 0) begin
            $error("DATA_WIDTH and ACC_WIDTH must be positive");
        end
        if (ACC_WIDTH < (2*DATA_WIDTH)) begin
            $warning("ACC_WIDTH is smaller than product width; accumulation may truncate");
        end
    end

endmodule
