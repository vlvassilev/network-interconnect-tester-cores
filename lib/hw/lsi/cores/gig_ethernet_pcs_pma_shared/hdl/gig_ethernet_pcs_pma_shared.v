`timescale 1 ps/1 ps

module gig_ethernet_pcs_pma_shared
   (      
      input wire  refclk625_in,
      output clk125_out,

      output clk312_out,


      output rst_125_out,
      output tx_logic_reset,
      output rx_logic_reset,
      output rx_locked,
      output tx_locked,
      output        tx_bsc_rst_out,
      output        rx_bsc_rst_out,
      output        tx_bs_rst_out,
      output        rx_bs_rst_out,
      output        tx_rst_dly_out,
      output        rx_rst_dly_out,
      output        tx_bsc_en_vtc_out,
      output        rx_bsc_en_vtc_out,
      output        tx_bs_en_vtc_out,
      output        rx_bs_en_vtc_out,
      output        riu_clk_out,
      output [5:0]  riu_addr_out,
      output [15:0] riu_wr_data_out, 
      output        riu_wr_en_out,
      output [1:0]  riu_nibble_sel_out,
      output        tx_pll_clk_out,
      output        rx_pll_clk_out,
      output        tx_rdclk_out,
      input [15:0]  riu_rddata_3,
      input         riu_valid_3,
      input         riu_prsnt_3,
      input [15:0]  riu_rddata_2,
      input         riu_valid_2,
      input         riu_prsnt_2,
      input [15:0]  riu_rddata_1,
      input         riu_valid_1,
      input         riu_prsnt_1,
      input [15:0]  riu_rddata_0,
      input         riu_valid_0,
      input         riu_prsnt_0,
      output [8:0]  rx_btval_3,
      output [8:0]  rx_btval_2,
      output [8:0]  rx_btval_1,
      output [8:0]  rx_btval_0,
      input  wire tx_dly_rdy_0,
      input  wire rx_dly_rdy_0,
      input  wire rx_vtc_rdy_0,
      input  wire tx_vtc_rdy_0,
      input  wire tx_dly_rdy_1,
      input  wire rx_dly_rdy_1,
      input  wire rx_vtc_rdy_1,
      input  wire tx_vtc_rdy_1,
      input  wire tx_dly_rdy_2,
      input  wire rx_dly_rdy_2,
      input  wire rx_vtc_rdy_2,
      input  wire tx_vtc_rdy_2,
      input  wire tx_dly_rdy_3,
      input  wire rx_dly_rdy_3,
      input  wire rx_vtc_rdy_3,
      input  wire tx_vtc_rdy_3,
      input         reset

   );

wire  tx_logic_rst_int;
wire  rx_logic_rst_int;

wire clk_125_i     ;
wire clk_312_i     ;

wire rst_125_i     ;

wire tx_bsc_rst;
wire rx_bsc_rst;
wire tx_bs_rst;
wire rx_bs_rst;
wire tx_rst_dly;
wire tx_bsc_en_vtc;
wire rx_bsc_en_vtc;
wire tx_bs_en_vtc ;
wire rx_bs_en_vtc ;
wire rx_rst_dly;
wire riu_clk;
wire [5:0] riu_addr;
wire [15:0] riu_wr_data;
wire riu_wr_en;
wire [1:0]  riu_nibble_sel;
wire tx_pll_clk;
wire rx_pll_clk;
wire tx_dly_rdy;
wire tx_vtc_rdy;
wire rx_dly_rdy;
wire rx_vtc_rdy;
wire tx_rdclk;     
wire clockin_se_out;
assign tx_bsc_rst_out      = tx_bsc_rst;
assign rx_bsc_rst_out      = rx_bsc_rst;
assign tx_bs_rst_out       = tx_bs_rst;
assign rx_bs_rst_out       = rx_bs_rst;
assign tx_rst_dly_out      = tx_rst_dly;
assign rx_rst_dly_out      = rx_rst_dly;
assign tx_bsc_en_vtc_out   = tx_bsc_en_vtc;
assign rx_bsc_en_vtc_out   = rx_bsc_en_vtc;
assign tx_bs_en_vtc_out    = tx_bs_en_vtc ;
assign rx_bs_en_vtc_out    = rx_bs_en_vtc ;
assign riu_clk_out         = riu_clk;
assign riu_addr_out        = riu_addr;
assign riu_wr_data_out     = riu_wr_data; 
assign riu_wr_en_out       = riu_wr_en;
assign riu_nibble_sel_out  = riu_nibble_sel;
assign tx_pll_clk_out      = tx_pll_clk;
assign rx_pll_clk_out      = rx_pll_clk;
assign tx_rdclk_out        = tx_rdclk;




assign tx_dly_rdy = tx_dly_rdy_0 & tx_dly_rdy_1 & tx_dly_rdy_2 & tx_dly_rdy_3;
assign tx_vtc_rdy = tx_vtc_rdy_0 & tx_vtc_rdy_1 & tx_vtc_rdy_2 & tx_vtc_rdy_3;
assign rx_dly_rdy = rx_dly_rdy_0 & rx_dly_rdy_1 & rx_dly_rdy_2 & rx_dly_rdy_3;
assign rx_vtc_rdy = rx_vtc_rdy_0 & rx_vtc_rdy_1 & rx_vtc_rdy_2 & rx_vtc_rdy_3;
assign tx_logic_reset = tx_logic_rst_int;
assign rx_logic_reset = rx_logic_rst_int;


assign logic_reset = tx_logic_rst_int || rx_logic_rst_int;

 gig_ethernet_pcs_pma_reset_sync_ex reset_sync_clk125_i (
    .clk       (clk_125_i),
    .reset_in  (logic_reset),
    .reset_out (rst_125_i));
 
 gig_ethernet_pcs_pma_clock_reset  # ( .example_simulation             (0) )  
clock_reset_i (
        .clockin             (refclk625_in),
 
        .clockin_se_out      (clockin_se_out),
        .resetin             (reset),
        .tx_dly_rdy          (tx_dly_rdy),
        .tx_vtc_rdy          (tx_vtc_rdy),
        .rx_dly_rdy          (rx_dly_rdy),
        .rx_vtc_rdy          (rx_vtc_rdy),
        .tx_bsc_envtc        (tx_bsc_en_vtc),
        .tx_bs_envtc         (tx_bs_en_vtc),
        .rx_bsc_envtc        (rx_bsc_en_vtc),
        .rx_bs_envtc         (rx_bs_en_vtc),
        .tx_sysclk           (tx_rdclk),// -- 312.5mhz
        .tx_wrclk            (clk_125_i),// -- 125 mhz
        .tx_clkoutphy        (tx_pll_clk),// -- 1250 mhz
        .rx_sysclk           (clk_312_i),// -- 312.5 mhz
        .rx_riuclk           (riu_clk),// -- 208 mhz
        .rx_clkoutphy        (rx_pll_clk),// -- 625 mhz
        .tx_locked           (tx_locked),
        .tx_bs_rstdly        (tx_rst_dly),
        .tx_bs_rst           (tx_bs_rst),
        .tx_bsc_rst          (tx_bsc_rst),
        .tx_logicrst         (tx_logic_rst_int),
        .rx_locked           (rx_locked),
        .rx_bs_rstdly        (rx_rst_dly),
        .rx_bs_rst           (rx_bs_rst),
        .rx_bsc_rst           (rx_bsc_rst),
        .rx_logicrst         (rx_logic_rst_int),
        .riu_addr            (riu_addr),
        .riu_wrdata          (riu_wr_data),
        .riu_rddata_0        (riu_rddata_0),
        .riu_valid_0         (riu_valid_0),
        .rx_btval_0          (rx_btval_0),
        .riu_prsnt_0         (riu_prsnt_0),
        .riu_wr_en           (riu_wr_en),
        .riu_nibble_sel      (riu_nibble_sel),
        .riu_rddata_3        (riu_rddata_3),
        .riu_valid_3         (riu_valid_3 ),
        .riu_prsnt_3         (riu_prsnt_3 ),
        .riu_rddata_2        (riu_rddata_2),
        .riu_valid_2         (riu_valid_2 ),
        .riu_prsnt_2         (riu_prsnt_2 ),
        .riu_rddata_1        (riu_rddata_1),
        .riu_valid_1         (riu_valid_1 ),
        .riu_prsnt_1         (riu_prsnt_1 ),
        .rx_btval_3          (rx_btval_3  ),
        .rx_btval_2          (rx_btval_2  ),
        .rx_btval_1          (rx_btval_1  ),
        .debug_out           ()
    );

assign rst_125_out = rst_125_i ;
assign clk125_out  = clk_125_i;

assign clk312_out  = clk_312_i;

endmodule // gig_ethernet_pcs_pma_shared
