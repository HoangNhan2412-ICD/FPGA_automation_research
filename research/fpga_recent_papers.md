# FPGA / GEMM / Attention / Transformer recent papers

Ngày ghi chú: 2026-06-11. Phạm vi: các paper/preprint có liên quan trực tiếp đến FPGA accelerator, GEMM/systolic array, Transformer/Attention accelerator, INT8/low-bit quantization, tiling, memory reuse, BRAM/FIFO/ping-pong/double buffer.

> Quy ước kiểm chứng:
> - `Verified from source`: thông tin được lấy trực tiếp từ abstract/trang paper/PDF được link trong mục nguồn.
> - `Needs verification`: chưa kiểm tra được chi tiết trong full paper, hoặc chỉ thấy qua abstract/trang metadata, hoặc số liệu cần đối chiếu thêm trước khi dùng trong báo cáo chính thức.
> - Không dùng các số FPS/GOPS/LUT/FF/BRAM/timing/board bên dưới làm baseline của project nếu chưa mở full paper và tái kiểm tra bằng synthesis/simulation của project.

## 1. FlightLLM: Efficient Large Language Model Inference with a Complete Mapping Flow on FPGAs

- **Năm công bố:** 2024.
- **Nguồn/link/citation:** Shulin Zeng et al., accepted to ACM/SIGDA FPGA 2024, arXiv: <https://arxiv.org/abs/2401.03868>, DOI: <https://doi.org/10.48550/arXiv.2401.03868>.
- **Mục tiêu chính:** tăng hiệu quả inference LLM batch size 1 trên FPGA bằng mapping flow hoàn chỉnh cho mô hình nén/sparse/quantized.
- **Kiến trúc phần cứng chính:** configurable sparse DSP chain cho các pattern sparsity; always-on-chip decode scheme để tăng hiệu quả băng thông bộ nhớ; hỗ trợ mixed precision và compilation thích nghi theo độ dài sequence.
- **Có dùng FPGA board nào không:** có. Abstract nêu Xilinx Alveo U280 và Versal VHK158.
- **Có số liệu hiệu năng nào không:** có. Abstract nêu 6.0x energy efficiency và 1.8x cost efficiency so với NVIDIA V100S; 1.2x throughput so với NVIDIA A100 trên Versal VHK158. **Needs verification** trước khi đưa vào bảng so sánh chính vì cần đọc full paper để biết workload, power model, batch size, model, toolchain.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Thiết kế PE/DSP chain có thể cấu hình để hỗ trợ dense trước, sau đó mở rộng sparse.
  - Chia rõ `decode/load` và `compute` để tránh stall do memory bandwidth.
  - Ghi chú tốt cho roadmap: chưa nên triển khai sparse LLM ngay; trước hết nên hoàn thiện GEMM INT8 + buffer ping-pong + tiling.

## 2. BAQET: BRAM-aware Quantization for Efficient Transformer Inference via Stream-based Architecture on an FPGA

- **Năm công bố:** 2025.
- **Nguồn/link/citation:** LingChi Yang et al., FPGA 2025: 51, DOI <https://doi.org/10.1145/3706628.3708849>, DBLP <https://dblp.org/rec/conf/fpga/YangCLLHH25.html>, PDF/slide link tìm được: <https://people.ece.uw.edu/hauck/publications/BAQET_FPGA25.pdf>.
- **Mục tiêu chính:** co-design quantization với ràng buộc BRAM để inference Transformer hiệu quả hơn trên FPGA.
- **Kiến trúc phần cứng chính:** stream-based Transformer inference architecture; trọng tâm là giảm footprint/bottleneck BRAM khi xử lý attention/softmax và luồng dữ liệu.
- **Có dùng FPGA board nào không:** có dấu hiệu dùng AMD/Xilinx Virtex UltraScale+ U55C trong slide/PDF tìm được. **Needs verification** bằng full paper/PDF chính thức.
- **Có số liệu hiệu năng nào không:** có thể có trong paper/slide, nhưng trong ghi chú này chưa trích số cụ thể ngoài metadata. **Needs verification**.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Khi thêm Attention, cần thiết kế buffer theo BRAM budget ngay từ đầu, không chỉ theo số MAC.
  - Tách bảng parameter cho bit-width, sequence length tile, head dimension tile, depth buffer.
  - Ưu tiên streaming attention nhỏ trước: Q/K/V tile -> score tile -> softmax approximate/testbench -> V tile.

## 3. High-Frequency Systolic Array-Based Transformer Accelerator on Field Programmable Gate Arrays

