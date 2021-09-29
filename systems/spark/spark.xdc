#     References:
#     [1] Xilinx pg047-gig-eth-pcs-pma.pdf v16_1 p.117
#     [2] Linaro 96Boards-CE-Specification.pdf v1.0 p.16-20
#     [3] Avnet ultra96-schematics.pdf
#     [4] Lightside Instruments spark-v1-schematics.pdf
#
#     IO standard for Bank 26 Vcco supply is fixed at 1.8V
#     IO standard for Bank 65 Vcco supply is fixed at 1.2V
#
# ----------------------------------------------------------------------------
# High-speed expansion connector
# ---------------------------------------------------------------------------- 
# Ethernet96 port map
# BYTE usage in BANK 65:
# ----------------------
# BYTE   Nibble   PCS/PMA           Usage
# --------------------------------------------------------------
# 0      Lower    eth_pcs_pma_3_rx  PORT 3 RX, REF CLK 625MHz
#        Upper                      Not connected
# 1      Lower    eth_pcs_pma_0_1   PORT 0,1 RX
#        Upper    eth_pcs_pma_0_1   PORT 0,1 TX
# 2      Lower                      Not connected
#        Upper    eth_pcs_pma_3_tx  PORT 3 TX
# 3      Lower    eth_pcs_pma_2     PORT 2 RX
#        Upper    eth_pcs_pma_2     PORT 2 TX

#Spark v.0 port map (SFP0 RX SFP1 TX coincide with Port 2 and can be tested with disabled auto-negotiation)
#Name|Rx     |Tx
#----+-------+-------+
#SFP0|DSI_D0 |DSI_D1
#SFP1|DSI_D2 |DSI_D3
#SFP2|CSI1_C |CSI1_D1
#SFP3|CSI1_D0|CSI0_D3
#SFP4|CSI0_D2|CSI0_D1
#SFP5|CSI0_D0|CSI0_C
# BYTE   Nibble   PCS/PMA              Usage (lane0, lane1, lane2)
# -----------------------------------------------------------------
# 0      Lower    eth_pcs_pma_3_rx rx(0)  SFP2 RX, SFP3 RX, SFP2 TX
#        Upper    eth_pcs_pma_3_rx tx(0)  Not connected
# 1      Lower    eth_pcs_pma_3_tx tx(0)  SFP5 TX, SFP5 RX
#        Upper    eth_pcs_pma_3_tx rx(0)  SFP4 RX, SFP3 TX, ?
# 2      Lower    eth_pcs_pma_2 rx(0)     Not connected
#        Upper    eth_pcs_pma_2 tx(0)     DSI_CLK
# 3      Lower    eth_pcs_pma_0_1 rx(2,0) SFP0 RX, SFP0 TX, SFP1 RX
#        Upper    eth_pcs_pma_0_1 tx(1,0) SFP1 TX,

#Spark v.1 port map (SFP0 RX SFP1 TX coincide with Port 2 and can be tested with disabled auto-negotiation)
#Name|Rx     |Tx
#----+-------+-------+
#SFP0|3L0 DSI_D0 |0L0 CSI1_C
#SFP1|3L2 DSI_D2 |3U0 DSI_D3
#SFP2|3L1 DSI_D1 |0L2 CSI1_D1
#SFP3|2U0 DSI_CLK|0L1 CSI1_D0
#SFP4|1U0 CSI0_D2|1L2 CSI0_D1
#SFP5|1U1 CSI0_D3|1L0 CSI0_C

# BYTE   Nibble   PCS/PMA              Usage (lane0, lane1, lane2)
# -----------------------------------------------------------------
# 0      Lower    eth_pcs_pma_2_3_5_tx tx(1,2,0)      SFP0,    SFP3,    SFP2
#        Upper    eth_pcs_pma_2_3_5_tx rx(1,2,0)      ?,       ?,       ?
# 1      Lower    eth_pcs_pma_0_1 tx(0,2)             SFP5 TX, CSI0_D0, SFP4 TX
#        Upper    eth_pcs_pma_0_1 rx(1,0)             SFP4 RX, SFP5 RX, ?
# 2      Lower    eth_pcs_pma_2_rx tx(0)              ?,       ?,       ?
#        Upper    eth_pcs_pma_2_rx rx(0)              SFP3 RX, ?,       ?
# 3      Lower    eth_pcs_pma_3_4_5_rx_4_tx rx(1,2,0) SFP0 RX, SFP2 RX, SFP1 RX
#        Upper    eth_pcs_pma_3_4_5_rx_4_tx tx(0) SFP1 TX, ?, ?

