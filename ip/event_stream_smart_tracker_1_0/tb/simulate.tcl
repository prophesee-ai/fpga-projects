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
