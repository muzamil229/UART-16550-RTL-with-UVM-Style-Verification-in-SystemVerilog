`timescale 1ns / 1ps


module fifo_tb();
 
     reg clk,rst;
     reg en,push_in,pop_in;
     reg [7:0] din;
     reg [3:0] threshold;
     wire [7:0] dout;
     wire empty,full;
     wire underrun,overrun;
     wire thre_trig;
     
     fifo_top uut(    clk,rst,
                      en,push_in,pop_in,
                       din,
                       threshold,
                       dout,
                      empty,full,
                      underrun,overrun,
                      thre_trig
                     );
                     
                     initial begin
                         clk = 0;
                         rst = 0;
                         en =  0;
                         din = 0;
                     end
                     
                     always #5 clk=~clk;
                     
                     
                     initial begin
                     rst = 1'b1;
                     repeat(5) @(posedge clk);
                     
                     for(int i=0;i<20;i++)
                     begin
                        rst =1'b0;
                        push_in<=1'b1;
                        din = $urandom();
                        pop_in = 1'b0;
                        en = 1'b1;
                        threshold = 4'ha;
                        @(posedge clk);
                    end
                    
                    ////////////////////////////read
                    for(int i=0;i<20;i++)
                    begin
                        rst = 1'b0;
                        push_in =1'b0;
                        din =0;
                        pop_in = 1'b1;
                        en = 1'b1;
                        threshold = 4'ha;
                        @(posedge clk);
                    end
                    
                 end
                                    
endmodule
