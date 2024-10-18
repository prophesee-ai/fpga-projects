#!/usr/bin/env -S vivado -mode batch -notrace -source

#*******************************************************************************
#
#  Tcl script to create an IP simulation project
#
#  It requires at least one argument after -tclargs:
#  - IP directory name: the IP directory should be in the ip folder
#  Optional argument is:
#  - force: overwrite the project directory in build/ip if it exists
#  - run: run the testcases
#
#  Vivado version: Vivado v2022.2 (64-bit)
#  Tcl version:    8.5
#
#*******************************************************************************

package require fileutil
package require inifile

# Add colors to output messages:
# INFO in green
# WARNING in orange
# ERROR in red
# Messages from Vivado have no color
proc puts_info    {str} { puts "\033\[1;32mINFO: $str\033\[0m" }
proc puts_warning {str} { puts "\033\[1;33mWARNING: $str\033\[0m" }
proc puts_error   {str} { puts "\033\[1;31mERROR: $str\033\[0m" }

# ------------------------------------------------------------------------------
# Process arguments to get the project name and optional arguments
# ------------------------------------------------------------------------------

set project_name    ""
set force_build_dir false
set run_simulation  false

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--project_name" { incr i; set project_name [lindex $::argv $i] }
      "--force"        { set force_build_dir true }
      "--run"          { set run_simulation true }
      default {
        if { [regexp {^-} $option] } {
          puts_error "Unknown option '$option' specified, usage is \"./scripts/create_ip_sim_project.tcl -tclargs --project_name ip_name_X_Y\""
          exit 1
        }
      }
    }
  }
}

if { $project_name eq "" } {
  puts_error "IP name is missing from arguments, usage is \"./scripts/create_ip_sim_project.tcl -tclargs --project_name ip_name_X_Y\""
  exit 1
}

# Check if the IP exists
set ip_root_dir [file normalize [file dirname [info script]]/../ip/$project_name]
if { ![file isdirectory $ip_root_dir] } {
  puts_error "$project_name is not a valid IP directory, check that the IP is present in the ip/ directory"
  exit 1
}

# Vivado project will be created in the build/ip directory.
# Check if the project directory already exist, if the force option is true, delete it and create a new one
set target_dir [file normalize [file dirname [info script]]/../build/ip/$project_name]
if { [file isdirectory $target_dir] } {
  # Project directory already exists
  if { $force_build_dir } {
    puts_warning "Overwriting $target_dir"
    file delete -force $target_dir
  } else {
    puts_error "$target_dir already exists, use the --force option if you want to overwrite it"
    exit 1
  }
} else {
  puts_info "Creating $target_dir"
}

# Create the build directory
file mkdir $target_dir

# ------------------------------------------------------------------------------
# Set paths
# ------------------------------------------------------------------------------

# ip_root_dir and target_dir are defined above
set script_dir            [file dirname [file normalize [info script]]]
set root_dir              [file normalize $script_dir/..]
set platforms_dir         [file normalize $root_dir/platforms]

set tb_dir                [file normalize $ip_root_dir/tb]
set src_dir               [file normalize $ip_root_dir/hdl]
set sim_dir               [file normalize $tb_dir/src]
set ip_repo_dir           [file normalize $root_dir/ip]

# ------------------------------------------------------------------------------
# Get the project's FPGA part number from the platform
# ------------------------------------------------------------------------------

# Get all the platforms properties files, if a specific platform is needed, you need to specify it manually, otherwise
# the first one will be chosen
# If there is no platforms directory, use a default fpga part
if { [file isdirectory $platforms_dir] } {
  set platform_properties_files [glob -directory [file normalize $platforms_dir] -type f "*/platform.properties"]
  set platform_properties       [ini::open [lindex $platform_properties_files 0] r]
  set fpga_part                 [string trim [ini::value $platform_properties "fpga" "fpga_part"]]
} else {
  set fpga_part "xck26-sfvc784-2lv-c"
}

