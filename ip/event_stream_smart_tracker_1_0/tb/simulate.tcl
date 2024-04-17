# Copyright (c) Prophesee S.A. - All Rights Reserved
# Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
# You may not use this file except in compliance with these License T&C's.

if [expr $argc == 0] {
  launch_simulation
} else {
  puts "Number of simulations to run: [llength $argv]"
  foreach i $argv {
    puts "Launching simuation: $i ..."
    # Set current simset
    launch_simulation -simset $i
    run all
  }
}
