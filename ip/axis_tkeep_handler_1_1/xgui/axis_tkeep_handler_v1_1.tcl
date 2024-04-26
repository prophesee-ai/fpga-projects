# Copyright (c) Prophesee S.A.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "AXIS_TDATA_WIDTH_G" -widget comboBox
  ipgui::add_param $IPINST -name "AXIS_TUSER_WIDTH_G"

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

