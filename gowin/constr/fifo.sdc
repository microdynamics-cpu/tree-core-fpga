//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.10 
//Created Time: 2023-02-05 17:37:53

create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
# create_clock -name clk_mem -period 2.5 -waveform {0 1.25} [get_nets {clk_mem}]
