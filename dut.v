// ============================================================
// Banked Memory Interleaving Controller (DUT)
// Simple, unparameterized Verilog
// ============================================================
module bmic_dut (
    input clk, rst_n,

    // Processor / User Interface
    input [7:0]  user_addr,
    input user_req,
    input [15:0] user_din,
    input user_we,
    output reg  [15:0] bank0_dout,
    output reg  [15:0] bank1_dout,

    // Physical Memory Hardware Interface - Bank 0 (Even)
    output wire [6:0]  b0_addr,
    output wire [15:0] b0_din,
    output wire        b0_we,
    input  wire [15:0] b0_dout_in,

    // Physical Memory Hardware Interface - Bank 1 (Odd)
    output wire [6:0]  b1_addr,
    output wire [15:0] b1_din,
    output wire        b1_we,
    input  wire [15:0] b1_dout_in
);

    // -----------------------------------------------------------
    // Internal Registers
    // -----------------------------------------------------------
    reg [7:0]  addr_reg;
    reg [15:0] din_reg;
    reg        we_reg;
    reg        req_reg;
    reg        bank_sel;   // 0 = Bank0 (even), 1 = Bank1 (odd)

    // -----------------------------------------------------------
    // Input Capture Stage
    // -----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= 8'd0;
            din_reg  <= 16'd0;
            we_reg   <= 1'b0;
            req_reg  <= 1'b0;
            bank_sel <= 1'b0;
        end else begin
            addr_reg <= user_addr;
            din_reg  <= user_din;
            we_reg   <= user_we;
            req_reg  <= user_req;
            bank_sel <= user_addr[0];
        end
    end

    // -----------------------------------------------------------
    // Bank 0 (Even) Drive Logic
    // -----------------------------------------------------------
    assign b0_addr = addr_reg[7:1];
    assign b0_din  = din_reg;
    assign b0_we   = req_reg & we_reg & ~bank_sel;

    // -----------------------------------------------------------
    // Bank 1 (Odd) Drive Logic
    // -----------------------------------------------------------
    assign b1_addr = addr_reg[7:1];
    assign b1_din  = din_reg;
    assign b1_we   = req_reg & we_reg & bank_sel;

    // -----------------------------------------------------------
    // Read Data Capture Stage
    // -----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bank0_dout <= 16'd0;
            bank1_dout <= 16'd0;
        end else begin
            bank0_dout <= b0_dout_in;
            bank1_dout <= b1_dout_in;
        end
    end

endmodule
