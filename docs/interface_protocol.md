# Interface protocol của `gemm_int8_top`

Ngày cập nhật: 2026-06-11.

## 1. Packed row-major format

`gemm_int8_top` dùng packed vector theo thứ tự **row-major**. Phần tử có chỉ số nhỏ nằm ở bit thấp hơn. Cú pháp SystemVerilog tương ứng là `vector[base +: WIDTH]`, trong đó `base` là bit thấp nhất của phần tử.

### `a_matrix`: A[M][K]

Phần tử `A[row][col]` nằm tại:

```systemverilog
a_matrix[((row*K + col)*DATA_WIDTH) +: DATA_WIDTH]
```

Tương đương bit range:

```text
lsb = (row*K + col) * DATA_WIDTH
msb = lsb + DATA_WIDTH - 1
A[row][col] = a_matrix[msb:lsb]
```

### `b_matrix`: B[K][N]

Phần tử `B[row][col]` nằm tại:

```systemverilog
b_matrix[((row*N + col)*DATA_WIDTH) +: DATA_WIDTH]
```

Tương đương bit range:

```text
lsb = (row*N + col) * DATA_WIDTH
msb = lsb + DATA_WIDTH - 1
B[row][col] = b_matrix[msb:lsb]
```

### `c_matrix`: C[M][N]

Phần tử `C[row][col]` nằm tại:

```systemverilog
c_matrix[((row*N + col)*ACC_WIDTH) +: ACC_WIDTH]
```

Tương đương bit range:

```text
lsb = (row*N + col) * ACC_WIDTH
msb = lsb + ACC_WIDTH - 1
C[row][col] = c_matrix[msb:lsb]
```

## 2. Ví dụ cụ thể với ma trận 2x2

Với `M=2`, `N=2`, `K=2`, `DATA_WIDTH=8`, `ACC_WIDTH=32`:

### A 2x2

```text
A = [[A00, A01],
     [A10, A11]]
```

| Phần tử | Bit range |
|---|---:|
| `A[0][0]` | `a_matrix[7:0]` |
| `A[0][1]` | `a_matrix[15:8]` |
| `A[1][0]` | `a_matrix[23:16]` |
| `A[1][1]` | `a_matrix[31:24]` |

### B 2x2

```text
B = [[B00, B01],
     [B10, B11]]
```

| Phần tử | Bit range |
|---|---:|
| `B[0][0]` | `b_matrix[7:0]` |
| `B[0][1]` | `b_matrix[15:8]` |
| `B[1][0]` | `b_matrix[23:16]` |
| `B[1][1]` | `b_matrix[31:24]` |

### C 2x2

```text
C = [[C00, C01],
     [C10, C11]]
```

| Phần tử | Bit range |
|---|---:|
| `C[0][0]` | `c_matrix[31:0]` |
| `C[0][1]` | `c_matrix[63:32]` |
| `C[1][0]` | `c_matrix[95:64]` |
| `C[1][1]` | `c_matrix[127:96]` |

## 3. Protocol control/status

### `rst_n`

- Reset bất đồng bộ, active-low.
- Khi `rst_n=0`, module đưa FSM về `S_IDLE`, xóa `busy`, `done`, chỉ số nội bộ và `c_matrix`.
- Sau khi nhả reset (`rst_n=1`), nên chờ ít nhất một cạnh clock trước khi phát `start` trong testbench/host logic để waveform dễ đọc.

### `start`

- `start` là lệnh bắt đầu phép GEMM.
- Cách dùng khuyến nghị: chỉ assert `start=1` khi module đang idle (`busy=0`, `done=0`) và giữ trong một chu kỳ clock.
- Testbench drive `start` tại cạnh âm trước cạnh clock lấy mẫu để tránh race với `always_ff` của DUT.
- Không nên phát start mới khi `busy=1` hoặc khi `done=1` chưa được clear về idle.

### `busy`

- `busy=1` khi module đang ở pha compute.
- Sau khi `start` được lấy mẫu ở `S_IDLE`, `busy` được assert và giữ trong quá trình tính.
- Khi tính xong và vào `S_DONE`, `busy=0`.

### `done`

- `done=1` khi toàn bộ `c_matrix` hợp lệ.
- `done` giữ mức 1 trong `S_DONE`.
- Khi `start=0`, FSM quay về `S_IDLE` ở cạnh clock tiếp theo và `done` sẽ được hạ trong chu kỳ idle kế tiếp.

### Thời điểm `c_matrix` valid

- `c_matrix` chỉ được xem là valid khi `done=1`.
- Sau khi `done=1`, `c_matrix` ổn định cho tới khi phép chạy kế tiếp bắt đầu và module xóa/ghi lại output.
- Không nên đọc `c_matrix` trong lúc `busy=1`, vì các phần tử output đang được accumulate dần theo từng chu kỳ.

## 4. Signed/unsigned và bit width

- A và B là **signed INT8** khi dùng default `DATA_WIDTH=8`.
- Mỗi phần tử input có range `-128..127`.
- Product raw của một MAC có width `PRODUCT_WIDTH = 2*DATA_WIDTH`; với INT8 là signed 16-bit.
- `product_wide` giữ tích signed raw trước khi đưa vào accumulator.
- `product_value` được sign-extend hoặc truncate về `ACC_WIDTH` trước khi cộng vào `c_matrix`.
- Để tránh overflow accumulator, nên chọn:

```text
ACC_WIDTH >= 2*DATA_WIDTH + ceil(log2(K))
```

- Default `ACC_WIDTH=32` đủ rộng cho các test 2x2 và 4x4 hiện tại.
- Repo chưa claim overflow-safety cho mọi cấu hình lớn; nếu tăng `K`, cần kiểm chứng lại range dữ liệu và accumulator width.
