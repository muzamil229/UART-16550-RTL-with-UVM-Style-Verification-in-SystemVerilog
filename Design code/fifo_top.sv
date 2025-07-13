`timescale 1ns / 1ps

module fifo_top(
input rst, clk, en, push_in, pop_in,
input [7:0] din,
output [7:0] dout,
output empty, full, overrun, underrun, 
input [3:0] threshold,
output thre_trigger
);
 
 
reg [7:0] mem [16];
reg [3:0] waddr = 0;
 
 
logic push , pop ;
 
//////////// empty flag
reg empty_t = 0;
always@(posedge clk, posedge rst)
begin
if(rst)
  begin
  empty_t <= 1'b0; 
  end
  else
  begin
    case({push, pop})
     2'b01: empty_t <=  (~|(waddr) | ~en );
     2'b10: empty_t <= 1'b0;
     default : ;
     endcase
  end
 
end
 
 
//////////////////full flag
reg full_t = 0;
always@(posedge clk, posedge rst)
begin
if(rst)
  begin
  full_t <= 1'b0; 
  end
  else
  begin
    case({push, pop})
     2'b10: full_t <=  (&(waddr) | ~en );
     2'b01: full_t <= 1'b0;
     default : ;
     endcase
  end
 
end
 
////////////////////////////////////////////////
 
 
assign push = push_in & ~full_t;
assign pop  = pop_in  & ~empty_t;
 
/////////////// read fifo --> always first element
assign dout = mem[0];
 
 
 
//////////////// write pointer update
always@(posedge clk, posedge rst)
begin
if(rst)
begin
            waddr <= 4'h0;
end
else
begin
         case({push, pop})
         
         2'b10:
             begin
             if(waddr != 4'hf && full_t == 1'b0) 
              waddr <= waddr + 1;
             else
              waddr <= waddr;
            end
        
         2'b01:
             begin
              if(waddr != 0 && empty_t == 1'b0)
              waddr <= waddr - 1;
              else
              waddr <= waddr;
             end
         
         default: ;
         endcase
end
 
end
//////////////////memory update
 
always@(posedge clk)
begin
case({push, pop})
2'b00: ;
 
2'b01: begin //pop 
        for(int i = 0; i < 14; i++)
        begin
        mem[i] <= mem[i+1];
        end
        mem[15] <= 8'h00;
end
 
2'b10 : begin
       mem[waddr] <= din;
end
 
2'b11 :  begin
        for(int i = 0; i < 14; i++)
        begin
        mem[i] <= mem[i+1];
        end
        mem[15] <= 8'h00;
        mem[waddr - 1] <= din;
end
 
endcase
end
 
 
 
 
/////// no read on empty fifo
 
 
 
 
///////////////// underrun
reg underrun_t = 0;
always@(posedge clk, posedge rst)
begin
 if(rst)
  underrun_t <= 1'b0;
 else if(pop_in == 1'b1 && empty_t == 1'b1)
  underrun_t <= 1'b1;
 else
  underrun_t <= 1'b0;
end
////////////////////// overrun
 
reg overrun_t = 1'b0;
 
always@(posedge clk, posedge rst)
begin
if(rst)
   overrun_t <= 1'b0; 
  else if(push_in == 1'b1 && full_t == 1'b1)
   overrun_t <= 1'b1;
  else
   overrun_t <= 1'b0;  
end
 
 
///////////////// threshold
reg thre_t = 0;
always@(posedge clk, posedge rst)
begin
if(rst)
  begin
  thre_t <= 1'b0; 
  end
  else if(push ^ pop) /// 1 1
  begin
  thre_t <= (waddr >= threshold ) ? 1'b1 : 1'b0;
  end
 
end
 
//////////////////
assign empty = empty_t;
assign full = full_t;
assign overrun = overrun_t;
assign underrun = underrun_t;
assign thre_trigger = thre_t; 
 
endmodule