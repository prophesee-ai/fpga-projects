
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/event_stream_smart_tracker_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  #Adding Group
  set Enable [ipgui::add_group $IPINST -name "Enable" -parent ${Page_0} -display_name {Enabling Event Flow Control}]
  set ENABLE_SMART_DROP_G [ipgui::add_param $IPINST -name "ENABLE_SMART_DROP_G" -parent ${Enable}]
  set_property tooltip {Smart dropper generation} ${ENABLE_SMART_DROP_G}
  ipgui::add_param $IPINST -name "ENABLE_TS_CHECKER_G" -parent ${Enable}
  set ENABLE_TH_RECOVERY_G [ipgui::add_param $IPINST -name "ENABLE_TH_RECOVERY_G" -parent ${Enable}]
  set_property tooltip {Analyse the event stream and add missing TH event(s) if missing or gap} ${ENABLE_TH_RECOVERY_G}

  #Adding Group
  set Smart_Dropper_parameters [ipgui::add_group $IPINST -name "Smart Dropper parameters" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "SMART_DROP_FIFO_DEPTH_G" -parent ${Smart_Dropper_parameters}
  ipgui::add_param $IPINST -name "SMART_DROP_REDUCE_FLOW_THRESHOLD_G" -parent ${Smart_Dropper_parameters}
  ipgui::add_param $IPINST -name "SMART_DROP_ALL_THRESHOLD_G" -parent ${Smart_Dropper_parameters}

  #Adding Group
  set Generic_parameter [ipgui::add_group $IPINST -name "Generic parameter" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "TIME_HIGH_PERIOD_US_G" -parent ${Generic_parameter}
  ipgui::add_param $IPINST -name "BYPASS_PIPELINE_STAGES_G" -parent ${Generic_parameter} -show_range false



}

proc update_PARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G { PARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G PARAM_VALUE.ENABLE_SMART_DROP_G } {
	# Procedure called to update SMART_DROP_ALL_THRESHOLD_G when any of the dependent parameters in the arguments change
	
	set SMART_DROP_ALL_THRESHOLD_G ${PARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G}
	set ENABLE_SMART_DROP_G ${PARAM_VALUE.ENABLE_SMART_DROP_G}
	set values(ENABLE_SMART_DROP_G) [get_property value $ENABLE_SMART_DROP_G]
	if { [gen_USERPARAMETER_SMART_DROP_ALL_THRESHOLD_G_ENABLEMENT $values(ENABLE_SMART_DROP_G)] } {
		set_property enabled true $SMART_DROP_ALL_THRESHOLD_G
	} else {
		set_property enabled false $SMART_DROP_ALL_THRESHOLD_G
	}
}

proc validate_PARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G { PARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G } {
	# Procedure called to validate SMART_DROP_ALL_THRESHOLD_G
	return true
}

proc update_PARAM_VALUE.SMART_DROP_FIFO_DEPTH_G { PARAM_VALUE.SMART_DROP_FIFO_DEPTH_G PARAM_VALUE.ENABLE_SMART_DROP_G } {
	# Procedure called to update SMART_DROP_FIFO_DEPTH_G when any of the dependent parameters in the arguments change
	
	set SMART_DROP_FIFO_DEPTH_G ${PARAM_VALUE.SMART_DROP_FIFO_DEPTH_G}
	set ENABLE_SMART_DROP_G ${PARAM_VALUE.ENABLE_SMART_DROP_G}
	set values(ENABLE_SMART_DROP_G) [get_property value $ENABLE_SMART_DROP_G]
	if { [gen_USERPARAMETER_SMART_DROP_FIFO_DEPTH_G_ENABLEMENT $values(ENABLE_SMART_DROP_G)] } {
		set_property enabled true $SMART_DROP_FIFO_DEPTH_G
	} else {
		set_property enabled false $SMART_DROP_FIFO_DEPTH_G
	}
}

proc validate_PARAM_VALUE.SMART_DROP_FIFO_DEPTH_G { PARAM_VALUE.SMART_DROP_FIFO_DEPTH_G } {
	# Procedure called to validate SMART_DROP_FIFO_DEPTH_G
	return true
}

proc update_PARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G { PARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G PARAM_VALUE.ENABLE_SMART_DROP_G } {
	# Procedure called to update SMART_DROP_REDUCE_FLOW_THRESHOLD_G when any of the dependent parameters in the arguments change
	
	set SMART_DROP_REDUCE_FLOW_THRESHOLD_G ${PARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G}
	set ENABLE_SMART_DROP_G ${PARAM_VALUE.ENABLE_SMART_DROP_G}
	set values(ENABLE_SMART_DROP_G) [get_property value $ENABLE_SMART_DROP_G]
	if { [gen_USERPARAMETER_SMART_DROP_REDUCE_FLOW_THRESHOLD_G_ENABLEMENT $values(ENABLE_SMART_DROP_G)] } {
		set_property enabled true $SMART_DROP_REDUCE_FLOW_THRESHOLD_G
	} else {
		set_property enabled false $SMART_DROP_REDUCE_FLOW_THRESHOLD_G
	}
}

proc validate_PARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G { PARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G } {
	# Procedure called to validate SMART_DROP_REDUCE_FLOW_THRESHOLD_G
	return true
}

proc update_PARAM_VALUE.AXIL_ADDR_WIDTH_G { PARAM_VALUE.AXIL_ADDR_WIDTH_G } {
	# Procedure called to update AXIL_ADDR_WIDTH_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIL_ADDR_WIDTH_G { PARAM_VALUE.AXIL_ADDR_WIDTH_G } {
	# Procedure called to validate AXIL_ADDR_WIDTH_G
	return true
}

proc update_PARAM_VALUE.AXIL_DATA_WIDTH_G { PARAM_VALUE.AXIL_DATA_WIDTH_G } {
	# Procedure called to update AXIL_DATA_WIDTH_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIL_DATA_WIDTH_G { PARAM_VALUE.AXIL_DATA_WIDTH_G } {
	# Procedure called to validate AXIL_DATA_WIDTH_G
	return true
}

proc update_PARAM_VALUE.BYPASS_PIPELINE_STAGES_G { PARAM_VALUE.BYPASS_PIPELINE_STAGES_G } {
	# Procedure called to update BYPASS_PIPELINE_STAGES_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BYPASS_PIPELINE_STAGES_G { PARAM_VALUE.BYPASS_PIPELINE_STAGES_G } {
	# Procedure called to validate BYPASS_PIPELINE_STAGES_G
	return true
}

proc update_PARAM_VALUE.ENABLE_SMART_DROP_G { PARAM_VALUE.ENABLE_SMART_DROP_G } {
	# Procedure called to update ENABLE_SMART_DROP_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_SMART_DROP_G { PARAM_VALUE.ENABLE_SMART_DROP_G } {
	# Procedure called to validate ENABLE_SMART_DROP_G
	return true
}

proc update_PARAM_VALUE.ENABLE_TH_RECOVERY_G { PARAM_VALUE.ENABLE_TH_RECOVERY_G } {
	# Procedure called to update ENABLE_TH_RECOVERY_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_TH_RECOVERY_G { PARAM_VALUE.ENABLE_TH_RECOVERY_G } {
	# Procedure called to validate ENABLE_TH_RECOVERY_G
	return true
}

proc update_PARAM_VALUE.ENABLE_TS_CHECKER_G { PARAM_VALUE.ENABLE_TS_CHECKER_G } {
	# Procedure called to update ENABLE_TS_CHECKER_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_TS_CHECKER_G { PARAM_VALUE.ENABLE_TS_CHECKER_G } {
	# Procedure called to validate ENABLE_TS_CHECKER_G
	return true
}

proc update_PARAM_VALUE.TIME_HIGH_PERIOD_US_G { PARAM_VALUE.TIME_HIGH_PERIOD_US_G } {
	# Procedure called to update TIME_HIGH_PERIOD_US_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TIME_HIGH_PERIOD_US_G { PARAM_VALUE.TIME_HIGH_PERIOD_US_G } {
	# Procedure called to validate TIME_HIGH_PERIOD_US_G
	return true
}

proc update_PARAM_VALUE.C_axil_s_BASEADDR { PARAM_VALUE.C_axil_s_BASEADDR } {
	# Procedure called to update C_axil_s_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_axil_s_BASEADDR { PARAM_VALUE.C_axil_s_BASEADDR } {
	# Procedure called to validate C_axil_s_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_axil_s_HIGHADDR { PARAM_VALUE.C_axil_s_HIGHADDR } {
	# Procedure called to update C_axil_s_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_axil_s_HIGHADDR { PARAM_VALUE.C_axil_s_HIGHADDR } {
	# Procedure called to validate C_axil_s_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.ENABLE_TH_RECOVERY_G { MODELPARAM_VALUE.ENABLE_TH_RECOVERY_G PARAM_VALUE.ENABLE_TH_RECOVERY_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_TH_RECOVERY_G}] ${MODELPARAM_VALUE.ENABLE_TH_RECOVERY_G}
}

proc update_MODELPARAM_VALUE.ENABLE_SMART_DROP_G { MODELPARAM_VALUE.ENABLE_SMART_DROP_G PARAM_VALUE.ENABLE_SMART_DROP_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_SMART_DROP_G}] ${MODELPARAM_VALUE.ENABLE_SMART_DROP_G}
}

