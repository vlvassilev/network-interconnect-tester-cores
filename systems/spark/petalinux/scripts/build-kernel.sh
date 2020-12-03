#!/bin/bash -e
cd spark
cp ../kernel-config build/tmp/work/ultra96_zynqmp-xilinx-linux/linux-xlnx/4.19-xilinx-v2019.2+git999-r0/linux-xlnx-4.19-xilinx-v2019.2+git999/.config
petalinux-build -c kernel --silentconfig
petalinux-build
petalinux-package --boot --fsbl ./images/linux/zynqmp_fsbl.elf --fpga ../../spark/spark.runs/impl_1/spark_wrapper.bit --u-boot images/linux/u-boot.elf --force
