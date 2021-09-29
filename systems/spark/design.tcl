################################################################
# Block diagram build script
################################################################
# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

create_bd_design $design_name

current_bd_design $design_name

set parentCell [get_bd_cells /]

# Get object for parentCell
set parentObj [get_bd_cells $parentCell]
if { $parentObj == "" } {
   puts "ERROR: Unable to find parent cell <$parentCell>!"
   return
}

# Make sure parentObj is hier blk
set parentType [get_property TYPE $parentObj]
if { $parentType ne "hier" } {
   puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
   return
}

# Save current instance; Restore later
set oldCurInst [current_bd_instance .]

# Set parent object as current
current_bd_instance $parentObj

# Add the Processor System and apply board preset
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]

# Enable GP0, HP0 and GPIO EMIO
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {1} \
CONFIG.PSU__USE__M_AXI_GP1 {0} \
CONFIG.PSU__USE__M_AXI_GP2 {0} \
CONFIG.PSU__USE__S_AXI_GP2 {1} \
CONFIG.PSU__USE__IRQ0 {1} \
CONFIG.PSU__USE__IRQ1 {1} \
CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {1} \
CONFIG.PSU__GPIO_EMIO__PERIPHERAL__IO {8} \
CONFIG.PSU__UART0__MODEM__ENABLE {1} \
CONFIG.PSU__NUM_FABRIC_RESETS {3}] [get_bd_cells zynq_ultra_ps_e_0]

# Add the Ethernet PCS/PMA cores
create_bd_cell -type ip -vlnv xilinx.com:ip:gig_ethernet_pcs_pma eth_pcs_pma_0_1
create_bd_cell -type ip -vlnv xilinx.com:ip:gig_ethernet_pcs_pma eth_pcs_pma_3_4_5_rx_4_tx
create_bd_cell -type ip -vlnv xilinx.com:ip:gig_ethernet_pcs_pma eth_pcs_pma_2_rx
create_bd_cell -type ip -vlnv xilinx.com:ip:gig_ethernet_pcs_pma eth_pcs_pma_2_3_5_tx
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:gig_ethernet_pcs_pma_shared:1.0 eth_pcs_pma_shared

# Ports 0 and 1 configuration: Asynchronous
set_property -dict [list CONFIG.Standard {1000BASEX} \
CONFIG.Ext_Management_Interface {true} \
CONFIG.EMAC_IF_TEMAC {TEMAC} \
CONFIG.SupportLevel {Include_Shared_Logic_in_Example_Design} \
CONFIG.NumOfLanes {2} \
CONFIG.TxLane0_Placement {DIFF_PAIR_0} \
CONFIG.TxLane1_Placement {DIFF_PAIR_2} \
CONFIG.RxLane0_Placement {DIFF_PAIR_1} \
CONFIG.RxLane1_Placement {DIFF_PAIR_0} \
CONFIG.Tx_In_Upper_Nibble {0} \
CONFIG.ClockSelection {Async} \
CONFIG.Ext_Management_Interface {true} \
CONFIG.Auto_Negotiation {true}] [get_bd_cells eth_pcs_pma_0_1]

# Port 4 + Port 3,5 (RX only) configuration: Asynchronous
set_property -dict [list CONFIG.Standard {1000BASEX} \
CONFIG.Ext_Management_Interface {true} \
CONFIG.EMAC_IF_TEMAC {TEMAC} \
CONFIG.SupportLevel {Include_Shared_Logic_in_Example_Design} \
CONFIG.NumOfLanes {3} \
CONFIG.TxLane0_Placement {DIFF_PAIR_1} \
CONFIG.TxLane1_Placement {DIFF_PAIR_0} \
CONFIG.RxLane0_Placement {DIFF_PAIR_1} \
CONFIG.RxLane1_Placement {DIFF_PAIR_2} \
CONFIG.Tx_In_Upper_Nibble {1} \
CONFIG.InstantiateBitslice0 {true} \
CONFIG.RxNibbleBitslice0Used {false} \
CONFIG.ClockSelection {Async} \
CONFIG.Ext_Management_Interface {true} \
CONFIG.Auto_Negotiation {true}] [get_bd_cells eth_pcs_pma_3_4_5_rx_4_tx]

# Port 2 (RX Only) configuration: Asynchronous, Auto-neg disabled
set_property -dict [list CONFIG.Standard {1000BASEX} \
CONFIG.Ext_Management_Interface {true} \
CONFIG.EMAC_IF_TEMAC {TEMAC} \
CONFIG.SupportLevel {Include_Shared_Logic_in_Example_Design} \
CONFIG.NumOfLanes {1} \
CONFIG.TxLane0_Placement {DIFF_PAIR_0} \
CONFIG.RxLane0_Placement {DIFF_PAIR_0} \
CONFIG.Tx_In_Upper_Nibble {0} \
CONFIG.ClockSelection {Async} \
CONFIG.Ext_Management_Interface {true} \
CONFIG.Auto_Negotiation {false}] [get_bd_cells eth_pcs_pma_2_rx]

# Port 2,3,5 (TX Only) configuration: Asynchronous, Auto-neg disabled
set_property -dict [list CONFIG.Standard {1000BASEX} \
CONFIG.Ext_Management_Interface {true} \
CONFIG.EMAC_IF_TEMAC {TEMAC} \
CONFIG.SupportLevel {Include_Shared_Logic_in_Example_Design} \
CONFIG.NumOfLanes {3} \
CONFIG.TxLane0_Placement {DIFF_PAIR_1} \
CONFIG.TxLane1_Placement {DIFF_PAIR_2} \
CONFIG.RxLane0_Placement {DIFF_PAIR_1} \
CONFIG.RxLane1_Placement {DIFF_PAIR_2} \
CONFIG.Tx_In_Upper_Nibble {0} \
CONFIG.ClockSelection {Async} \
CONFIG.Ext_Management_Interface {true} \
CONFIG.Auto_Negotiation {false}] [get_bd_cells eth_pcs_pma_2_3_5_tx]

# Add the Lightside Instruments AS IP cores
#create_bd_cell -type ip -vlnv lightside-instruments.com:ip:rate_limiter:2.0 rate_limiter_2
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:gmii_mux:1.0 gmii_mux_0
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:gmii_mux:1.0 gmii_mux_1
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:gmii_mux:1.0 gmii_mux_2
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:gmii_mux:1.0 gmii_mux_3
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:gmii_mux:1.0 gmii_mux_4
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:gmii_mux:1.0 gmii_mux_5
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:gmii_mux:1.0 gmii_mux_6
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:traffic_generator_gmii:1.0 traffic_generator_gmii_0
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:traffic_generator_gmii:1.0 traffic_generator_gmii_1
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:traffic_analyzer_gmii:1.0 traffic_analyzer_gmii_0
create_bd_cell -type ip -vlnv lightside-instruments.com:ip:rtclock:1.0 rtclock_0

# Add the AXI Ethernet Subsystem cores
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_2
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_3
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_4
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_5

# Add the AXI DMAs
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_ethernet_0_dma
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_ethernet_1_dma
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_ethernet_2_dma
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_ethernet_3_dma
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_ethernet_4_dma
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_ethernet_5_dma

# Port 0 configuration
set_property -dict [list CONFIG.Include_IO {false} \
CONFIG.TXCSUM {Full} \
CONFIG.RXCSUM {Full} \
CONFIG.Frame_Filter {false} \
CONFIG.axisclkrate {100}] [get_bd_cells axi_ethernet_0]

# Port 1 configuration
set_property -dict [list CONFIG.Include_IO {false} \
CONFIG.TXCSUM {Full} \
CONFIG.RXCSUM {Full} \
CONFIG.Frame_Filter {false} \
CONFIG.axisclkrate {100}] [get_bd_cells axi_ethernet_1]

# Port 2 configuration
set_property -dict [list CONFIG.Include_IO {false} \
CONFIG.TXCSUM {Full} \
CONFIG.RXCSUM {Full} \
CONFIG.Frame_Filter {false} \
CONFIG.axisclkrate {100}] [get_bd_cells axi_ethernet_2]

# Port 3 configuration
set_property -dict [list CONFIG.Include_IO {false} \
CONFIG.TXCSUM {Full} \
CONFIG.RXCSUM {Full} \
CONFIG.Frame_Filter {false} \
CONFIG.axisclkrate {100}] [get_bd_cells axi_ethernet_3]

# Port 4 configuration
set_property -dict [list CONFIG.Include_IO {false} \
CONFIG.TXCSUM {Full} \
CONFIG.RXCSUM {Full} \
CONFIG.Frame_Filter {false} \
CONFIG.axisclkrate {100}] [get_bd_cells axi_ethernet_4]

# Port 5 configuration
set_property -dict [list CONFIG.Include_IO {false} \
CONFIG.TXCSUM {Full} \
CONFIG.RXCSUM {Full} \
CONFIG.Frame_Filter {false} \
CONFIG.axisclkrate {100}] [get_bd_cells axi_ethernet_5]

