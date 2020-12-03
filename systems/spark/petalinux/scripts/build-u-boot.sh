#!/bin/bash -e
rm -rf a b
mkdir -p src/common/project-spec/meta-user/recipes-bsp/u-boot/files
mkdir -p a/ ; cp platform-auto.h.original a/platform-auto.h
mkdir -p b/ ; cp platform-auto.h b/platform-auto.h
diff -Naur platform-auto.h.original platform-auto.h > src/common/project-spec/meta-user/recipes-bsp/u-boot/files/platform-auto.patch || true
cp src/common/project-spec/meta-user/recipes-bsp/u-boot/files/platform-auto.patch spark/project-spec/meta-user/recipes-bsp/u-boot/files/platform-auto.patch
cp platform-auto.h spark/project-spec/meta-user/recipes-bsp/u-boot/files/
cd spark
petalinux-build -c u-boot -x clean
petalinux-build -c u-boot
petalinux-package --boot --fsbl ./images/linux/zynqmp_fsbl.elf --fpga ../../spark/spark.runs/impl_1/spark_wrapper.bit --u-boot images/linux/u-boot.elf --force
