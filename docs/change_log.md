# Change log

## 2026-06-11 - Baseline GEMM RTL, testbench, docs, research refresh

### Thêm RTL

- Thêm `rtl/gemm_int8_top.sv` làm top module baseline cho signed INT8 GEMM.
- Interface flatten row-major để dễ tạo stimulus và debug.
- FSM gồm `S_IDLE`, `S_COMPUTE`, `S_DONE`.
- Accumulator mặc định `ACC_WIDTH=32`; input mặc định `DATA_WIDTH=8`.
- Không có số liệu synthesis/timing/resource vì chưa chạy FPGA tool.

### Thêm testbench

- Thêm `tb/tb_gemm_int8_top.sv`.
- Testbench tạo clock/reset, input mẫu 2x2, expected output, PASS/FAIL rõ ràng.
- Có `$dumpfile("build/tb_gemm_int8_top.vcd")` cho waveform khi chạy bằng Icarus Verilog.

### Tài liệu

- Thêm/cập nhật `docs/architecture.md`.
- Thêm/cập nhật `docs/signal_table.md`.
- Thêm/cập nhật `docs/parameter_table.md`.
- Thêm/cập nhật `docs/diagrams.md` với Mermaid block/dataflow/FSM diagrams.
- Thêm/cập nhật `docs/todo.md`.
- Thêm/cập nhật `docs/simulation_report.md`.

### Research

- Rà soát và giữ nguyên hướng research chính trong `research/fpga_recent_papers.md`.
- Ghi rõ mọi thông tin hiệu năng/paper cần kiểm chứng trước khi dùng làm baseline project.

### Kiểm tra môi trường

- Kiểm tra `iverilog` và `verilator`: chưa có trong PATH của container.
- Chưa chạy được RTL simulation thật trong môi trường này.

## 2026-06-11 - Rerun simulation/lint and fix timescale warning

- Thêm `` `timescale 1ns/1ps `` vào `rtl/gemm_int8_top.sv` để đồng bộ với testbench và loại bỏ warning timescale của Icarus/Verilator.
- Đổi offset `c_bit_index` dạng `int unsigned` thành `c_elem_index` có width theo `$clog2(M*N)` để tránh warning unused high bits khi lint bằng Verilator.
- Cập nhật testbench để drive `start` tại cạnh âm trước cạnh lấy mẫu, kiểm tra thêm `busy` sau `start`, tránh race giữa testbench và DUT đồng thời tránh signal `busy` bị khai báo nhưng không dùng trong lint.
- Chạy lại Icarus Verilog simulation: PASS với expected output `[[17, 3], [39, 5]]`.
- Chạy lại Verilator lint bằng `--timing`: PASS.
- Cập nhật `docs/simulation_report.md` với kết quả chạy thật và lệnh lint đúng cho testbench có delay/event control.

## 2026-06-11 - Interface protocol and expanded GEMM tests

- Thêm `docs/interface_protocol.md` mô tả packed row-major bit range cho A/B/C, ví dụ 2x2, protocol `start/busy/done/rst_n`, thời điểm `c_matrix` valid và signed/width policy.
- Mở rộng `tb/tb_gemm_int8_top.sv` thành nhiều test: baseline 2x2, negative INT8, zero matrix, 2x2 identity và 4x4 identity.
- Thêm `product_wide` signed `2*DATA_WIDTH` trong RTL để product raw của MAC rõ ràng trước khi resize về `ACC_WIDTH`.
- Cập nhật `docs/simulation_report.md`, `docs/signal_table.md`, `docs/parameter_table.md` theo test và width mới.
- Chạy lại Icarus Verilog simulation và Verilator lint: PASS.
- Không thêm synthesis/timing/resource/board-result claim.