# DMA configuration
set_property -dict [list CONFIG.c_sg_length_width {16} \
CONFIG.c_include_mm2s_dre {1} \
CONFIG.c_sg_use_stsapp_length {1} \
CONFIG.c_include_s2mm_dre {1}] [get_bd_cells axi_ethernet_0_dma]
set_property -dict [list CONFIG.c_sg_length_width {16} \
CONFIG.c_include_mm2s_dre {1} \
CONFIG.c_sg_use_stsapp_length {1} \
CONFIG.c_include_s2mm_dre {1}] [get_bd_cells axi_ethernet_1_dma]
set_property -dict [list CONFIG.c_sg_length_width {16} \
CONFIG.c_include_mm2s_dre {1} \
CONFIG.c_sg_use_stsapp_length {1} \
CONFIG.c_include_s2mm_dre {1}] [get_bd_cells axi_ethernet_2_dma]
set_property -dict [list CONFIG.c_sg_length_width {16} \
CONFIG.c_include_mm2s_dre {1} \
CONFIG.c_sg_use_stsapp_length {1} \
CONFIG.c_include_s2mm_dre {1}] [get_bd_cells axi_ethernet_3_dma]
set_property -dict [list CONFIG.c_sg_length_width {16} \
CONFIG.c_include_mm2s_dre {1} \
CONFIG.c_sg_use_stsapp_length {1} \
CONFIG.c_include_s2mm_dre {1}] [get_bd_cells axi_ethernet_4_dma]
set_property -dict [list CONFIG.c_sg_length_width {16} \
CONFIG.c_include_mm2s_dre {1} \
CONFIG.c_sg_use_stsapp_length {1} \
CONFIG.c_include_s2mm_dre {1}] [get_bd_cells axi_ethernet_5_dma]

## Rate limiter
#set_property -dict [list CONFIG.C_M_AXIS_DATA_WIDTH {32} \
#CONFIG.C_S_AXIS_DATA_WIDTH {32} \
#CONFIG.C_M_AXIS_TUSER_WIDTH {32} \
#CONFIG.C_S_AXIS_TUSER_WIDTH {32}] [get_bd_cells rate_limiter_2]

# Constant for the AXI Ethernet clk_en signal
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_clk_en
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0x01}] [get_bd_cells const_clk_en]
connect_bd_net [get_bd_pins const_clk_en/dout] [get_bd_pins axi_ethernet_0/clk_en]
connect_bd_net [get_bd_pins const_clk_en/dout] [get_bd_pins axi_ethernet_1/clk_en]
connect_bd_net [get_bd_pins const_clk_en/dout] [get_bd_pins axi_ethernet_2/clk_en]
connect_bd_net [get_bd_pins const_clk_en/dout] [get_bd_pins axi_ethernet_3/clk_en]
connect_bd_net [get_bd_pins const_clk_en/dout] [get_bd_pins axi_ethernet_4/clk_en]
connect_bd_net [get_bd_pins const_clk_en/dout] [get_bd_pins axi_ethernet_5/clk_en]

# GMII connections for ports 0,1 and 4
#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0/gmii] [get_bd_intf_pins eth_pcs_pma_0_1/gmii_pcs_pma_0]
#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_1/gmii] [get_bd_intf_pins eth_pcs_pma_0_1/gmii_pcs_pma_1]
#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_4/gmii] [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_pcs_pma_1]

# GMII connections for port 2
# Connect GMII RX interface of port 2
##connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rxclk_0] [get_bd_pins axi_ethernet_2/gmii_rx_clk]
#connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_dv_0] [get_bd_pins axi_ethernet_2/gmii_rx_dv]
#connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_er_0] [get_bd_pins axi_ethernet_2/gmii_rx_er]
#connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rxd_0] [get_bd_pins axi_ethernet_2/gmii_rxd]

# Connect GMII TX interface of port 2
##connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_txclk_0] [get_bd_pins axi_ethernet_2/gmii_tx_clk]
#connect_bd_net [get_bd_pins axi_ethernet_2/gmii_tx_en] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_en_0]
#connect_bd_net [get_bd_pins axi_ethernet_2/gmii_tx_er] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_dv_0]
#connect_bd_net [get_bd_pins axi_ethernet_2/gmii_txd] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_txd_0]

# GMII connections for port 3
# Connect GMII RX interface of port 3
#connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxclk_0] [get_bd_pins axi_ethernet_3/gmii_rx_clk]
#connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_0] [get_bd_pins axi_ethernet_3/gmii_rx_dv]
#connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_0] [get_bd_pins axi_ethernet_3/gmii_rx_er]
#connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_0] [get_bd_pins axi_ethernet_3/gmii_rxd]

# Connect GMII TX interface of port 3
#connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_txclk_1] [get_bd_pins axi_ethernet_3/gmii_tx_clk]
#connect_bd_net [get_bd_pins axi_ethernet_3/gmii_tx_en] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_en_1]
#connect_bd_net [get_bd_pins axi_ethernet_3/gmii_tx_er] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_er_1]
#connect_bd_net [get_bd_pins axi_ethernet_3/gmii_txd] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_txd_1]

# GMII connections for port 5
# Connect GMII RX interface of port 5
#connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxclk_2] [get_bd_pins axi_ethernet_5/gmii_rx_clk]
#connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_2] [get_bd_pins axi_ethernet_5/gmii_rx_dv]
#connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_2] [get_bd_pins axi_ethernet_5/gmii_rx_er]
#connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_2] [get_bd_pins axi_ethernet_5/gmii_rxd]

# Connect GMII TX interface of port 5
#connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_txclk_2] [get_bd_pins axi_ethernet_5/gmii_tx_clk]
#connect_bd_net [get_bd_pins axi_ethernet_5/gmii_tx_en] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_en_2]
#connect_bd_net [get_bd_pins axi_ethernet_5/gmii_tx_er] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_er_2]
#connect_bd_net [get_bd_pins axi_ethernet_5/gmii_txd] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_txd_2]

# eth_pcs_pma_2_rx to eth_pcs_pma_2_3_5_tx
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bsc_rst_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/tx_bsc_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bsc_rst_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/rx_bsc_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bs_rst_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/tx_bs_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bs_rst_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/rx_bs_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_rst_dly_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/tx_rst_dly]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_rst_dly_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/rx_rst_dly]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_clk_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/riu_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_wr_en_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/riu_wr_en]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_pll_clk_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/tx_pll_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_pll_clk_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/rx_pll_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_rdclk_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/tx_rdclk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_addr_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/riu_addr]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_wr_data_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/riu_wr_data]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_nibble_sel_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/riu_nibble_sel]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_btval_3] [get_bd_pins eth_pcs_pma_2_3_5_tx/rx_btval]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bsc_en_vtc_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/tx_bsc_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bsc_en_vtc_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/rx_bsc_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bs_en_vtc_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/tx_bs_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bs_en_vtc_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/rx_bs_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/clk125m]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk312_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/clk312]

# eth_pcs_pma_shared to eth_pcs_pma_2_rx
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bsc_rst_out] [get_bd_pins eth_pcs_pma_2_rx/tx_bsc_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bsc_rst_out] [get_bd_pins eth_pcs_pma_2_rx/rx_bsc_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bs_rst_out] [get_bd_pins eth_pcs_pma_2_rx/tx_bs_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bs_rst_out] [get_bd_pins eth_pcs_pma_2_rx/rx_bs_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_rst_dly_out] [get_bd_pins eth_pcs_pma_2_rx/tx_rst_dly]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_rst_dly_out] [get_bd_pins eth_pcs_pma_2_rx/rx_rst_dly]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_clk_out] [get_bd_pins eth_pcs_pma_2_rx/riu_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_wr_en_out] [get_bd_pins eth_pcs_pma_2_rx/riu_wr_en]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_pll_clk_out] [get_bd_pins eth_pcs_pma_2_rx/tx_pll_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_pll_clk_out] [get_bd_pins eth_pcs_pma_2_rx/rx_pll_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_rdclk_out] [get_bd_pins eth_pcs_pma_2_rx/tx_rdclk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_addr_out] [get_bd_pins eth_pcs_pma_2_rx/riu_addr]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_wr_data_out] [get_bd_pins eth_pcs_pma_2_rx/riu_wr_data]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_nibble_sel_out] [get_bd_pins eth_pcs_pma_2_rx/riu_nibble_sel]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_btval_0] [get_bd_pins eth_pcs_pma_2_rx/rx_btval]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bsc_en_vtc_out] [get_bd_pins eth_pcs_pma_2_rx/tx_bsc_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bsc_en_vtc_out] [get_bd_pins eth_pcs_pma_2_rx/rx_bsc_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bs_en_vtc_out] [get_bd_pins eth_pcs_pma_2_rx/tx_bs_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bs_en_vtc_out] [get_bd_pins eth_pcs_pma_2_rx/rx_bs_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins eth_pcs_pma_2_rx/clk125m]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk312_out] [get_bd_pins eth_pcs_pma_2_rx/clk312]

# eth_pcs_pma_shared to eth_pcs_pma_3_4_5_rx_4_tx
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bsc_rst_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/tx_bsc_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bsc_rst_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/rx_bsc_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bs_rst_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/tx_bs_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bs_rst_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/rx_bs_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_rst_dly_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/tx_rst_dly]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_rst_dly_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/rx_rst_dly]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_clk_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/riu_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_wr_en_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/riu_wr_en]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_pll_clk_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/tx_pll_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_pll_clk_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/rx_pll_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_rdclk_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/tx_rdclk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_addr_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/riu_addr]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_wr_data_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/riu_wr_data]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_nibble_sel_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/riu_nibble_sel]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_btval_2] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/rx_btval]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bsc_en_vtc_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/tx_bsc_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bsc_en_vtc_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/rx_bsc_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bs_en_vtc_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/tx_bs_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bs_en_vtc_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/rx_bs_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/clk125m]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk312_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/clk312]

