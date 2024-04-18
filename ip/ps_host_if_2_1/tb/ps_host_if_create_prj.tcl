# Copyright (c) Prophesee S.A. - All Rights Reserved
# Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
# You may not use this file except in compliance with these License T&C's.

package require fileutil
package require inifile
package require vivado_utils

namespace eval vivado_utils {
    # Create the ensemble command
    namespace ensemble create
}

# -----------------------------------------------------------------------------
# Set the project's FPGA Part Number
# -----------------------------------------------------------------------------

# TE0808 Zynq US+ 6EG
set fpga_part                     "xczu6eg-ffvc900-1-e"

# Project name, board revision and sensor version
set project_name                  [lindex $argv 0]

# -----------------------------------------------------------------------------
# Setting Paths
# -----------------------------------------------------------------------------

# Set the reference directory for source file relative paths (by default the value is script directory path)
set target_dir                    .
set script_dir                    [::fileutil::relative [file normalize $target_dir] [file dirname [file normalize [info script]]]]
set common_dir                    [::fileutil::relative [file normalize $target_dir] [file normalize $script_dir/../../../../common]]
set common_src_dir                [::fileutil::relative [file normalize $target_dir] [file normalize $common_dir/src]]
set root_dir                      [::fileutil::relative [file normalize $target_dir] [file normalize $script_dir/..]]
set tb_dir			                  [::fileutil::relative [file normalize $target_dir] [file normalize $script_dir]]
set ip_gen_dir                    [::fileutil::relative [file normalize $target_dir] [file normalize $script_dir/build/ip_gen]]
set src_dir                       [::fileutil::relative [file normalize $target_dir] [file normalize $root_dir/hdl]]
set sim_dir                       [::fileutil::relative [file normalize $target_dir] [file normalize $tb_dir/src]]
set constraints_dir               [::fileutil::relative [file normalize $target_dir] [file normalize $root_dir/constr]]
set ip_repo_dir										[::fileutil::relative [file normalize $target_dir] [file normalize $common_dir/ip_repo]]

# -----------------------------------------------------------------------------
# Fetch and set the release number
# -----------------------------------------------------------------------------

set release_properties_file [::fileutil::relative [file normalize $target_dir] [file normalize $root_dir/release.properties]]
set release_properties      [ini::open $release_properties_file r]
set release_ip_version  [string trim [ini::value $release_properties "release" "ip_version"]]
set release_id              "RC_[string map {. _} $release_ip_version]"

set ip_rev_nbs [split $release_ip_version "."]
if {[llength $ip_rev_nbs] != 2} {
  puts "ERROR: Invalid IP version number: $release_ip_version"
  puts "       The IP version must be in the format <x.x>"
  puts "Exiting."
  exit 1
}

set ip_major_rev_nb [lindex $ip_rev_nbs 0]
set ip_minor_rev_nb [lindex $ip_rev_nbs 1]

puts "INFO: IP Version: $release_ip_version"


# -----------------------------------------------------------------------------
# Creating Project
# -----------------------------------------------------------------------------

puts "INFO: Creating $project_name project with release id $release_id at [file normalize $target_dir] ..."

# Create project
create_project -force $project_name $target_dir

# Set the directory path for the new project
set  proj_dir         [get_property directory [current_project]]
set  checkpoint_dir   [::fileutil::relative [file normalize $target_dir] [file normalize $proj_dir/checkpoints]]
file mkdir $checkpoint_dir

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

# -----------------------------------------------------------------------------
# Source fileset
# -----------------------------------------------------------------------------
# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# -----------------------------------------------------------------------------
# IP repository custom path
# -----------------------------------------------------------------------------
set obj [get_filesets sources_1]
if { $obj != {} } {
   set_property "ip_repo_paths" "[file normalize "$ip_repo_dir"]" $obj

   # Rebuild user ip_repo's index before adding any source files
   update_ip_catalog -rebuild
}

# -----------------------------------------------------------------------------
# Import Sources
# -----------------------------------------------------------------------------

puts "INFO: Importing sources into 'sources_1'..."

# Set 'sources_1' fileset object
set sources_1_obj [get_filesets sources_1]

# Add VHDL sources
set vhdl_sources [list \
    [file normalize "$common_src_dir/utils/ccam_utils/xilinx/ccam_utils.vhd"] \
    [file normalize "$common_src_dir/utils/ccam_evt_types_v2/ccam_evt_types.vhd"] \
    [file normalize "$common_src_dir/utils/ccam_evt_types_v3.vhd"] \
    [file normalize "$common_src_dir/verification/evt_record.vhd"] \
    [file normalize "$common_src_dir/verification/evt_replay.vhd"] \
]

