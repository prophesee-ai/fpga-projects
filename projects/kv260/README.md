**Prophesee's KRIA GENERIC**
==========================================

Overview
--------

This Prophesee System package contains the source files and scripts necessary to build the **Kria Generic** FPGA's project, named **kv260**. This projet targets the **Kria Plafeform: kv260** with FPGA **xck26** from **Xilinx**.

This document provides instructions on:
- Environment Requirements and Setup
- Project Creation
- Project Synthesis and Implementation
- Project Simulation
- IP Simulation

For additional information or support, please contact Prophesee Support at [support@prophesee.ai](mailto:support@prophesee.ai)

Package Structure
-----------------

### Contents

The following table describes the main scripts and folders of the package.

| Package File / Folder                   | Contents                                                                    |
| --------------------------------------- | --------------------------------------------------------------------------- |
| README.md                               | Readme file with package info                                               |
| CHANGELOG.md                            | Changelog file with update info                                             |
| common                                  | IP Repo directory with PSEE IP and sources for simulation                   |
| psee_generic                            | TCL script for project generation, constraint file and top test bench       |


The first levels of the package hierarchy are shown below.

```
kria_psee_generic
├── CHANGELOG.md
├── README.md
├── common
│   ├── ip_repo
│       ├── axis_tkeep_handler_1_0
│       ├── event_stream_smart_tracker_1_0
│       └── ps_host_if_2_0
│   └── src
│       ├── axi4_stream
│       ├── mipi
│       ├── utils
│       └── verification
├── psee_generic
│   ├── kv260_RC_0_1_0.tcl
│   ├── kv260_system_register.coe
│   ├── constr
│   └── tb
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

## Create the project using the TCL script

To create the project, go into the **root** directory.
Then run the following commands:

```
$ vivado -source psee_generic/kv260_RC_0_1_0.tcl -tclargs --origin_dir "./psee_generic/" --project_name "./build/kv260/kv260"
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

##### Open the *kv260* Vivado Project

To open the project with the Vivado GUI run:

```
$ vivado build/kv260/kv260.xpr
```

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

*build/kv260/kv260.runs/impl_1/kv260.bit*

## Prophesee's Kria Generic IPs

### axis_tkeep_handler_1_0 overall presentation

The tkeep handler is in charge of giving to the rest of the pipeline, a full 64bits valid data.

#### axis_tkeep_handler_1_0 overall verification and simulation

There is no test bench nor valid simulation for the moment for this IP.

### event_stream_smart_tracker_1_0 overall presentation

The ESST regulate the back pressure coming from the ps_host_if. Various parameters are accessible through the GUI interface in the Block Design and change slightly the behavior of the IP. Functions of the IP are:
  - Drop input events after a defined threshold.
  - Analysing the timestamp and raise flags if condition are not met.
  - Generate new TimeStamp event(s) such as TimeHigh if the IP detect a loss of them in the pipeline.
  - Generate OTHERS event for the user to know when the drop occurs.

#### event_stream_smart_tracker_1_0 overall verification and simulation

To create the standalone test bench for simulation run from a terminal:

```
$ cd common/ip_repo/event_stream_smart_tracker_1_0/tb/
$ vivado -source event_stream_smart_tracker_create_prj.tcl -tclargs event_stream_smart_tracker_tb
```

In the vivado GUI, select the simulation test case you want in the Project manager settings.

| ID     | Module(s) tested   | Description                                             |
| ------ | ------------------ | ------------------------------------------------------- |
| TC_001 | ESST               | Nominal case with no bypass                             |
| TC_002 | ESST               | Error case with smart dropper. Back pressure simulation |
| TC_003 | ESST               | TC_002 with TH Recovery enable -> No TH should miss     |
| TC_004 | ESST               | Error case with TS Checker                              |
| TC_005 | ESST               | Nominal case with RAW Data (no evt) and control bypass  |

### ps_host_if_2_0 overall presentation

The PS Host Interface makes the interface between the intern pipeline of the PL to give to the DMA and thus PS the input (and processed) events. Functions of the IP are:
  - Making the clock interface between PL and PS DMA.
  - Pack the events into a different data vector width if necessary.
  - Manage the tlast with TIMEOUT capability if necessary.
  - Generate counter to output stream for debug or tests.

#### ps_host_if_2_0 overall verification and simulation

To create the standalone test bench for simulation run from a terminal:

```
$ cd common/ip_repo/ps_host_if_2_0/tb/
$ vivado -source ps_host_if_create_prj.tcl -tclargs event_stream_smart_tracker_tb
```

In the vivado GUI, select the simulation test case you want in the Project manager settings.

| ID     | Module(s) tested   | Description                                             |
| ------ | ------------------ | ------------------------------------------------------- |
| TC_001 | PS_HOST_IF         | Nominal case with no bypass                             |


