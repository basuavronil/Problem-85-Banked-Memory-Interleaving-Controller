# Problem-85-Banked-Memory-Interleaving-Controller
## Pinout / Interface Ports

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
