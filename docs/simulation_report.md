# Simulation report

Ngày cập nhật: 2026-06-11.

## Mục tiêu kiểm thử

Testbench đầu tiên là `tb/tb_gemm_int8_top.sv`, kiểm thử `gemm_int8_top` với GEMM signed INT8 kích thước 2x2.

Input:

```text
A = [[1, 2],
     [3, 4]]

B = [[ 5, -1],
     [ 6,  2]]
```

Expected:

```text
C = A*B = [[17, 3],
           [39, 5]]
```

## Kết quả trong môi trường hiện tại

- Đã cài/chạy được Icarus Verilog trong container và simulation PASS.
- Đã cài/chạy được Verilator lint với tùy chọn `--timing` và lint PASS.
- Đã chạy Python golden check cho input 2x2 và xác nhận expected output là `[[17, 3], [39, 5]]`; đây là kiểm tra độc lập cho expected output, không thay thế RTL simulation.
- Ghi chú: `apt-get update` có cảnh báo proxy `403 Forbidden` với repo `mise.jdx.dev`, nhưng các package từ Ubuntu archive vẫn cài được và không ảnh hưởng đến Icarus/Verilator check.

## Lệnh chạy bằng Icarus Verilog

Chạy từ root repo:

```bash
mkdir -p build
iverilog -g2012 -Wall -o build/tb_gemm_int8_top.vvp rtl/gemm_int8_top.sv tb/tb_gemm_int8_top.sv
vvp build/tb_gemm_int8_top.vvp
```

Kỳ vọng log có các dòng `PASS_CHECK` cho từng phần tử C và dòng cuối:

```text
PASS: tb_gemm_int8_top completed successfully
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

Kết quả Icarus Verilog có `PASS_CHECK` cho cả 4 phần tử output và dòng cuối `PASS: tb_gemm_int8_top completed successfully`. Verilator lint không báo lỗi sau khi thêm timescale cho RTL, dùng `--timing` cho testbench có delay/event control, thu hẹp width của chỉ số output, drive `start` không bị race tại cạnh clock và dùng signal `busy` trong testbench.
