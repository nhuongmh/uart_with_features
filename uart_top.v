`timescale 1ns / 1ps

module uart_top
(
  input clk, reset,
  input         rx,
  input [15:0]   uart_config,
  input [15:0]  uart_baudgen,
  input [15:0]  uart_data_write,
  input         uart_write,
  input         uart_read,
  input         uart_en,

  output        tx,
  output  [15:0]  uart_data_read ,
  output  [15:0]      uart_status 
);
//===========================================================================
  wire   [7:0]    trx_config;
  wire   [15:0]   baud_config ;
  wire   [2:0]    tx_fifo_config ;
  wire   [2:0]    rx_fifo_config ;
  wire   [6:0]    rxff_status ;
  wire   [3:0]    txff_status ;
  wire   [15:0]   rxff_data_out ;
  wire   [7:0]    txff_data_in  ;
  wire   [11:0]   data_from_rx  ;
  wire            rx_done      ;
  wire   [7:0]    data_to_tx    ;
  wire            tx_done       ;
  wire            tx_start     ;
  wire            tick         ;
  wire            txff_empty   ;
  wire            txff_write   ;
  wire            rxff_read   ;
  wire            baudgen_en  ;

//===========================================================================
  assign          tx_start = ~txff_empty ;
//===========================================================================
  uart_interface    UIF1
  (
    .clk              (clk),
    .reset            (reset),
    .config_reg_in    (uart_config),
    .baud_set_in      (uart_baudgen),
    .data_write_in    (uart_data_write),
    .data_read_in     (rxff_data_out),
    .uart_en          (uart_en),
    .uart_read        (uart_read),
    .uart_write       (uart_write) ,
    .tx_status        (txff_status),
    .rx_status        (rxff_status),

    .uart_status      (uart_status),
    .data_read_out    (uart_data_read),
    .inter_config     (trx_config),
    .inter_baud_set   (baud_config),
    .tx_write_out     (txff_write),
    .rx_read_out      (rxff_read),
    .data_write_out   (txff_data_in),
    .rx_lvff_int      (rx_fifo_config),
    .tx_lvff_int      (tx_fifo_config),
    .baudgen_en       (baudgen_en)
    ) ;
//==========================================================================//
  uart_baudgen     UBG1
  (
    .clk              (clk),
    .reset            (reset),
    .clk_en           (baudgen_en),
    .M                (baud_config),
    .tick_out         (tick)
    ) ;
//===========================================================================
  uart_rx           URX1
  (
    .UART_ICTLR       (trx_config),
    .clk              (clk),
    .reset            (reset),
    .tick             (tick),
    .rx               (rx),
    .rx_data_out      (data_from_rx),
    .rx_done          (rx_done)
    ) ;
//===========================================================================
  uart_rx_fifo        URF1
  (
    .clk              (clk),
    .reset            (reset),
    .rx_fifo_int      (rx_fifo_config),
    .rx_data_in       (data_from_rx),
    .rx_rd            (rxff_read),
    .rx_wr            (rx_done),
    .rx_data_out      (rxff_data_out),
    .rx_status         (rxff_status)
    ) ;
//===========================================================================
  uart_tx             UTX1
  (
    .UART_ICTLR       (trx_config),
    .clk              (clk),
    .reset            (reset),
    .start_tx         (tx_start),
    .tick             (tick),
    .data_in          (data_to_tx),
    .tx_done          (tx_done),
    .tx               (tx)
    ) ;
//===========================================================================
  uart_tx_fifo        UTF1
  (
    .clk              (clk),
    .reset            (reset),
    .tx_data_in       (txff_data_in),
    .tx_fifo_int      (tx_fifo_config),
    .tx_data_out      (data_to_tx),
    .tx_rd            (tx_done),
    .tx_wr            (txff_write),
    .txff_empty       (txff_empty),
    .tx_status        (txff_status)
    ) ;
//===========================================================================
    endmodule