# Bank 65 (1.2V)

# BANK65_BYTE0 Lower nibble
set_property PACKAGE_PIN T2   [get_ports {sfp_port_5_tx_txn}];  # "T2.CSI1_C_N" Clock capable DBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_5_tx_txn}];
set_property PACKAGE_PIN T3   [get_ports {sfp_port_5_tx_txp}];  # "T3.CSI1_C_P" Clock capable DBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_5_tx_txp}];
set_property PACKAGE_PIN R3   [get_ports {sfp_port_2_tx_txn}];  # "R3.CSI1_D0_N"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_tx_txn}];
set_property PACKAGE_PIN P3   [get_ports {sfp_port_2_tx_txp}];  # "P3.CSI1_D0_P"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_tx_txp}];
set_property PACKAGE_PIN U1   [get_ports {sfp_port_3_tx_txn}];  # "U1.CSI1_D1_N"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_3_tx_txn}];
set_property PACKAGE_PIN U2   [get_ports {sfp_port_3_tx_txp}];  # "U2.CSI1_D1_P"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_3_tx_txp}];

#get_ports {phy_gpio_tri_io[4]}

# BANK65_BYTE0 Upper nibble
set_property PACKAGE_PIN T4   [get_ports {sfp_port_5_tx_rxn}];  # T4 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_5_tx_rxn}];
set_property PACKAGE_PIN R4   [get_ports {sfp_port_5_tx_rxp}];  # R4 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_5_tx_rxp}];
set_property PACKAGE_PIN T1   [get_ports {sfp_port_2_tx_rxn}];  # T1 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_tx_rxn}];
set_property PACKAGE_PIN R1   [get_ports {sfp_port_2_tx_rxp}];  # R1 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_tx_rxp}];
set_property PACKAGE_PIN R5   [get_ports {sfp_port_3_tx_rxn}];  # R5 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_3_tx_rxn}];
set_property PACKAGE_PIN P5   [get_ports {sfp_port_3_tx_rxp}];  # P5 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_3_tx_rxp}];

# BANK65_BYTE1 Lower nibble
set_property PACKAGE_PIN P1   [get_ports {sfp_port_0_txn}];  # "P1.CSI0_C_N" Clock capable QBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_0_txn}];
set_property PACKAGE_PIN N2   [get_ports {sfp_port_0_txp}];  # "N2.CSI0_C_P" Clock capable QBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_0_txp}];
set_property PACKAGE_PIN N4   [get_ports {phy_gpio_tri_io[4]}];  # "N4.CSI0_D0_N"
set_property IOSTANDARD SSTL12 [get_ports {phy_gpio_tri_io[4]}];
set_property PACKAGE_PIN N5   [get_ports {phy_gpio_tri_io[5]}];  # "N5.CSI0_D0_P"
set_property IOSTANDARD SSTL12 [get_ports {phy_gpio_tri_io[5]}];
set_property PACKAGE_PIN M1   [get_ports {sfp_port_1_txn}];  # "M1.CSI0_D1_N"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_1_txn}];
set_property PACKAGE_PIN M2   [get_ports {sfp_port_1_txp}];  # "M2.CSI0_D1_P"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_1_txn}];

# BANK65_BYTE1 Upper nibble
set_property PACKAGE_PIN M4   [get_ports {sfp_port_1_rxn}];  # "M4.CSI0_D2_N" Clock capable QBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_1_rxn}];
set_property PACKAGE_PIN M5   [get_ports {sfp_port_1_rxp}];  # "M5.CSI0_D2_P" Clock capable QBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_1_rxp}];
set_property PACKAGE_PIN L1   [get_ports {sfp_port_0_rxn}];  # "L1.CSI0_D3_N" Global clock capable
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_0_rxn}];
set_property PACKAGE_PIN L2   [get_ports {sfp_port_0_rxp}];  # "L2.CSI0_D3_P" Global clock capable
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_0_rxp}];
set_property PACKAGE_PIN L3   [get_ports {phy_gpio_tri_io[2]}];  # L3 Not connected
set_property IOSTANDARD SSTL12 [get_ports {phy_gpio_tri_io[2]}];
set_property PACKAGE_PIN L4   [get_ports {phy_gpio_tri_io[3]}];  # L4 Not connected
set_property IOSTANDARD SSTL12 [get_ports {phy_gpio_tri_io[3]}];

