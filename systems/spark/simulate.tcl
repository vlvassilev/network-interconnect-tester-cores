cd spark
open_project spark.xpr
launch_simulation
add_wave {{/tb/spark_wrapper_i/spark_i/eth_pcs_pma_0_1/gmii_txd_1}}
add_wave {{/tb/spark_wrapper_i/spark_i/eth_pcs_pma_0_1/gmii_rxd_0}}
add_wave {{/tb/spark_wrapper_i/spark_i/eth_pcs_pma_0_1/status_vector_0}}
add_wave {{/tb/spark_wrapper_i/spark_i/eth_pcs_pma_0_1/status_vector_1}}
add_wave {{/tb/spark_wrapper_i/spark_i/eth_pcs_pma_0_1/reset}}
add_wave {{/tb/spark_wrapper_i/spark_i/eth_pcs_pma_shared/reset}}
run 200 us

