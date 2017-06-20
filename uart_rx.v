`timescale 1ns /1ps

module uart_rx
  (
    input   [7:0]   UART_ICTLR ,      
    input         clk, reset,
    input         tick,
    input         rx,
    output [11:0] rx_data_out,
    output rx_done                  ) ;
//============================================================================//
  wire       rx_en  = UART_ICTLR[0]    ;
  wire       pa_en  = UART_ICTLR[2]    ;
  wire       pa_ev  = UART_ICTLR[3]    ;
  wire       STOP_B = UART_ICTLR[4]    ;
  wire [2:0] DBIT   = UART_ICTLR[7:5]  ;

//============================================================================//
  localparam [2:0]
    IDLE      = 3'b000 ,
    START     = 3'b001 ,
    DATA      = 3'b010 ,
    PARITY    = 3'b011 ,
    STOP      = 3'b100 ;

  reg   [2:0] state,  next_state ;   // state register
  reg   [3:0] b_tick, b_next ;      // baud tick for baud rate
  reg   [2:0] n_bit, n_next ;       // number of bit that received
  reg   [11:0] rx_reg, rx_reg_next ; //internal register for store received bit
  reg         parity_error = 1'b0;
  reg         break_error  = 1'b0;
  reg         frame_error  = 1'b0;
  reg         rx_done_reg  = 1'b0;
  // rx_done_reg used for delay 1 clk after receive process has completed in order to update rx_reg
//============================================================================//
initial
begin
  state = IDLE ;
  b_tick = 4'h0 ;
  n_bit = 4'b0 ;
  rx_reg = 12'h0 ;
  end
//============================================================================//
always @(posedge clk or posedge reset or posedge rx_en)
begin
if(rx_en)
    if(reset)
      begin
        state   <= IDLE ;
        b_tick  <= 0    ;
        n_bit   <= 0    ;
        rx_reg  <= 0    ;
      end
    else
      begin
      state   <= next_state ;
      b_tick  <= b_next     ;
      n_bit   <= n_next     ;
      rx_reg  <= rx_reg_next;
      end

end
//============================================================================//
  always @(*)
    begin
    next_state  = state ;
    rx_done_reg = 1'b0  ;
    b_next      = b_tick;
    n_next      = n_bit ;
    rx_reg_next = rx_reg ;

    case(state)
    IDLE:
        begin
        if(~rx)
          begin
            next_state      = START ;
            b_next          = 0 ;
            rx_reg_next     = 0 ;
          end
        end
    START:
    begin
        if(tick)
          if(b_tick==7)
            begin
            next_state = DATA  ;
            b_next     = 0     ;
            n_next     = 0     ;
            end
          else
            b_next = b_tick + 1 ;
      end
    DATA:
    begin
        if(tick)
          if(b_tick == 15)
            begin
              b_next      = 0;
              rx_reg_next <= {4'b0, rx, rx_reg[7:1]} ;
              if(n_bit==(DBIT))
                begin
                  n_next      = 0 ;
                  if(pa_en)
                    next_state  = PARITY ;
                  else
                    next_state  = STOP   ;
                end
              else
                n_next  = n_bit + 1 ;
            end
          else
            b_next  = b_tick  + 1 ;
      end
      PARITY:
      begin
        if(tick)
          if(b_tick==15)
          begin
            b_next = 0 ;
            parity_error  = (^rx_reg[7:0]) ^ (~pa_ev) ^ rx ;
            break_error   = ((rx_reg[7:0]==8'b0) & (~rx)) ; //temp 
            next_state = STOP ;
          end
          else
              b_next = b_tick + 1 ;
      end
      STOP:
      begin
          if(tick)
            if(b_tick==15)
              begin
                b_next  = 0 ;
                break_error = break_error & (~rx) ;
                frame_error = frame_error | (~rx)    ;
                if(n_bit == STOP_B)
                  begin
                    n_next       = 0 ;
                    next_state  = IDLE ; 
                    rx_reg_next      =  {1'b0, break_error, parity_error, frame_error, rx_reg[7:0]} ;
                    rx_done_reg = 1'b1 ;
                  end
                else
                  n_next = n_bit + 1 ;
              end
            else
              b_next = b_tick + 1 ;
        end
      endcase
end
//============================================================================//
assign rx_done = rx_done_reg ;
assign rx_data_out = rx_reg  ;


endmodule // uart_rx
