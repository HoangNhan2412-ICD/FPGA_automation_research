# TODO cho project FPGA automation research

Ngày cập nhật: 2026-06-11.

## Ưu tiên gần

- [x] Thêm baseline RTL `gemm_int8_top` để có top module có thể simulate.
- [x] Thêm testbench 2x2 INT8 signed với expected output và PASS/FAIL.
- [x] Tạo tài liệu kiến trúc, signal, parameter, diagram.
- [ ] Chạy Icarus Verilog hoặc Verilator trong môi trường có tool RTL.
- [ ] Thêm CI/script simulation khi tool được cài.
- [ ] Tách `int8_mac` hoặc `pe` thành module riêng và thêm testbench riêng.
- [ ] Thêm test 4x4 và test giá trị âm/nhiều trường hợp overflow accumulator.

## GEMM/systolic roadmap

- [ ] Giữ `gemm_int8_top` làm reference sequential core.
- [ ] Tạo systolic array 2x2 output-stationary.
- [ ] So sánh output systolic với reference sequential trên cùng input.
- [ ] Thêm tile buffer A/B/C.
- [ ] Thêm FSM load/compute/store.
- [ ] Thêm backpressure/valid-ready nếu chuyển sang streaming interface.

## Attention/Transformer roadmap

- [ ] Dùng GEMM core cho Q/K/V projection.
- [ ] Thêm attention score tile `Q*K^T`.
- [ ] Thêm softmax fixed-point/approximation module riêng và testbench riêng.
- [ ] Thêm `P*V` attention output.
- [ ] Thêm FFN layer 1/layer 2.

## Verification checklist

- [ ] Reset trong lúc idle.
- [ ] Reset giữa lúc compute.
- [ ] `start` pulse dài hơn 1 chu kỳ.
- [ ] Signed input âm/dương hỗn hợp.
- [ ] Width accumulator với `K` lớn hơn 2.
- [ ] Parameter khác default: 2x4, 4x2, 4x4.
- [ ] Waveform review: FSM, counter, product, accumulator.

## Needs verification

- [ ] Chưa có synthesis/timing/resource trên FPGA board.
- [ ] Chưa có benchmark throughput/GOPS/FPS.
- [ ] Chưa kiểm chứng Vivado/Verilator/Icarus trong môi trường hiện tại vì tool RTL chưa có sẵn.
