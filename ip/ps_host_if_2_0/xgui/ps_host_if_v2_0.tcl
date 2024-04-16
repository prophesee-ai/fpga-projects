# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Group
  set AXI4-Lite_Register_Addressing [ipgui::add_group $IPINST -name "AXI4-Lite Register Addressing" -display_name {AXI4-Lite Register Bus}]
  ipgui::add_param $IPINST -name "AXIL_ADDR_WIDTH_G" -parent ${AXI4-Lite_Register_Addressing} -show_range false
  ipgui::add_param $IPINST -name "AXIL_DATA_WIDTH_G" -parent ${AXI4-Lite_Register_Addressing} -widget comboBox

  #Adding Group
  set AXI4-Stream_Event_Stream [ipgui::add_group $IPINST -name "AXI4-Stream Event Stream"]
  ipgui::add_param $IPINST -name "AXIS_TDATA_WIDTH_G" -parent ${AXI4-Stream_Event_Stream} -widget comboBox
  ipgui::add_param $IPINST -name "AXIS_TUSER_WIDTH_G" -parent ${AXI4-Stream_Event_Stream}

  #Adding Group
  set Asynchronous_FIFO [ipgui::add_group $IPINST -name "Asynchronous FIFO"]
  ipgui::add_param $IPINST -name "MEMORY_TYPE_G" -parent ${Asynchronous_FIFO} -widget comboBox
  ipgui::add_param $IPINST -name "AFIFO_DEPTH_G" -parent ${Asynchronous_FIFO}


}

proc update_PARAM_VALUE.AFIFO_DEPTH_G { PARAM_VALUE.AFIFO_DEPTH_G } {
	# Procedure called to update AFIFO_DEPTH_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AFIFO_DEPTH_G { PARAM_VALUE.AFIFO_DEPTH_G } {
	# Procedure called to validate AFIFO_DEPTH_G
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

proc update_PARAM_VALUE.AXIS_TDATA_WIDTH_G { PARAM_VALUE.AXIS_TDATA_WIDTH_G } {
	# Procedure called to update AXIS_TDATA_WIDTH_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_TDATA_WIDTH_G { PARAM_VALUE.AXIS_TDATA_WIDTH_G } {
	# Procedure called to validate AXIS_TDATA_WIDTH_G
	return true
}

proc update_PARAM_VALUE.AXIS_TUSER_WIDTH_G { PARAM_VALUE.AXIS_TUSER_WIDTH_G } {
	# Procedure called to update AXIS_TUSER_WIDTH_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_TUSER_WIDTH_G { PARAM_VALUE.AXIS_TUSER_WIDTH_G } {
	# Procedure called to validate AXIS_TUSER_WIDTH_G
	return true
}

proc update_PARAM_VALUE.MEMORY_TYPE_G { PARAM_VALUE.MEMORY_TYPE_G } {
	# Procedure called to update MEMORY_TYPE_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MEMORY_TYPE_G { PARAM_VALUE.MEMORY_TYPE_G } {
	# Procedure called to validate MEMORY_TYPE_G
	return true
}

proc update_PARAM_VALUE.C_axil_reg_BASEADDR { PARAM_VALUE.C_axil_reg_BASEADDR } {
	# Procedure called to update C_axil_reg_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_axil_reg_BASEADDR { PARAM_VALUE.C_axil_reg_BASEADDR } {
	# Procedure called to validate C_axil_reg_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_axil_reg_HIGHADDR { PARAM_VALUE.C_axil_reg_HIGHADDR } {
	# Procedure called to update C_axil_reg_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_axil_reg_HIGHADDR { PARAM_VALUE.C_axil_reg_HIGHADDR } {
	# Procedure called to validate C_axil_reg_HIGHADDR
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

proc update_MODELPARAM_VALUE.AXIS_TDATA_WIDTH_G { MODELPARAM_VALUE.AXIS_TDATA_WIDTH_G PARAM_VALUE.AXIS_TDATA_WIDTH_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_TDATA_WIDTH_G}] ${MODELPARAM_VALUE.AXIS_TDATA_WIDTH_G}
}

proc update_MODELPARAM_VALUE.AXIS_TUSER_WIDTH_G { MODELPARAM_VALUE.AXIS_TUSER_WIDTH_G PARAM_VALUE.AXIS_TUSER_WIDTH_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_TUSER_WIDTH_G}] ${MODELPARAM_VALUE.AXIS_TUSER_WIDTH_G}
}

proc update_MODELPARAM_VALUE.MEMORY_TYPE_G { MODELPARAM_VALUE.MEMORY_TYPE_G PARAM_VALUE.MEMORY_TYPE_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MEMORY_TYPE_G}] ${MODELPARAM_VALUE.MEMORY_TYPE_G}
}

proc update_MODELPARAM_VALUE.AFIFO_DEPTH_G { MODELPARAM_VALUE.AFIFO_DEPTH_G PARAM_VALUE.AFIFO_DEPTH_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AFIFO_DEPTH_G}] ${MODELPARAM_VALUE.AFIFO_DEPTH_G}
}
