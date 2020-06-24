# Vivado Launch Script
#### Change design settings here #######
set design gig_ethernet_pcs_pma_shared
set top gig_ethernet_pcs_pma_shared
set device xczu3eg-sbva484-1-e
set proj_dir ./synth
set ip_version 1.0
set lib_name ip
set vendor lightside-instruments.com
#####################################
# set IP paths
#####################################

#####################################
# Project Settings
#####################################
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device} -ip
set_property source_mgmt_mode All [current_project]  
set_property top ${top} [current_fileset]
set_property ip_repo_paths ../../../  [current_fileset]
puts "Creating Output Port Lookup IP"
# Project Constraints
#####################################
# Project Structure & IP Build
#####################################
read_verilog "./hdl/gig_ethernet_pcs_pma_shared.v"
read_verilog "./hdl/gig_ethernet_pcs_pma_reset_sync_ex.v"
read_vhdl "./hdl/gig_ethernet_pcs_pma_clock_reset.vhd"
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

ipx::package_project

ipx::add_bus_interface refclk625_in [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces refclk625_in -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces refclk625_in -of_objects [ipx::current_core]]
ipx::add_port_map CLK [ipx::get_bus_interfaces refclk625_in -of_objects [ipx::current_core]]
set_property physical_name refclk625_in [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces refclk625_in -of_objects [ipx::current_core]]]

ipx::add_bus_interface clk125_out [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces clk125_out -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces clk125_out -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces clk125_out -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces clk125_out -of_objects [ipx::current_core]]
set_property value 125000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces clk125_out -of_objects [ipx::current_core]]]
ipx::add_port_map CLK [ipx::get_bus_interfaces clk125_out -of_objects [ipx::current_core]]
set_property physical_name clk125_out [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces clk125_out -of_objects [ipx::current_core]]]
ipx::infer_user_parameters [ipx::current_core]

set_property name ${design} [ipx::current_core]
set_property library ${lib_name} [ipx::current_core]
set_property vendor_display_name {Lightside Instruments AS} [ipx::current_core]
set_property company_url {http://lightside-instruments.com} [ipx::current_core]
set_property vendor {lightside-instruments.com} [ipx::current_core]
#set_property supported_families {{virtex7} {Production}} [ipx::current_core]
set_property taxonomy {{/lsi/generic}} [ipx::current_core]
set_property version ${ip_version} [ipx::current_core]
set_property display_name ${design} [ipx::current_core]
set_property description ${design} [ipx::current_core]

puts stdout [ipx::get_file_groups]
set proj_filegroup_synth [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
set proj_filegroup_sim [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
puts stdout ${proj_filegroup_sim}

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
#close_project

#file delete -force ${proj_dir} 