# eth_pcs_pma_shared to eth_pcs_pma_0_1
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bsc_rst_out] [get_bd_pins eth_pcs_pma_0_1/tx_bsc_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bsc_rst_out] [get_bd_pins eth_pcs_pma_0_1/rx_bsc_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bs_rst_out] [get_bd_pins eth_pcs_pma_0_1/tx_bs_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bs_rst_out] [get_bd_pins eth_pcs_pma_0_1/rx_bs_rst]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_rst_dly_out] [get_bd_pins eth_pcs_pma_0_1/tx_rst_dly]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_rst_dly_out] [get_bd_pins eth_pcs_pma_0_1/rx_rst_dly]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_clk_out] [get_bd_pins eth_pcs_pma_0_1/riu_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_wr_en_out] [get_bd_pins eth_pcs_pma_0_1/riu_wr_en]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_pll_clk_out] [get_bd_pins eth_pcs_pma_0_1/tx_pll_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_pll_clk_out] [get_bd_pins eth_pcs_pma_0_1/rx_pll_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_rdclk_out] [get_bd_pins eth_pcs_pma_0_1/tx_rdclk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_addr_out] [get_bd_pins eth_pcs_pma_0_1/riu_addr]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_wr_data_out] [get_bd_pins eth_pcs_pma_0_1/riu_wr_data]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/riu_nibble_sel_out] [get_bd_pins eth_pcs_pma_0_1/riu_nibble_sel]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_btval_1] [get_bd_pins eth_pcs_pma_0_1/rx_btval]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bsc_en_vtc_out] [get_bd_pins eth_pcs_pma_0_1/tx_bsc_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bsc_en_vtc_out] [get_bd_pins eth_pcs_pma_0_1/rx_bsc_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/tx_bs_en_vtc_out] [get_bd_pins eth_pcs_pma_0_1/tx_bs_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rx_bs_en_vtc_out] [get_bd_pins eth_pcs_pma_0_1/rx_bs_en_vtc]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins eth_pcs_pma_0_1/clk125m]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk312_out] [get_bd_pins eth_pcs_pma_0_1/clk312]

# Shared logic connections
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/riu_rd_data] [get_bd_pins eth_pcs_pma_shared/riu_rddata_1]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/riu_valid] [get_bd_pins eth_pcs_pma_shared/riu_valid_1]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/riu_rd_data] [get_bd_pins eth_pcs_pma_shared/riu_rddata_2]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/riu_valid] [get_bd_pins eth_pcs_pma_shared/riu_valid_2]
connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/riu_rd_data] [get_bd_pins eth_pcs_pma_shared/riu_rddata_3]
connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/riu_valid] [get_bd_pins eth_pcs_pma_shared/riu_valid_3]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/riu_rd_data] [get_bd_pins eth_pcs_pma_shared/riu_rddata_0]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/riu_valid] [get_bd_pins eth_pcs_pma_shared/riu_valid_0]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/riu_prsnt] [get_bd_pins eth_pcs_pma_shared/riu_prsnt_1]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/riu_prsnt] [get_bd_pins eth_pcs_pma_shared/riu_prsnt_2]
connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/riu_prsnt] [get_bd_pins eth_pcs_pma_shared/riu_prsnt_3]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/riu_prsnt] [get_bd_pins eth_pcs_pma_shared/riu_prsnt_0]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/tx_dly_rdy] [get_bd_pins eth_pcs_pma_shared/tx_dly_rdy_1]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/rx_dly_rdy] [get_bd_pins eth_pcs_pma_shared/rx_dly_rdy_1]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/tx_vtc_rdy] [get_bd_pins eth_pcs_pma_shared/tx_vtc_rdy_1]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/rx_vtc_rdy] [get_bd_pins eth_pcs_pma_shared/rx_vtc_rdy_1]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/tx_dly_rdy] [get_bd_pins eth_pcs_pma_shared/tx_dly_rdy_2]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/rx_dly_rdy] [get_bd_pins eth_pcs_pma_shared/rx_dly_rdy_2]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/tx_vtc_rdy] [get_bd_pins eth_pcs_pma_shared/tx_vtc_rdy_2]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/rx_vtc_rdy] [get_bd_pins eth_pcs_pma_shared/rx_vtc_rdy_2]
connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/tx_dly_rdy] [get_bd_pins eth_pcs_pma_shared/tx_dly_rdy_3]
connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/rx_dly_rdy] [get_bd_pins eth_pcs_pma_shared/rx_dly_rdy_3]
connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/tx_vtc_rdy] [get_bd_pins eth_pcs_pma_shared/tx_vtc_rdy_3]
connect_bd_net [get_bd_pins eth_pcs_pma_2_3_5_tx/rx_vtc_rdy] [get_bd_pins eth_pcs_pma_shared/rx_vtc_rdy_3]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/tx_dly_rdy] [get_bd_pins eth_pcs_pma_shared/tx_dly_rdy_0]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/rx_dly_rdy] [get_bd_pins eth_pcs_pma_shared/rx_dly_rdy_0]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/tx_vtc_rdy] [get_bd_pins eth_pcs_pma_shared/tx_vtc_rdy_0]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/rx_vtc_rdy] [get_bd_pins eth_pcs_pma_shared/rx_vtc_rdy_0]

# Clocks
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_0/axis_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_1/axis_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_2/axis_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_3/axis_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_4/axis_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_5/axis_clk]
#connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins rate_limiter_2/axis_aclk]

connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins axi_ethernet_0/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins axi_ethernet_1/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins axi_ethernet_2/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins axi_ethernet_3/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins axi_ethernet_4/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins axi_ethernet_5/gtx_clk]

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_0/s_axi_lite_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_1/s_axi_lite_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_2/s_axi_lite_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_3/s_axi_lite_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_4/s_axi_lite_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_5/s_axi_lite_clk]

connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins traffic_generator_gmii_0/clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins traffic_generator_gmii_1/clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins traffic_analyzer_gmii_0/clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins rtclock_0/clk]

# Resets
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic reset_invert
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells reset_invert]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic dcd0_invert
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells dcd0_invert]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic dcd1_invert
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells dcd1_invert]

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn1] [get_bd_pins reset_invert/Op1]
connect_bd_net [get_bd_pins reset_invert/Res] [get_bd_pins eth_pcs_pma_shared/reset]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rst_125_out] [get_bd_pins eth_pcs_pma_0_1/reset]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rst_125_out] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/reset]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rst_125_out] [get_bd_pins eth_pcs_pma_2_3_5_tx/reset]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/rst_125_out] [get_bd_pins eth_pcs_pma_2_rx/reset]

