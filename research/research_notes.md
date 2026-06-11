# Research notes for FPGA GEMM / Attention / Transformer accelerator

Ngày cập nhật: 2026-06-11.

## Search scope used

Các từ khóa đã dùng khi tìm paper:

- `FPGA Transformer accelerator INT8 quantization attention FPGA board BRAM ping pong buffer`
- `GEMM systolic array FPGA accelerator tiling memory reuse paper 2023`
- `FPGA accelerator attention transformer systolic array INT8 paper Alveo U280`
- `BAQET BRAM-aware Quantization for Efficient Transformer FPGA 2025 paper`
- `High-Frequency Systolic Array-Based Transformer Accelerator FPGA board 2023`
- `LLM on FPGA Squeezing Language Models FPGA Multi-Query Attention`

## Observations

### 1. GEMM/systolic array should be the first stable RTL core

Nhiều paper Transformer FPGA vẫn quy về các linear layers lớn: Q/K/V projection, output projection, FFN. Vì vậy project hiện tại nên ưu tiên:

- INT8 matrix multiply với accumulator đủ rộng.
- Output-stationary hoặc weight-stationary dataflow rõ ràng.
- PE array parameterized nhưng giữ đơn giản.
- Testbench nhỏ kiểm chứng với ma trận mẫu và golden result.

### 2. BRAM-aware design quan trọng ngang với số DSP

Các paper gần đây nhấn mạnh memory bottleneck, KV cache, BRAM footprint, streaming, tiling. Với project này, tài liệu nên định nghĩa sớm:

- `TILE_M`, `TILE_N`, `TILE_K`.
- input/weight/output buffer depth.
- ping-pong buffer state machine.
- read/write arbitration giữa load, compute, store.

### 3. Transformer accelerator nên tái sử dụng GEMM core

Một GEMM core có thể phục vụ nhiều block:

- Q/K/V projection.
- Attention score `Q*K^T`.
- Attention output `P*V`.
- FFN layer 1/layer 2.
- Output projection.

Do đó không nên tạo nhiều multiplier array riêng khi repo còn nhỏ. Nên xây một datapath tuyến tính, dễ simulate.

### 4. Nonlinear ops nên tách module và testbench riêng

Softmax, LayerNorm, GELU/ReLU thường khó timing và khó xác minh hơn GEMM. Theo hướng từ QUARK và các paper Transformer FPGA:

- Không nhồi nonlinear vào GEMM PE.
- Dùng module riêng với `valid_in/valid_out`.
- Dùng fixed-point format rõ ràng.
- Dùng approximate LUT/piecewise sau khi có golden test.

### 5. Approximation/sparsity là roadmap, không phải bước đầu

FlightLLM, A³, FTRANS, CoQMoE có nhiều ý tưởng mạnh nhưng tăng độ phức tạp verification. Với project Verilog hiện tại:

- Dense INT8 GEMM trước.
- Exact attention nhỏ trước.
- Sparse/approx/low-bit cực thấp sau.
- Mỗi thay đổi phải có testbench PASS/FAIL.

## Suggested next research tasks

1. Tải full PDF các paper quan trọng và điền bảng chi tiết board/tool/resource.
2. Tạo `docs/parameter_table.md` cho `DATA_WIDTH`, `ACC_WIDTH`, `TILE_M/N/K`, buffer depth.
3. Tạo block diagram cho datapath: DMA/mock loader -> ping-pong buffer -> systolic array -> output buffer.
4. Tạo checklist verification: reset, signedness, accumulator overflow, valid alignment, FSM terminal states.
5. Khi có RTL, thêm simulation report với golden matrix multiply và attention tile nhỏ.

## Verification cautions

- Không copy số FPS/GOPS/LUT/FF/BRAM vào README chính nếu chưa mở full paper và ghi rõ điều kiện đo.
- Không so sánh paper HLS/Chisel/ASIC trực tiếp với Verilog RTL của repo nếu chưa normalize clock, precision, board, batch, model, input size.
- Các paper dùng GPU baseline cần kiểm tra batch size, power measurement, GPU model, software stack.

## Open verification items

- Needs verification: exact board/toolchain/resource tables for BAQET, LLM on FPGA, CoQMoE, QUARK, A³, and FTRANS.
- Needs verification: whether each reported FPS/GOPS/tokens/s number uses post-synthesis, post-implementation, board measurement, or model-level estimate.