- **Năm công bố:** 2023.
- **Nguồn/link/citation:** Yonghao Chen, Tianrui Li, Xiaojie Chen, Zhigang Cai, Tao Su, *Electronics* 12(4):822, DOI <https://doi.org/10.3390/electronics12040822>, HTML <https://www.mdpi.com/2079-9292/12/4/822>.
- **Mục tiêu chính:** thiết kế systolic array tần số cao cho Transformer accelerator trên FPGA, tập trung vào MHA và FFN.
- **Kiến trúc phần cứng chính:** systolic array cấu hình compile-time; on-chip buffers cho Weight/Bias/X/Q/K/V; AXI/DMA từ DRAM; data reorder; read/write arbiter; multi-clock-domain cho Softmax/LayerNorm thấp tần hơn systolic array; mapping một cell tương ứng một DSP slice.
- **Có dùng FPGA board nào không:** có. Paper nêu Xilinx ZCU102.
- **Có số liệu hiệu năng nào không:** có. Abstract nêu 588 MHz và 474 MHz cho kích thước array khác nhau, cải thiện 1.8x và 1.5x trên ZCU102. **Needs verification** trước khi so với project vì phụ thuộc cấu hình array, constraints và tool version.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Bắt đầu từ interface buffer rõ ràng: weight/input/output buffer + arbiter + core systolic.
  - Thêm pipeline register giữa PE để giảm critical path.
  - Với softmax/layernorm, dùng clock/valid pipeline riêng hoặc module tách rời, không ép chạy cùng timing với GEMM core.

## 4. FTRANS: Energy-Efficient Acceleration of Transformers using FPGA

- **Năm công bố:** 2020.
- **Nguồn/link/citation:** Bingbing Li et al., arXiv <https://arxiv.org/abs/2007.08563>, DOI <https://doi.org/10.48550/arXiv.2007.08563>, ACM/IEEE ISLPED 2020 theo metadata.
- **Mục tiêu chính:** tăng hiệu quả Transformer-based language representations trên FPGA bằng nén mô hình và architecture-level acceleration.
- **Kiến trúc phần cứng chính:** enhanced block-circulant matrix representation để nén weights; acceleration design cho Transformer; tận dụng cấu trúc nén để giảm storage/compute.
- **Có dùng FPGA board nào không:** abstract không nêu board cụ thể. **Needs verification** trong full paper.
- **Có số liệu hiệu năng nào không:** abstract nêu giảm model size up to 16x; 27.07x performance và 81x energy efficiency so với CPU; up to 8.80x energy efficiency so với GPU. **Needs verification** trước khi dùng vì cần biết board, model, dataset, power measurement.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Có thể xem block-circulant là hướng nghiên cứu sau khi GEMM dense chạy đúng.
  - Trước mắt áp dụng bài học: lưu weight dạng layout thân thiện với hardware, tránh transpose runtime.
  - Nên thêm notes về weight packing/tiling trong docs/parameter_table.md sau này.

## 5. Generating Systolic Array Accelerators With Reusable Blocks

- **Năm công bố:** 2020.
- **Nguồn/link/citation:** L. Jia et al., *IEEE Micro* July/August 2020, PDF <https://ceca.pku.edu.cn/docs/20200915170624995514.pdf>.
- **Mục tiêu chính:** tạo systolic array bằng các block tái sử dụng thay vì viết tay mọi biến thể; giữ cycle-level control ở RTL/generator level.
- **Kiến trúc phần cứng chính:** grid PE 2D; data feeders/data collectors có SRAM buffers; PE pipeline controllers; hỗ trợ output-stationary và weight-stationary dataflow; double buffer RAM trong data feeder để overlap transfer với compute.
- **Có dùng FPGA board nào không:** có. Paper nêu Xilinx VU9P platform với Vivado 2018.2.
- **Có số liệu hiệu năng nào không:** paper nêu GEMM generated architecture đạt 322 MHz integer, 264 MHz floating point; với M=N=K=256 trên VU9P, floating-point đạt 677.3 GOp/s. **Needs verification** nếu dùng so sánh vì đây là generator/Chisel, không phải Verilog project hiện tại.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Tách module thành PE, PE array, feeder, collector, top controller.
  - Dùng `valid`/`ready` hoặc `valid` pipeline rõ ràng cho từng cạnh array.
  - Thiết kế buffer double/ping-pong ngay ở feeder để overlap load/compute/store.

## 6. Systolic Tensor Array: An Efficient Structured-Sparse GEMM Accelerator for Mobile CNN Inference