# Constants for the PHY addresses
# ------------------------------------------------
# PCS/PMA PHYs have addresses: 1 and 2 (for ports 2,3,5 where separate rx and tx pcs/pma blocks are needed)
# Note that ports 2,3,5 have two PCS/PMA PHYs
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_phyaddr_0
set_property -dict [list CONFIG.CONST_WIDTH {5} CONFIG.CONST_VAL {0x01}] [get_bd_cells const_phyaddr_0]
connect_bd_net [get_bd_pins const_phyaddr_0/dout] [get_bd_pins eth_pcs_pma_0_1/phyaddr_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_phyaddr_1
set_property -dict [list CONFIG.CONST_WIDTH {5} CONFIG.CONST_VAL {0x01}] [get_bd_cells const_phyaddr_1]
connect_bd_net [get_bd_pins const_phyaddr_1/dout] [get_bd_pins eth_pcs_pma_0_1/phyaddr_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_phyaddr_2_rx
set_property -dict [list CONFIG.CONST_WIDTH {5} CONFIG.CONST_VAL {0x01}] [get_bd_cells const_phyaddr_2_rx]
connect_bd_net [get_bd_pins const_phyaddr_2_rx/dout] [get_bd_pins eth_pcs_pma_2_rx/phyaddr_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_phyaddr_2_tx
set_property -dict [list CONFIG.CONST_WIDTH {5} CONFIG.CONST_VAL {0x02}] [get_bd_cells const_phyaddr_2_tx]
connect_bd_net [get_bd_pins const_phyaddr_2_tx/dout] [get_bd_pins eth_pcs_pma_2_3_5_tx/phyaddr_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_phyaddr_3_rx
set_property -dict [list CONFIG.CONST_WIDTH {5} CONFIG.CONST_VAL {0x01}] [get_bd_cells const_phyaddr_3_rx]
connect_bd_net [get_bd_pins const_phyaddr_3_rx/dout] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/phyaddr_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_phyaddr_3_tx
set_property -dict [list CONFIG.CONST_WIDTH {5} CONFIG.CONST_VAL {0x02}] [get_bd_cells const_phyaddr_3_tx]
connect_bd_net [get_bd_pins const_phyaddr_3_tx/dout] [get_bd_pins eth_pcs_pma_2_3_5_tx/phyaddr_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_phyaddr_4
set_property -dict [list CONFIG.CONST_WIDTH {5} CONFIG.CONST_VAL {0x01}] [get_bd_cells const_phyaddr_4]
connect_bd_net [get_bd_pins const_phyaddr_4/dout] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/phyaddr_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_phyaddr_5_rx
set_property -dict [list CONFIG.CONST_WIDTH {5} CONFIG.CONST_VAL {0x01}] [get_bd_cells const_phyaddr_5_rx]
connect_bd_net [get_bd_pins const_phyaddr_5_rx/dout] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/phyaddr_2]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_phyaddr_5_tx
set_property -dict [list CONFIG.CONST_WIDTH {5} CONFIG.CONST_VAL {0x02}] [get_bd_cells const_phyaddr_5_tx]
connect_bd_net [get_bd_pins const_phyaddr_5_tx/dout] [get_bd_pins eth_pcs_pma_2_3_5_tx/phyaddr_2]

# signal_detect tied HIGH
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_signal_detect
connect_bd_net [get_bd_pins const_signal_detect/dout] [get_bd_pins eth_pcs_pma_0_1/signal_detect_0]
connect_bd_net [get_bd_pins const_signal_detect/dout] [get_bd_pins eth_pcs_pma_0_1/signal_detect_1]
connect_bd_net [get_bd_pins const_signal_detect/dout] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/signal_detect_0]
connect_bd_net [get_bd_pins const_signal_detect/dout] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/signal_detect_1]
connect_bd_net [get_bd_pins const_signal_detect/dout] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/signal_detect_2]
connect_bd_net [get_bd_pins const_signal_detect/dout] [get_bd_pins eth_pcs_pma_2_rx/signal_detect_0]
connect_bd_net [get_bd_pins const_signal_detect/dout] [get_bd_pins eth_pcs_pma_2_3_5_tx/signal_detect_0]
connect_bd_net [get_bd_pins const_signal_detect/dout] [get_bd_pins eth_pcs_pma_2_3_5_tx/signal_detect_1]
connect_bd_net [get_bd_pins const_signal_detect/dout] [get_bd_pins eth_pcs_pma_2_3_5_tx/signal_detect_2]

# Create SFP ports
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp_port_0
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_0_1/sfp_0] [get_bd_intf_ports sfp_port_0]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp_port_1
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_0_1/sfp_1] [get_bd_intf_ports sfp_port_1]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp_port_2_tx
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp_port_2_rx
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp_port_3_tx
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp_port_3_rx
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp_port_4
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp_port_5_tx
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp_port_5_rx
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/sfp_0] [get_bd_intf_ports sfp_port_3_rx]
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/sfp_1] [get_bd_intf_ports sfp_port_4]
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/sfp_2] [get_bd_intf_ports sfp_port_5_rx]
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_2_3_5_tx/sfp_0] [get_bd_intf_ports sfp_port_2_tx]
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_2_3_5_tx/sfp_1] [get_bd_intf_ports sfp_port_3_tx]
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_2_3_5_tx/sfp_2] [get_bd_intf_ports sfp_port_5_tx]
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_2_rx/sfp_0] [get_bd_intf_ports sfp_port_2_rx]

# Create MDIO port
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 mdio
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0/mdio] [get_bd_intf_pins eth_pcs_pma_0_1/mdio_pcs_pma_0]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_1/mdio] [get_bd_intf_pins eth_pcs_pma_0_1/mdio_pcs_pma_1]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_2/mdio] [get_bd_intf_pins eth_pcs_pma_2_rx/mdio_pcs_pma_0]
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_2_rx/ext_mdio_pcs_pma_0] [get_bd_intf_pins eth_pcs_pma_2_3_5_tx/mdio_pcs_pma_0]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_3/mdio] [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/mdio_pcs_pma_0]
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/ext_mdio_pcs_pma_0] [get_bd_intf_pins eth_pcs_pma_2_3_5_tx/mdio_pcs_pma_1]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_4/mdio] [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/mdio_pcs_pma_1]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_5/mdio] [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/mdio_pcs_pma_2]
connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/ext_mdio_pcs_pma_2] [get_bd_intf_pins eth_pcs_pma_2_3_5_tx/mdio_pcs_pma_2]

# Connect the tri-state inputs for the MDIO bus
connect_bd_net [get_bd_pins axi_ethernet_0/mdio_mdio_t] [get_bd_pins eth_pcs_pma_0_1/mdio_t_in_0]
connect_bd_net [get_bd_pins axi_ethernet_1/mdio_mdio_t] [get_bd_pins eth_pcs_pma_0_1/mdio_t_in_1]
connect_bd_net [get_bd_pins axi_ethernet_2/mdio_mdio_t] [get_bd_pins eth_pcs_pma_2_rx/mdio_t_in_0]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/ext_mdio_t_0] [get_bd_pins eth_pcs_pma_2_3_5_tx/mdio_t_in_0]
connect_bd_net [get_bd_pins axi_ethernet_3/mdio_mdio_t] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/mdio_t_in_0]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/ext_mdio_t_0] [get_bd_pins eth_pcs_pma_2_3_5_tx/mdio_t_in_1]
connect_bd_net [get_bd_pins axi_ethernet_4/mdio_mdio_t] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/mdio_t_in_1]
connect_bd_net [get_bd_pins axi_ethernet_5/mdio_mdio_t] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/mdio_t_in_2]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/ext_mdio_t_2] [get_bd_pins eth_pcs_pma_2_3_5_tx/mdio_t_in_2]

# Create the ref clk 625MHz port
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk_625mhz
#set_property CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ [get_bd_intf_pins eth_pcs_pma_shared/refclk625_in]] [get_bd_intf_ports ref_clk_625mhz]
#connect_bd_intf_net [get_bd_intf_pins eth_pcs_pma_shared/refclk625_in] [get_bd_intf_ports ref_clk_625mhz]

# pps (1 sec) signal from GPS e.g. gpsclock4ultra96 or aes-acc-u96-me-mez + MIKROE-2670
create_bd_port -dir I ls_mezz_int0
create_bd_port -dir I ls_mezz_int1

# ref clk (10 MHz) signal from GPS e.g. gpsclock4ultra96
create_bd_port -dir I -type clk -freq_hz 10000000 ref_clk_10mhz

# PHY RESET for ports 0,1 and 2
##create_bd_port -dir O reset_port_0_n
##connect_bd_net [get_bd_ports reset_port_0_n] [get_bd_pins axi_ethernet_0/phy_rst_n]
##create_bd_port -dir O reset_port_1_n
##connect_bd_net [get_bd_ports reset_port_1_n] [get_bd_pins axi_ethernet_1/phy_rst_n]
##create_bd_port -dir O reset_port_2_n
##connect_bd_net [get_bd_ports reset_port_2_n] [get_bd_pins axi_ethernet_2/phy_rst_n]

# PHY RESET for port 3:
# We connect PHY3 to fabric reset pl_resetn2 so that we can control it from software, rather than connecting it to
# axi_ethernet_3/phy_rst_n which is asserted whenever the AXI Ethernet is reset (occurs for example when running 
# ifconfig eth3 up). We need to have control of the reset because PHY3 provides the 625MHz clock driving ALL ports,
# so we don't want it to go down at the wrong time.
##create_bd_port -dir O reset_port_3_n
##connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn2] [get_bd_ports reset_port_3_n]

# Create port for the PHY GPIOs
##create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 phy_gpio
##connect_bd_intf_net [get_bd_intf_ports phy_gpio] [get_bd_intf_pins zynq_ultra_ps_e_0/GPIO_0]

# PS GP0 and HP0 port clocks
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk]

# DMA Connections
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0_dma/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_0/s_axis_txd]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0_dma/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_0/s_axis_txc]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0/m_axis_rxd] [get_bd_intf_pins axi_ethernet_0_dma/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0/m_axis_rxs] [get_bd_intf_pins axi_ethernet_0_dma/S_AXIS_STS]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_1_dma/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_1/s_axis_txd]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_1_dma/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_1/s_axis_txc]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_1/m_axis_rxd] [get_bd_intf_pins axi_ethernet_1_dma/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_1/m_axis_rxs] [get_bd_intf_pins axi_ethernet_1_dma/S_AXIS_STS]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_2_dma/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_2/s_axis_txd]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_2_dma/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_2/s_axis_txc]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_2/m_axis_rxd] [get_bd_intf_pins axi_ethernet_2_dma/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_2/m_axis_rxs] [get_bd_intf_pins axi_ethernet_2_dma/S_AXIS_STS]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_3_dma/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_3/s_axis_txd]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_3_dma/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_3/s_axis_txc]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_3/m_axis_rxd] [get_bd_intf_pins axi_ethernet_3_dma/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_3/m_axis_rxs] [get_bd_intf_pins axi_ethernet_3_dma/S_AXIS_STS]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_4_dma/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_4/s_axis_txd]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_4_dma/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_4/s_axis_txc]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_4/m_axis_rxd] [get_bd_intf_pins axi_ethernet_4_dma/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_4/m_axis_rxs] [get_bd_intf_pins axi_ethernet_4_dma/S_AXIS_STS]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_5_dma/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_5/s_axis_txd]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_5_dma/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_5/s_axis_txc]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_5/m_axis_rxd] [get_bd_intf_pins axi_ethernet_5_dma/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins axi_ethernet_5/m_axis_rxs] [get_bd_intf_pins axi_ethernet_5_dma/S_AXIS_STS]

