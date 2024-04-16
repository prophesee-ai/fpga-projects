## 0.1.0 - (2024-03-06)
---

### New
* First released of kv260 project, with:
    - Project generation scripts
    - Simulation pattern sources
    - List of PSEE IPs for Vivado :
      - PS_HOST_IF (Interface with DMA and PS Unit, also control tlast timeout)
      - EVENT_STREAM_SMART_TRACKER (BackPressure control and management of overflow)
      - TKEEP_HANDLER (Managing the TKEEP signals)
      - Among with their standalone test-benches if exists