all: clean
	vivado -mode batch -source build.tcl -tclargs 1
	vivado -mode batch -source simulate.tcl
	@! grep -R 'Error:' spark/spark.sim/sim_1/behav/xsim/simulate.log
	vivado -mode batch -source bitstream.tcl

clean:
	rm -rf ip_*  vivado*.* *.xml xgui/ .Xil* *.*~ *.zip 
