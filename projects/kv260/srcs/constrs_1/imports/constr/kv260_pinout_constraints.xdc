# Copyright (c) Prophesee S.A. - All Rights Reserved
# Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
# You may not use this file except in compliance with these License T&C's.

# CCAM5 Interface

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

# Fan control

# FAN ENABLE: HDA20 on bank 45, SOM240_1_C24
set_property PACKAGE_PIN A12      [get_ports {fan_en_b[0]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {fan_en_b[0]}]
set_property SLEW        SLOW     [get_ports {fan_en_b[0]}]
set_property DRIVE       4        [get_ports {fan_en_b[0]}]

