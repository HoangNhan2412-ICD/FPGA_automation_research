# Kiến trúc FPGA GEMM/Transformer accelerator

Ngày cập nhật: 2026-06-11.

## Trạng thái repo sau phân tích

Repo ban đầu chỉ có tài liệu nghiên cứu, chưa có RTL accelerator hoặc testbench có thể chạy. Thay đổi này thêm baseline RTL đầu tiên để project có một top module rõ ràng, dễ simulate và làm nền cho systolic array/Attention/Transformer nhỏ.

## Top module chính

Top module hiện tại là `gemm_int8_top` trong `rtl/gemm_int8_top.sv`.

Mục tiêu của module:

- Tính GEMM signed INT8 theo công thức `C[M,N] = A[M,K] * B[K,N]`.
- Dùng accumulator signed `ACC_WIDTH`, mặc định 32 bit.
- Dữ liệu ma trận được flatten row-major để interface đơn giản, không phụ thuộc bus ngoài.
- Kiến trúc hiện tại là sequential one-MAC-per-cycle để ưu tiên đúng chức năng, dễ debug, dễ kiểm chứng trước khi mở rộng thành systolic array.

## Module con

Hiện tại chưa có module con RTL riêng. `gemm_int8_top` chứa trực tiếp:

- FSM điều khiển `S_IDLE`, `S_COMPUTE`, `S_DONE`.
- Bộ đếm chỉ số `m_idx_q`, `n_idx_q`, `k_idx_q`.
- Hàm truy cập phần tử flatten `get_a_value()` và `get_b_value()`.
- MAC signed INT8 -> signed accumulator.

Việc chưa tách PE/MAC thành module con là chủ ý để baseline nhỏ và dễ simulate. TODO tương lai: tách `int8_mac`, `pe`, `systolic_array`, `tile_buffer`, `controller` sau khi baseline này ổn định.

## Luồng dữ liệu

1. Testbench/host đặt `a_matrix` và `b_matrix` theo layout row-major.
2. Testbench/host kéo `start = 1` trong một chu kỳ khi `rst_n = 1`.
3. `gemm_int8_top` xóa `c_matrix`, bật `busy`, rồi đi vào `S_COMPUTE`.
4. Mỗi chu kỳ `S_COMPUTE`, module đọc một cặp phần tử `A[m,k]`, `B[k,n]`, nhân signed và cộng vào `C[m,n]`.
5. Bộ đếm chạy theo thứ tự `m -> n -> k` logic thực thi thực tế là hoàn tất toàn bộ `k` cho từng `C[m,n]`, sau đó chuyển sang `n`, rồi `m`.
6. Khi phần tử cuối `C[M-1,N-1]` hoàn tất, FSM chuyển sang `S_DONE`, hạ `busy`, bật `done`.
7. `done` giữ mức 1 cho tới khi `start` được hạ, sau đó module quay về `S_IDLE`.

## FSM

| State | Ý nghĩa | Hành động chính | Điều kiện chuyển |
|---|---|---|---|
| `S_IDLE` | Chờ lệnh chạy | `busy=0`, `done=0`, reset chỉ số nội bộ | Nếu `start=1`: xóa `c_matrix`, sang `S_COMPUTE` |
| `S_COMPUTE` | Tính GEMM | Mỗi chu kỳ cộng `A[m,k]*B[k,n]` vào `C[m,n]` | Khi chưa hết K/N/M: tăng chỉ số; khi hết toàn bộ: sang `S_DONE` |
| `S_DONE` | Báo hoàn tất | `busy=0`, `done=1`, giữ output ổn định | Khi `start=0`: quay về `S_IDLE` |

## Chính sách signed/width/reset

- `a_matrix` và `b_matrix` là signed packed vectors, mỗi phần tử được lấy ra thành `logic signed [DATA_WIDTH-1:0]`.
- Nhân dùng `$signed(a_value) * $signed(b_value)` và sign-extend/truncate vào `ACC_WIDTH`.
- Mặc định `DATA_WIDTH=8`, `ACC_WIDTH=32`, đủ rộng cho các test 2x2/4x4 nhỏ.
- Reset bất đồng bộ active-low (`rst_n`) xóa FSM, chỉ số, `busy`, `done`, `c_matrix`.
- Nếu `ACC_WIDTH < 2*DATA_WIDTH`, module in `$warning` trong simulation vì product có thể bị truncate.

## Hướng phát triển đề xuất

1. Giữ `gemm_int8_top` làm golden/reference sequential core.
2. Tách module MAC/PE riêng và thêm testbench riêng cho PE.
3. Thêm systolic array 2x2 hoặc 4x4 có cùng kết quả với reference core.
4. Thêm tile buffer và FSM load/compute/store.
5. Tái sử dụng GEMM core cho Q/K/V projection, attention score `Q*K^T`, attention output `P*V`, FFN.
