# Bảng signal cho các module quan trọng

Ngày cập nhật: 2026-06-11.

## `gemm_int8_top`

| Signal | Direction | Width | Signed? | Mô tả |
|---|---:|---:|---:|---|
| `clk` | input | 1 | No | Clock chính cho FSM và datapath. |
| `rst_n` | input | 1 | No | Reset bất đồng bộ active-low. Khi `0`, xóa state/chỉ số/output/status. |
| `start` | input | 1 | No | Pulse bắt đầu phép GEMM. Nên giữ 1 trong một chu kỳ và hạ xuống sau đó. |
| `a_matrix` | input | `M*K*DATA_WIDTH` | Yes | Ma trận A flatten row-major. Phần tử `A[row,col]` ở bit `((row*K+col)*DATA_WIDTH)+:DATA_WIDTH`. |
| `b_matrix` | input | `K*N*DATA_WIDTH` | Yes | Ma trận B flatten row-major. Phần tử `B[row,col]` ở bit `((row*N+col)*DATA_WIDTH)+:DATA_WIDTH`. |
| `busy` | output | 1 | No | Bật khi module đang tính trong `S_COMPUTE`. |
| `done` | output | 1 | No | Bật khi toàn bộ output `c_matrix` hợp lệ trong `S_DONE`. |
| `c_matrix` | output | `M*N*ACC_WIDTH` | Yes | Ma trận C flatten row-major, mỗi phần tử là accumulator signed `ACC_WIDTH`. |

## Signal nội bộ đáng chú ý

| Signal | Width/type | Mô tả |
|---|---:|---|
| `state_q` | enum 2 bit | FSM hiện tại: `S_IDLE`, `S_COMPUTE`, `S_DONE`. |
| `m_idx_q` | `int unsigned` | Chỉ số hàng output C và hàng A. |
| `n_idx_q` | `int unsigned` | Chỉ số cột output C và cột B. |
| `k_idx_q` | `int unsigned` | Chỉ số reduction K. |
| `a_value` | signed `DATA_WIDTH` | Phần tử A hiện tại. |
| `b_value` | signed `DATA_WIDTH` | Phần tử B hiện tại. |
| `product_value` | signed `ACC_WIDTH` | Tích signed đã đưa về width accumulator. |
| `c_elem_index` | `logic [C_ELEM_INDEX_WIDTH-1:0]` | Chỉ số phần tử C hiện tại; bit offset khi truy cập packed output là `c_elem_index*ACC_WIDTH`. |

## Testbench `tb_gemm_int8_top`

| Signal/task | Mô tả |
|---|---|
| `clk` | Clock 100 MHz tương đương period 10 ns trong simulation. |
| `rst_n` | Reset kéo thấp 3 chu kỳ đầu. |
| `set_a(row,col,value)` | Helper ghi phần tử A vào packed vector theo row-major. |
| `set_b(row,col,value)` | Helper ghi phần tử B vào packed vector theo row-major. |
| `expect_c(row,col,expected)` | Helper so sánh output và in `PASS_CHECK`/`FAIL`. |
| `$dumpfile("build/tb_gemm_int8_top.vcd")` | Waveform dump cho Icarus/GTKWave. |
