// ============================================================
// Testbench for Banked Memory Interleaving Controller
// ============================================================
`timescale 1ns/1ps

// ============================================================
// Simple Physical Memory Model (stand-in for real Bank0/Bank1 HW)
// The DUT has no storage of its own -- b0_dout_in / b1_dout_in are
// DUT *inputs*, so something must emulate the physical bank memory
// during simulation. 128 x 16-bit, unparameterized.
// ============================================================
module simple_mem (
    input  wire        clk,
    input  wire [6:0]  addr,
    input  wire [15:0] din,
    input  wire        we,
    output reg  [15:0] dout
);

    reg [15:0] mem [0:127];
    integer i;

    initial begin
        for (i = 0; i < 128; i = i + 1)
            mem[i] = 16'd0;
    end

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;
        dout <= mem[addr];
    end

endmodule

module bmic_tb;

    reg         clk;
    reg         rst_n;

    reg  [7:0]  user_addr;
    reg         user_req;
    reg  [15:0] user_din;
    reg         user_we;
    wire [15:0] bank0_dout;
    wire [15:0] bank1_dout;

    wire [6:0]  b0_addr;
    wire [15:0] b0_din;
    wire        b0_we;
    wire [15:0] b0_dout_in;

    wire [6:0]  b1_addr;
    wire [15:0] b1_din;
    wire        b1_we;
    wire [15:0] b1_dout_in;

    // -----------------------------------------------------------
    // DUT Instantiation
    // -----------------------------------------------------------
    bmic_dut dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .user_addr  (user_addr),
        .user_req   (user_req),
        .user_din   (user_din),
        .user_we    (user_we),
        .bank0_dout (bank0_dout),
        .bank1_dout (bank1_dout),
        .b0_addr    (b0_addr),
        .b0_din     (b0_din),
        .b0_we      (b0_we),
        .b0_dout_in (b0_dout_in),
        .b1_addr    (b1_addr),
        .b1_din     (b1_din),
        .b1_we      (b1_we),
        .b1_dout_in (b1_dout_in)
    );

    // -----------------------------------------------------------
    // Physical Bank 0 / Bank 1 Memory Models
    // -----------------------------------------------------------
    simple_mem bank0_mem (
        .clk  (clk),
        .addr (b0_addr),
        .din  (b0_din),
        .we   (b0_we),
        .dout (b0_dout_in)
    );

    simple_mem bank1_mem (
        .clk  (clk),
        .addr (b1_addr),
        .din  (b1_din),
        .we   (b1_we),
        .dout (b1_dout_in)
    );

    // -----------------------------------------------------------
    // Clock Generation: 10ns period
    // -----------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -----------------------------------------------------------
    // Task: issue a single request (write or read)
    // -----------------------------------------------------------
    task do_req;
        input [7:0]  addr;
        input [15:0] din;
        input        we;
        begin
            @(negedge clk);
            user_addr = addr;
            user_din  = din;
            user_we   = we;
            user_req  = 1'b1;
            @(negedge clk);
            user_req  = 1'b0;
        end
    endtask

    // -----------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------
    initial begin
        // Waveform dump
        $dumpfile("bmic_tb.vcd");
        $dumpvars(0, bmic_tb);

        // Live signal monitor
        $monitor("T=%0t rst_n=%b | addr=%0d we=%b req=%b din=%h | b0_addr=%0d b0_we=%b b0_din=%h b0_dout_in=%h | b1_addr=%0d b1_we=%b b1_din=%h b1_dout_in=%h | bank0_dout=%h bank1_dout=%h",
                 $time, rst_n, user_addr, user_we, user_req, user_din,
                 b0_addr, b0_we, b0_din, b0_dout_in,
                 b1_addr, b1_we, b1_din, b1_dout_in,
                 bank0_dout, bank1_dout);

        // Init
        rst_n     = 1'b0;
        user_addr = 8'd0;
        user_din  = 16'd0;
        user_we   = 1'b0;
        user_req  = 1'b0;

        // Hold reset
        #12;
        rst_n = 1'b1;

        // Write to even address (Bank0) -> addr=10, data=0xAAAA
        do_req(8'd10, 16'hAAAA, 1'b1);

        // Write to odd address (Bank1) -> addr=11, data=0xBBBB
        do_req(8'd11, 16'hBBBB, 1'b1);

        // Write another even address -> addr=20, data=0x1234
        do_req(8'd20, 16'h1234, 1'b1);

        // Write another odd address -> addr=21, data=0x5678
        do_req(8'd21, 16'h5678, 1'b1);

        // Read back even address 10 (Bank0)
        do_req(8'd10, 16'd0, 1'b0);

        // Read back odd address 11 (Bank1)
        do_req(8'd11, 16'd0, 1'b0);

        // Read back even address 20 (Bank0)
        do_req(8'd20, 16'd0, 1'b0);

        // Read back odd address 21 (Bank1)
        do_req(8'd21, 16'd0, 1'b0);

        // A few idle cycles to let last reads settle
        #40;

        $display("TEST COMPLETE");
        $finish;
    end

endmodule
