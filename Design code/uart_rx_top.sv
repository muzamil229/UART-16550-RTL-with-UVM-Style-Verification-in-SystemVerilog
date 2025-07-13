`timescale 1ns / 1ps


module uart_rx_top(
input clk, rst, baud_pulse, rx, sticky_parity, eps,
input pen,
input [1:0] wls,
output reg push,
output reg pe, fe, bi,
output reg [7:0] dout
    );
 
typedef enum logic [2:0] {idle = 0, start = 1, read = 2, parity = 3, stop = 4} state_type;
state_type state = idle;
 
 
////////////////detect falling edge
reg rx_reg = 1'b1;
wire fall_edge;
 
 
always@(posedge clk)
begin
rx_reg <= rx;
end
 
assign fall_edge = rx_reg;
 
 ///////////////////////////    
 reg [2:0] bitcnt;
 reg [3:0] count = 0;
 reg pe_reg; /// parity error
  
always@(posedge clk, posedge rst)    
 begin
 if(rst)
  begin
  state <= idle;
  push  <= 1'b0;
  pe    <= 1'b0;
  fe    <= 1'b0;
  bi    <= 1'b0;
  bitcnt <= 8'h00;
  end
 else
   begin
      push  <= 1'b0;
      
      if(baud_pulse)
         begin
                   case(state)
                   
                   //////////////////////////////// idle state
                           idle : 
                           begin
                             if(!fall_edge)
                             begin
                             state <= start;
                             count <= 5'd15;
                             end
                             else
                             begin
                             state <= idle;
                             end
                           end
                       //////////////////////////////detect start   
                           
                           start:
                           begin
                           count <= count - 1;
                           
                           
                           if(count == 5'd7)
                                begin
                                     if(rx == 1'b1)
                                       begin
                                       state <= idle;
                                       count <= 5'd15;
                                       end
                                      else
                                       begin
                                       state <= start;
                                       end
                                end
                           else if (count == 0)
                                 begin
                                 state <= read;
                                 count <= 5'd15;
                                 bitcnt <= {1'b1,wls};
                                 end
                                 
                                 
                           end
                           
                           
                           ///////////////////////////read byte from rx pin
                           read: begin
                           
                               count <= count - 1;
                               
                                if(count == 5'd7)
                                begin
                                            case(wls)
                                            2'b00: dout <= {3'b000, rx, dout[4:1]}; 
                                            2'b01: dout <= {2'b00 , rx, dout[5:1]}; 
                                            2'b10: dout <= {1'b0  , rx, dout[6:1]}; 
                                            2'b11: dout <= {        rx, dout[7:1]}; 
                                            endcase
                                            
                                            state <= read;
                                end
                               else if (count == 0)
                                begin
                                        if(bitcnt == 0)
                                               begin
                                                                                                                
                                                                 case({sticky_parity, eps})
                                                                 2'b00: pe_reg <= ~^{rx,dout}; /// odd parity -> pe : no. of 1's even
                                                                 2'b01: pe_reg <= ^{rx,dout}; ///even parity
                                                                 2'b10: pe_reg <= ~rx; /// parity should be 1
                                                                 2'b00: pe_reg <= rx; /// parity should be 0
                                                                 endcase
                                                                 
                                                       if(pen == 1'b1)
                                                             begin
                                                                 state <= parity;
                                                                 count  <= 5'd15;
 
                                                             
                                                              end
                                                          else 
                                                                begin
                                                                state <= stop; 
                                                                count  <= 5'd15;
                                                                end
                                                                       
                                                         end  /// bitcnt reaches 0
                                               
                                           else
                                                      begin
                                                      bitcnt <= bitcnt - 1;
                                                      state  <= read;
                                                      count  <= 5'd15;
                                                      end  /// send rest of bits
                                 end
                           
                           end
                           
                           
                           ////////////////////////////detect parity error
                           parity: 
                           begin
                                 count <= count - 1;
                           
                           
                                         if(count == 5'd7)
                                            begin
                                             pe <= pe_reg;
                                             state <= parity;
                                            end
                                       else if (count == 0)
                                             begin
                                             state <= stop;
                                             count <= 5'd15;
                                             end
                           
                           end
                           
                           //////////////////////// detect frame error
                           stop : begin
                           
                                  count <= count - 1;
                           
                                      if(count == 5'd7)
                                            begin
                                             fe    <= ~rx;
                                             push  <= 1'b1;
                                             state <= stop;
                                            end
                                       else if (count == 0)
                                             begin
                                             state <= idle;
                                             count <= 5'd15;
                                             end
                                  end
                                  
 
                           default: ;
                           
                           
                   endcase
         end
   end
 
 end   
    
 
 
    
endmodule