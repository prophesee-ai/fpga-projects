## 1.0.0 - (2024-06-10)
---

### New
* Update kv260 project to Vivado 2024.1:
    - Update MIPI CSI-2 RX Subsystem IP from 5.2 to 6.0
    - Update Zynq Ultrascale+ MPSoc IP from 3.4 to 3.5
    - Update minor (revision) on some IPs


## 0.2.3 - (2024-05-03)
---

### New
* License changed to Apache-2.0
* Missing logo added to Prophesee IPs


## 0.2.2 - (2024-04-18)
---

### New
* First release of kv260 project, with:
    - Project generation script
    - Simulation pattern sources
    - Prophesee IPs for Vivado (with their standalone testbenches when they exist):
      - ps_host_if v2.1 (Interface with DMA and PS unit, also control tlast timeout)
      - event_stream_smart_tracker v1.0 (Back-pressure control and overflow management)
      - axis_tkeep_handler v1.1 (Managing the TKEEP signals)
