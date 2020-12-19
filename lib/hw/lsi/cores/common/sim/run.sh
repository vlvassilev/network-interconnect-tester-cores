#!/bin/bash -e

iverilog tb.v -o tb ../hdl/ethernet_crc_8.v -I../hdl
./tb
