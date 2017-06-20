`timescale 1ns / 1ps
module uart_top2
( 
	input clk,
	input	start,
	input 	rx,
	output	tx,
	output	[7:0] data_out_1,
	output	test 
	)

wire tick ;
wire	tx_done ;
wire data_out ;
wire 	rx_done ;

assign 	data_out_1 = data_out[7:0] ;
assign	test = 1'b1 ;
uart_tx		UTX2
(
	.UART_ICTLR (8'b11100011),
	.clk	(clk),
	.reset	(1'b0),
	.start_tx	(start),
	.tick		(tick),
	.data_in	(8'h41),
	.tx_done	(tx_done),
	.tx 		(tx)
	) ;
uart_rx 	URX2
(
	.UART_ICTLR (8'b11100011),
	.clk (clk),
	.reset (1'b0),
	.tick	(tick),
	.rx 	(rx),
	.rx_data_out (data_out),
	.rx_done 	(rx_done)
	) ;

baud_gen		BG2
( .clk	(clk),
	.reset (1'b0 ),
	.clk_en	(1'b1),
	.M 		(16'd27),
	.tick_out (tick)
	) ;

endmodule
