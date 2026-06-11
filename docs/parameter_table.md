# Bảng parameter

Ngày cập nhật: 2026-06-11.

## `gemm_int8_top`

| Parameter | Default | Ý nghĩa | Ghi chú kiểm chứng |
|---|---:|---|---|
| `M` | 2 | Số hàng của A và C. | Phải > 0. Testbench hiện kiểm thử `M=2`. |
| `N` | 2 | Số cột của B và C. | Phải > 0. Testbench hiện kiểm thử `N=2`. |
| `K` | 2 | Chiều reduction: A là `M x K`, B là `K x N`. | Phải > 0. Testbench hiện kiểm thử `K=2`. |
| `DATA_WIDTH` | 8 | Bit width của phần tử input A/B. | Mặc định INT8 signed. |
| `ACC_WIDTH` | 32 | Bit width accumulator/output C. | Mặc định đủ rộng cho test nhỏ. Nếu nhỏ hơn `2*DATA_WIDTH`, simulation cảnh báo truncate product. |

## Công thức width

| Vector | Công thức width | Layout |
|---|---:|---|
| `a_matrix` | `M*K*DATA_WIDTH` | Row-major, `A[row,col]`. |
| `b_matrix` | `K*N*DATA_WIDTH` | Row-major, `B[row,col]`. |
| `c_matrix` | `M*N*ACC_WIDTH` | Row-major, `C[row,col]`. |

## Gợi ý parameter tương lai

| Parameter tương lai | Mục đích | Trạng thái |
|---|---|---|
| `TILE_M`, `TILE_N`, `TILE_K` | Chia tile cho GEMM/systolic array. | TODO. |
| `ARRAY_ROWS`, `ARRAY_COLS` | Kích thước systolic array. | TODO. |
| `BUFFER_DEPTH_A/B/C` | Depth BRAM/FIFO cho tile buffers. | TODO / Needs verification theo target FPGA. |
| `OUTPUT_SATURATE` | Bật/tắt saturation khi ghi output hẹp hơn accumulator. | TODO. |
| `SIGNED_MODE` | Cho phép signed/unsigned input. | TODO, hiện fixed signed. |
