# Simulation report

Ngày cập nhật: 2026-06-11.

## Mục tiêu kiểm thử

Testbench `tb/tb_gemm_int8_top.sv` kiểm thử `gemm_int8_top` với nhiều case signed INT8:

| Test | Kích thước | Mục tiêu | Expected summary | Kết quả |
|---|---:|---|---|---|
| `2x2_original_mixed_sign` | 2x2 | Case baseline ban đầu, có B âm | `[[17, 3], [39, 5]]` | PASS |
| `2x2_negative_int8` | 2x2 | A âm và B âm/dương để kiểm tra signed multiply | `[[-5, 5], [-11, 11]]` | PASS |
| `2x2_zero_matrix` | 2x2 | A zero, B khác zero | Ma trận zero | PASS |
| `2x2_identity_matrix` | 2x2 | Nhân với identity | Output bằng A | PASS |
| `4x4_identity_matrix` | 4x4 | Instance 4x4, B identity | Output bằng A 4x4 | PASS |

Case baseline ban đầu:

```text
A = [[1, 2],
     [3, 4]]

B = [[ 5, -1],
     [ 6,  2]]

C = A*B = [[17, 3],
           [39, 5]]
```

## Kết quả trong môi trường hiện tại

- Đã cài/chạy được Icarus Verilog trong container và simulation PASS.
- Đã cài/chạy được Verilator lint với tùy chọn `--timing` và lint PASS.
- Đã chạy Python golden check cho các case 2x2/4x4 và xác nhận expected output; đây là kiểm tra độc lập cho expected output, không thay thế RTL simulation.
- Ghi chú: `apt-get update` có cảnh báo proxy `403 Forbidden` với repo `mise.jdx.dev`, nhưng các package từ Ubuntu archive vẫn cài được và không ảnh hưởng đến Icarus/Verilator check.

## Lệnh chạy bằng Icarus Verilog

Chạy từ root repo:

```bash
mkdir -p build
iverilog -g2012 -Wall -o build/tb_gemm_int8_top.vvp rtl/gemm_int8_top.sv tb/tb_gemm_int8_top.sv
vvp build/tb_gemm_int8_top.vvp
```

Kỳ vọng log có `TEST_PASS` cho từng test và dòng cuối:

```text
PASS: tb_gemm_int8_top completed all tests successfully
```

Waveform được ghi tại:

```text
build/tb_gemm_int8_top.vcd
```

## Lệnh chạy bằng Verilator lint

```bash
verilator --lint-only --sv --timing -Wall rtl/gemm_int8_top.sv tb/tb_gemm_int8_top.sv
```

## Lệnh chạy bằng Vivado xsim gợi ý

```tcl
read_verilog -sv rtl/gemm_int8_top.sv
read_verilog -sv tb/tb_gemm_int8_top.sv
set_property top tb_gemm_int8_top [current_fileset -simset]
launch_simulation
run all
```

## Chưa kiểm chứng

- Chưa có synthesis/timing/resource.
- Chưa có số liệu FPGA board.
- Chưa kiểm chứng waveform bằng GTKWave/Vivado GUI trong container này.

## Log chạy lại 2026-06-11

Các lệnh đã chạy lại trong container hiện tại:

```bash
mkdir -p build && iverilog -g2012 -Wall -o build/tb_gemm_int8_top.vvp rtl/gemm_int8_top.sv tb/tb_gemm_int8_top.sv && vvp build/tb_gemm_int8_top.vvp
verilator --lint-only --sv --timing -Wall rtl/gemm_int8_top.sv tb/tb_gemm_int8_top.sv
```

Kết quả Icarus Verilog có `TEST_PASS` cho 5 test (`2x2_original_mixed_sign`, `2x2_negative_int8`, `2x2_zero_matrix`, `2x2_identity_matrix`, `4x4_identity_matrix`) và dòng cuối `PASS: tb_gemm_int8_top completed all tests successfully`. Verilator lint không báo lỗi sau khi thêm timescale cho RTL, dùng `--timing` cho testbench có delay/event control, thu hẹp width của chỉ số output, drive `start` không bị race tại cạnh clock và dùng signal `busy` trong testbench.

## Signed/width review

- A/B dùng signed `DATA_WIDTH`, default INT8.
- Product raw dùng `PRODUCT_WIDTH = 2*DATA_WIDTH`, default signed 16-bit.
- Product được sign-extend hoặc truncate về `ACC_WIDTH` trước khi accumulate.
- Default `ACC_WIDTH=32` đủ rộng cho các case 2x2/4x4 trong testbench.
- Chưa có synthesis/timing/resource/board result.