# BANK65_BYTE2 Lower nibble
set_property PACKAGE_PIN J2   [get_ports {sfp_port_2_rx_txn}];  # J2 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_rx_txn}];
set_property PACKAGE_PIN J3   [get_ports {sfp_port_2_rx_txp}];  # J3 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_rx_txp}];
set_property PACKAGE_PIN K3   [get_ports {phy_gpio_tri_io[0]}];  # K3 Not connected
set_property IOSTANDARD SSTL12 [get_ports {phy_gpio_tri_io[0]}];
set_property PACKAGE_PIN K4   [get_ports {phy_gpio_tri_io[1]}];  # K4 Not connected
set_property IOSTANDARD SSTL12 [get_ports {phy_gpio_tri_io[1]}];
#set_property PACKAGE_PIN J1   [get_ports {sfp_port_2_rxn}];  # J1 Not connected
#set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_rxn}];
#set_property PACKAGE_PIN K1   [get_ports {sfp_port_2_rxp}];  # K1 Not connected
#set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_rxp}];

# BANK65_BYTE2 Upper nibble
set_property PACKAGE_PIN H5   [get_ports {sfp_port_2_rx_rxn}];  # "H5.DSI_CLK_N" Clock capable QBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_rx_rxn}];
set_property PACKAGE_PIN J5   [get_ports {sfp_port_2_rx_rxp}];  # "J5.DSI_CLK_P" Clock capable QBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_2_rx_rxp}];

# BANK65_BYTE3 Lower nibble
set_property PACKAGE_PIN F1   [get_ports {sfp_port_5_rx_rxn}];  # "F1.DSI_D0_N" Clock capable DBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_5_rx_rxn}];
set_property PACKAGE_PIN G1   [get_ports {sfp_port_5_rx_rxp}];  # "G1.DSI_D0_P" Clock capable DBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_5_rx_rxp}];
set_property PACKAGE_PIN E3   [get_ports {sfp_port_3_rx_rxn}];  # "E3.DSI_D1_N"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_3_rx_rxn}];
set_property PACKAGE_PIN E4   [get_ports {sfp_port_3_rx_rxp}];  # "E4.DSI_D1_P"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_3_rx_rxp}];
set_property PACKAGE_PIN D1   [get_ports {sfp_port_4_rxn}];  # "D1.DSI_D2_N"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_4_rxn}];
set_property PACKAGE_PIN E1   [get_ports {sfp_port_4_rxp}];  # "E1.DSI_D2_P"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_4_rxp}];

# BANK65_BYTE3 Upper nibble
set_property PACKAGE_PIN C3   [get_ports {sfp_port_4_txn}];  # "C3.DSI_D3_N" Clock capable DBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_4_txn}];
set_property PACKAGE_PIN D3   [get_ports {sfp_port_4_txp}];  # "D3.DSI_D3_P" Clock capable DBC
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_4_txp}];
set_property PACKAGE_PIN F2   [get_ports {sfp_port_3_rx_txn}];  # F2 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_3_rx_txn}];
set_property PACKAGE_PIN F3   [get_ports {sfp_port_3_rx_txp}];  # F3 Not connected
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_3_rx_txp}];
set_property PACKAGE_PIN C2   [get_ports {sfp_port_5_rx_txn}];  # "C2.HSIC_DATA"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_5_rx_txn}];
set_property PACKAGE_PIN D2   [get_ports {sfp_port_5_rx_txp}];  # "D2 Not connected?"
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sfp_port_5_rx_txp}];

# Set VREF to VCC/2 = 0.6V in Bank 65 for the sfp inputs
set_property INTERNAL_VREF 0.60 [get_iobanks 65]