# Fetch and set the IP name and release number using the directory name
set ip_dirname                [split [file tail [file normalize $ip_root_dir]] "_"]
set ip_name                   [join [lrange $ip_dirname 0 [llength $ip_dirname]-3] "_"]
set ip_version                [lindex $ip_dirname end-1].[lindex $ip_dirname end]

set project_name "${ip_name}_sim"

puts_info "Simulating $ip_name IP version $ip_version"

# ------------------------------------------------------------------------------
# Creating project
# ------------------------------------------------------------------------------

puts_info "Creating $project_name project for FPGA part $fpga_part at [file normalize $target_dir]"

# Create project
create_project -force $project_name $target_dir

# Set the directory path for the new project
set proj_dir   [get_property directory [current_project]]
set ip_gen_dir $proj_dir/ip

# Create directory for generated IP
file mkdir $ip_gen_dir

# Set project properties
set project_obj [get_projects $project_name]
set_property "default_lib"        "xil_defaultlib" $project_obj
set_property "part"               $fpga_part       $project_obj
set_property "simulator_language" "Mixed"          $project_obj
set_property "source_mgmt_mode"   "DisplayOnly"    $project_obj
set_property "target_language"    "VHDL"           $project_obj

# Set message severities
set_msg_config -id {DRC 23-20}     -new_severity {INFO}
set_msg_config -id {Synth 8-3331}  -new_severity {INFO}
set_msg_config -id {Synth 8-3332}  -new_severity {INFO}
set_msg_config -id {Synth 8-3917}  -new_severity {INFO}
set_msg_config -id {Timing 38-316} -new_severity {INFO}

# ------------------------------------------------------------------------------
# Source fileset and IP repository
# ------------------------------------------------------------------------------

# Create 'sources_1' fileset (if not found)
if { [string equal [get_filesets -quiet sources_1] ""] } {
  create_fileset -srcset sources_1
}

# Set IP repository path and rebuild IP catalog before adding any source files
puts_info "Using IP repo [file normalize $ip_repo_dir]"
set_property "ip_repo_paths" $ip_repo_dir [get_filesets sources_1]
update_ip_catalog -rebuild

# ------------------------------------------------------------------------------
# Import sources and add IP
# ------------------------------------------------------------------------------

puts_info "Importing sources into 'sources_1' fileset..."

# Get all files from the tb/src directory
set sources [glob -directory $sim_dir -type f *.vhd]
add_files -fileset sources_1 [file normalize $sources]
# Add the IP reg bank package
add_files -fileset sources_1 [file normalize "$src_dir/${ip_name}_reg_bank_pkg.vhd"]

puts_info "Create IP and Generate"

# Create IP
set ip_inst_name ${ip_name}_0
create_ip -name $ip_name -vendor prophesee.ai -library ip -version $ip_version -module_name $ip_inst_name -dir $ip_gen_dir
generate_target {instantiation_template} [get_files [file normalize $ip_gen_dir/$ip_inst_name/$ip_inst_name.xci]]
generate_target all [get_files [file normalize $ip_gen_dir/$ip_inst_name/$ip_inst_name.xci]]

# Add IP
set file $ip_inst_name/$ip_inst_name.xci
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "generate_files_for_reference" -value "0" -objects $file_obj
set_property -name "registered_with_manager" -value "1" -objects $file_obj
if { ![get_property "is_locked" $file_obj] } {
  set_property -name "synth_checkpoint_mode" -value "Singular" -objects $file_obj
}

# Automatic update and compile order
set_property "source_mgmt_mode" "all" [current_project]
update_compile_order -fileset sources_1

# ------------------------------------------------------------------------------
# Create testcases: go through all tc_* directories in tb
# ------------------------------------------------------------------------------

# Python setup: make sure a virtual environment is being used, otherwise simulation scripts won't be
# executed (which is the expected behavior for released projects)
if { ![info exists ::env(VIRTUAL_ENV)] } {
  puts_warning "Use a virtual environment for Python if you want to generate the pattern files"
} else {
  puts_info "Using Python from virtual environment $::env(VIRTUAL_ENV)"
  set python $::env(VIRTUAL_ENV)/bin/python
}

