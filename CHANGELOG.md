# Prophesee KV260 Project Changelog

## 1.0.0 - (2024-11-08)

### Added

* Script to generate IP simulation projects

### Changed

* PL clock frequency set to 125MHz

* New IPs for kv260 project:
    - axis_tkeep_handler v2.0
    - event_stream_smart_tracker v2.0
    - ps_host_if v3.0

* Directory structure

### Removed

* Previous IP versions

## 0.2.3 - (2024-05-03)

### Changed

* License changed to Apache-2.0


## 0.2.2 - (2024-04-18)

### Added

* First release of kv260 project, with:
    - Project generation script
    - Simulation pattern sources
    - Prophesee IPs for Vivado (with their standalone testbenches when they exist):
      - axis_tkeep_handler v1.1 (Managing the TKEEP signal)
      - event_stream_smart_tracker v1.0 (Back-pressure control and overflow management)
      - ps_host_if v2.1 (Interface with DMA and PS unit, also control tlast timeout)
