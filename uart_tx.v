
`timescale 1ns/1ps


module uart_tx
 (
 	input	[7:0]   UART_ICTLR ,
	input clk, reset,
	input start_tx,
	input tick,
	input [7:0] data_in,
  
	output reg tx_done,
	output tx 		);

wire 			 tx_en   = UART_ICTLR[1] ;
wire 			 pa_en   = UART_ICTLR[2] ;
wire 			 pa_ev	 = UART_ICTLR[3] ;
wire 			 STOP_B  = UART_ICTLR[4] ;
wire [2:0] DBIT 	 = UART_ICTLR[7:5] ;


localparam 			[2:0]
								IDLE 			= 3'b000,			// State
								START 		= 3'b001,
								DATA 			= 3'b010,
								PARITY		= 3'b011,
								STOP			= 3'b100;


reg [2:0]	state, state_next;
reg [3:0]	b_tick, b_next;					//counter for baudrate gen
reg [2:0]	n_bit, n_next;					//number of bits are transmitted
reg [7:0]	tx_reg, tx_reg_next;					// byte register to transmitt
reg 		tx1_reg, tx1_next	;
reg 		parity_bit ;

initial
begin
	state = IDLE ;
	state_next = IDLE ;
	b_tick = 4'h0 ;
	b_next = 4'h0 ;
	n_bit = 3'b0;
	n_next = 3'b0 ;
	tx_reg = 8'h0 ;
	tx_reg_next = 8'h0 ;
	tx1_reg = 1'b1 ;
	tx1_next = 1'b1 ;
	tx_done = 1'b1 ;
end
//===========================================================================
always @(posedge clk or posedge reset or posedge tx_en)
begin
if(tx_en)
				if(reset)
						begin
						state  			<= IDLE;
						b_tick 			<=  0;
						n_bit 			<=  0;
						tx_reg 			<=  0;
						tx1_reg			<= 1'b1;
						end
				else
						begin
						state 			<= state_next ;
						b_tick 			<= b_next ;
						n_bit 			<= n_next;
						tx_reg 			<= tx_reg_next ;
						tx1_reg 		<= tx1_next ;
						end

end
//============================================================================
always @(*)
begin
					state_next 		= state ;
					tx_done 			= 1'b0;
					b_next 				= b_tick;
					n_next				= n_bit;
					tx_reg_next			= tx_reg;
					tx1_next			= tx1_reg;

	case( state )
		IDLE: 	begin
							tx1_next = 1'b1;											// idle bit
								if(start_tx)
									begin
									state_next 			= START ;					//change state
									b_next 				= 1'b0;						//counter = 0 for idle
									tx_reg_next			= data_in;					//get data in to interal reg

									end
						end
		START: 	begin
							tx1_next = 1'b0;
								if(tick)
									if(b_tick == 15)								// if the time is up
										begin
											state_next 	= DATA;
											b_next 			= 	0;							//reset counter
											n_next			=  0;
										end
								 else
											b_next 			= b_tick + 1;
						end

		DATA: 	begin
							tx1_next = tx_reg[0];									// bit to transmitte
								if(tick)
								if(b_tick == 15)									//time is up?
									begin
											b_next 	= 0;										//reset counter
											tx_reg_next	= tx_reg >> 1;					//take bit one by one
											if(n_bit == (DBIT))					//if all bits are transmitted
												begin
												n_next = 0 ;
												if(pa_en)
													state_next = PARITY ;
												else
												state_next = STOP ;							//then go STOP
												end
										else
											n_next = n_bit + 1;
									end
							 else																	//if time is not up
				 		 			b_next = b_tick + 1;
						end
	PARITY:		begin
							tx1_next = (^data_in)^(~pa_ev) ;
							if(tick)
								if(b_tick == 15)
									begin
										b_next = 0 ;
										n_next = 0 ;
										state_next = STOP ;
										end
								else
									b_next = b_tick + 1 ;
				end

		STOP: 	begin
						tx1_next = 1'b1;													//stop bit
						if(tick)
							if(b_tick ==	 15)
								if(n_bit == STOP_B)
									begin
									state_next = IDLE;
									tx_done		 = 1'b1;									//anounce that a frame is transmitted
									end
								else
									n_next = n_bit + 1 ;
							else
								b_next = b_tick + 1;
					end

	endcase

end

assign tx = tx1_reg;

endmodule