connect_bd_net [get_bd_pins axi_ethernet_0_dma/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_0_dma/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txc_arstn]
connect_bd_net [get_bd_pins axi_ethernet_0_dma/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_0_dma/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxs_arstn]
connect_bd_net [get_bd_pins axi_ethernet_1_dma/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_1/axi_txd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_1_dma/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_1/axi_txc_arstn]
connect_bd_net [get_bd_pins axi_ethernet_1_dma/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_1/axi_rxd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_1_dma/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_1/axi_rxs_arstn]
connect_bd_net [get_bd_pins axi_ethernet_2_dma/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_2/axi_txd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_2_dma/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_2/axi_txc_arstn]
connect_bd_net [get_bd_pins axi_ethernet_2_dma/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_2/axi_rxd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_2_dma/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_2/axi_rxs_arstn]
connect_bd_net [get_bd_pins axi_ethernet_3_dma/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_3/axi_txd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_3_dma/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_3/axi_txc_arstn]
connect_bd_net [get_bd_pins axi_ethernet_3_dma/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_3/axi_rxd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_3_dma/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_3/axi_rxs_arstn]
connect_bd_net [get_bd_pins axi_ethernet_4_dma/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_4/axi_txd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_4_dma/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_4/axi_txc_arstn]
connect_bd_net [get_bd_pins axi_ethernet_4_dma/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_4/axi_rxd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_4_dma/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_4/axi_rxs_arstn]
connect_bd_net [get_bd_pins axi_ethernet_5_dma/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_5/axi_txd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_5_dma/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_5/axi_txc_arstn]
connect_bd_net [get_bd_pins axi_ethernet_5_dma/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_5/axi_rxd_arstn]
connect_bd_net [get_bd_pins axi_ethernet_5_dma/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_5/axi_rxs_arstn]


connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_0_dma/m_axi_sg_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_0_dma/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_0_dma/m_axi_s2mm_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_1_dma/m_axi_sg_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_1_dma/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_1_dma/m_axi_s2mm_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_2_dma/m_axi_sg_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_2_dma/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_2_dma/m_axi_s2mm_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_3_dma/m_axi_sg_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_3_dma/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_3_dma/m_axi_s2mm_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_4_dma/m_axi_sg_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_4_dma/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_4_dma/m_axi_s2mm_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_5_dma/m_axi_sg_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_5_dma/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_5_dma/m_axi_s2mm_aclk]

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_0_dma/s_axi_lite_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_1_dma/s_axi_lite_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_2_dma/s_axi_lite_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_3_dma/s_axi_lite_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_4_dma/s_axi_lite_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_ethernet_5_dma/s_axi_lite_aclk]

# Concats for the interrupts

#irq0
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0
set_property -dict [list CONFIG.NUM_PORTS {8}] [get_bd_cells xlconcat_0]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0]

connect_bd_net [get_bd_pins axi_ethernet_0/mac_irq] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins axi_ethernet_0/interrupt] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins axi_ethernet_0_dma/mm2s_introut] [get_bd_pins xlconcat_0/In2]
connect_bd_net [get_bd_pins axi_ethernet_0_dma/s2mm_introut] [get_bd_pins xlconcat_0/In3]

connect_bd_net [get_bd_pins axi_ethernet_1/mac_irq] [get_bd_pins xlconcat_0/In4]
connect_bd_net [get_bd_pins axi_ethernet_1/interrupt] [get_bd_pins xlconcat_0/In5]
connect_bd_net [get_bd_pins axi_ethernet_1_dma/mm2s_introut] [get_bd_pins xlconcat_0/In6]
connect_bd_net [get_bd_pins axi_ethernet_1_dma/s2mm_introut] [get_bd_pins xlconcat_0/In7]


#irq1
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_1
set_property -dict [list CONFIG.NUM_PORTS {8}] [get_bd_cells xlconcat_1]
connect_bd_net [get_bd_pins xlconcat_1/dout] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq1]

# We need more then 16 interrupts (pl_ps_irq0 with max 8 is already used so on (pl_ps_irq1 we use axi intc IP core to cascade more then 8.
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_0

connect_bd_net [get_bd_pins axi_intc_0/irq] [get_bd_pins xlconcat_1/In0]


create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_1_0
set_property -dict [list CONFIG.NUM_PORTS {12}] [get_bd_cells xlconcat_1_0]
connect_bd_net [get_bd_pins xlconcat_1_0/dout] [get_bd_pins axi_intc_0/intr]


connect_bd_net [get_bd_pins axi_ethernet_2/mac_irq] [get_bd_pins xlconcat_1_0/In0]
connect_bd_net [get_bd_pins axi_ethernet_2/interrupt] [get_bd_pins xlconcat_1_0/In1]
connect_bd_net [get_bd_pins axi_ethernet_2_dma/mm2s_introut] [get_bd_pins xlconcat_1_0/In2]
connect_bd_net [get_bd_pins axi_ethernet_2_dma/s2mm_introut] [get_bd_pins xlconcat_1_0/In3]
connect_bd_net [get_bd_pins axi_ethernet_3/mac_irq] [get_bd_pins xlconcat_1_0/In4]
connect_bd_net [get_bd_pins axi_ethernet_3/interrupt] [get_bd_pins xlconcat_1_0/In5]
connect_bd_net [get_bd_pins axi_ethernet_3_dma/mm2s_introut] [get_bd_pins xlconcat_1_0/In6]
connect_bd_net [get_bd_pins axi_ethernet_3_dma/s2mm_introut] [get_bd_pins xlconcat_1_0/In7]

#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_2
#set_property -dict [list CONFIG.NUM_PORTS {8}] [get_bd_cells xlconcat_2]
#connect_bd_net [get_bd_pins xlconcat_2/dout] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq1]

# Connect eth4 directly to GIC
connect_bd_net [get_bd_pins axi_ethernet_4/mac_irq] [get_bd_pins xlconcat_1/In1]
connect_bd_net [get_bd_pins axi_ethernet_4/interrupt] [get_bd_pins xlconcat_1/In2]
connect_bd_net [get_bd_pins axi_ethernet_4_dma/mm2s_introut] [get_bd_pins xlconcat_1/In3]
connect_bd_net [get_bd_pins axi_ethernet_4_dma/s2mm_introut] [get_bd_pins xlconcat_1/In4]

connect_bd_net [get_bd_pins axi_ethernet_5/mac_irq] [get_bd_pins xlconcat_1_0/In8]
connect_bd_net [get_bd_pins axi_ethernet_5/interrupt] [get_bd_pins xlconcat_1_0/In9]
connect_bd_net [get_bd_pins axi_ethernet_5_dma/mm2s_introut] [get_bd_pins xlconcat_1_0/In10]
connect_bd_net [get_bd_pins axi_ethernet_5_dma/s2mm_introut] [get_bd_pins xlconcat_1_0/In11]

# Automation for the S_AXI interfaces of the AXI Ethernet ports
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_0/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0/s_axi]
set_property range 256K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_ethernet_0_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_1/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_ethernet_1/s_axi]
set_property range 256K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_ethernet_1_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_2/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_ethernet_2/s_axi]
set_property range 256K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_ethernet_2_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_3/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_ethernet_3/s_axi]
set_property range 256K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_ethernet_3_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_4/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_ethernet_4/s_axi]
set_property range 256K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_ethernet_4_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_5/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_ethernet_5/s_axi]
set_property range 256K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_axi_ethernet_5_Reg0}]
#apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/rate_limiter_2/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins rate_limiter_2/s_axi]
#set_property range 256K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_rate_limiter_2_Reg0}]

# Automation for the S_AXI interfaces of the AXI DMAs
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_0_dma/S_AXI_LITE} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_1_dma/S_AXI_LITE} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_1_dma/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_2_dma/S_AXI_LITE} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_2_dma/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_3_dma/S_AXI_LITE} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_3_dma/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_4_dma/S_AXI_LITE} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_4_dma/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_ethernet_5_dma/S_AXI_LITE} intc_ip {/ps8_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_5_dma/S_AXI_LITE]

# Automation for the M_AXI interfaces of the AXI DMAs
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {Auto} Master {/axi_ethernet_0_dma/M_AXI_SG} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {Auto} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_0_dma/M_AXI_MM2S} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_MM2S]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_0_dma/M_AXI_S2MM} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_S2MM]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_1_dma/M_AXI_SG} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_1_dma/M_AXI_SG]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_1_dma/M_AXI_MM2S} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_1_dma/M_AXI_MM2S]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_1_dma/M_AXI_S2MM} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_1_dma/M_AXI_S2MM]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_4_dma/M_AXI_SG} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_4_dma/M_AXI_SG]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_4_dma/M_AXI_MM2S} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_4_dma/M_AXI_MM2S]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_4_dma/M_AXI_S2MM} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_4_dma/M_AXI_S2MM]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_5_dma/M_AXI_SG} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_5_dma/M_AXI_SG]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_5_dma/M_AXI_MM2S} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_5_dma/M_AXI_MM2S]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_5_dma/M_AXI_S2MM} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_5_dma/M_AXI_S2MM]

# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_2_dma/M_AXI_SG} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_2_dma/M_AXI_SG]
# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_2_dma/M_AXI_MM2S} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_2_dma/M_AXI_MM2S]
# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_2_dma/M_AXI_S2MM} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_2_dma/M_AXI_S2MM]

# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_3_dma/M_AXI_SG} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_3_dma/M_AXI_SG]
# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_3_dma/M_AXI_MM2S} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_3_dma/M_AXI_MM2S]
# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/axi_ethernet_3_dma/M_AXI_S2MM} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_ethernet_3_dma/M_AXI_S2MM]


