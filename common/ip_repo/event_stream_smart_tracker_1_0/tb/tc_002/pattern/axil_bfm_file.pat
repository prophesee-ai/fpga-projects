# __regmap_hash__ = 904f56f26f15416093ee8ede30d3e2bcb32bb29ff16a9546d205e5db007bf117
C Enable ESST
W 00000004 00000001
C Configuration of Smart Dropper
W 00000008 00000002
C Configuration of TH Recovery
W 00000018 00000001
C Configuration of TS Checker
W 0000001C 00000401
C Checking Ip Version
R 00000000 00010000 0 0 FFFFFFFF
C Disable Back Pressure
W 10000000 00000001
C Config Done
S
C Enable Back Pressure after 100 clk cycle for 400 clk cycles
W 10000000 00000000 100 400
C Disable Back Pressure
W 10000000 00000001 0 0
S
C Check counter : SMART DROPPER
R 0000000C 00000005 2000 0 FFFFFFFF
R 00000010 00000000 0 0 FFFFFFFF
R 00000014 000001A0 0 0 FFFFFFFF
C Check flag : SMART DROPPER
R 00000008 00000004 0 0 00000004
C Check Done
S
E
