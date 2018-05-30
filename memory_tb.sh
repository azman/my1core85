#!/bin/bash

iverilog -o memory_tb memory_tb.v
vvp memory_tb
rm -rf memory_tb