#create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
#set_property -dict [list CONFIG.NUM_SI {3}] [get_bd_cells smartconnect_0]
#set_property -dict [list CONFIG.NUM_SI {16}] [get_bd_cells axi_smc]
#connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins axi_smc/S15_AXI]
#connect_bd_net [get_bd_pins smartconnect_0/aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
#connect_bd_net [get_bd_pins smartconnect_0/aresetn] [get_bd_pins rst_ps8_0_100M/peripheral_aresetn]
#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_3_dma/M_AXI_SG] [get_bd_intf_pins smartconnect_0/S00_AXI]
#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_3_dma/M_AXI_MM2S] [get_bd_intf_pins smartconnect_0/S01_AXI]
#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_3_dma/M_AXI_S2MM] [get_bd_intf_pins smartconnect_0/S02_AXI]
#assign_bd_address [get_bd_addr_segs {zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW }]
#assign_bd_address [get_bd_addr_segs {zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM }]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/gmii_mux_0/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins gmii_mux_0/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_gmii_mux_0_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/gmii_mux_1/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins gmii_mux_1/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_gmii_mux_1_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/gmii_mux_2/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins gmii_mux_2/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_gmii_mux_2_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/gmii_mux_3/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins gmii_mux_3/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_gmii_mux_3_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/gmii_mux_4/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins gmii_mux_4/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_gmii_mux_4_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/gmii_mux_5/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins gmii_mux_5/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_gmii_mux_5_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/gmii_mux_6/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins gmii_mux_6/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_gmii_mux_6_Reg0}]


apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/traffic_generator_gmii_0/S_AXI} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins traffic_generator_gmii_0/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_traffic_generator_gmii_0_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/traffic_generator_gmii_1/S_AXI} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins traffic_generator_gmii_1/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_traffic_generator_gmii_1_Reg0}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/traffic_analyzer_gmii_0/S_AXI} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins traffic_analyzer_gmii_0/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_traffic_analyzer_gmii_0_Reg0}]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/rtclock_0/S_AXI} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins rtclock_0/S_AXI]
set_property range 16K [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_rtclock_0_Reg0}]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_intc_0/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_intc_0/s_axi]

# Create ports for Bluetooth UART0
create_bd_port -dir I BT_ctsn
connect_bd_net [get_bd_ports BT_ctsn] [get_bd_pins zynq_ultra_ps_e_0/emio_uart0_ctsn]
create_bd_port -dir O BT_rtsn
connect_bd_net [get_bd_ports BT_rtsn] [get_bd_pins zynq_ultra_ps_e_0/emio_uart0_rtsn]

# # Binary counter to generate a test signal for the 125MHz output clock
# # Uncomment the following block if you want to use this test signal
# create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary c_counter_binary_0
# set_property -dict [list CONFIG.Output_Width {2}] [get_bd_cells c_counter_binary_0]
# connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins c_counter_binary_0/CLK]
# create_bd_port -dir O clk125_test
# create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice counter_slice
# set_property -dict [list CONFIG.DIN_TO {1} CONFIG.DIN_FROM {1} CONFIG.DIN_WIDTH {2} CONFIG.DIN_FROM {1} CONFIG.DOUT_WIDTH {1}] [get_bd_cells counter_slice]
# connect_bd_net [get_bd_pins c_counter_binary_0/Q] [get_bd_pins counter_slice/Din]
# connect_bd_net [get_bd_ports clk125_test] [get_bd_pins counter_slice/Dout]

connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins gmii_mux_0/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins gmii_mux_1/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins gmii_mux_2/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins gmii_mux_3/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins gmii_mux_4/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins gmii_mux_5/gtx_clk]
connect_bd_net [get_bd_pins eth_pcs_pma_shared/clk125_out] [get_bd_pins gmii_mux_6/gtx_clk]

#delete_bd_objs [get_bd_intf_nets axi_ethernet_0_gmii]

#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_2/gmii] [get_bd_intf_pins gmii_mux_2/gmii_in_1]

#regular interface - 1 of 5 (default)
connect_bd_net [get_bd_pins axi_ethernet_0/gmii_txd] [get_bd_pins gmii_mux_0/gmii_in_0_txd]
connect_bd_net [get_bd_pins axi_ethernet_0/gmii_tx_en] [get_bd_pins gmii_mux_0/gmii_in_0_tx_en]
connect_bd_net [get_bd_pins axi_ethernet_0/gmii_tx_er] [get_bd_pins gmii_mux_0/gmii_in_0_tx_er]

#loopback - 2 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rxd_0] [get_bd_pins gmii_mux_0/gmii_in_1_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_dv_0] [get_bd_pins gmii_mux_0/gmii_in_1_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_er_0] [get_bd_pins gmii_mux_0/gmii_in_1_tx_er]

#traffic-generator-gmii - 4 of 5
connect_bd_net [get_bd_pins traffic_generator_gmii_0/gmii_d] [get_bd_pins gmii_mux_0/gmii_in_3_txd]
connect_bd_net [get_bd_pins traffic_generator_gmii_0/gmii_en] [get_bd_pins gmii_mux_0/gmii_in_3_tx_en]
connect_bd_net [get_bd_pins traffic_generator_gmii_0/gmii_er] [get_bd_pins gmii_mux_0/gmii_in_3_tx_er]

#neighbour passthrough - 5 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rxd_1] [get_bd_pins gmii_mux_0/gmii_in_4_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_dv_1] [get_bd_pins gmii_mux_0/gmii_in_4_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_er_1] [get_bd_pins gmii_mux_0/gmii_in_4_tx_er]

#rx path to axi_ethernet_0 (2 of 2)
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rxd_0] [get_bd_pins axi_ethernet_0/gmii_rxd]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_er_0] [get_bd_pins axi_ethernet_0/gmii_rx_er]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_dv_0] [get_bd_pins axi_ethernet_0/gmii_rx_dv]

#connect_bd_intf_net [get_bd_intf_pins gmii_mux_2/gmii_out] [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_pcs_pma_0]
connect_bd_net [get_bd_pins gmii_mux_0/gmii_out_txd] [get_bd_pins eth_pcs_pma_0_1/gmii_txd_0]
connect_bd_net [get_bd_pins gmii_mux_0/gmii_out_tx_en] [get_bd_pins eth_pcs_pma_0_1/gmii_tx_en_0]
connect_bd_net [get_bd_pins gmii_mux_0/gmii_out_tx_er] [get_bd_pins eth_pcs_pma_0_1/gmii_tx_er_0]



#delete_bd_objs [get_bd_intf_nets axi_ethernet_1_gmii]

#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_1/gmii] [get_bd_intf_pins gmii_mux_1/gmii_in_1]

#regular interface - 1 of 5 (default)
connect_bd_net [get_bd_pins axi_ethernet_1/gmii_txd] [get_bd_pins gmii_mux_1/gmii_in_0_txd]
connect_bd_net [get_bd_pins axi_ethernet_1/gmii_tx_en] [get_bd_pins gmii_mux_1/gmii_in_0_tx_en]
connect_bd_net [get_bd_pins axi_ethernet_1/gmii_tx_er] [get_bd_pins gmii_mux_1/gmii_in_0_tx_er]

#loopback - 2 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rxd_1] [get_bd_pins gmii_mux_1/gmii_in_1_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_dv_1] [get_bd_pins gmii_mux_1/gmii_in_1_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_er_1] [get_bd_pins gmii_mux_1/gmii_in_1_tx_er]

#traffic-generator-gmii - 4 of 5
connect_bd_net [get_bd_pins traffic_generator_gmii_1/gmii_d] [get_bd_pins gmii_mux_1/gmii_in_3_txd]
connect_bd_net [get_bd_pins traffic_generator_gmii_1/gmii_en] [get_bd_pins gmii_mux_1/gmii_in_3_tx_en]
connect_bd_net [get_bd_pins traffic_generator_gmii_1/gmii_er] [get_bd_pins gmii_mux_1/gmii_in_3_tx_er]

#neighbour passthrough - 5 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rxd_0] [get_bd_pins gmii_mux_1/gmii_in_4_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_dv_0] [get_bd_pins gmii_mux_1/gmii_in_4_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_er_0] [get_bd_pins gmii_mux_1/gmii_in_4_tx_er]

#rx path to axi_ethernet_1 (1 of 1)
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rxd_1] [get_bd_pins axi_ethernet_1/gmii_rxd]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_er_1] [get_bd_pins axi_ethernet_1/gmii_rx_er]
connect_bd_net [get_bd_pins eth_pcs_pma_0_1/gmii_rx_dv_1] [get_bd_pins axi_ethernet_1/gmii_rx_dv]

#connect_bd_intf_net [get_bd_intf_pins gmii_mux_1/gmii_out] [get_bd_intf_pins eth_pcs_pma_0_1/gmii_*]
connect_bd_net [get_bd_pins gmii_mux_1/gmii_out_txd] [get_bd_pins eth_pcs_pma_0_1/gmii_txd_1]
connect_bd_net [get_bd_pins gmii_mux_1/gmii_out_tx_en] [get_bd_pins eth_pcs_pma_0_1/gmii_tx_en_1]
connect_bd_net [get_bd_pins gmii_mux_1/gmii_out_tx_er] [get_bd_pins eth_pcs_pma_0_1/gmii_tx_er_1]