## Bank 66
#set_property PACKAGE_PIN A2   [get_ports {HSIC_STR                }];  # "A2.HSIC_STR"

## Bank 26 (1.8V)
#set_property PACKAGE_PIN E8   [get_ports {ref_clk_125mhz_clk_p}];  # "E8.CSI0_MCLK"
#set_property IOSTANDARD DIFF_SSTL18_I [get_ports {ref_clk_125mhz_clk_p}];
#set_property ODT RTT_48 [get_ports {ref_clk_125mhz_clk_p}];
#set_property PACKAGE_PIN D8   [get_ports {ref_clk_125mhz_clk_n}];  # "D8.CSI1_MCLK"
#set_property IOSTANDARD DIFF_SSTL18_I [get_ports {ref_clk_125mhz_clk_n}];
#set_property ODT RTT_48 [get_ports {ref_clk_125mhz_clk_n}];

# Set VREF to VCC/2 = 0.9V to enable the ref_clk input
#set_property INTERNAL_VREF 0.90 [get_iobanks 26]

# ----------------------------------------------------------------------------
# Low-speed expansion connector
# ---------------------------------------------------------------------------- 
# All of the pins that are commented out below can be used for whatever you need.
# To use them, just add logic to the Vivado block diagram, connect the logic to external
# ports and then change the port names in the below constraints and uncomment them.
# ---------------------------------------------------------------------------- 
# Bank 23 (1.8V)
#set_property PACKAGE_PIN D7   [get_ports {HD_GPIO_0}];  # "D7.HDGC_GPIO_0" UART0_CTS, PIN 3
#set_property IOSTANDARD LVCMOS18 [get_ports {HD_GPIO_0}];
set_property PACKAGE_PIN F8   [get_ports {ls_mezz_uart0_tx}];  # "F8.HD_GPIO_1" UART0_TXD, PIN 5
set_property IOSTANDARD LVCMOS18 [get_ports {ls_mezz_uart0_tx}];
set_property PACKAGE_PIN F7   [get_ports {ls_mezz_uart0_rx}];  # "F7.HD_GPIO_2" UART0_RXD, PIN 7
set_property IOSTANDARD LVCMOS18 [get_ports {ls_mezz_uart0_rx}];
#set_property PACKAGE_PIN G7   [get_ports {HD_GPIO_3}];  # "G7.HD_GPIO_3" UART0_RTS, PIN 9
#set_property IOSTANDARD LVCMOS18 [get_ports {HD_GPIO_3}];
set_property PACKAGE_PIN F6   [get_ports {ls_mezz_uart1_tx}];  # "F6.HD_GPIO_4" UART1_TXD, PIN 11
set_property IOSTANDARD LVCMOS18 [get_ports {ls_mezz_uart1_tx}];
set_property PACKAGE_PIN G5   [get_ports {ls_mezz_uart1_rx}];  # "G5.HD_GPIO_5" UART1_RXD, PIN 13
set_property IOSTANDARD LVCMOS18 [get_ports {ls_mezz_uart1_rx}];
##set_property PACKAGE_PIN A6   [get_ports {reset_port_0_n}];  # "A6.HD_GPIO_6" GPIO-G, PIN 29
##set_property IOSTANDARD LVCMOS18 [get_ports {reset_port_0_n}];
##set_property PACKAGE_PIN A7   [get_ports {reset_port_2_n}];  # "A7.HD_GPIO_7" GPIO-I, PIN 31
##set_property IOSTANDARD LVCMOS18 [get_ports {reset_port_2_n}];
set_property PACKAGE_PIN G6   [get_ports {ls_mezz_int0}];  # "G6.HD_GPIO_8" GPIO-K, PIN 33
set_property IOSTANDARD LVCMOS18 [get_ports {ls_mezz_int0}];
#set_property PACKAGE_PIN E6   [get_ports {HD_GPIO_9}];  # "E6.HD_GPIO_9" PCM_FS, PIN 16
#set_property IOSTANDARD LVCMOS18 [get_ports {HD_GPIO_9}];
#set_property PACKAGE_PIN E5   [get_ports {HD_GPIO_10}];  # "E5.HD_GPIO_10" PCM_CLK, PIN 18
#set_property IOSTANDARD LVCMOS18 [get_ports {HD_GPIO_10}];
#set_property PACKAGE_PIN D6   [get_ports {HD_GPIO_11}];  # "D6.HDGC_GPIO_11" PCM_DO, PIN 20
#set_property IOSTANDARD LVCMOS18 [get_ports {HD_GPIO_11}];
set_property PACKAGE_PIN D5   [get_ports {ref_clk_10mhz}];  # "D5.HDGC_GPIO_12" PCM_DI, PIN 22
set_property IOSTANDARD LVCMOS18 [get_ports {ref_clk_10mhz}];
##set_property PACKAGE_PIN C7   [get_ports {reset_port_1_n}];  # "C7.HDGC_GPIO_13" GPIO-H, PIN 30
##set_property IOSTANDARD LVCMOS18 [get_ports {reset_port_1_n}];
##set_property PACKAGE_PIN B6   [get_ports {reset_port_3_n}];  # "B6.HD_GPIO_14" GPIO-J, PIN 32
##set_property IOSTANDARD LVCMOS18 [get_ports {reset_port_3_n}];
set_property PACKAGE_PIN C5   [get_ports {ls_mezz_int1}];  # "C5.HDGC_GPIO_15" GPIO-L, PIN 34
set_property IOSTANDARD LVCMOS18 [get_ports {ls_mezz_int1}];

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets *_i/eth_pcs_pma_3_rx/inst/clock_reset_i/iclkbuf/O]

