# ============================================================================
# Project: AHB-to-Wishbone Bridge
# File: run.do
# Description: ModelSim/Questa compilation and simulation script
# Execution: Run this from inside the /sim directory
# ============================================================================

# 1. Clean up old compilation files to ensure a fresh build
if {[file exists work]} {
    vdel -lib work -all
}

# 2. Create a new work library
vlib work
vmap work work

# 3. Compile RTL design files (relative path from /sim to /rtl)
vlog -work work ../rtl/wb_dummy_slave.sv
vlog -work work ../rtl/ahb2wb_bridge.sv

# 4. Compile Top-Level Testbench (relative path from /sim to /tb)
vlog -work work ../tb/tb_ahb2wb.sv

# 5. Start simulation (with optimization disabled for full waveform visibility)
vsim -voptargs="+acc" work.tb_ahb2wb

# 6. Add all top-level signals to the waveform viewer
add wave -position insertpoint sim:/tb_ahb2wb/*

# 7. Run the simulation
run -all