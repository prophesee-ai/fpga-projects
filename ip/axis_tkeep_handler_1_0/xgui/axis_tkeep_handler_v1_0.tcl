# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "AXIL_ADDR_WIDTH_G" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXIL_DATA_WIDTH_G" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "DATA_BUS_WIDTH_G" -parent ${Page_0} -widget comboBox


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

proc update_PARAM_VALUE.DATA_BUS_WIDTH_G { PARAM_VALUE.DATA_BUS_WIDTH_G } {
	# Procedure called to update DATA_BUS_WIDTH_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_BUS_WIDTH_G { PARAM_VALUE.DATA_BUS_WIDTH_G } {
	# Procedure called to validate DATA_BUS_WIDTH_G
	return true
}


proc update_MODELPARAM_VALUE.AXIL_ADDR_WIDTH_G { MODELPARAM_VALUE.AXIL_ADDR_WIDTH_G PARAM_VALUE.AXIL_ADDR_WIDTH_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIL_ADDR_WIDTH_G}] ${MODELPARAM_VALUE.AXIL_ADDR_WIDTH_G}
}

proc update_MODELPARAM_VALUE.AXIL_DATA_WIDTH_G { MODELPARAM_VALUE.AXIL_DATA_WIDTH_G PARAM_VALUE.AXIL_DATA_WIDTH_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIL_DATA_WIDTH_G}] ${MODELPARAM_VALUE.AXIL_DATA_WIDTH_G}
}

proc update_MODELPARAM_VALUE.DATA_BUS_WIDTH_G { MODELPARAM_VALUE.DATA_BUS_WIDTH_G PARAM_VALUE.DATA_BUS_WIDTH_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_BUS_WIDTH_G}] ${MODELPARAM_VALUE.DATA_BUS_WIDTH_G}
}

