# AGENTS.md

## Ngôn ngữ
- Giải thích bằng tiếng Việt.
- Code dùng Verilog hoặc SystemVerilog.

## Mục tiêu project
- Đây là project FPGA accelerator cho GEMM / Attention / Transformer nhỏ.
- Ưu tiên code dễ hiểu, dễ simulate, dễ debug.
- Chưa cần tối ưu cực hạn ngay từ đầu.

## Quy tắc code
- Không tự ý đổi top-level interface nếu chưa giải thích lý do.
- Mỗi module mới phải có testbench.
- Mọi sửa đổi phải giải thích rõ đã sửa file nào và vì sao.
- Luôn kiểm tra lỗi width mismatch, signed/unsigned, reset, FSM và port mapping.

## Quy tắc simulation
- Nếu có thể, hãy chạy lint/simulation.
- Nếu không chạy được tool, hãy ghi rõ lệnh tôi cần chạy bằng Vivado, Icarus Verilog hoặc Verilator.
- Testbench phải có clock, reset, input mẫu và PASS/FAIL rõ ràng.

## Quy tắc tài liệu
- Khi phân tích repo, hãy tạo hoặc cập nhật:
  - docs/architecture.md
  - docs/signal_table.md
  - docs/parameter_table.md
  - docs/diagrams.md
  - docs/simulation_report.md

## Quy tắc nghiên cứu paper
- Không bịa tên paper, số liệu FPS, GOPS, LUT, FF, BRAM.
- Nếu dùng paper, phải ghi nguồn/link/citation.
- Nếu số liệu chưa được kiểm chứng, ghi rõ là chưa kiểm chứng.

## Ưu tiên làm việc
1. Đúng chức năng.
2. Dễ simulate.
3. Dễ đọc.
4. Có testbench.
5. Có tài liệu.
6. Sau đó mới tối ưu timing/pipeline.
