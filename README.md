# Overview
This project provides library of cores for implementation of network interconnect device tester
instruments conforming to https://datatracker.ietf.org/doc/draft-ietf-bmwg-network-tester-cfg (current ver. -03)
in hardware.

# Directory structure
lib/hw/cores/lsi/*: Contains HDL (Verilog) source implementing the IP cores part of the network interconnect device tester design
lib/sw/cores/lsi/*: Contains software source implementing the YANG modules part of the network interconnect device tester design as netconfd loadable modules (SILs)

systems/*: Contains example projects for supported open-source hardware and virtual (cocotb/iverilog simulation)

systems/spark: Spark-2.x 6x SFP+ board based on Ultra96. Open-source hardware (OSHWA UID NO000005). Contains build scripts and configuration files for Vivado and Petalinux.

systems/simulation: A cocotb/iverilog simulation of a system with register interfaces of 1x *traffic_generator_gmii* and 1x *traffic_analyzer_gmii* and 1x *rtclock* cores connected.

# Building SD card image (FPGA bitstream + Linux)
```
./build.sh
```
# Coding style
The project coding style is based on the guidelines used in the NetFPGA project.

# Organization
```
                   NETCONF Server (YANG Model)

 TRAFFIC-GENERATOR (SW)               TRAFFIC-ANALYZER (SW)
     |                                    |
 Socket API                           Socket API
     |               \   |   /            |
  OS Kernel         {RTCLOCK}          OS Kernel
     |               /   |   \            |
    DMA                                  DMA
     | (AXI)                              | (AXI)
    MAC  TRAFFIC-GENERATOR (HW)          MAC    TRAFFIC-ANALYZER (HW)
      \   /                               |       |
       \ /                                |       |
       {+} GMII_MUX                       +---+---+
        | (GMII)                              | (GMII)
       PHY                                   PHY
        |                                     |
      SFP+ TX                               SFP+ RX
        |                                     |
        +->--------------------------------->-+
```
