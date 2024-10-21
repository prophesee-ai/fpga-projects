# Copyright (c) Prophesee S.A.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Kria KV260 Vision AI Starter Kit SOM

################################################################
# CCAM5 Interface
################################################################

# MRSTn (RPI ENABLE): HDA09 on bank 45, SOM240_1_A15
set_property PACKAGE_PIN F11      [get_ports {gpio_generic_tri_o[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {gpio_generic_tri_o[0]}]
set_property SLEW        SLOW     [get_ports {gpio_generic_tri_o[0]}]
set_property DRIVE       4        [get_ports {gpio_generic_tri_o[0]}]

# PSU_EN: HDA10 on bank 45, SOM240_1_A16
set_property PACKAGE_PIN J12      [get_ports {gpio_generic_tri_o[1]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {gpio_generic_tri_o[1]}]
set_property SLEW        SLOW     [get_ports {gpio_generic_tri_o[1]}]
set_property DRIVE       4        [get_ports {gpio_generic_tri_o[1]}]

# CCI I2C: I2C1 switch 2
# SCL: HDA00_CC on bank 45, SOM240_1_D16
set_property PACKAGE_PIN G11      [get_ports {ccam5_i2c_scl_io}]
set_property IOSTANDARD  LVCMOS33 [get_ports {ccam5_i2c_scl_io}]
set_property SLEW        SLOW     [get_ports {ccam5_i2c_scl_io}]
set_property DRIVE       4        [get_ports {ccam5_i2c_scl_io}]
# SDA: HDA01 on bank 45, SOM240_1_D17
set_property PACKAGE_PIN F10      [get_ports {ccam5_i2c_sda_io}]
set_property IOSTANDARD  LVCMOS33 [get_ports {ccam5_i2c_sda_io}]
set_property SLEW        SLOW     [get_ports {ccam5_i2c_sda_io}]
set_property DRIVE       4        [get_ports {ccam5_i2c_sda_io}]

################################################################
# FAN ENABLE: HDA20 on bank 45, SOM240_1_C24
################################################################

set_property PACKAGE_PIN A12      [get_ports {fan_en_b[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {fan_en_b[0]}]
set_property SLEW        SLOW     [get_ports {fan_en_b[0]}]
set_property DRIVE       4        [get_ports {fan_en_b[0]}]
