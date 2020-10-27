`timescale 1ns / 1ps

module tb();
  localparam HALF_CLK_PERIOD = 0.8;

  // Should be updated according to the generated address map
  localparam [31:0] gmii_mux_0_address = 32'hA0200000;
  localparam [31:0] gmii_mux_1_address = 32'hA0210000;
  localparam [31:0] axi_ethernet_0_address = 32'hA0000000;
  localparam [31:0] tri_mode_ethernet_mac_2_address = 32'hA01E0000;
  localparam [31:0] traffic_generator_gmii_0_address = 32'hA0270000;
  localparam [31:0] traffic_analyzer_gmii_0_address = 32'hA0280000;
  reg aclk =1'b0;
  reg arstn = 1'b0;

  reg BT_ctsn;

  wire sfp_port_0_rxn;
  wire sfp_port_0_rxp;
  wire sfp_port_1_rxn;
  wire sfp_port_1_rxp;

  wire BT_ctsn;
  wire BT_rtsn;

  wire sfp_port_0_txn;
  wire sfp_port_0_txp;
  wire sfp_port_1_txn;
  wire sfp_port_1_txp;


  reg resp;
  reg [31:0] read_data;
  reg [63:0] read_data_64;
  reg [63:0] read_data_again_64;

  spark_wrapper spark_wrapper_i
       (.BT_ctsn(BT_ctsn),
        .BT_rtsn(BT_rtsn),
        .sfp_port_0_rxn(sfp_port_0_rxn),
        .sfp_port_0_rxp(sfp_port_0_rxp),
        .sfp_port_0_txn(sfp_port_0_txn),
        .sfp_port_0_txp(sfp_port_0_txp),
        .sfp_port_1_rxn(sfp_port_1_rxn),
        .sfp_port_1_rxp(sfp_port_1_rxp),
        .sfp_port_1_txn(sfp_port_1_txn),
        .sfp_port_1_txp(sfp_port_1_txp));

 // rеsеt
 initial begin
    arstn = 1'b0;
    #(HALF_CLK_PERIOD * 2*10);
    arstn = 1'b1;
    #(HALF_CLK_PERIOD * 2*10);

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
    #200;
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b0);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h1);
    #2000 ;  // This delay depends on your clock frequency. It should be at least 16 clock cycles.
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h0);
    #2000 ;

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h2);

    #20000 ;

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h0);

    #20000 ;

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h2);

    #20000 ;

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(32'h0);

    #1000 ;

    /* enable port0 traffic generator */
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(gmii_mux_0_address, 4, read_data, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(gmii_mux_0_address+8, 4, 32'h00000003, resp);

    /* enable port1 traffic generator */
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(gmii_mux_1_address, 4, read_data, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(gmii_mux_1_address+8, 4, 32'h00000003, resp);

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(gmii_mux_0_address+32'h00, 4, read_data, resp);
    $display("gmii_mux IP id (%x)", read_data);

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(traffic_generator_gmii_0_address+32'h00, 4, read_data, resp);
    $display("traffic_generator_gmii IP id (%x)", read_data);

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h0C, 4, 32'h12345678, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(traffic_generator_gmii_0_address+32'h0C, 4, read_data, resp);
    $display("traffic_generator_gmii FLIP reg (%x)", read_data);

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_analyzer_gmii_0_address+32'h0C, 4, 32'h12345678, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(traffic_analyzer_gmii_0_address+32'h0C, 4, read_data, resp);
    $display("traffic_analyzer_gmii FLIP reg (%x)", read_data);

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h14, 4, 32'h0000000C, resp); /* interframe gap */
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h44, 4, 32'h00000048, resp); /* layer 1 frame size */
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h55555555, resp); /* frame data */
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h555555d5, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h01020304, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h05060708, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h090a0b0c, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h0d0e0f10, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h11121314, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h15161718, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h191a1b1c, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h1d1e1f20, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h21222324, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h25262728, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h292a2b2c, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h2d2e2f30, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h31323334, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h35363738, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h393a3b3c, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h50, 4, 32'h344ca062, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h14, 4, 32'h0000000C, resp); /* interframe gap */


    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+16, 4, 32'h00000001, resp); /* set the enable bit reg control[0] */

    #50000 ;

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+16, 4, 32'h00000000, resp); /* clear the enable bit reg control[0] */

    #5000

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_generator_gmii_0_address+32'h0C, 4, 32'h12345678, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(traffic_generator_gmii_0_address+32'h0C, 4, read_data, resp);
    $display("traffic_generator_gmii FLIP reg (%x)", read_data);

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.write_data(traffic_analyzer_gmii_0_address+32'h0C, 4, 32'h12345678, resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(traffic_analyzer_gmii_0_address+32'h0C, 4, read_data, resp);
    $display("traffic_analyzer_gmii FLIP reg (%x)", read_data);

    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(traffic_analyzer_gmii_0_address+32'h28, 4, read_data_64[31:0], resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(traffic_analyzer_gmii_0_address+32'h2C, 4, read_data_64[63:32], resp);
    $display("traffic_analyzer_gmii OCTETS reg (%x)", read_data_64);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(traffic_analyzer_gmii_0_address+32'h30, 4, read_data_64[31:0], resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(traffic_analyzer_gmii_0_address+32'h34, 4, read_data_64[63:32], resp);
    $display("traffic_analyzer_gmii OCTETS_IDLE reg (%x)", read_data_64);


    // Read RX Good Frames counter pg051
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(axi_ethernet_0_address+32'h00000290, 4, read_data_64[31:0], resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(axi_ethernet_0_address+32'h00000294, 4, read_data_64[63:32], resp);

    if(read_data_64 < 2) begin
      $error("Too few frames received at eth0");
    end

    #5000

   // Read RX Good Frames counter pg051
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(axi_ethernet_0_address+32'h00000290, 4, read_data_again_64[31:0], resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(axi_ethernet_0_address+32'h00000294, 4, read_data_again_64[63:32], resp);

     if(read_data_again_64 != read_data_64) begin
      $error("No new frames expected");
     end

    // Read TX Good Frames counter pg051
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(axi_ethernet_0_address+32'h000002D8, 4, read_data_64[31:0], resp);
    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(axi_ethernet_0_address+32'h000002DC, 4, read_data_64[63:32], resp);

    // Read TX Good Frames counter pg051
//    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(tri_mode_ethernet_mac_2_address+32'h000002d8, 4, read_data_64[31:0], resp);
//    tb.spark_wrapper_i.spark_i.zynq_ultra_ps_e_0.inst.read_data(tri_mode_ethernet_mac_2_address+32'h000002dc, 4, read_data_64[63:32], resp);


    $finish;

 end


assign sfp_port_0_rxn = sfp_port_1_txn;
assign sfp_port_0_rxp = sfp_port_1_txp;
assign sfp_port_1_rxn = sfp_port_0_txn;
assign sfp_port_1_rxp = sfp_port_0_txp;

endmodule

