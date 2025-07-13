`timescale 1ns/1ps
module all_mod_tb;

reg clk, rst, wr, rd;
reg rx;
reg [2:0] addr;
reg [7:0] din;
wire tx;
wire [7:0] dout;

all_mod dut (clk, rst, wr, rd, rx, addr, din, tx, dout);

always #5 clk = ~clk;

initial begin
  clk = 0; rst = 0; wr = 0; rd = 0; addr = 0; din = 0; rx = 1;
end

// CONFIGURE UART
initial begin

  rst = 1;
  repeat(5) @(posedge clk);
  rst = 0;

  @(negedge clk); wr = 1; addr = 3'h3; din = 8'b1000_0000; // DLAB = 1
  @(negedge clk); addr = 3'h0; din = 8'b0000_1000;         // LSB = 8
  @(negedge clk); addr = 3'h1; din = 8'b0000_0001;         // MSB = 1
  @(negedge clk); addr = 3'h3; din = 8'b0000_1111;         // DLAB = 0, WLS=00, PEN=1, EPS=0
  @(negedge clk); wr = 0; rd = 0;

  @(posedge dut.uart_tx_inst.sreg_empty);
  repeat(48) @(posedge dut.uart_tx_inst.baud_pulse);

  $stop;
end

// RX BIT STREAM
initial begin
  reg [7:0] rx_reg = 8'h45;


  rx = 0; // start bit
  repeat (16) @(posedge dut.uart_regs_inst.baud_out);

  for (int i = 0; i < 8; i++) begin
    #1;
    rx = rx_reg[i];
    repeat (16) @(posedge dut.uart_regs_inst.baud_out);
  end

  rx = ~^rx_reg[7:0]; // odd parity
  repeat (16) @(posedge dut.uart_regs_inst.baud_out);

  rx = 1; // stop bit
  repeat (16) @(posedge dut.uart_regs_inst.baud_out);

  $finish;
end

endmodule
