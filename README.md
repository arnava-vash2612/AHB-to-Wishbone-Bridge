# AHB-to-Wishbone Bridge

### RTL Implementation & Verification

**Author:** Arnava Vashishtha  
---

## Overview

This repository contains the complete SystemVerilog RTL design and verification environment for an AHB-to-Wishbone Bridge.

The bridge operates as an **AHB Slave** on the input interface and a **Wishbone Master** on the output interface.

Its primary function is to resolve the phase mismatch between the high-performance, pipelined AHB protocol—where the Address and Data phases are decoupled—and the flat, single-phase Wishbone B.3 protocol.

---

## Architecture & Flow Control

The core of the bridge is an FSM-governed latching stage.

It captures AHB address and control signals during the AHB Address Phase (Cycle 1) and holds them until the AHB Data Phase (Cycle 2), allowing them to be asserted concurrently on the Wishbone bus.

### Stall Mechanism (Backpressure)

Because the AHB Master expects immediate data execution but the target Wishbone Slave may require wait states, the bridge actively manages flow control.

* The bridge drives `HREADYOUT = 0` during active Wishbone cycles to freeze the AHB Master's instruction pipeline.
* Upon receiving `ACK_I` from the Wishbone Slave, the bridge restores `HREADYOUT = 1`, finalizing the transfer.

---

## FSM States

| State | Description |
| :--- | :--- |
| `IDLE` | Waits for a valid AHB transfer (`HTRANS == NONSEQ` or `SEQ`). |
| `LATCH_ADDR` | Captures `HADDR`, `HWRITE`, and `HSIZE`. Asserts stall (`HREADYOUT = 0`). |
| `WB_ACTIVE` | Asserts `CYC_O` and `STB_O` to initiate the Wishbone transaction. |
| `WAIT_ACK` | Holds the stall while waiting for the target slave to assert `ACK_I` or `ERR_I`. |
| `COMPLETE` | Routes read data, drives `HREADYOUT = 1` for one cycle to recover the bus, and returns to `IDLE`. |

---

## Repository Files

* `docs/index.html` — Interactive Project Presentation
* `docs/FSMStateLogic.png` — State machine diagram
* `docs/Simulation_Waveforms.png` — Verification evidence
* `rtl/ahb2wb_bridge.sv` — Core bridge DUT
* `rtl/wb_dummy_slave.sv` — Dummy target with artificial wait-states
* `tb/tb_ahb2wb.sv` — Top-level testbench

---

## How to Run the Simulation (EDA Playground)

This project is fully synthesizable and is designed to be easily simulated in cloud-based environments like **EDA Playground**.

1. **Create a New Project:** Open [EDA Playground](https://www.edaplayground.com/).
2. **Design Files (RTL):** * Copy the contents of `rtl/ahb2wb_bridge.sv` and `rtl/wb_dummy_slave.sv` into the `design.sv` window on the right (or create new tabs for them).
3. **Testbench File:** * Copy the contents of `tb/tb_ahb2wb.sv` into the `testbench.sv` window on the left.
4. **Environment Settings (Left Menu):**
   * **Testbench + Design:** Select `SystemVerilog/Verilog`.
   * **Tools & Simulators:** Select a commercial simulator capable of running SystemVerilog (e.g., *Aldec Riviera Pro*, *Mentor Questa*, or *Synopsys VCS*). 
   * **Run Options:** Check the box for **"Open EPWave after run"** to view the timing waveforms.
5. **Execute:** Click the **Run** button at the top. 

The console will display the transaction logs, and the EPWave window will open automatically to show the stall mechanism (`HREADYOUT`) and phase alignment in action.