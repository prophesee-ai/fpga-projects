**Prophesee's KV260 project**
==========================================

Overview
--------

This Prophesee KV260 package contains the source files and scripts necessary to build the **KV260** FPGA's project, named **kv260**. This projet targets the **Kria Plafeform: kv260** with FPGA **xck26** from **Xilinx**.

This document provides instructions on:
- Environment Requirements and Setup
- Project Creation
- Project Synthesis and Implementation
- Project Simulation

For additional information or support, please contact Prophesee Support at [support@prophesee.ai](mailto:support@prophesee.ai)

Package Structure
-----------------

### Contents

The following table describes the main scripts and folders of the package.

| Package File / Folder                   | Contents                                                                    |
| --------------------------------------- | --------------------------------------------------------------------------- |
| README.md                               | Readme file with package info                                               |
| CHANGELOG.md                            | Changelog file with update info                                             |
| kv260                                   | TCL script for project generation, constraint file and top test bench       |


The first levels of the package hierarchy are shown below.

```
kv260
├── CHANGELOG.md
├── README.md
├── kv260_RC_0_1_0.tcl
└── srcs
    ├── coe
    ├── constr
    ├── hdl
    └── sim_tc_001
```


## Environment Setup

### Requirements

This project has been tested and validated using the following configuration:

- Operating System:
  - Distributor ID: Ubuntu
  - Description: Ubuntu 20.04.6 LTS
  - Release: 20.04.6 LTS (Focal Fossa)
  - Codename: Focal
  - Terminal: GNU bash, version 5.0.17(1)-release (x86_64-pc-linux-gnu)
- Xilinx Vivado Toolset:
  - Vivado v2022.2.1 (64-bit)
  - SW Build 3719031 on Thu Dec  8 18:35:06 MST 2022
  - IP Build 3718410 on Thu Dec  8 22:11:41 MST 2022
  - With installed support for Zynq US+ Devices

### Source the Xilinx Vivado Toolset
Open a bash terminal and ensure you have sourced the Vivado 2022.2 Toolset, .i.e:
```
$ /opt/eda/xilinx/2022.2/Vivado/2022.2/settings64.sh
```
Then check the tool version as follows:
```
$ vivado -version
Vivado v2022.2.1 (64-bit)
SW Build 3719031 on Thu Dec  8 18:35:06 MST 2022
IP Build 3718410 on Thu Dec  8 22:11:41 MST 2022
Tool Version Limit: 2022.10
Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
```

## Create a project using the TCL script

To create the project, go into the **kv260** directory.
Then run the following commands:

```
$ vivado -mode batch -source kv260_RC_0_1_0.tcl -tclargs --project_name "kv260"
$ vivado kv260.xpr
```

## Top Simulations

The project contains simulations sources with supported references files for input and matchpoint output.
For now, top simulation of the project contains one sanity test case, running standalone with full integration of the global design:

| ID     | Module(s) tested   | Description               |
| ------ | ------------------ | ------------------------- |
| TC_001 | TOP                | Sanity test               |

### Launch Top Simulation

To launch the top project simulation tc_001, select the tc_001 simulation source into the project manager settings and follow the default Vivado workflow using the GUI

## Synthesis and Implementation

The project contains the following synthesis and implementation runs pre-configured:

| Run Name | Description        | Strategy                  |
| -------- | ------------------ | ------------------------- |
| synth_1  | Synthesis run      | Vivado Synthesis Defaults |
| impl_1   | Implementation run | Performance_Retiming      |

### Launch Synthesis and Implementation

To launch the project synthesis and implementation, follow the default Vivado workflow using the GUI.

#### Launch Synthesis and Implementation via Vivado GUI

##### Run Generate Bitstream Step

With the *kv260* project opened on the Vivado GUI, click on:

*PROGRAM AND DEBUG --> Generate Bitstream*

##### Check Results

To check that the design successfully meets the timing closure, run the timing analysis as follows:

*IMPLEMENTATION --> Open Implemented Design --> Report Timing Summary*

Ensure that there is no timing violations.

**Note:** There can be small variations between synthesis and implementation runs.
We're continuously working to improve the predictability and robustness of the system.
If nevertheless, the implementation run fails, please relaunch it:
1. Right-click on **synth_1** run in **Design Runs** tab
2. Click on **Reset Runs**
3. Relaunch the synthesis and implementation runs: **PROGRAM AND DEBUG** --> **Generate Bitstream**

The project's bitstream file will be generated at:

*kv260/kv260.runs/impl_1/kv260.bit*