#set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets *_i/util_ds_buf_1/U0/BUFG_O[0]]

# DQS_BIAS is to be set to TRUE if internal DC biasing is used - this is recommended. 
# If the signal is biased externally on the board, should be set to FALSE
#set_property DQS_BIAS TRUE [get_ports sfp_port_0_rxp]
#set_property DQS_BIAS TRUE [get_ports sfp_port_0_rxn]
#set_property DQS_BIAS TRUE [get_ports sfp_port_1_rxp]
#set_property DQS_BIAS TRUE [get_ports sfp_port_1_rxn]
#set_property DQS_BIAS TRUE [get_ports sfp_port_2_rxp]
#set_property DQS_BIAS TRUE [get_ports sfp_port_2_rxn]
#set_property DQS_BIAS TRUE [get_ports sfp_port_3_rx_rxp]
#set_property DQS_BIAS TRUE [get_ports sfp_port_3_rx_rxn]
#set_property DQS_BIAS TRUE [get_ports ref_clk_625mhz_clk_p]
#set_property DQS_BIAS TRUE [get_ports ref_clk_625mhz_clk_n]

set_property ODT RTT_48 [get_ports sfp_port_0_rxp]
set_property ODT RTT_48 [get_ports sfp_port_0_rxn]
set_property ODT RTT_48 [get_ports sfp_port_1_rxp]
set_property ODT RTT_48 [get_ports sfp_port_1_rxn]
set_property ODT RTT_48 [get_ports sfp_port_2_rxp]
set_property ODT RTT_48 [get_ports sfp_port_2_rxn]
set_property ODT RTT_48 [get_ports sfp_port_3_rx_rxp]
set_property ODT RTT_48 [get_ports sfp_port_3_rx_rxn]
set_property ODT RTT_48 [get_ports ref_clk_625mhz_clk_p]
set_property ODT RTT_48 [get_ports ref_clk_625mhz_clk_n]

# Bluetooth UART0 pins
set_property IOSTANDARD LVCMOS18 [get_ports BT*]
#BT_HCI_RTS on FPGA /  emio_uart0_ctsn connect to 
set_property PACKAGE_PIN B7 [get_ports BT_ctsn]
#BT_HCI_CTS on FPGA / emio_uart0_rtsn
set_property PACKAGE_PIN B5 [get_ports BT_rtsn]

#create_clock -period 100 [get_ports ref_clk_10mhz]
create_clock -period 100 [get_ports util_ds_buf_0/util_ds_buf_0/BUFGCE_O]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets spark_i/util_ds_buf_0/U0/BUFGCE_O[0]]
#set property CLOCK_DEDICATED_ROUTE FALSE [get_nets spark_i/clk_wiz_0/clk_in1]
