`timescale 1ns / 1ps

module uart_rx_fifo
  (
  input           clk, reset ,
  input   [2:0]  rx_fifo_int,
  input   [11:0] rx_data_in,
  input          rx_rd, rx_wr ,

  output  [15:0] rx_data_out,
  output  [6:0]  rx_status
  );

parameter   W = 4 ;  // number of address line

reg [15:0]     rx_buf_array [2**W-1:0] ;
reg [W-1:0]   wr_ptr_reg, wr_ptr_next ;  //write pointer reg/next/accepted
reg [W-1:0]   rd_ptr_reg, rd_ptr_next ; //read pointer
reg           full_reg, empty_reg, full_next, empty_next ;
reg           overrun_reg, overrun_next ;
reg [3:0]     interrupt_level;
wire          interrupt  ;
integer       i ;
assign rx_data_out = rx_buf_array[rd_ptr_reg] ;           //NTC

initial begin
 #1 case(rx_fifo_int)
  3'b000: interrupt_level = 4'd1 ;
  3'b001: interrupt_level = 4'd2 ;
  3'b010: interrupt_level = 4'd4 ;
  3'b011: interrupt_level = 4'd8 ;
  3'b100: interrupt_level = 4'd12;
  3'b101: interrupt_level = 4'd14;
  default: interrupt_level = 4'd4;
  endcase
  wr_ptr_next = 4'h0 ;
  rd_ptr_next = 4'h0 ;
  full_next   = 1'b0 ;
  empty_next  = 1'b1 ;
  overrun_next= 1'b0 ;
  wr_ptr_reg  = 4'h0 ;
  rd_ptr_reg  = 4'h0 ;
  full_reg    = 1'b0 ;
  empty_reg   = 1'b1 ;
  overrun_reg = 1'b0 ;
  for(i=0;i<16;i=i+1)
    rx_buf_array[i] = 16'h0 ;
end

always @(posedge clk or posedge reset)
begin
    if(reset)
      begin
      wr_ptr_reg    <= 0 ;
      rd_ptr_reg    <= 0;
      full_reg      <= 1'b0 ;
      empty_reg     <= 1'b1 ;
      overrun_reg   <= 1'b0 ;
      end
    else
      begin
      wr_ptr_reg    <= wr_ptr_next ;
      rd_ptr_reg    <= rd_ptr_next ;
      full_reg      <= full_next   ;
      empty_reg     <= empty_next  ;
      overrun_reg   <= overrun_next;
      end
end

always @(posedge clk)
begin
    if(rx_wr & ~full_reg)
    begin
    rx_buf_array[wr_ptr_reg]      = {4'b0, rx_data_in} ;
    rx_buf_array[wr_ptr_reg][11]  = overrun_reg ;  //overrun error
    end
end

always @(*)
begin
      wr_ptr_next     = wr_ptr_reg ;
      rd_ptr_next     = rd_ptr_reg ;
      full_next       = full_reg   ;
      empty_next      = empty_reg  ;
      overrun_next    = overrun_reg;


      case({rx_rd, rx_wr})
        2'b01:  //write
            if(~full_reg)
              begin

                wr_ptr_next       =  wr_ptr_reg + 1  ;
                empty_next        =  1'b0 ;
                overrun_next      =  1'b0 ;
                if(wr_ptr_next == rd_ptr_reg)
                    full_next = 1'b1 ;
              end
            else
              overrun_next = 1'b1 ;
        2'b10:   //read
          if(~empty_reg)
            begin
              rd_ptr_next = rd_ptr_reg + 1 ;
              full_next   = 1'b0 ;
              if(rd_ptr_next == wr_ptr_reg)
              empty_next = 1'b1 ;
            end
        2'b11:  // read and write concurently
          begin
            wr_ptr_next = wr_ptr_reg + 1  ;
            rd_ptr_next = rd_ptr_reg + 1 ;
            if(rd_ptr_reg==wr_ptr_reg)
                rd_ptr_next = rd_ptr_reg ;
            if(full_reg)
              overrun_next = 1'b1 ;
          end

      endcase

end
assign interrupt = ((wr_ptr_reg - rd_ptr_reg)==interrupt_level)?1'b1:1'b0 ;
assign rx_status = {interrupt , overrun_reg, rx_data_in[10:8],empty_reg, full_reg } ;

endmodule // uart_tx_fifo
