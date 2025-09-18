#!/bin/bash
# Setup 1GB of CXL RAM
echo ram > /sys/bus/cxl/devices/decoder2.0/mode
echo 0x40000000 > /sys/bus/cxl/devices/decoder2.0/dpa_size
echo region0 > /sys/bus/cxl/devices/decoder0.0/create_ram_region
echo 256 > /sys/bus/cxl/devices/region0/interleave_granularity
echo 1 > /sys/bus/cxl/devices/region0/interleave_ways
echo 0x40000000 > /sys/bus/cxl/devices/region0/size
echo decoder2.0 > /sys/bus/cxl/devices/region0/target0
echo 1 > /sys/bus/cxl/devices/region0/commit
echo region0 > /sys/bus/cxl/drivers/cxl_region/bind