set sim_sources [list \
		[file normalize "$common_src_dir/verification/axil_master_bfm/axi_lite_master_bfm.vhd"] \
		[file normalize "$common_src_dir/verification/clk_rst_bfm/clk_rst_gen.vhd"] \
		[file normalize "$common_src_dir/verification/clk_rst_bfm/clk_rst_bfm.vhd"] \
    [file normalize "$common_src_dir/verification/axi_lite_reg_write_catcher.vhd"] \
    [file normalize "$sim_dir/axi4s_tlast_checker.vhd"] \
		[file normalize "$sim_dir/ps_host_if_tb.vhd"] \
]

# Insert Reg Bank files
# set regbank_files_list_name [file normalize $reg_banks_src_dir/files_list.txt]
#
# if { [file exists $regbank_files_list_name] == 1 } {
#   set fp              [open $regbank_files_list_name r]
#   set files_list_data [read $fp]
#   set files_list      [regexp -all -inline {\S+} $files_list_data]
#
#   foreach files $files_list {
#     set file_target [file normalize $files]
#     if (![file exists $file_target]) {
#       puts "File not found. Skipping: ${file_target}"
#     } else {
#       set system_vhdl_sources [linsert $system_vhdl_sources 0 $file_target]
#     }
#   }
# }

# Insert Reg Bank files
set regbank_files_list_name [file normalize "$src_dir/ps_host_if_reg_bank_pkg.vhd"]
set vhdl_sources [linsert $vhdl_sources 0 $regbank_files_list_name]


# Add VHDL RTL source files
add_files -norecurse -quiet -fileset $sources_1_obj $vhdl_sources
foreach file $vhdl_sources {
    set file_obj [get_files -of_objects $sources_1_obj [list "*$file"]]
    set_property "file_type" "VHDL" $file_obj
}

# Add VHDL sim source files
add_files -norecurse -fileset $sources_1_obj $sim_sources
foreach file $sim_sources {
    set file_obj [get_files -of_objects $sources_1_obj [list "*$file"]]
    set_property -name "file_type" -value "VHDL" -objects $file_obj
		set_property -name "used_in" -value "simulation" -objects $file_obj
		set_property -name "used_in_synthesis" -value "0" -objects $file_obj
}

puts "INFO: Create System Verilog sources list"
set system_verilog_sources [list \
]

set verilog_sources $system_verilog_sources
add_files -norecurse -quiet -fileset $sources_1_obj $verilog_sources

puts "INFO: Create IP and Generate"

set ip_name "ps_host_if"
set ip_inst_name ${ip_name}_0

# Create IP
create_ip -name $ip_name -vendor Prophesee -library ip -version $ip_major_rev_nb.$ip_minor_rev_nb -module_name $ip_inst_name -dir $ip_gen_dir
generate_target {instantiation_template} [get_files [file normalize $ip_gen_dir/$ip_inst_name/$ip_inst_name.xci]]
generate_target all [get_files  [file normalize $ip_gen_dir/$ip_inst_name/$ip_inst_name.xci]]

# Add IP
set file $ip_inst_name/$ip_inst_name.xci
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "generate_files_for_reference" -value "0" -objects $file_obj
set_property -name "registered_with_manager" -value "1" -objects $file_obj
if { ![get_property "is_locked" $file_obj] } {
  set_property -name "synth_checkpoint_mode" -value "Singular" -objects $file_obj
}

# Set the project's ID and version if needed
set_property generic [list \
] $sources_1_obj

puts "INFO: Create sim fileset"
# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset file properties for local files
# None

set normalize_pattern_dir [file normalize "$tb_dir/pattern"]

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
# Set the pattern file
set_property generic [list \
    AXIL_MASTER_PATTERN_FILE_G=$normalize_pattern_dir/axil_bfm_file.pat \
    IN_DATA_FILE_PATH_G=$normalize_pattern_dir/in_evt_file.evt \
    REF_DATA_FILE_PATH_G=$normalize_pattern_dir/ref_evt_file.evt \
    TIMEOUT_G=5000 \
] $obj

set_property -name "top" -value "ps_host_if_tb" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj
set_property -name "xsim.simulate.log_all_signals" -value "1" -objects $obj
set_property -name "xsim.simulate.runtime" -value "10ms" -objects [get_filesets sim_1]

puts "INFO: Finished $project_name project creation."
