# Research-to-project mapping

Ngày cập nhật: 2026-06-11.

Repo hiện tại đang ở giai đoạn rất sớm, chưa có RTL accelerator hoàn chỉnh. Vì vậy mapping dưới đây tập trung vào ý tưởng kiến trúc có thể áp dụng dần cho project Verilog/SystemVerilog, không phải cam kết hiệu năng.

## Mapping summary

| Paper | Applicable idea | Apply now? | Suggested project artifact |
|---|---|---:|---|
| High-Frequency Systolic Array-Based Transformer Accelerator on FPGAs | Tách systolic array, on-chip buffers, data reorder, arbiter; pipeline PE để dễ timing | Yes | `rtl/pe.sv`, `rtl/systolic_array.sv`, `rtl/tile_buffer.sv`, docs architecture |
| Generating Systolic Array Accelerators With Reusable Blocks | PE/feeder/collector/controller decomposition; output-stationary/weight-stationary dataflow; double buffer | Yes | Parameterized GEMM core + feeder/collector testbench |
| BAQET | BRAM-aware quantization and streaming Transformer inference | Soon | Parameter table for BRAM depth, sequence tile, head dimension tile |
| Systolic Tensor Array | INT8 GEMM and possible Tensor-PE/vectorized PE | Later | Start scalar PE; later add vector PE variant |
| LLM on FPGA: Squeezing Language Models... | Tiny on-chip Transformer, MQA, Verilog streaming, BRAM/DSP budgeting | Soon/later | Tiny attention block roadmap after GEMM core |
| FlightLLM | Sparse DSP chain, always-on-chip decode, mixed precision | Later | Sparse/mixed-precision roadmap only |
| FTRANS | Compression-aware layout, block-circulant weights | Later | Weight packing/compression experiments after dense baseline |
| A³ | Approximate attention / skipping unimportant computations | Later | Optional score-tile mask/enable after exact attention |
| CoQMoE | Reusable linear operators and streaming attention kernels | Later | Reuse GEMM core for all linear layers |
| QUARK | Circuit sharing for nonlinear Transformer ops | Later | Shared Softmax/GELU/LayerNorm approximate units |

## Recommended implementation order for this project

### Stage 1: Dense INT8 GEMM baseline

- Implement signed INT8 multiply and signed/wider accumulator.
- Choose one dataflow first, preferably output-stationary for easy golden checking.
- Add small testbench: 2x2 or 4x4 matrix, reset, valid sequence, PASS/FAIL.
- Document width behavior: input width, product width, accumulator width, output rounding/saturation.

**Research basis:** High-frequency systolic array paper and reusable-block systolic generator both show the benefit of clear PE array structure and explicit data movement.

### Stage 2: Tiling and on-chip buffers

- Add tile buffers for A, B, C/output.
- Add ping-pong/double buffer only after single-buffer flow passes simulation.
- Define load/compute/store FSM states.
- Add tests for partial tiles and reset during idle.

**Research basis:** BAQET emphasizes BRAM constraints; reusable-block systolic paper emphasizes data feeders/collectors and buffer reuse via tiling.

### Stage 3: Transformer linear layers

- Reuse GEMM core for Q/K/V projection and FFN.
- Use fixed dimensions in early testbench to avoid control complexity.
- Keep top-level interface stable; if changed, document why.

**Research basis:** High-frequency Transformer accelerator focuses on MHA/FFN blocks around the same systolic array idea.

### Stage 4: Small exact attention

- Compute `Q*K^T` tile.
- Add softmax approximation only after exact/fixed-point baseline exists.
- Compute `P*V` using same GEMM datapath where possible.
- Add testbench with small sequence length and deterministic fixed-point vectors.

**Research basis:** LLM-on-FPGA/MQA and BAQET suggest memory-friendly attention; A³ is useful later for approximation but should not replace exact baseline now.

### Stage 5: Optimizations only after correctness

Potential optimizations:

- Vector/Tensor-PE for higher INT8 reuse.
- Weight-stationary mode for weight reuse.
- Sparse tile skipping.
- MQA/GQA to reduce KV memory.
- Shared nonlinear units.

Each optimization must include:

- Separate testbench or updated testbench.
- Width/signedness review.
- Reset/FSM review.
- Updated simulation report.

## Risks to avoid

- Do not mix unverified paper metrics with project metrics.
- Do not implement sparse/approx attention before dense GEMM is stable.
- Do not add a complex top-level interface without a documented reason.
- Do not optimize timing by obscuring control logic; this project prioritizes easy simulation/debug first.
