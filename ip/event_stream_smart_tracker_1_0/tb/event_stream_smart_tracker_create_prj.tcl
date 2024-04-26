# Copyright (c) Prophesee S.A.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

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
set root_dir                      [::fileutil::relative [file normalize $target_dir] [file normalize $script_dir/..]]
set tb_dir                        [::fileutil::relative [file normalize $target_dir] [file normalize $script_dir]]
set sim_dir                       [::fileutil::relative [file normalize $target_dir] [file normalize $tb_dir/src]]
set ip_repo_dir                   [::fileutil::relative [file normalize $target_dir] [file normalize $root_dir/..]]
set ip_gen_dir                    [::fileutil::relative [file normalize $target_dir] [file normalize $target_dir/ip_gen]]

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
    [file normalize "$sim_dir/ccam_utils.vhd"] \
    [file normalize "$sim_dir/ccam_evt_types.vhd"] \
    [file normalize "$sim_dir/ccam_evt_types_v3.vhd"] \
    [file normalize "$sim_dir/evt_record.vhd"] \
    [file normalize "$sim_dir/evt_replay.vhd"] \
]
    
set sim_sources [list \
    [file normalize "$sim_dir/axi_lite_master_bfm.vhd"] \
    [file normalize "$sim_dir/clk_rst_gen.vhd"] \
    [file normalize "$sim_dir/clk_rst_bfm.vhd"] \
    [file normalize "$sim_dir/axi4s_pipeline_stage_ena.vhd"] \
    [file normalize "$sim_dir/axi_lite_reg_write_catcher.vhd"] \
    [file normalize "$sim_dir/event_stream_smart_tracker_tb.vhd"] \
]

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

set ip_name "event_stream_smart_tracker"
set ip_inst_name ${ip_name}_0

# Create IP
create_ip -name $ip_name -vendor prophesee.ai -library ip -version $ip_major_rev_nb.$ip_minor_rev_nb -module_name $ip_inst_name -dir $ip_gen_dir
set_property -dict [list \
  CONFIG.ENABLE_TS_CHECKER_G {true} \
] [get_ips $ip_inst_name]
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

puts "INFO: Create SIM_TC_001 : Sanity test"
# Create 'sim_tc_001' fileset (if not found)
if {[string equal [get_filesets -quiet sim_tc_001] ""]} {
  create_fileset -simset sim_tc_001
}

# Set 'sim_tc_001' fileset file properties for local files
# None

set normalize_pattern_dir [file normalize "$tb_dir/tc_001/pattern"]

# Set 'sim_tc_001' fileset properties
set obj [get_filesets sim_tc_001]
# Set the pattern file
set_property generic [list \
    AXIL_MASTER_PATTERN_FILE_G=$normalize_pattern_dir/axil_bfm_file.pat \
    IN_DATA_FILE_PATH_G=$normalize_pattern_dir/in_evt_file.evt \
    REF_DATA_FILE_PATH_G=$normalize_pattern_dir/ref_evt_file.evt \
    TIMEOUT_G=1000000 \
    START_DATA_IN_TASK_G=1 \
    BACK_PRESSURE_SIM_G=false \
] $obj

set_property -name "top" -value "event_stream_smart_tracker_tb" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj
set_property -name "xsim.simulate.log_all_signals" -value "1" -objects $obj
set_property -name "xsim.simulate.runtime" -value "25ms" -objects $obj

puts "INFO: Create SIM_TC_002 : Smart Dropper typical case with Back Pressure enable (TH Recovery and TS Checker bypassed)"
# Create 'sim_tc_002' fileset (if not found)
if {[string equal [get_filesets -quiet sim_tc_002] ""]} {
  create_fileset -simset sim_tc_002
}

# Set 'sim_tc_002' fileset file properties for local files
# None

set normalize_pattern_dir [file normalize "$tb_dir/tc_002/pattern"]

# Set 'sim_tc_002' fileset properties
set obj [get_filesets sim_tc_002]
# Set the pattern file
set_property generic [list \
    AXIL_MASTER_PATTERN_FILE_G=$normalize_pattern_dir/axil_bfm_file.pat \
    IN_DATA_FILE_PATH_G=$normalize_pattern_dir/in_evt_file.evt \
    REF_DATA_FILE_PATH_G=$normalize_pattern_dir/ref_evt_file.evt \
    TIMEOUT_G=1000000 \
    START_DATA_IN_TASK_G=1 \
    BACK_PRESSURE_SIM_G=true \
] $obj

