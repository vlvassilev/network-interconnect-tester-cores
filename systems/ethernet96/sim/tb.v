`timescale 1ns / 1ps

module axi_eth_v1_tb();
  localparam HALF_CLK_PERIOD = 0.8;

  reg aclk =1'b0;
  reg arstn = 1'b0;

  reg BT_ctsn;
  wire mdio_mdio_io;
  wire [7:0]phy_gpio_tri_io;

  wire sgmii_port_0_rxn;
  wire sgmii_port_0_rxp;
  reg sgmii_port_1_rxn;
  reg sgmii_port_1_rxp;
  wire sgmii_port_2_rxn;
  wire sgmii_port_2_rxp;
  reg sgmii_port_3_rx_rxn;
  reg sgmii_port_3_rx_rxp;
  reg sgmii_port_3_tx_rxn;
  reg sgmii_port_3_tx_rxp;


  wire BT_ctsn;
  wire BT_rtsn;
  wire mdio_mdc;
  wire mdio_mdio_i;
  wire mdio_mdio_io;
  wire mdio_mdio_o;
  wire mdio_mdio_t;

  wire [0:7]phy_gpio_tri_io;
  wire [0:0]reset_port_0_n;
  wire [0:0]reset_port_1_n;
  wire [0:0]reset_port_2_n;
  wire reset_port_3_n;
  wire sgmii_port_0_txn;
  wire sgmii_port_0_txp;
  wire sgmii_port_1_txn;
  wire sgmii_port_1_txp;

  wire sgmii_port_2_txn;
  wire sgmii_port_2_txp;

  wire sgmii_port_3_rx_txn;
  wire sgmii_port_3_rx_txp;
  wire sgmii_port_3_tx_rxn;
  wire sgmii_port_3_tx_rxp;
  wire sgmii_port_3_tx_txn;
  wire sgmii_port_3_tx_txp;

  reg resp;
  reg [31:0] read_data;

  axi_eth_v1_wrapper axi_eth_v1_wrapper_i
       (.BT_ctsn(BT_ctsn),
        .BT_rtsn(BT_rtsn),
        .mdio_mdc(mdio_mdc),
        .mdio_mdio_io(mdio_mdio_io),
        .phy_gpio_tri_io(phy_gpio_tri_io),
        .reset_port_0_n(reset_port_0_n),
        .reset_port_1_n(reset_port_1_n),
        .reset_port_2_n(reset_port_2_n),
        .reset_port_3_n(reset_port_3_n),
        .sgmii_port_0_rxn(sgmii_port_0_rxn),
        .sgmii_port_0_rxp(sgmii_port_0_rxp),
        .sgmii_port_0_txn(sgmii_port_0_txn),
        .sgmii_port_0_txp(sgmii_port_0_txp),
        .sgmii_port_1_rxn(sgmii_port_1_rxn),
        .sgmii_port_1_rxp(sgmii_port_1_rxp),
        .sgmii_port_1_txn(sgmii_port_1_txn),
        .sgmii_port_1_txp(sgmii_port_1_txp),
        .sgmii_port_2_rxn(sgmii_port_2_rxn),
        .sgmii_port_2_rxp(sgmii_port_2_rxp),
        .sgmii_port_2_txn(sgmii_port_2_txn),
        .sgmii_port_2_txp(sgmii_port_2_txp),
        .sgmii_port_3_rx_rxn(sgmii_port_3_rx_rxn),
        .sgmii_port_3_rx_rxp(sgmii_port_3_rx_rxp),
        .sgmii_port_3_rx_txn(sgmii_port_3_rx_txn),
        .sgmii_port_3_rx_txp(sgmii_port_3_rx_txp),
        .sgmii_port_3_tx_rxn(sgmii_port_3_tx_rxn),
        .sgmii_port_3_tx_rxp(sgmii_port_3_tx_rxp),
        .sgmii_port_3_tx_txn(sgmii_port_3_tx_txn),
        .sgmii_port_3_tx_txp(sgmii_port_3_tx_txp));
 
 // rеsеt
 initial begin
    arstn = 1'b0;
    #(HALF_CLK_PERIOD * 2*10);
    arstn = 1'b1;
    #(HALF_CLK_PERIOD * 2*10);

    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
    #200;
    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b0);
    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h1);
    #2000 ;  // This delay depends on your clock frequency. It should be at least 16 clock cycles.
    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h0);
    #2000 ;

    //This drives the pl_resetn1 GPIO output (bank 5, bit 30)
    /* set GPIO_DIRM_BANK_5 bit 30 */
    //axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.write_data(32'hFF0A0344, 4, 32'h40000000, resp);
    /* set GPIO_OPEN_BANK_5 bit 30 */
    //axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.write_data(32'hFF0A0348, 4, 32'h40000000, resp);
    /* set GPIO_DATA_BANK_5 bit 30 */
    //axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.write_data(32'hFF0A0054, 4, 32'h40000000, resp);
    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h2);

    #20000 ;

    /* clear GPIO_DATA_BANK_5 bit 30 */
    //axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.write_data(32'hFF0A0054, 4, 32'h00000000, resp);
    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h0);

    #20000 ;

    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h2);

    #20000 ;

    /* clear GPIO_DATA_BANK_5 bit 30 */
    //axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.write_data(32'hFF0A0054, 4, 32'h00000000, resp);
    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h0);

    //This drives the LEDs on the GPIO output
    //tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.write_data(32'hA0000000,4, 32'hFFFFFFFF, resp);
    //tb.axi_eth_v1_wrapper_i.axi_eth_v1_i..zynq_ultra_ps_e_0.inst.read_data(32'hA0000000,4, read_data, resp);


    /* enable port0 line loopback */
    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.read_data(32'hA0180000, 4, read_data, resp);
    axi_eth_v1_tb.axi_eth_v1_wrapper_i.axi_eth_v1_i.zynq_ultra_ps_e_0.inst.write_data(32'hA0180008, 4, 32'h00000000, resp);
 end


assign sgmii_port_2_rxn = sgmii_port_0_txn;
assign sgmii_port_2_rxp = sgmii_port_0_txp;
assign sgmii_port_0_rxn = sgmii_port_2_txn;
assign sgmii_port_0_rxp = sgmii_port_2_txp;

endmodule