#delete_bd_objs [get_bd_intf_nets axi_ethernet_2_gmii]

#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_2/gmii] [get_bd_intf_pins gmii_mux_2/gmii_in_0]

#regular interface - 1 of 5 (default)
connect_bd_net [get_bd_pins axi_ethernet_2/gmii_txd] [get_bd_pins gmii_mux_2/gmii_in_0_txd]
connect_bd_net [get_bd_pins axi_ethernet_2/gmii_tx_en] [get_bd_pins gmii_mux_2/gmii_in_0_tx_en]
connect_bd_net [get_bd_pins axi_ethernet_2/gmii_tx_er] [get_bd_pins gmii_mux_2/gmii_in_0_tx_er]

#loopback - 2 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rxd_0] [get_bd_pins gmii_mux_2/gmii_in_1_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_dv_0] [get_bd_pins gmii_mux_2/gmii_in_1_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_er_0] [get_bd_pins gmii_mux_2/gmii_in_1_tx_er]

#traffic-generator-gmii - 4 of 5
connect_bd_net [get_bd_pins traffic_generator_gmii_0/gmii_d] [get_bd_pins gmii_mux_2/gmii_in_3_txd]
connect_bd_net [get_bd_pins traffic_generator_gmii_0/gmii_en] [get_bd_pins gmii_mux_2/gmii_in_3_tx_en]
connect_bd_net [get_bd_pins traffic_generator_gmii_0/gmii_er] [get_bd_pins gmii_mux_2/gmii_in_3_tx_er]

#neighbour passthrough - 5 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_0] [get_bd_pins gmii_mux_2/gmii_in_4_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_0] [get_bd_pins gmii_mux_2/gmii_in_4_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_0] [get_bd_pins gmii_mux_2/gmii_in_4_tx_er]

#rx path to axi_ethernet_2 (1 of 1)
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rxd_0] [get_bd_pins axi_ethernet_2/gmii_rxd]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_er_0] [get_bd_pins axi_ethernet_2/gmii_rx_er]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_dv_0] [get_bd_pins axi_ethernet_2/gmii_rx_dv]

#connect_bd_intf_net [get_bd_intf_pins gmii_mux_2/gmii_out] [get_bd_intf_pins eth_pcs_pma_2_3_5_tx/gmii_pcs_pma_0]
connect_bd_net [get_bd_pins gmii_mux_2/gmii_out_txd] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_txd_0]
connect_bd_net [get_bd_pins gmii_mux_2/gmii_out_tx_en] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_en_0]
connect_bd_net [get_bd_pins gmii_mux_2/gmii_out_tx_er] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_er_0]



#delete_bd_objs [get_bd_intf_nets axi_ethernet_3_gmii]

#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_3/gmii] [get_bd_intf_pins gmii_mux_3/gmii_in_0]

#regular interface - 1 of 5 (default)
connect_bd_net [get_bd_pins axi_ethernet_3/gmii_txd] [get_bd_pins gmii_mux_3/gmii_in_0_txd]
connect_bd_net [get_bd_pins axi_ethernet_3/gmii_tx_en] [get_bd_pins gmii_mux_3/gmii_in_0_tx_en]
connect_bd_net [get_bd_pins axi_ethernet_3/gmii_tx_er] [get_bd_pins gmii_mux_3/gmii_in_0_tx_er]

#loopback - 2 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_0] [get_bd_pins gmii_mux_3/gmii_in_1_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_0] [get_bd_pins gmii_mux_3/gmii_in_1_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_0] [get_bd_pins gmii_mux_3/gmii_in_1_tx_er]

#traffic-generator-gmii - 4 of 5
connect_bd_net [get_bd_pins traffic_generator_gmii_1/gmii_d] [get_bd_pins gmii_mux_3/gmii_in_3_txd]
connect_bd_net [get_bd_pins traffic_generator_gmii_1/gmii_en] [get_bd_pins gmii_mux_3/gmii_in_3_tx_en]
connect_bd_net [get_bd_pins traffic_generator_gmii_1/gmii_er] [get_bd_pins gmii_mux_3/gmii_in_3_tx_er]

#neighbour passthrough - 5 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rxd_0] [get_bd_pins gmii_mux_3/gmii_in_4_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_dv_0] [get_bd_pins gmii_mux_3/gmii_in_4_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_er_0] [get_bd_pins gmii_mux_3/gmii_in_4_tx_er]

#rx path to axi_ethernet_3 (1 of 1)
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_0] [get_bd_pins axi_ethernet_3/gmii_rxd]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_0] [get_bd_pins axi_ethernet_3/gmii_rx_er]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_0] [get_bd_pins axi_ethernet_3/gmii_rx_dv]

#connect_bd_intf_net [get_bd_intf_pins gmii_mux_3/gmii_out] [get_bd_intf_pins eth_pcs_pma_2_3_5_tx/gmii_pcs_pma_1]
connect_bd_net [get_bd_pins gmii_mux_3/gmii_out_txd] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_txd_1]
connect_bd_net [get_bd_pins gmii_mux_3/gmii_out_tx_en] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_en_1]
connect_bd_net [get_bd_pins gmii_mux_3/gmii_out_tx_er] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_er_1]



#delete_bd_objs [get_bd_intf_nets axi_ethernet_4_gmii]


#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_4/gmii] [get_bd_intf_pins gmii_mux_4/gmii_in_0]

#regular interface - 1 of 5 (default)
connect_bd_net [get_bd_pins axi_ethernet_4/gmii_txd] [get_bd_pins gmii_mux_4/gmii_in_0_txd]
connect_bd_net [get_bd_pins axi_ethernet_4/gmii_tx_en] [get_bd_pins gmii_mux_4/gmii_in_0_tx_en]
connect_bd_net [get_bd_pins axi_ethernet_4/gmii_tx_er] [get_bd_pins gmii_mux_4/gmii_in_0_tx_er]

#loopback - 2 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_1] [get_bd_pins gmii_mux_4/gmii_in_1_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_1] [get_bd_pins gmii_mux_4/gmii_in_1_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_1] [get_bd_pins gmii_mux_4/gmii_in_1_tx_er]

#traffic-generator-gmii - 4 of 5
connect_bd_net [get_bd_pins traffic_generator_gmii_0/gmii_d] [get_bd_pins gmii_mux_4/gmii_in_3_txd]
connect_bd_net [get_bd_pins traffic_generator_gmii_0/gmii_en] [get_bd_pins gmii_mux_4/gmii_in_3_tx_en]
connect_bd_net [get_bd_pins traffic_generator_gmii_0/gmii_er] [get_bd_pins gmii_mux_4/gmii_in_3_tx_er]

#neighbour passthrough - 5 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_2] [get_bd_pins gmii_mux_4/gmii_in_4_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_2] [get_bd_pins gmii_mux_4/gmii_in_4_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_2] [get_bd_pins gmii_mux_4/gmii_in_4_tx_er]

#rx path to axi_ethernet_4 (1 of 1)
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_1] [get_bd_pins axi_ethernet_4/gmii_rxd]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_1] [get_bd_pins axi_ethernet_4/gmii_rx_er]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_1] [get_bd_pins axi_ethernet_4/gmii_rx_dv]

#connect_bd_intf_net [get_bd_intf_pins gmii_mux_4/gmii_out] [get_bd_intf_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_pcs_pma_1]
connect_bd_net [get_bd_pins gmii_mux_4/gmii_out_txd] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_txd_1]
connect_bd_net [get_bd_pins gmii_mux_4/gmii_out_tx_en] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_tx_en_1]
connect_bd_net [get_bd_pins gmii_mux_4/gmii_out_tx_er] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_tx_er_1]



#delete_bd_objs [get_bd_intf_nets axi_ethernet_5_gmii]

#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_5/gmii] [get_bd_intf_pins gmii_mux_5/gmii_in_0]

#regular interface - 1 of 5 (default)
connect_bd_net [get_bd_pins axi_ethernet_5/gmii_txd] [get_bd_pins gmii_mux_5/gmii_in_0_txd]
connect_bd_net [get_bd_pins axi_ethernet_5/gmii_tx_en] [get_bd_pins gmii_mux_5/gmii_in_0_tx_en]
connect_bd_net [get_bd_pins axi_ethernet_5/gmii_tx_er] [get_bd_pins gmii_mux_5/gmii_in_0_tx_er]

#loopback - 2 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_2] [get_bd_pins gmii_mux_5/gmii_in_1_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_2] [get_bd_pins gmii_mux_5/gmii_in_1_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_2] [get_bd_pins gmii_mux_5/gmii_in_1_tx_er]

#traffic-generator-gmii - 4 of 5
connect_bd_net [get_bd_pins traffic_generator_gmii_1/gmii_d] [get_bd_pins gmii_mux_5/gmii_in_3_txd]
connect_bd_net [get_bd_pins traffic_generator_gmii_1/gmii_en] [get_bd_pins gmii_mux_5/gmii_in_3_tx_en]
connect_bd_net [get_bd_pins traffic_generator_gmii_1/gmii_er] [get_bd_pins gmii_mux_5/gmii_in_3_tx_er]

#neighbour passthrough - 5 of 5
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_1] [get_bd_pins gmii_mux_5/gmii_in_4_txd]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_1] [get_bd_pins gmii_mux_5/gmii_in_4_tx_en]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_1] [get_bd_pins gmii_mux_5/gmii_in_4_tx_er]