set_property -name "top" -value "event_stream_smart_tracker_tb" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj
set_property -name "xsim.simulate.log_all_signals" -value "1" -objects $obj
set_property -name "xsim.simulate.runtime" -value "25ms" -objects $obj

puts "INFO: Create SIM_TC_003 : TH Recovery typical case with Back Pressure enable (Smart Dropper enable with TH loss created. TS Checker bypassed)"
# Create 'sim_tc_003' fileset (if not found)
if {[string equal [get_filesets -quiet sim_tc_003] ""]} {
  create_fileset -simset sim_tc_003
}

# Set 'sim_tc_003' fileset file properties for local files
# None

set normalize_pattern_dir [file normalize "$tb_dir/tc_003/pattern"]

# Set 'sim_tc_003' fileset properties
set obj [get_filesets sim_tc_003]
# Set the pattern file
set_property generic [list \
    AXIL_MASTER_PATTERN_FILE_G=$normalize_pattern_dir/axil_bfm_file.pat \
    IN_DATA_FILE_PATH_G=$normalize_pattern_dir/in_evt_file.evt \
    REF_DATA_FILE_PATH_G=$normalize_pattern_dir/ref_evt_file.evt \
    TIMEOUT_G=1000000 \
    START_DATA_IN_TASK_G=1 \
    BACK_PRESSURE_SIM_G=true \
] $obj

set_property -name "top" -value "event_stream_smart_tracker_tb" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj
set_property -name "xsim.simulate.log_all_signals" -value "1" -objects $obj
set_property -name "xsim.simulate.runtime" -value "25ms" -objects $obj

puts "INFO: Create SIM_TC_004 : TS Checker typical case. TH missing in the data stream. OTHER evt generation with dropping events. (TH recovery and Smart Dropper bypassed)"
# Create 'sim_tc_004' fileset (if not found)
if {[string equal [get_filesets -quiet sim_tc_004] ""]} {
  create_fileset -simset sim_tc_004
}

# Set 'sim_tc_004' fileset file properties for local files
# None

set normalize_pattern_dir [file normalize "$tb_dir/tc_004/pattern"]

# Set 'sim_tc_004' fileset properties
set obj [get_filesets sim_tc_004]
# Set the pattern file
set_property generic [list \
    AXIL_MASTER_PATTERN_FILE_G=$normalize_pattern_dir/axil_bfm_file.pat \
    IN_DATA_FILE_PATH_G=$normalize_pattern_dir/in_evt_file.evt \
    REF_DATA_FILE_PATH_G=$normalize_pattern_dir/ref_evt_file.evt \
    TIMEOUT_G=1000000 \
    START_DATA_IN_TASK_G=1 \
    BACK_PRESSURE_SIM_G=false \
] $obj

set_property -name "top" -value "event_stream_smart_tracker_tb" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj
set_property -name "xsim.simulate.log_all_signals" -value "1" -objects $obj
set_property -name "xsim.simulate.runtime" -value "25ms" -objects $obj

puts "INFO: Create SIM_TC_005 : Sanity check with control bypass"
# Create 'sim_tc_005' fileset (if not found)
if {[string equal [get_filesets -quiet sim_tc_005] ""]} {
  create_fileset -simset sim_tc_005
}

# Set 'sim_tc_005' fileset file properties for local files
# None

set normalize_pattern_dir [file normalize "$tb_dir/tc_005/pattern"]

# Set 'sim_tc_005' fileset properties
set obj [get_filesets sim_tc_005]
# Set the pattern file
set_property generic [list \
    AXIL_MASTER_PATTERN_FILE_G=$normalize_pattern_dir/axil_bfm_file.pat \
    IN_DATA_FILE_PATH_G=$normalize_pattern_dir/in_evt_file.evt \
    REF_DATA_FILE_PATH_G=$normalize_pattern_dir/ref_evt_file.evt \
    TIMEOUT_G=1000000 \
    START_DATA_IN_TASK_G=1 \
    BACK_PRESSURE_SIM_G=false \
] $obj

set_property -name "top" -value "event_stream_smart_tracker_tb" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj
set_property -name "xsim.simulate.log_all_signals" -value "1" -objects $obj
set_property -name "xsim.simulate.runtime" -value "25ms" -objects $obj

current_fileset -simset [ get_filesets sim_tc_001 ]
delete_fileset [ get_filesets sim_1 ]

puts "INFO: Finished $project_name project creation."
