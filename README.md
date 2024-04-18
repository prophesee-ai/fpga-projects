**Prophesee FPGA Projects**
===========================

Overview
--------

This Prophesee repository contains the source files and scripts necessary to build Prophesee FPGA projects.

For additional information or support, please contact Prophesee Support at [support@prophesee.ai](mailto:support@prophesee.ai)

Package Structure
-----------------

### Contents

The following table describes the main scripts and folders of the package.

| Package File / Folder                   | Contents                                                                    |
| --------------------------------------- | --------------------------------------------------------------------------- |
| README.md                               | Readme file with package info                                               |
| ip                                      | IP repository with Prophesee IPs                                            |
| projects/kv260                          | TCL script and sources for kv260 project generation and simulation          |


The first levels of the package hierarchy are shown below:

```
fpga-projects
├── README.md
├── ip
│   ├── axis_tkeep_handler_1_1
│   ├── event_stream_smart_tracker_1_0
│   └── ps_host_if_2_1
└── projects
    └── kv260
        ├── README.md
        ├── kv260_RC_0_2_2.tcl
        └── srcs
            ├── coe
            ├── constr
            ├── hdl
            └── sim_tc_001
```