set sim_tc [lsort [glob -nocomplain -directory $tb_dir tc_*]]
foreach testcase $sim_tc {
  puts_info "Create [file tail $testcase] testcase"

  if { [info exists python] } {
    # Generate pattern files using the Python script
    set test_script [glob -directory $testcase *.py]
    if { [llength $test_script] > 1 } {
      puts_error "There are more than one python file in the $testcase directory"
      exit 1
    }
    # Workaround to use Python from the virtual environment (see https://adaptivesupport.amd.com/s/question/0D54U000067pqBPSAY/how-to-run-the-system-python-from-tcl-script-in-vivado-20222?language=en_US)
    unset -nocomplain ::env(PYTHONHOME)
    unset -nocomplain ::env(PYTHONPATH)
    set python_script [exec -ignorestderr $python $test_script]
    puts $python_script
  }

  # Create fileset
  set fileset "sim_[file tail $testcase]"
  if { [string equal [get_filesets -quiet $fileset] ""] } {
    create_fileset -simset $fileset
  }

  set normalize_pattern_dir [file normalize "$testcase/pattern"]

  # Get fileset properties
  set obj [get_filesets $fileset]

  # Get testcase generics (including pattern files) from simulation.properties
  set simulation_properties [ini::open [file normalize "$testcase/simulation.properties"] r]
  # Normalize pattern entries
  if { [ini::exists $simulation_properties "pattern"] } {
    array set pattern_array [ini::get $simulation_properties "pattern"]
    foreach key [array names pattern_array] {
      lappend generic_list "$key=[file normalize "$testcase/[string trim $pattern_array($key)]"]"
    }
  }
  # Take generics as is
  if { [ini::exists $simulation_properties "generic"] } {
    array set generic_array [ini::get $simulation_properties "generic"]
    foreach key [array names generic_array] {
      lappend generic_list "$key=[string trim $generic_array($key)]"
    }
  }
  set_property generic $generic_list $obj

  # Check if there is waveform configuration files
  set waveform [glob -nocomplain -directory "$testcase/wave" -type f "*.wcfg"]
  add_files -quiet -fileset $fileset -norecurse [file normalize $waveform]

  # Set properties
  set_property -name "top" -value "${ip_name}_tb" -objects $obj
  set_property -name "top_lib" -value "xil_defaultlib" -objects $obj
  set_property -name "xsim.simulate.log_all_signals" -value "1" -objects $obj
  set_property -name "xsim.simulate.runtime" -value "10ms" -objects $obj
}

# Make sim_tc_001 active (or the first testcase found) and delete the default sim_1 testcase
current_fileset -simset [ get_filesets sim_[file tail [lindex $sim_tc 0]] ]
delete_fileset [get_filesets sim_1]

# If the --run option is set, run all the simulation testcases
if { $run_simulation } {
  foreach testcase [get_filesets sim_*] {
    set log_file $target_dir/$testcase.log
    set simulation_steps "compile elaborate simulate"
    puts_info "Running $testcase, log saved to $log_file"
    foreach step $simulation_steps {
      if { [catch {launch_simulation -simset [get_filesets $testcase] -mode behavioral -step $step > $log_file}] } {
        puts_error "Simulation failed during $step step:"
        set fp [open "$log_file" r]
        set log_data [read $fp]
        close $fp
        set log_lines [split $log_data "\n"]
        foreach line $log_lines {
          if { [string match "ERROR:*" $line] } {
            puts $line
          }
        }
        break
      }
    }

    if { $step eq "simulate" } {
      # Analyze the simulation log
      set fp [open "$log_file" r]
      set log_data [read $fp]
      close $fp

      if { [string match "*End of Test with Success*" $log_data] } {
        puts_info "Simulation ended with success"
      } else {
        puts_warning "Simulation ended without a success message, check the log file"
      }
    }
  }
}

close_project
