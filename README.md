# Problem-85-Banked-Memory-Interleaving-Controller

# Why Not Multi-Port Memory? (Hardware Design Trade-offs) why divide the memory into banks instead - 
## Overview
While adding multiple read/write ports to a single memory array sounds like an ideal architectural fix, physical hardware constraints make true multi-porting impractical for large memory structures like main memory or large caches. Instead, engineers rely on **banked memory interleaving**.

## Core Reasons Against Multi-Port Memory
### 1. Silicon Area Explosion ($O(N^2)$ Scaling)
* **Single-Port (1R/1W):** Uses standard 6-Transistor (6T) SRAM cells with a single pair of bit-lines and word-lines.
* **Multi-Port (2R/2W+):** Requires duplicating word-lines, bit-lines, and adding extra access transistors (8T to 10T+) to **every single memory cell**.
* **Impact:** Physical silicon footprint increases by **200% to 300%**, dramatically driving up manufacturing costs for the exact same storage capacity.

### 2. High Wire Capacitance & Slower Clock Speeds
* Adding multiple bit-lines and word-lines across a shared memory array drastically increases **parasitic wire capacitance and resistance**.
* **Impact:** Signals take longer to charge and discharge, forcing designers to lower the maximum operating clock frequency of the entire memory array.

### 3. Increased Dynamic Power Consumption
* Power equation: $P = C \cdot V^2 \cdot f$ (where $C$ is wire capacitance).
* **Impact:** Multi-port arrays feature massive internal wire capacitance. Every read/write operation energizes a larger network of high-capacitance lines, burning significantly more dynamic power than localized, smaller memory banks.

## The Engineering Alternative: Banked Interleaving
Instead of scaling memory cells horizontally with expensive extra ports, banking achieves parallel throughput by using:
* Standard, low-cost single-port memory cells (~5% area overhead for control logic).
* Independent parallel arrays (banks) addressed via address interleaving (e.g., even/odd LSB routing).
* Faster local access speeds and lower active power consumption.
  
# Pinout / Interface Ports
## Top-Level Block Diagram — Banked Memory Interleaving Controller

```
                         ┌───────────────────────────────────────────────────────────────┐
                         │        BANKED MEMORY INTERLEAVING CONTROLLER (Top)            │
                         │                                                               │
   clk    ───────────────►│                                                              │
   rst_n  ───────────────►│  (async active-low reset)                                    │
                         │                                                               │
 ─────────── Processor / User Interface ───────────         Internal Registers           │
                         │                                                               │
  user_addr[7:0] ───────►│ ──┐                          ┌─────────────────────────┐      │
   user_req       ───────►│  ├─► addr_reg[7:0]  ────────►│ bank_sel = addr_reg[0] │      │
   user_din[15:0] ───────►│  ├─► din_reg[15:0]           │  (0 = Bank0 / Even)    │      │
   user_we        ───────►│  ├─► we_reg                 │  (1 = Bank1 / Odd)      │      │
                         │  └─► req_reg (req pipeline)  └─────────────────────────┘      │
                         │                                                               │
                         │        ┌───────────────────────────────────────────┐          │
                         │        │  b0_dout_reg[15:0]  ◄── captured from     │          │
                         │        │                          b0_dout_in       │          │
   bank0_dout[15:0]◄─────│────────┤                                           │          │
                         │        │  b1_dout_reg[15:0]  ◄── captured from     │          │
                         │        │                          b1_dout_in       │          │
   bank1_dout[15:0]◄─────│────────┤                                           │          │
                         │        └───────────────────────────────────────────┘          │
                         │                                                               │
 ────────── Physical Memory Hardware Interface (Bank 0 / Bank 1) ──────────              │
                         │                                                               │
   b0_addr[6:0]   ◄──────│── addr_reg[7:1]   (= user_addr[7:1])                          │
   b0_din[15:0]   ◄──────│── din_reg[15:0]                                               │
   b0_we          ◄──────│── we_reg & ~bank_sel  (write only if target = Bank0)          │
   b0_dout_in[15:0]──────►│──► b0_dout_reg                                               │
                         │                                                               │
   b1_addr[6:0]   ◄──────│── addr_reg[7:1]   (= user_addr[7:1])                          │
   b1_din[15:0]   ◄──────│── din_reg[15:0]                                               │
   b1_we          ◄──────│── we_reg & bank_sel   (write only if target = Bank)           │
   b1_dout_in[15:0]──────►│──► b1_dout_reg                                               │
                         │                                                               │
                         └───────────────────────────────────────────────────────────────┘
```
## Understanding the Interfaces
This controller sits between two very different "worlds" and translates between them.

### 1. User Interface (Processor side)

This is how the outside world — a CPU, another module, or a testbench — talks to your design. It's simple and doesn't know anything about banks or how memory is physically split up.

| Signal        | What it means in plain words          |
|----------------|----------------------------------------|
| `user_addr`    | "Here's the address I want"            |
| `user_req`     | "Go — process my request now"          |
| `user_din`     | "Here's the data to write"             |
| `user_we`      | "This is a write (1) or a read (0)"    |
| `bank0_dout`   | "Give me back the data" (from Bank 0)  |
| `bank1_dout`   | "Give me back the data" (from Bank 1)  |

