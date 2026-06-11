# Sơ đồ Mermaid

Ngày cập nhật: 2026-06-11.

## Sơ đồ block tổng thể hiện tại

```mermaid
flowchart LR
    TB[Testbench / Host stimulus] -->|clk, rst_n, start| TOP[gemm_int8_top]
    TB -->|a_matrix row-major| TOP
    TB -->|b_matrix row-major| TOP
    TOP -->|busy, done| TB
    TOP -->|c_matrix row-major| TB

    subgraph TOP_DETAIL[gemm_int8_top internals]
        FSM[FSM controller]
        IDX[m/n/k counters]
        READ[Flattened A/B element readers]
        MAC[Signed INT8 multiply + ACC_WIDTH accumulate]
        CREG[c_matrix registers]
        FSM --> IDX
        IDX --> READ
        READ --> MAC
        MAC --> CREG
        FSM --> CREG
    end
```

## Sơ đồ luồng dữ liệu

```mermaid
flowchart TD
    A[A matrix packed row-major] --> ASEL[Select A[m,k]]
    B[B matrix packed row-major] --> BSEL[Select B[k,n]]
    IDX[m_idx_q, n_idx_q, k_idx_q] --> ASEL
    IDX --> BSEL
    ASEL --> MUL[Signed multiply]
    BSEL --> MUL
    MUL --> ADD[Accumulate into C[m,n]]
    COLD[Previous C[m,n]] --> ADD
    ADD --> CNEW[Updated c_matrix]
    CNEW --> DONE[done=1 when all m,n,k complete]
```

## Sơ đồ FSM hiện tại

```mermaid
stateDiagram-v2
    [*] --> S_IDLE
    S_IDLE: busy=0\ndone=0\nindices=0
    S_COMPUTE: busy=1\ndone=0\nC[m,n]+=A[m,k]*B[k,n]
    S_DONE: busy=0\ndone=1\nC stable

    S_IDLE --> S_COMPUTE: start == 1
    S_COMPUTE --> S_COMPUTE: not last m/n/k
    S_COMPUTE --> S_DONE: last m/n/k complete
    S_DONE --> S_IDLE: start == 0
```

## Sơ đồ roadmap systolic/Transformer tương lai

```mermaid
flowchart LR
    HOST[Host / DMA / AXI stream] --> LOAD[Load controller]
    LOAD --> ABUF[A tile buffer]
    LOAD --> BBUF[B/Weight tile buffer]
    ABUF --> SA[Systolic array / GEMM core]
    BBUF --> SA
    SA --> CBUF[C/output tile buffer]
    CBUF --> STORE[Store controller]
    STORE --> HOST

    SA --> QKV[Future Q/K/V projection]
    SA --> SCORE[Future Q*K^T score]
    SA --> PV[Future P*V attention output]
    SA --> FFN[Future FFN layers]
```