proc update_MODELPARAM_VALUE.SMART_DROP_FIFO_DEPTH_G { MODELPARAM_VALUE.SMART_DROP_FIFO_DEPTH_G PARAM_VALUE.SMART_DROP_FIFO_DEPTH_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SMART_DROP_FIFO_DEPTH_G}] ${MODELPARAM_VALUE.SMART_DROP_FIFO_DEPTH_G}
}

proc update_MODELPARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G { MODELPARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G PARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G}] ${MODELPARAM_VALUE.SMART_DROP_REDUCE_FLOW_THRESHOLD_G}
}

proc update_MODELPARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G { MODELPARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G PARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G}] ${MODELPARAM_VALUE.SMART_DROP_ALL_THRESHOLD_G}
}

proc update_MODELPARAM_VALUE.AXIL_DATA_WIDTH_G { MODELPARAM_VALUE.AXIL_DATA_WIDTH_G PARAM_VALUE.AXIL_DATA_WIDTH_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIL_DATA_WIDTH_G}] ${MODELPARAM_VALUE.AXIL_DATA_WIDTH_G}
}

proc update_MODELPARAM_VALUE.AXIL_ADDR_WIDTH_G { MODELPARAM_VALUE.AXIL_ADDR_WIDTH_G PARAM_VALUE.AXIL_ADDR_WIDTH_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIL_ADDR_WIDTH_G}] ${MODELPARAM_VALUE.AXIL_ADDR_WIDTH_G}
}

proc update_MODELPARAM_VALUE.ENABLE_TS_CHECKER_G { MODELPARAM_VALUE.ENABLE_TS_CHECKER_G PARAM_VALUE.ENABLE_TS_CHECKER_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_TS_CHECKER_G}] ${MODELPARAM_VALUE.ENABLE_TS_CHECKER_G}
}

proc update_MODELPARAM_VALUE.TIME_HIGH_PERIOD_US_G { MODELPARAM_VALUE.TIME_HIGH_PERIOD_US_G PARAM_VALUE.TIME_HIGH_PERIOD_US_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TIME_HIGH_PERIOD_US_G}] ${MODELPARAM_VALUE.TIME_HIGH_PERIOD_US_G}
}

proc update_MODELPARAM_VALUE.BYPASS_PIPELINE_STAGES_G { MODELPARAM_VALUE.BYPASS_PIPELINE_STAGES_G PARAM_VALUE.BYPASS_PIPELINE_STAGES_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BYPASS_PIPELINE_STAGES_G}] ${MODELPARAM_VALUE.BYPASS_PIPELINE_STAGES_G}
}

