#!/bin/bash -e

#Use 1 for v1 and 2 for v2
board_ver=2

#1. Build IP core modules
top_dir=`pwd`

cd ${top_dir}/lib/hw/lsi/cores/traffic_generator
vivado -mode batch -source traffic_generator.tcl

cd ${top_dir}/lib/hw/lsi/cores/traffic_generator_gmii
vivado -mode batch -source traffic_generator_gmii.tcl

cd ${top_dir}/lib/hw/lsi/cores/traffic_analyzer_gmii
vivado -mode batch -source traffic_analyzer_gmii.tcl

cd ${top_dir}/lib/hw/lsi/cores/rtclock
vivado -mode batch -source rtclock.tcl

cd ${top_dir}/lib/hw/lsi/cores/gmii_mux
vivado -mode batch -source gmii_mux.tcl

cd ${top_dir}/lib/hw/lsi/cores/gig_ethernet_pcs_pma_shared
vivado -mode batch -source gig_ethernet_pcs_pma_shared.tcl

#2. Build system
cd ${top_dir}/systems/spark
vivado -mode batch -source build.tcl -tclargs $board_ver

vivado -mode batch -source simulate.tcl
! grep -R 'Too few frames received at eth1' spark/spark.sim/sim_1/behav/xsim/simulate.log

vivado -mode batch -source bitstream.tcl


#3. Build petalinux
cd ${top_dir}/systems/spark/petalinux
./build-petalinux $board_ver
