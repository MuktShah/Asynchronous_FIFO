# Asynchronous FIFO

A parameterized **asynchronous FIFO** implemented in Verilog HDL, designed to safely transfer data between two independent clock domains. The design uses separate write and read clocks, Gray-coded pointers, and two-stage pointer synchronizers for clock-domain crossing.

---

## Architecture

![Asynchronous FIFO Architecture](architecture/async_fifo.png)

---


## Project Structure

```text
Asynchronous_FIFO/
│
├── architecture/
│   └── async_fifo.png
│
├── rtl/
│   └── async_fifo.v
│
├── simulation/
│   └── async_fifo_tb.v
│
├── waveform/
│   └── waveform.png
└── README.md
```

---

## FIFO Parameters

The FIFO is parameterized using:

```verilog
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 4;
```

The FIFO depth is derived as:

```text
DEPTH = 2^ADDR_WIDTH
```

With the default parameters:

```text
Data width = 8 bits
Address width = 4 bits
FIFO depth = 16 entries
```

The implementation uses an additional pointer bit so that wrap-around can be distinguished when generating the `full` and `empty` conditions.

---

## Interface

| Signal | Direction | Description |
| ------ | --------- | ----------- |
| `wr_clk` | Input | Write-domain clock |
| `rd_clk` | Input | Read-domain clock |
| `rst` | Input | Asynchronous active-high reset |
| `wr_en` | Input | Write enable |
| `din` | Input | Input data |
| `full` | Output | Indicates that the FIFO cannot accept another write |
| `rd_en` | Input | Read enable |
| `dout` | Output | Output data |
| `empty` | Output | Indicates that the FIFO has no data available to read |

---
## Binary and Gray-Code Pointers

The write and read pointers are maintained in binary form for memory addressing. Gray-coded versions are generated for clock-domain crossing.

The binary-to-Gray conversion is:

```verilog
gray = (binary >> 1) ^ binary;
```

Gray code is used because only one bit changes between consecutive pointer values, which reduces the risk of multiple-bit sampling errors while crossing between asynchronous clock domains.

The lower pointer bits select the FIFO memory entry, while the additional pointer bit(s) provide wrap-around information for status generation.

---



## Empty Detection

The FIFO is empty when the next read pointer is equal to the synchronized write pointer.

The RTL implements:

```verilog
assign empty_next =
        (rd_ptr_gray_next == wr_ptr_gray_sync2);
```

Conceptually:

```text
Next Read Pointer == Synchronized Write Pointer
                     ↓
                   EMPTY
```

This means there is no unread data remaining in the FIFO.

---

## Full Detection

The FIFO is full when the next write pointer reaches the read pointer after a complete FIFO wrap-around.

The RTL compares the next Gray-coded write pointer with the synchronized read pointer after inverting the upper pointer bits:

```verilog
assign full_next =
    (wr_ptr_gray_next ==
    {
        ~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
         rd_ptr_gray_sync2[ADDR_WIDTH-2:0]
    });
```

Conceptually:

```text
Next Write Pointer == Wrapped Read Pointer
                      ↓
                     FULL
```

The extra pointer information is what allows the design to distinguish an empty FIFO from a FIFO whose pointers have wrapped around to the same memory index.

---

## Reset Behavior

The FIFO uses a common asynchronous active-high reset.

During reset:

```text
Write pointer = 0
Read pointer  = 0
Full          = 0
Empty         = 1
Output data   = 0
Synchronizer registers = 0
```

After reset, the FIFO starts in the empty state and can accept writes immediately once the write-side logic is enabled.

---

## Simulation

The testbench is located at:

```text
simulation/async_fifo_tb.v
```

It generates two independent clocks:

```verilog
wr_clk → 10 ns period
rd_clk → 14 ns period
```

The testbench exercises the FIFO using several scenarios:

### Test 1 — Write

Eight bytes are written into the FIFO:

```text
10, 11, 12, 13, 14, 15, 16, 17
```

### Test 2 — Read

The previously written values are read back after allowing time for pointer synchronization.

### Test 3 — Simultaneous Read/Write

Eight values are written while eight values are read concurrently:

```text
A0, A1, A2, A3, A4, A5, A6, A7
```

The testbench also waits on the `full` and `empty` flags before attempting operations that would otherwise overflow or underflow the FIFO.

---

## Simulation Waveform

![Simulation Waveform](waveform/waveform.png)






---

## Advantages

- Safely transfers data between unrelated clock domains
- Prevents FIFO overflow through the `full` flag
- Prevents FIFO underflow through the `empty` flag
- Parameterized and reusable RTL
- Simple, modular Verilog implementation
- Demonstrates practical clock-domain crossing techniques

