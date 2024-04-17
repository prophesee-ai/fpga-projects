**Prophesee's FPGA Projects**
==========================================

Overview
--------

This Prophesee repository contains the source files and scripts necessary to build Psee's FPGA projects.

For additional information or support, please contact Prophesee Support at [support@prophesee.ai](mailto:support@prophesee.ai)

Package Structure
-----------------

### Contents

The following table describes the main scripts and folders of the package.

| Package File / Folder                   | Contents                                                                    |
| --------------------------------------- | --------------------------------------------------------------------------- |
| README.md                               | Readme file with package info                                               |
| ip                                      | IP Repo directory with PSEE IPs                                             |
| projects/kv260                          | TCL script for project generation, constraint file and top test bench       |


The first levels of the package hierarchy are shown below.

```
fpga-projects
├── README.md
├── ip
│   ├── axis_tkeep_handler_1_1
│   ├── event_stream_smart_tracker_1_0
│   └── ps_host_if_2_1
├── projects
|   └── kv260
│       ├── CHANGELOG.md
│       ├── README.md
│       ├── kv260_RC_0_1_0.tcl
│       ├── kv260_system_register.coe
│       └── srcs
│           ├── sources_1
│           ├── constrs_1
│           └── sim_tc_001
```

