#!/bin/bash -e
iverilog tb.v -o tb ../hdl/traffic_analyzer_gmii.v ../hdl/bram_io.v ../hdl/testframe_parser.v ../../traffic_generator_gmii/hdl/traffic_generator_gmii.v ../../rtclock/hdl/rtclock.v -I../hdl -I../../common/hdl -I../../rtclock/hdl -I../../traffic_generator_gmii/hdl
./tb
