#!/bin/bash -e
rm -rf a b
mkdir -p src/common/project-spec/meta-user/recipes-bsp/fsbl/files
mkdir -p a/lib/sw_apps/zynqmp_fsbl/src/ ; cp xfsbl_hooks.c.original a/lib/sw_apps/zynqmp_fsbl/src/xfsbl_hooks.c
mkdir -p b/lib/sw_apps/zynqmp_fsbl/src/ ; cp xfsbl_hooks.c b/lib/sw_apps/zynqmp_fsbl/src/xfsbl_hooks.c
diff -Naur a/lib/sw_apps/zynqmp_fsbl/src/xfsbl_hooks.c b/lib/sw_apps/zynqmp_fsbl/src/xfsbl_hooks.c > src/common/project-spec/meta-user/recipes-bsp/fsbl/files/fsbl_hooks.patch || true
cp src/common/project-spec/meta-user/recipes-bsp/fsbl/files/fsbl_hooks.patch spark/project-spec/meta-user/recipes-bsp/fsbl/files/fsbl_hooks.patch
cd spark
petalinux-build -c fsbl -x clean
petalinux-build -c fsbl
petalinux-package --boot --fsbl ./images/linux/zynqmp_fsbl.elf --fpga ../../spark/spark.runs/impl_1/spark_wrapper.bit --u-boot images/linux/u-boot.elf --force