#rx path to axi_ethernet_5 (1 of 1)
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_2] [get_bd_pins axi_ethernet_5/gmii_rxd]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_2] [get_bd_pins axi_ethernet_5/gmii_rx_er]
connect_bd_net [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_2] [get_bd_pins axi_ethernet_5/gmii_rx_dv]

#connect_bd_intf_net [get_bd_intf_pins gmii_mux_5/gmii_out] [get_bd_intf_pins eth_pcs_pma_2_3_5_tx/gmii_pcs_pma_0]
connect_bd_net [get_bd_pins gmii_mux_5/gmii_out_txd] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_txd_2]
connect_bd_net [get_bd_pins gmii_mux_5/gmii_out_tx_en] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_en_2]
connect_bd_net [get_bd_pins gmii_mux_5/gmii_out_tx_er] [get_bd_pins eth_pcs_pma_2_3_5_tx/gmii_tx_er_2]


#analyzer mux
#inputs

connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_0_txd] [get_bd_pins eth_pcs_pma_0_1/gmii_rxd_0]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_0_tx_en] [get_bd_pins eth_pcs_pma_0_1/gmii_rx_dv_0]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_0_tx_er] [get_bd_pins eth_pcs_pma_0_1/gmii_rx_er_0]

connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_1_txd] [get_bd_pins eth_pcs_pma_0_1/gmii_rxd_1]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_1_tx_en] [get_bd_pins eth_pcs_pma_0_1/gmii_rx_dv_1]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_1_tx_er] [get_bd_pins eth_pcs_pma_0_1/gmii_rx_er_1]

connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_2_txd] [get_bd_pins eth_pcs_pma_2_rx/gmii_rxd_0]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_2_tx_en] [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_dv_0]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_2_tx_er] [get_bd_pins eth_pcs_pma_2_rx/gmii_rx_er_0]

connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_3_txd] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_0]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_3_tx_en] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_0]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_3_tx_er] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_0]

connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_4_txd] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_1]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_4_tx_en] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_1]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_4_tx_er] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_1]

connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_5_txd] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rxd_2]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_5_tx_en] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_dv_2]
connect_bd_net [get_bd_pins gmii_mux_6/gmii_in_5_tx_er] [get_bd_pins eth_pcs_pma_3_4_5_rx_4_tx/gmii_rx_er_2]

#output

connect_bd_net [get_bd_pins traffic_analyzer_gmii_0/gmii_d] [get_bd_pins gmii_mux_6/gmii_out_txd]
connect_bd_net [get_bd_pins traffic_analyzer_gmii_0/gmii_en] [get_bd_pins gmii_mux_6/gmii_out_tx_en]
connect_bd_net [get_bd_pins traffic_analyzer_gmii_0/gmii_er] [get_bd_pins gmii_mux_6/gmii_out_tx_er]

#connect_bd_net [get_bd_pins traffic_analyzer_gmii_0/gmii_d] [get_bd_pins eth_pcs_pma_0_1/gmii_rxd_0]
#connect_bd_net [get_bd_pins traffic_analyzer_gmii_0/gmii_en] [get_bd_pins eth_pcs_pma_0_1/gmii_rx_dv_0]
#connect_bd_net [get_bd_pins traffic_analyzer_gmii_0/gmii_er] [get_bd_pins eth_pcs_pma_0_1/gmii_rx_er_0]


#rtclock
connect_bd_net [get_bd_pins traffic_analyzer_gmii_0/sec] [get_bd_pins rtclock_0/sec]
connect_bd_net [get_bd_pins traffic_analyzer_gmii_0/nsec] [get_bd_pins rtclock_0/nsec]
connect_bd_net [get_bd_pins traffic_generator_gmii_0/sec] [get_bd_pins rtclock_0/sec]
connect_bd_net [get_bd_pins traffic_generator_gmii_0/nsec] [get_bd_pins rtclock_0/nsec]
connect_bd_net [get_bd_pins traffic_generator_gmii_1/sec] [get_bd_pins rtclock_0/sec]
connect_bd_net [get_bd_pins traffic_generator_gmii_1/nsec] [get_bd_pins rtclock_0/nsec]

connect_bd_net [get_bd_ports ls_mezz_int0] [get_bd_pins rtclock_0/pps]
connect_bd_net [get_bd_ports ls_mezz_int1] [get_bd_pins rtclock_0/pps2]


#delete_bd_objs [get_bd_intf_nets axi_ethernet_2_dma_M_AXIS_MM2S]

#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_2_dma/M_AXIS_MM2S] [get_bd_intf_pins rate_limiter_2/s_axis]
#connect_bd_intf_net [get_bd_intf_pins axi_ethernet_2/s_axis_txd] [get_bd_intf_pins rate_limiter_2/m_axis]
#connect_bd_net [get_bd_pins rate_limiter_2/axis_resetn] [get_bd_pins axi_ethernet_0_dma/mm2s_prmry_reset_out_n]

connect_bd_net [get_bd_pins traffic_generator_gmii_0/resetn] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn2]
connect_bd_net [get_bd_pins traffic_generator_gmii_1/resetn] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn2]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins eth_pcs_pma_shared/clk125_out]
connect_bd_net [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]
disconnect_bd_net /zynq_ultra_ps_e_0_pl_resetn2 [get_bd_pins traffic_generator_gmii_0/resetn]
disconnect_bd_net /zynq_ultra_ps_e_0_pl_resetn2 [get_bd_pins traffic_generator_gmii_1/resetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins traffic_generator_gmii_0/resetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins traffic_generator_gmii_1/resetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins traffic_analyzer_gmii_0/resetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins rtclock_0/resetn]


#Add 100->625 MHz clock management tile (CMT) using the mixed-mode clock manager (MMCM)
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {625} CONFIG.MMCM_CLKFBOUT_MULT_F {125} CONFIG.MMCM_CLKOUT0_DIVIDE_F {2.000} CONFIG.CLKOUT1_JITTER {80.439} CONFIG.CLKOUT1_PHASE_ERROR {84.520} CONFIG.USE_RESET {false}] [get_bd_cells clk_wiz_0]

#connect_bd_net [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins ref_clk_10mhz]
# Use BUFGCE for clock HS pins- start
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_ds_buf_0
set_property -dict [list CONFIG.C_BUF_TYPE {BUFGCE}] [get_bd_cells util_ds_buf_0]
connect_bd_net [get_bd_pins util_ds_buf_0/BUFGCE_O] [get_bd_pins clk_wiz_0/clk_in1]
connect_bd_net [get_bd_ports ref_clk_10mhz] [get_bd_pins util_ds_buf_0/BUFGCE_I]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
set_property -dict [list CONFIG.CONST_VAL {1}] [get_bd_cells xlconstant_0]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins util_ds_buf_0/BUFGCE_CE]
# Use BUFGCE for clock HS pins- end

connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins eth_pcs_pma_shared/refclk625_in]

# UARTs 0,1
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_2
create_bd_port -dir I ls_mezz_uart0_rx
create_bd_port -dir O ls_mezz_uart0_tx
create_bd_port -dir I ls_mezz_uart1_rx
create_bd_port -dir O ls_mezz_uart1_tx
#create_bd_port -dir I ls_mezz_uart2_rx
#create_bd_port -dir O ls_mezz_uart2_tx

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_uart16550_0/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_uart16550_0/s_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_uart16550_1/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_uart16550_1/s_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_uart16550_2/s_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_uart16550_2/s_axi]

connect_bd_net [get_bd_ports ls_mezz_uart0_rx] [get_bd_pins axi_uart16550_0/sin]
connect_bd_net [get_bd_ports ls_mezz_uart0_tx] [get_bd_pins axi_uart16550_0/sout]

# connect_bd_net [get_bd_ports ls_mezz_int0] [get_bd_pins axi_uart16550_0/dcdn]
connect_bd_net [get_bd_ports ls_mezz_int0] [get_bd_pins dcd0_invert/Op1]
connect_bd_net [get_bd_pins dcd0_invert/Res] [get_bd_pins axi_uart16550_0/dcdn]


connect_bd_net [get_bd_ports ls_mezz_uart1_rx] [get_bd_pins axi_uart16550_1/sin]
connect_bd_net [get_bd_ports ls_mezz_uart1_tx] [get_bd_pins axi_uart16550_1/sout]

#connect_bd_net [get_bd_ports ls_mezz_int1] [get_bd_pins axi_uart16550_1/dcdn]
connect_bd_net [get_bd_ports ls_mezz_int1] [get_bd_pins dcd1_invert/Op1]
connect_bd_net [get_bd_pins dcd1_invert/Res] [get_bd_pins axi_uart16550_1/dcdn]


# loopback
connect_bd_net [get_bd_pins axi_uart16550_2/sin] [get_bd_pins axi_uart16550_2/sout]

connect_bd_net [get_bd_pins axi_uart16550_0/ip2intc_irpt] [get_bd_pins xlconcat_1/In5]
connect_bd_net [get_bd_pins axi_uart16550_1/ip2intc_irpt] [get_bd_pins xlconcat_1/In6]
connect_bd_net [get_bd_pins axi_uart16550_2/ip2intc_irpt] [get_bd_pins xlconcat_1/In7]

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
