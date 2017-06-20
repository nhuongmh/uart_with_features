`timescale 1ns / 1ps

module uart_tx_fifo
  (
  input         clk, reset ,
  input   [7:0] tx_data_in,
  input   [2:0] tx_fifo_int,

  output  [7:0] tx_data_out,
  input   tx_rd, tx_wr ,
  output         txff_empty,
  output  [3:0]  tx_status
  );

parameter   W = 4 ;  // number of address line

reg [7:0]     tx_buf_array [2**W-1:0] ;
reg [W-1:0]   wr_ptr_reg, wr_ptr_next ;  //write pointer reg/next/accepted
reg [W-1:0]   rd_ptr_reg, rd_ptr_next ; //read pointer
reg   full_reg, empty_reg, full_next, empty_next;
reg  [3:0]     interrupt_level  ;
wire          interrupt ;


assign tx_data_out = tx_buf_array[rd_ptr_reg] ;           //NTC

initial begin
 #1 case(tx_fifo_int)
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
  wr_ptr_reg  = 4'h0 ;
  rd_ptr_reg  = 4'h0 ;
  full_reg    = 1'b0 ;
  empty_reg   = 1'b1 ;
end

always @(posedge clk or posedge reset)
begin
    if(reset)
      begin
      wr_ptr_reg <= 4'h0 ;
      rd_ptr_reg <= 4'h0;
      full_reg   <= 1'b0 ;
      empty_reg  <= 1'b1 ;

      end
    else
      begin
      wr_ptr_reg  <= wr_ptr_next ;
      rd_ptr_reg  <= rd_ptr_next ;
      full_reg    <= full_next   ;
      empty_reg   <= empty_next  ;

      end
end

always @(posedge clk)
begin
    if(tx_wr & ~full_reg)
    tx_buf_array[wr_ptr_reg] <= tx_data_in ;
end

always @(*)
begin
      wr_ptr_next = wr_ptr_reg ;
      rd_ptr_next = rd_ptr_reg ;
      full_next   = full_reg   ;
      empty_next  = empty_reg  ;

      case({tx_rd, tx_wr})
        2'b01:  //write
            if(~full_reg)
            begin
              wr_ptr_next  =  wr_ptr_reg + 1  ;
              empty_next   =  1'b0 ;
              if(wr_ptr_next == rd_ptr_reg)
              full_next = 1'b1 ;
            end
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
          end

      endcase

end
assign interrupt  = ((wr_ptr_reg - rd_ptr_reg)==interrupt_level)?1'b1:1'b0 ;
assign tx_status  = {interrupt, empty_reg, full_reg, ~empty_reg} ;
assign txff_empty = empty_reg ;


endmodule // uart_tx_fifo