- **Năm công bố:** 2020.
- **Nguồn/link/citation:** Zhi-Gang Liu, Paul N. Whatmough, Matthew Mattina, accepted by IEEE Computer Architecture Letters, arXiv <https://arxiv.org/abs/2005.08098>, DOI <https://doi.org/10.48550/arXiv.2005.08098>.
- **Mục tiêu chính:** cải thiện GEMM INT8 bằng Tensor-PE và structured sparsity cho inference.
- **Kiến trúc phần cứng chính:** traditional scalar PE được mở rộng thành Tensor-PE; Systolic Tensor Array tăng intra-PE operand reuse/datapath efficiency; biến thể STA-DBB hỗ trợ density-bound block sparse format.
- **Có dùng FPGA board nào không:** abstract không nêu board FPGA. Có thể là accelerator/microarchitecture study, không nhất thiết là FPGA implementation. **Needs verification**.
- **Có số liệu hiệu năng nào không:** abstract nêu STA cải thiện area/power 2.08x/1.36x so với conventional SA ở iso-throughput với INT8; STA-DBB cải thiện area/power 3.14x/1.97x cho DBB sparse. **Needs verification** trước khi đưa vào bảng chính.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Giai đoạn đầu nên giữ scalar INT8 MAC PE cho dễ debug.
  - Sau khi đúng chức năng, có thể thêm vectorized/Tensor-PE nhỏ để tăng reuse trong PE.
  - Structured sparse chưa nên triển khai trước khi dense tiling và accumulator width được kiểm chứng.

## 7. A³: Accelerating Attention Mechanisms in Neural Networks with Approximation

- **Năm công bố:** 2020.
- **Nguồn/link/citation:** Tae Jun Ham et al., HPCA 2020, arXiv <https://arxiv.org/abs/2002.10941>, DOI <https://doi.org/10.48550/arXiv.2002.10941>.
- **Mục tiêu chính:** tăng tốc attention bằng approximation và hardware specialization, dựa trên quan sát attention giống content-based search và nhiều phép tính không đóng góp vào output cuối.
- **Kiến trúc phần cứng chính:** approximate attention accelerator; tập trung vào chọn/bỏ qua computation không quan trọng thay vì tính đầy đủ mọi score.
- **Có dùng FPGA board nào không:** abstract không nêu FPGA board. Paper là hardware accelerator cho attention nhưng không nên giả định là FPGA implementation. **Needs verification**.
- **Có số liệu hiệu năng nào không:** abstract nêu cải thiện energy efficiency nhiều bậc và speedup đáng kể so với conventional hardware. Không có số cụ thể trong ghi chú này. **Needs verification**.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Dùng làm hướng nghiên cứu dài hạn cho sparse/approx attention.
  - Không đưa approximation vào RTL giai đoạn đầu; trước hết cần attention exact với testbench PASS/FAIL.
  - Có thể thêm hook `mask/enable` cho score tile để sau này bỏ qua một số tile.

## 8. CoQMoE: Co-Designed Quantization and Computation Orchestration for Mixture-of-Experts Vision Transformer on FPGA

- **Năm công bố:** 2025.
- **Nguồn/link/citation:** Jiale Dong et al., accepted by Euro-Par 2025 (oral), arXiv <https://arxiv.org/abs/2506.08496>, DOI <https://doi.org/10.48550/arXiv.2506.08496>.
- **Mục tiêu chính:** triển khai quantized MoE Vision Transformer hiệu quả trên FPGA với resource-aware accelerator architecture.
- **Kiến trúc phần cứng chính:** dual-stage quantization; scale reparameterization; streaming attention kernels tối ưu latency; reusable linear operators để cân bằng performance/resource.
- **Có dùng FPGA board nào không:** abstract không nêu board cụ thể. **Needs verification** trong full paper/code.
- **Có số liệu hiệu năng nào không:** abstract nêu gần 155 FPS, 5.35x throughput improvement, >80% energy reduction so với SOTA FPGA MoE accelerators và <1% accuracy loss. **Needs verification** trước khi đưa vào báo cáo chính thức.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Reusable linear operator là hướng rất phù hợp: cùng GEMM core dùng cho Q/K/V projection, FFN, output projection.
  - Streaming attention kernel nên là milestone sau GEMM.
  - MoE routing chưa phù hợp với repo hiện tại nếu chưa có cơ sở Transformer nhỏ.

## 9. QUARK: Quantization-Enabled Circuit Sharing for Transformer Acceleration by Exploiting Common Patterns in Nonlinear Operations

- **Năm công bố:** 2025/2026 metadata: submitted 2025, arXiv v2 2026, accepted ICCAD 2025.
- **Nguồn/link/citation:** Zhixiong Zhao et al., arXiv <https://arxiv.org/abs/2511.06767>, DOI <https://doi.org/10.48550/arXiv.2511.06767>.
- **Mục tiêu chính:** giảm overhead của nonlinear operations trong Transformer bằng quantization-enabled circuit sharing trên FPGA.
- **Kiến trúc phần cứng chính:** framework FPGA cho nonlinear ops; circuit sharing cho patterns chung trong nonlinear layers; approximate nonlinear operators.
- **Có dùng FPGA board nào không:** abstract không nêu board. **Needs verification**.
- **Có số liệu hiệu năng nào không:** abstract nêu up to 1.96x end-to-end speedup so với GPU và giảm hardware overhead nonlinear modules >50% so với prior approaches. **Needs verification**.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Khi thêm Softmax/GELU/LayerNorm, gom chung LUT/approx units thay vì nhân bản nhiều module.
  - Cần testbench riêng cho nonlinear approximate unit với error bound rõ ràng.
  - Giai đoạn đầu chỉ ghi roadmap, chưa sửa RTL.

