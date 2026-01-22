`timescale 1ns/1ps

// ============================================================
// INTERFACE
// ============================================================
interface uart_if;
  logic clk;
  logic rst;
  logic wr;
  logic rd;
  logic rx;
  logic tx;
  logic [2:0] addr;
  logic [7:0] din;
  logic [7:0] dout;
endinterface


// ============================================================
// TRANSACTION
// ============================================================
class uart_txn;
  bit [7:0] data;
endclass


// ============================================================
// GENERATOR
// ============================================================
class uart_generator;
  mailbox gen2drv;

  function new(mailbox m);
    gen2drv = m;
  endfunction

  task run();
    uart_txn t;
    t = new();
    t.data = 8'h45; // EXACT SAME RX BYTE AS YOUR TB
    gen2drv.put(t);
    $display("[GEN] RX DATA = 0x%0h", t.data);
  endtask
endclass


// ============================================================
// DRIVER (REGISTER CONFIG + RX BIT STREAM)
// ============================================================
class uart_driver;
  virtual uart_if vif;
  mailbox gen2drv;

  function new(virtual uart_if vif, mailbox m);
    this.vif = vif;
    this.gen2drv = m;
  endfunction

  task configure_uart();
    @(negedge vif.clk); vif.wr = 1; vif.addr = 3'h3; vif.din = 8'b1000_0000;
    @(negedge vif.clk); vif.addr = 3'h0; vif.din = 8'b0000_1000;
    @(negedge vif.clk); vif.addr = 3'h1; vif.din = 8'b0000_0001;
    @(negedge vif.clk); vif.addr = 3'h3; vif.din = 8'b0000_1111;
    @(negedge vif.clk); vif.wr = 0;
  endtask

  task drive_rx();
    uart_txn t;
    gen2drv.get(t);

    vif.rx = 0; // start bit
    repeat (16) @(posedge tb.dut.uart_regs_inst.baud_out);

    for (int i = 0; i < 8; i++) begin
      vif.rx = t.data[i];
      repeat (16) @(posedge tb.dut.uart_regs_inst.baud_out);
    end

    vif.rx = ~^t.data; // odd parity
    repeat (16) @(posedge tb.dut.uart_regs_inst.baud_out);

    vif.rx = 1; // stop bit
    repeat (16) @(posedge tb.dut.uart_regs_inst.baud_out);
  endtask

  task run();
    configure_uart();
    drive_rx();
  endtask
endclass


// ============================================================
// MONITOR
// ============================================================
class uart_monitor;
  virtual uart_if vif;
  mailbox mon2sb;

  function new(virtual uart_if vif, mailbox m);
    this.vif = vif;
    this.mon2sb = m;
  endfunction

  task run();
    uart_txn t;
    t = new();
    @(posedge vif.rd);
    t.data = vif.dout;
    $display("[MON] RX DATA = 0x%0h", t.data);
    mon2sb.put(t);
  endtask
endclass


// ============================================================
// SCOREBOARD
// ============================================================
class uart_scoreboard;
  mailbox gen2sb;
  mailbox mon2sb;

  function new(mailbox g, mailbox m);
    gen2sb = g;
    mon2sb = m;
  endfunction

  task run();
    uart_txn exp, act;
    gen2sb.get(exp);
    mon2sb.get(act);

    if (exp.data === act.data)
      $display("[SB PASS] DATA MATCH = 0x%0h", act.data);
    else
      $error("[SB FAIL] EXP=0x%0h GOT=0x%0h", exp.data, act.data);
  endtask
endclass


// ============================================================
// TOP TESTBENCH
// ============================================================
module tb;

  uart_if uif();

  mailbox gen2drv = new();
  mailbox gen2sb  = new();
  mailbox mon2sb  = new();

  uart_generator  gen;
  uart_driver     drv;
  uart_monitor    mon;
  uart_scoreboard sb;

  // DUT
  all_mod dut (
    .clk  (uif.clk),
    .rst  (uif.rst),
    .wr   (uif.wr),
    .rd   (uif.rd),
    .rx   (uif.rx),
    .addr (uif.addr),
    .din  (uif.din),
    .tx   (uif.tx),
    .dout (uif.dout)
  );

  // Clock
  always #5 uif.clk = ~uif.clk;

  // Reset
  initial begin
    uif.clk = 0;
    uif.rst = 1;
    uif.wr  = 0;
    uif.rd  = 0;
    uif.addr = 0;
    uif.din  = 0;
    uif.rx   = 1;
    repeat (5) @(posedge uif.clk);
    uif.rst = 0;
  end

  // Read RX register
  initial begin
    @(posedge dut.uart_rx_inst.rx_done);
    @(negedge uif.clk);
    uif.rd = 1;
    uif.addr = 3'h0;
    @(negedge uif.clk);
    uif.rd = 0;
  end

  // Environment
  initial begin
    gen = new(gen2drv);
    drv = new(uif, gen2drv);
    mon = new(uif, mon2sb);
    sb  = new(gen2sb, mon2sb);

    fork
      gen.run();
      drv.run();
      mon.run();
      sb.run();
    join_none
  end


  initial begin
    uart_txn t;
    gen2drv.peek(t);
    gen2sb.put(t);
  end

  initial begin
    #200_000;
    $display("=== UART UVM-STYLE TEST COMPLETE ===");
    $finish;
  end

endmodule
