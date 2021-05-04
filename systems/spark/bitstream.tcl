cd spark
open_project spark.xpr
update_compile_order -fileset sources_1
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if ([string compare [get_property STATUS [get_runs impl_1]] "write_bitstream Complete!"]) { exit -1 }
write_hw_platform -fixed -force -file spark_wrapper.xsa