## 10. LLM on FPGA: Squeezing Language Models by Quantization and Multi-Query Attention and its Efficient Hardware Architecture

- **Năm công bố:** 2025.
- **Nguồn/link/citation:** Seoyoon Chae, Taewook Kang, ISOCC 2025, DOI <https://doi.org/10.1109/ISOCC66390.2025.11329964>, ScholarWorks metadata <https://scholarx.skku.edu/item/a567f2df-f6a1-4136-822d-5c44d19d6cb6>, PDF link tìm được <https://chae-sy.github.io/files/2025-isocc-llm-fpga.pdf>.
- **Mục tiêu chính:** on-chip compressed Transformer language model bằng low-bit quantization và multi-query attention để giảm KV cache.
- **Kiến trúc phần cứng chính:** streaming Verilog architecture cho pre-layernorm, attention, FFN; dùng BRAM và DSP; toàn bộ prototype inference on-chip.
- **Có dùng FPGA board nào không:** metadata nêu Xilinx Artix-7 FPGA. **Needs verification** bằng PDF chính thức.
- **Có số liệu hiệu năng nào không:** metadata nêu KV cache compression 8x, sequence length tới 256, throughput 4.4K tokens/s, BRAM 31.9%, DSP 85%. **Needs verification** trước khi dùng vì thông tin lấy từ metadata/PDF link cần đọc kỹ full paper.
- **Ý tưởng áp dụng cho project Verilog hiện tại:**
  - Đây là paper gần với mục tiêu project vì nói rõ Verilog, BRAM, DSP và Transformer nhỏ.
  - Multi-query attention là hướng giảm bộ nhớ tốt hơn multi-head đầy đủ cho FPGA nhỏ.
  - Có thể tạo milestone `tiny_decoder_block` sau khi GEMM/Attention core đã có testbench.

## Kết luận ngắn

- Nhóm paper gần nhất với project hiện tại: **High-Frequency Systolic Array-Based Transformer Accelerator**, **Generating Systolic Array Accelerators With Reusable Blocks**, **BAQET**, và **LLM on FPGA: Squeezing Language Models...**
- Các ý tưởng nên áp dụng sớm: INT8 fixed-point GEMM, accumulator width rõ ràng, systolic PE array đơn giản, tiling theo BRAM, ping-pong/double buffer, feeder/collector tách khỏi core, testbench có PASS/FAIL.
- Các ý tưởng nên để roadmap: sparse DSP chain, block-circulant compression, approximate attention, MoE, circuit sharing nonlinear ops.

## Update 2026-06-11 for current RTL baseline

Baseline hiện tại của repo là signed INT8 GEMM sequential reference core, chưa phải systolic array đầy đủ. Vì vậy các paper trên nên được dùng theo thứ tự ưu tiên sau:

1. **Generating Systolic Array Accelerators With Reusable Blocks**: dùng để tách dần `gemm_int8_top` thành PE/feeder/collector/controller. Link: <https://ceca.pku.edu.cn/docs/20200915170624995514.pdf>.
2. **High-Frequency Systolic Array-Based Transformer Accelerator on Field Programmable Gate Arrays**: dùng làm tham chiếu block tổng thể cho Transformer accelerator gồm buffer, reorder, arbiter và systolic array. Link: <https://www.mdpi.com/2079-9292/12/4/822>.
3. **BAQET**: dùng để nhắc rằng attention/Transformer nhỏ cần BRAM-aware tiling và streaming từ đầu. Link: <https://people.ece.uw.edu/hauck/publications/BAQET_FPGA25.pdf>.
4. **FlightLLM**: dùng cho roadmap dài hạn về mixed precision/sparsity/memory-flow; chưa nên áp dụng vào RTL đầu tiên. Link: <https://arxiv.org/abs/2401.03868>.

### Ý tưởng có thể áp dụng ngay cho project này

- Giữ `gemm_int8_top` làm golden model phần cứng để so sánh với các core tối ưu hơn.
- Thêm PE signed INT8 riêng và testbench riêng trước khi tạo systolic array.
- Tạo systolic array nhỏ 2x2 hoặc 4x4 với cùng expected output như testbench hiện tại.
- Thêm tile buffers sau khi datapath một phép GEMM chạy đúng.
- Không đưa số liệu FPS/GOPS/LUT/FF/BRAM/timing từ paper vào README chính nếu chưa tự chạy synthesis/implementation và ghi rõ board/toolchain.
