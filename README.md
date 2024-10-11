# Prophesee FPGA Projects

## Overview

This repository contains the source files and scripts necessary to build Prophesee FPGA projects.

## Requirements

The projects in this repository have been tested and validated on the following setup:

- Ubuntu 20.04.6 LTS
- AMD Vivado 2022.2 (64-bit) with installed support for Zynq US+ Devices

Before running any Tcl script provided in this repository or before launching Vivado GUI you need to source the shell script located in the install directory of Vivado:

    source Vivado/2022.2/settings64.sh

## Content

### Prophesee FPGA Projects

The **projects** directory contains complete FPGA projects for AMD Vivado. Projects can be build using the script present in the **projects/project_name/scripts** directory, e.g.:

    ./projects/kv260/scripts/kv260.tcl

The Vivado project will be generated in the **build/projects** directory. It can be opened with Vivado GUI in order to run the synthesis, the implementation and to generate the bitstream:

    vivado build/projects/kv260/kv260.xpr

Refer to the **README.md** file in the **projects/project_name** directory for details about a particular FPGA project.

### Prophesee Event Processing IPs

The IP directory contains Prophesee Event Processing IPs used in the FPGA projects. These IPs can be simulated independently from a FPGA project. For that you can use the script `create_ip_sim_project.tcl` available in the **scripts** directory:

    ./scripts/create_ip_sim_project.tcl -tclargs --project_name ip_name_X_Y

The Vivado project will be generated in the **build/ip** directory.

Adding the `--run` option to the tcl script, all testcases simulations are run during the project build:

    ./scripts/create_ip_sim_project.tcl -tclargs --project_name ip_name_X_Y --run

## Support

For additional information or support, check our [Knowledge Center](https://support.prophesee.ai/).
