`timescale 1ns / 1ps



module uart_rx_top_tb();

    reg clk,rst, baud_pulse, rx, sticky_parity, eps;
    reg pen;
    reg [1:0] wls;
    wire push;
    wire pe, fe, bi;
    
    uart_rx_top uut( clk,rst, baud_pulse, rx, sticky_parity, eps,
                     pen,
                      wls,
                     push,
                     pe, fe, bi
                    );
                    
                    always #5 clk = ~clk;
                    
                   
                    
                    initial begin
                        clk = 0;
                        rst = 0;
                        baud_pulse = 0;
                        rx = 1;
                        sticky_parity = 0;
                        eps = 0;
                        pen = 1'b1;
                        wls = 2'b11;
                    end
                    
                    reg [7:0] rx_reg = 8'h45;
                    
                     initial begin
                        rst = 1'b1;
                        repeat (5) @(posedge clk);
                        rst = 1'b0;
                        
                        rx = 1'b0;
                        
                        repeat (16) @(posedge baud_pulse);
                        
                        for(int i=0;i<8;i++)
                        begin
                            rx = rx_reg[i];
                            repeat (16) @(posedge baud_pulse);
                        end
                        
                        rx = ~^rx_reg;
                        
                        repeat (16)@(posedge baud_pulse);
                        rx =1;
                        repeat (16) @(posedge baud_pulse);
                        
                        end
                        
                        
                        integer count = 5;
                        
                        
                        always@(posedge clk)
                        begin
                            if(rst==0)
                            begin
                                if(count !=0)
                                begin
                                    count <= count - 1;
                                    baud_pulse <= 1'b0;
                                end
                                else
                                begin
                                    count <= 5;
                                    baud_pulse <= 1'b1;
                                end
                            end
                       end
                        
                      
                    
                        
endmodule
