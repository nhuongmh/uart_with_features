/* baud rate:
2400 -  4800 - 9600 - 14400 - 19200 - 38400 - 56000
*/

module uart_baudgen
  (
  input clk, reset,
  input clk_en,
  input [15:0] M,
  output tick_out );

  reg [15:0] bcounter ;  //counter for baudrate gennerator\

  initial 
  bcounter = 16'd0 ;

  always @ ( posedge clk )
  begin
    if(reset)
          bcounter <=0 ;
    else if (clk_en)
          bcounter <= (bcounter == (M-1))? 16'd0: bcounter+1 ;
  end
    assign tick_out = (bcounter==16'd0)?clk_en:1'b0 ;

  endmodule
