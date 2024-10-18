#!/usr/bin/env -S vivado -mode batch -notrace -source

if { $::argc != 1 } {
  puts "Usage is \"./scripts/create_project.tcl -tclargs <project_name>\""
  exit 1
}

set project_name [string trim [lindex $::argv 0]]
set project_dir  [file normalize [file dirname [info script]]/../projects/$project_name]

source "$project_dir/scripts/$project_name.tcl"
