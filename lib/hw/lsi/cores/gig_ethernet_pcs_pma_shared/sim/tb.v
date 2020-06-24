`timescale 1ns / 1ps

module tb();
  localparam HALF_CLK_PERIOD = 0.8;

  reg ref_clk_625mhz_clk=1'b0;

  wire refclk625_in;
  wire clk125_out;

  wire clk312_out;


  wire rst_125_out;
  wire tx_logic_reset;
  wire rx_logic_reset;
  wire rx_locked;
  wire tx_locked;
  wire        tx_bsc_rst_out;
  wire        rx_bsc_rst_out;
  wire        tx_bs_rst_out;
  wire        rx_bs_rst_out;
  wire        tx_rst_dly_out;
  wire        rx_rst_dly_out;
  wire        tx_bsc_en_vtc_out;
  wire        rx_bsc_en_vtc_out;
  wire        tx_bs_en_vtc_out;
  wire        rx_bs_en_vtc_out;
  wire        riu_clk_out;
  wire [5:0]  riu_addr_out;
  wire [15:0] riu_wr_data_out; 
  wire        riu_wr_en_out;
  wire [1:0]  riu_nibble_sel_out;
  wire        tx_pll_clk_out;
  wire        rx_pll_clk_out;
  wire        tx_rdclk_out;
  wire [15:0]  riu_rddata_3;
  wire         riu_valid_3;
  wire         riu_prsnt_3;
  wire [15:0]  riu_rddata_2;
  wire         riu_valid_2;
  wire         riu_prsnt_2;
  wire [15:0]  riu_rddata_1;
  wire         riu_valid_1;
  wire         riu_prsnt_1;
  wire [8:0]  rx_btval_3;
  wire [8:0]  rx_btval_2;
  wire [8:0]  rx_btval_1;
  wire tx_dly_rdy_1;
  wire rx_dly_rdy_1;
  wire rx_vtc_rdy_1;
  wire tx_vtc_rdy_1;
  wire tx_dly_rdy_2;
  wire rx_dly_rdy_2;
  wire rx_vtc_rdy_2;
  wire tx_vtc_rdy_2;
  wire tx_dly_rdy_3;
  wire rx_dly_rdy_3;
  wire rx_vtc_rdy_3;
  wire tx_vtc_rdy_3;
  reg         reset=1'b0;

  reg resp;

gig_ethernet_pcs_pma_shared gig_ethernet_pcs_pma_shared_i
   (      
     .refclk625_in(refclk625_in),
     .clk125_out(clk125_out),

     .clk312_out(clk312_out),


     .rst_125_out(rst_125_out),
     .tx_logic_reset(tx_logic_reset),
     .rx_logic_reset(rx_logic_reset),
     .rx_locked(rx_locked),
     .tx_locked(tx_locked),
     .tx_bsc_rst_out(tx_bsc_rst_out),
     .rx_bsc_rst_out(rx_bsc_rst_out),
     .tx_bs_rst_out(tx_bs_rst_out),
     .rx_bs_rst_out(rx_bs_rst_out),
     .tx_rst_dly_out(tx_rst_dly_out),
     .rx_rst_dly_out(rx_rst_dly_out),
     .tx_bsc_en_vtc_out(tx_bsc_en_vtc_out),
     .rx_bsc_en_vtc_out(rx_bsc_en_vtc_out),
     .tx_bs_en_vtc_out(tx_bs_en_vtc_out),
     .rx_bs_en_vtc_out(rx_bs_en_vtc_out),
     .riu_clk_out(riu_clk_out),
     .riu_addr_out(riu_addr_out),
     .riu_wr_data_out(riu_wr_data_out),
     .riu_wr_en_out(riu_wr_en_out),
     .riu_nibble_sel_out(riu_nibble_sel_out),
     .tx_pll_clk_out(tx_pll_clk_out),
     .rx_pll_clk_out(rx_pll_clk_out),
     .tx_rdclk_out(tx_rdclk_out),
     .riu_rddata_3(riu_rddata_3),
     .riu_valid_3(riu_valid_3),
     .riu_prsnt_3(riu_prsnt_3),
     .riu_rddata_2(riu_rddata_2),
     .riu_valid_2(riu_valid_2),
     .riu_prsnt_2(riu_prsnt_2),
     .riu_rddata_1(riu_rddata_1),
     .riu_valid_1(riu_valid_1),
     .riu_prsnt_1(riu_prsnt_1),
     .rx_btval_3(rx_btval_3),
     .rx_btval_2(rx_btval_2),
     .rx_btval_1(rx_btval_1),
     .tx_dly_rdy_1(tx_dly_rdy_1),
     .rx_dly_rdy_1(rx_dly_rdy_1),
     .rx_vtc_rdy_1(rx_vtc_rdy_1),
     .tx_vtc_rdy_1(tx_vtc_rdy_1),
     .tx_dly_rdy_2(tx_dly_rdy_2),
     .rx_dly_rdy_2(rx_dly_rdy_2),
     .rx_vtc_rdy_2(rx_vtc_rdy_2),
     .tx_vtc_rdy_2(tx_vtc_rdy_2),
     .tx_dly_rdy_3(tx_dly_rdy_3),
     .rx_dly_rdy_3(rx_dly_rdy_3),
     .rx_vtc_rdy_3(rx_vtc_rdy_3),
     .tx_vtc_rdy_3(tx_vtc_rdy_3),
     .reset(reset)
   );
 
 // rеsеt
 initial begin
    reset = 1'b0;
    #(HALF_CLK_PERIOD * 2*10);
    reset = 1'b1;
    #(HALF_CLK_PERIOD * 2*10);

    #200;

 end

//clk
always
begin
    #(HALF_CLK_PERIOD) ref_clk_625mhz_clk <= ~ref_clk_625mhz_clk;
        ref_clk_625mhz_clk <= ~ref_clk_625mhz_clk;
end

assign refclk625_in = ref_clk_625mhz_clk;

endmodule
