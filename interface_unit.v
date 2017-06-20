`timescale  1ns / 1ps

module uart_interface
(
  input               clk, reset,
  input     [15:0]    config_reg_in ,
  input     [15:0]    baud_set_in,
  input     [15:0]    data_write_in,
  input     [15:0]    data_read_in,
  input               uart_en,
  input               uart_read,
  input               uart_write,
  input     [3:0]     tx_status,
  input     [6:0]     rx_status,
  //input               rx_data_in,   //data from rx_fifo to UART_Interface

  output    [15:0]    uart_status,
  output    [15:0]    data_read_out,
  output    [7:0]     inter_config,
  output    [15:0]    inter_baud_set,
  output              tx_write_out,
  output              rx_read_out,
  output    [7:0]     data_write_out,
  output    [2:0]     rx_lvff_int,
  output    [2:0]     tx_lvff_int,
  output    reg       baudgen_en
  );

  localparam     [1:0]
                DISABLE = 2'b00,
                INIT    = 2'b01,
                RUNNING = 2'b10;
  reg       [1:0]     uart_state, uart_state_next    ;
  //reg       [15:0]    baud_set_reg, baud_set_next;
  reg       [7:0]     uart_config_reg, uart_config_next ;
  reg       [15:0]    uart_status_reg, uart_status_next ;


  assign inter_baud_set = baud_set_in ;
  assign tx_write_out   = uart_write  ;
  assign rx_read_out    = uart_read   ;
  assign data_write_out = data_write_in[7:0] ;
  assign data_read_out  = data_read_in ;
  assign rx_lvff_int    = config_reg_in[12:10] ;
  assign tx_lvff_int    = config_reg_in[9:7]  ;
initial begin
  uart_state      = DISABLE ;
  uart_state_next = DISABLE ;
  uart_status_reg = 16'b000000_10010_0000_0 ;
  uart_config_reg = 8'b111_0_1000 ;
  uart_config_next = 8'b111_0_1000  ; // default value
  baudgen_en      = 1'b0 ;
end
  always @(posedge clk or posedge reset)
  begin
      if(reset)
        begin
          uart_state      = DISABLE                 ;
          uart_status_reg = 16'b000000_10010_0000_0 ;
        //  baud_set_reg    = 16'h00                  ;
          uart_config_reg = 8'b111_0_1000           ;

        end
      else
        begin
        uart_state      = uart_state_next  ;
        uart_status_reg = uart_status_next ;
        uart_config_reg = uart_config_next ;
      //  baud_set_reg    = baud_set_next    ;

        end
  end

  always @(*)
  begin
      uart_state_next   = uart_state      ;
      uart_status_next   = uart_status_reg ;
      uart_config_next  = uart_config_reg ;
      //baud_set_next     = baud_set_reg    ;

      case(uart_state)

      DISABLE:
        begin

      //  baud_set_next    <= 16'h00                  ; // default (auto detect)
        if(uart_en)
          uart_state_next = INIT                  ;

        end
      INIT:
        begin
            uart_config_next[4:0] <= config_reg_in[4:0] ; //stop bit, even parity, parity_en, tx_en , rx en

          case(config_reg_in[6:5])
            2'b00: uart_config_next[7:5] <= 3'd4 ; // 5 bits data width
            2'b01: uart_config_next[7:5] <= 3'd5 ; // 6 bits
            2'b10: uart_config_next[7:5] <= 3'd6 ; // 7 bits
            2'b11: uart_config_next[7:5] <= 3'd7 ; // 8 bits
          endcase
            //uart_config_next[10:8]    <= config_reg_in[9:7] ; // tx interrupt fifo level select
            //uart_config_next[13:11]   <= config_reg_in[12:10] ; //rx interrupt fifo level select
          baudgen_en         <= 1'b1 ;
          #1 uart_state_next = RUNNING ;
          end

        RUNNING:
            begin
            if(~uart_en)
            uart_state_next = DISABLE ;
            uart_status_next[0]   <= 1'b1 ; // Running state
            uart_status_next[4:1] <= rx_status[5:2] ; // fe, pe, be, oe
            uart_status_next[5]   <= tx_status[0]   ; // busy flag
            uart_status_next[6]   <= rx_status[1]   ; // rx fifo empty flag
            uart_status_next[7]   <= tx_status[1]   ; //tx fifo full flag
            uart_status_next[8]   <= rx_status[0]   ; // rx fifo full flag
            uart_status_next[9]   <= tx_status[2]   ; //tx fifo empty flag
            uart_status_next[10]  <= tx_status[3]   ; // tx fifo interrupt
            uart_status_next[11]  <= rx_status[6]   ; // rx fifo interrupt
            uart_status_next[15:12] <= 4'b0000 ;

             end


    endcase
  end

  assign uart_status = {16'h0, uart_status_reg} ;
  assign inter_config = uart_config_reg ;

  endmodule
