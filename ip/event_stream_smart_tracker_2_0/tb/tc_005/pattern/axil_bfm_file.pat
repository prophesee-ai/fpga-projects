# __regmap_hash__ = 559dec401fb3100352dfd0d75640a0bdca953f58dbae6f94a75d6affffda2efe
C Enable Reset and Clear
W 00000000 00000006
C Disable Reset and Clear
W 00000000 00000000
C Enable Bypass
W 00000004 00000001
C Enable IP
W 00000000 00000001
C Configuration of Smart Dropper
W 00000014 00000002
C Configuration of TH Recovery
W 00000024 0000000E
C Configuration of TS Checker
W 00000028 00186A0E
W 00000000 00000005
W 00000000 00000001
C Checking Ip Version
R 00000010 00020000 0 0 FFFFFFFF
C Config Done
S
C Check counter : SMART DROPPER
R 00000018 00000000 2000 0 FFFFFFFF
R 0000001C 00000000 0 0 FFFFFFFF
R 00000020 00000000 0 0 FFFFFFFF
C Check flags : STATUS
R 00000008 00000000 0 0 00000000
C Check counter : TS CHECKER
R 0000002C 00000000 0 0 FFFFFFFF
R 00000030 00000000 0 0 FFFFFFFF
R 00000034 00000000 0 0 FFFFFFFF
C Check Done
S
E
