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
### Clock & Reset
- `clk` *(Input, 1-bit)*: System Clock.
- `rst_n` *(Input, 1-bit)*: Asynchronous Active-Low Reset.

### Processor / User Interface
- `user_addr` *(Input, `8` bits)*: Input target address from processor.
- `user_req` *(Input, 1-bit)*: Memory request trigger from processor.
- `user_din` *(Input, `16` bits)*: Data write input from processor.
- `user_we` *(Input, 1-bit)*: Write enable control (`1` = Write, `0` = Read).
- `bank0_dout` *(Output, `16` bits)*: Read data payload fetched from Bank 0 (Even).
- `bank1_dout` *(Output, `16` bits)*: Read data payload fetched from Bank 1 (Odd).

### Physical Memory Hardware Interface (Bank 0 & Bank 1)
- `b0_addr` *(Output, `7` bits)*: Reduced bank address sent directly to Bank 0 (`user_addr[7:1]`).
- `b0_din` *(Output, `16` bits)*: Data payload routed directly to Bank 0.
- `b0_we` *(Output, 1-bit)*: Write enable routed to Bank 0.
- `b0_dout_in` *(Input, `16` bits)*: Data output read directly from physical Bank 0.
- `b1_addr` *(Output, `7` bits)*: Reduced bank address sent directly to Bank 1 (`user_addr[7:1]`).
- `b1_din` *(Output, `16` bits)*: Data payload routed directly to Bank 1.
- `b1_we` *(Output, 1-bit)*: Write enable routed to Bank 1.
- `b1_dout_in` *(Input, `16` bits)*: Data output read directly from physical Bank 1.
