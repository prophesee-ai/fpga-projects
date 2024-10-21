# __regmap_hash__ = 559dec401fb3100352dfd0d75640a0bdca953f58dbae6f94a75d6affffda2efe
C Enable Reset and Clear
W 00000000 00000006
C Disable Reset and Clear
W 00000000 00000000
C Disable Bypass
W 00000004 00000000
C Enable IP
W 00000000 00000001
C Configuration of Smart Dropper
W 00000014 00000000
C Configuration of TH Recovery
W 00000024 0000000E
C Configuration of TS Checker
W 00000028 00000401
C Checking Ip Version
R 00000010 00020000 0 0 FFFFFFFF
C Disable Back Pressure
W 0000003F 00000001
C Config Done
S
C Enable Back Pressure after 100 clk cycle for 400 clk cycles
W 0000003F 00000000 100 400
C Disable Back Pressure
W 0000003F 00000001 0 0
S
C Check flags : TH RECOVERY
R 00000008 00000005 2000 0 00000000
R 00000018 00000005 0 0 00000000
C Check Done
S
E
