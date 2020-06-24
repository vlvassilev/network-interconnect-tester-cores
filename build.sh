#!/bin/bash -e

#1. Build IP core modules
top_dir=`pwd`

cd ${top_dir}/lib/hw/lsi/cores/traffic_generator
vivado -mode batch -source traffic_generator.tcl

cd ${top_dir}/lib/hw/lsi/cores/gmii_mux
vivado -mode batch -source gmii_mux.tcl

cd ${top_dir}/lib/hw/lsi/cores/gig_ethernet_pcs_pma_shared
vivado -mode batch -source gig_ethernet_pcs_pma_shared.tcl

#2. Build system
cd ${top_dir}/systems/spark
vivado -mode batch -source build.tcl -tclargs 1
vivado -mode batch -source simulate.tcl
vivado -mode batch -source bitstream.tcl
