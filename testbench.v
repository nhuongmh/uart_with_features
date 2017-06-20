`timescale 1ns/1ps

module testbench;
reg 	clk ;
reg 	rst ;

reg [15:0]	baud_register;
reg 		read;
reg 		write ;

reg  [7:0]	trx_config ;
wire 		tx_done ;
wire		tx ;
wire		tx_start ;
wire 		txff_empty ;
reg 		[15:0] uart_config ;
reg [15:0]	data_write ;
reg 		uart_en;
wire [15:0]	uart_status ;
wire [15:0] uart_data_read ;


 	uart_top 		UART
 	(
 	.clk 				(clk),
 	.reset 			 	(rst),
 	.rx 				(tx),
 	.uart_config 		(uart_config),
 	.uart_baudgen 			(baud_register),
 	.uart_data_write	(data_write),
 	.uart_write 		(write),
 	.uart_read			(read),
 	.uart_en 			(uart_en),
 	.tx 				(tx),
 	.uart_status 		(uart_status),
 	.uart_data_read		(uart_data_read)
 		) ;
initial
begin
	clk = 1'b0;
	rst = 1'b0;
	baud_register = 16'd27 ;	// 115200 baud
	uart_config	= 16'h096f ; 
	data_write 	 = 16'd00;
	#4000 read 		 = 1'b1 ;
	trx_config = 8'he2 ;
	uart_en		= 1'b1 ;
end

always 
forever #10 clk = ~ clk ;	// 50 Mhz

initial
	begin
	#20 data_write = 32'h0061;		//1
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h005c;		//2
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h00da;		//3
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h00e2;		//4
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h0023;		//5
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h00ad;		//6
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h00aff;		//7
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h0055;		//8
		write =  1'b1 ;
	#20	write =  1'b0 ;		
	#20 data_write = 32'h00aa;		//9
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h0055;		//10
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h00aa;		//11
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h0055;		//12
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h00aa;		//13
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h0055;		//14
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h00aa;		//15
		write =  1'b1 ;
	#20	write =  1'b0 ;
	#20 data_write = 32'h0055;		//16
		write =  1'b1 ;
	#20	write =  1'b0 ;

	end

endmodule 