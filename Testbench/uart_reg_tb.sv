`timescale 1ns / 1ps


module uart_reg_tb;
 
reg clk=0, rst=0;
reg wr_i,rd_i;
reg rx_fifo_empty_i;
reg [7:0] rx_fifo_in;
reg [2:0] addr_i;
reg [7:0] din_i;
reg rx_oe, rx_pe, rx_fe, rx_bi;
wire tx_push_o; ///add new data to TX FIFO
wire rx_pop_o;///read data from RX FIFO
 
wire baud_out; /// baud pulse for both tx and rx
 
wire tx_rst, rx_rst;
wire [3:0] rx_fifo_threshold;
 
wire [7:0] dout_o;
 
 csr_t csr;
 
regs_uart dut (clk, rst,wr_i,rd_i,rx_fifo_empty_i,rx_oe, rx_pe, rx_fe, rx_bi,addr_i, din_i, tx_push_o,rx_pop_o,baud_out,tx_rst, rx_rst,rx_fifo_threshold,dout_o, csr,rx_fifo_in);
 
always #5 clk = ~clk;
 
initial begin
rst = 1;
repeat(5) @(posedge clk);
rst = 0; 
/////// update lsb and msb of divisor
//////// sel DLAB(msb) of lcr (3H) reg to 1
@(negedge clk);
wr_i = 1;
addr_i = 3'h3;
din_i <= 8'b1000_0000;
 
/////////////// Update LSB of divisor latch
@(negedge clk);
addr_i = 3'h0;
din_i <= 8'b0000_1000; // 08
 
//////////// Update MSB of divisor latch
@(negedge clk);
addr_i = 3'h1;
din_i <= 8'b0000_0001;  ////0000_0001_0000_1000
 
//////////////Make DLAB 0 
@(negedge clk);
addr_i = 3'h3;
din_i <= 8'b0000_0000;
$stop;
end
 
endmodule