The processor just asks for an address and expects data back. It has no idea there are two separate physical memories underneath.

### 2. Memory Interface (Physical Bank side)

This is how you talk to the actual hardware — two separate, independent memory chips: Bank 0 and Bank 1. Each bank is "dumb" — it only understands its own local signals and has no idea the other bank even exists.

| Signal               | What it means in plain words                 |
|----------------------|-----------------------------------------------|
| `b0_addr` / `b1_addr`| "Here's your local address" (7 bits — no bank-select bit needed) |
| `b0_din` / `b1_din`  | "Here's the data to write"                    |
| `b0_we` / `b1_we`    | "Write now"                                    |
| `b0_dout_in` / `b1_dout_in` | "Here's what I read"                     |

### 3. So what does the Controller (middle block) actually do?

It's the **translator** that sits between the simple user interface and the two physical banks. Its job:

- **Splits the incoming address** into two parts:
  - The **bank-select bit** (`user_addr[0]`) — decides even (Bank 0) or odd (Bank 1)
  - The **local address** (`user_addr[7:1]`) — the actual row inside that bank
- **Routes the request** to the correct physical bank — only Bank 0's `we` fires for even addresses, only Bank 1's for odd addresses
- **Picks which bank's data to return** to the processor on a read
- **Holds registers** (`addr_reg`, `din_reg`, `we_reg`, `bank_sel`, `b0_dout_reg`, `b1_dout_reg`) since real hardware needs a clock cycle to latch and remember what was requested

### Why split memory into banks at all?

By putting even addresses in one physical chip and odd addresses in another, both banks can potentially be accessed independently — which is the whole idea behind "interleaving." The Controller is the piece of logic that makes this split invisible to the processor, while still correctly driving two separate physical memories underneath.

**Direction key:** an arrow shown next to a signal always points *out of* the block it's listed in if it reads `───►`, or *into* the block if it reads `◄───`.
- **Controller → Banking (outputs):** `addr_reg`, `din_reg`, `we_reg` drive `b0_addr/b0_din/b0_we` and `b1_addr/b1_din/b1_we` — these are the address/data/write-enable signals going **into** each physical bank (`◄──` on the bank side).
- **Banking → Controller (inputs):** `b0_dout_in`/`b1_dout_in` come back **out of** each bank (`──►` on the bank side) and are captured into `b0_dout_reg`/`b1_dout_reg`.
- `req_reg` and `bank_sel` stay internal — they only gate/select which bank's `we` fires, they don't cross the boundary themselves.

### Port Summary

| Signal            | Dir | Width | Description                                   |
|--------------------|-----|-------|------------------------------------------------|
| `clk`              | In  | 1     | System clock                                    |
| `rst_n`            | In  | 1     | Async active-low reset                          |
| `user_addr`        | In  | 8     | Target address from processor                   |
| `user_req`         | In  | 1     | Memory request trigger                          |
| `user_din`         | In  | 16    | Write data from processor                       |
| `user_we`          | In  | 1     | 1 = Write, 0 = Read                             |
| `bank0_dout`       | Out | 16    | Read data from Bank 0 (Even)                    |
| `bank1_dout`       | Out | 16    | Read data from Bank 1 (Odd)                     |
| `b0_addr`          | Out | 7     | Reduced address to Bank 0 (`user_addr[7:1]`)    |
| `b0_din`           | Out | 16    | Write data to Bank 0                            |
| `b0_we`            | Out | 1     | Write enable to Bank 0                          |
| `b0_dout_in`       | In  | 16    | Read data from physical Bank 0                  |
| `b1_addr`          | Out | 7     | Reduced address to Bank 1 (`user_addr[7:1]`)    |
| `b1_din`           | Out | 16    | Write data to Bank 1                            |
| `b1_we`            | Out | 1     | Write enable to Bank 1                          |
| `b1_dout_in`       | In  | 16    | Read data from physical Bank 1                  |

### Internal Registers (proposed)

| Register        | Width | Purpose                                                  |
|------------------|-------|---------------------------------------------------------|
| `addr_reg`       | 8     | Registered copy of `user_addr`                          |
| `din_reg`        | 16    | Registered copy of `user_din`                           |
| `we_reg`         | 1     | Registered copy of `user_we`                            |
| `req_reg`        | 1     | Registered/pipelined `user_req`                         |
| `bank_sel`       | 1     | `addr_reg[0]` — selects Bank0 (even) vs Bank1 (odd)     |
| `b0_dout_reg`    | 16    | Captured read data from Bank 0                          |
| `b1_dout_reg`    | 16    | Captured read data from Bank 1                          |
- `b1_we` *(Output, 1-bit)*: Write enable routed to Bank 1.
- `b1_dout_in` *(Input, `16` bits)*: Data output read directly from physical Bank 1.

# Output
## Waveform 
<img width="959" height="345" alt="image" src="https://github.com/user-attachments/assets/ec4afbe7-f10d-4342-859a-fdc717e6eca9" />

## Simulation terminal 
<img width="767" height="400" alt="image" src="https://github.com/user-attachments/assets/48b4049b-3a2f-4cbc-846d-16417916523e" />
