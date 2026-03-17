#!/bin/bash
set -e

echo "[INFO] Compile RTL and testbench..."
vlog rtl/*.v testbench/*.v

echo "[INFO] Run simulation..."
vsim elevator_tb -do "do scripts/wave.do; run -all"

echo "[INFO] Simulation completed."
