

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "event_stream_smart_tracker" "NUM_INSTANCES" "DEVICE_ID"  "C_axil_s_BASEADDR" "C_axil_s_HIGHADDR"
}
