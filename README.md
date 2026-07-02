\# AHB-to-Wishbone Bridge



\### RTL Implementation \& Verification



\*\*Author:\*\* Arnava Vashishtha



\---



\## Overview



This repository contains the complete SystemVerilog RTL design and verification environment for an AHB-to-Wishbone Bridge.



The bridge operates as an \*\*AHB Slave\*\* on the input interface and a \*\*Wishbone Master\*\* on the output interface.



Its primary function is to resolve the phase mismatch between the high-performance, pipelined AHB protocol—where the Address and Data phases are decoupled—and the flat, single-phase Wishbone B.3 protocol.



\---



\## Architecture \& Flow Control



The core of the bridge is an FSM-governed latching stage.



It captures AHB address and control signals during the AHB Address Phase (Cycle 1) and holds them until the AHB Data Phase (Cycle 2), allowing them to be asserted concurrently on the Wishbone bus.



\### Stall Mechanism (Backpressure)



Because the AHB Master expects immediate data execution but the target Wishbone Slave may require wait states, the bridge actively manages flow control.



\* The bridge drives `HREADYOUT = 0` during active Wishbone cycles to freeze the AHB Master's instruction pipeline.

\* Upon receiving `ACK\_I` from the Wishbone Slave, the bridge restores `HREADYOUT = 1`, finalizing the transfer.



\---



\## FSM States



| State        | Description                                                                                       |

| ------------ | ------------------------------------------------------------------------------------------------- |

| `IDLE`       | Waits for a valid AHB transfer (`HTRANS == NONSEQ` or `SEQ`).                                     |

| `LATCH\_ADDR` | Captures `HADDR`, `HWRITE`, and `HSIZE`. Asserts stall (`HREADYOUT = 0`).                         |

| `WB\_ACTIVE`  | Asserts `CYC\_O` and `STB\_O` to initiate the Wishbone transaction.                                 |

| `WAIT\_ACK`   | Holds the stall while waiting for the target slave to assert `ACK\_I` or `ERR\_I`.                  |

| `COMPLETE`   | Routes read data, drives `HREADYOUT = 1` for one cycle to recover the bus, and returns to `IDLE`. |



\---



\## Repository Structure



```text

Arnava\_Vashishtha\_AHB2WB/

│

├── docs/                         # Documentation and presentation assets

│   ├── index.html                # Interactive HTML/SVG project presentation

│   ├── FSMStateLogic.png         # State machine diagram

│   └── Simulation\_Waveforms.png  # Verification evidence

│

├── rtl/                          # Synthesizable SystemVerilog design

│   ├── ahb2wb\_bridge.sv          # Core bridge DUT

│   └── wb\_dummy\_slave.sv         # Dummy target with artificial wait-states

│

├── sim/                          # Simulation execution sandbox

│   └── run.do                    # ModelSim/Questa compilation and execution script

│

├── tb/                           # Verification environment

│   └── tb\_ahb2wb.sv              # Top-level testbench

│

├── .gitignore                    # Ignores generated files such as work/, transcripts, and .vcd

│

└── README.md                     # Project documentation

```



\---



\## How to Run the Simulation



This project is configured to run in \*\*ModelSim\*\* or \*\*Questa Advanced Simulator\*\*.



Source files and simulation artifacts are strictly separated.



1\. Navigate to the `sim/` directory inside the project folder.



2\. Launch your simulator, such as ModelSim or Questa.



3\. Execute the provided TCL script in the simulator console:



```tcl

do run.do

```



The script will automatically:



\* Clean previous builds

\* Map the `work` library

\* Compile the RTL and Testbench files

\* Resolve relative file paths

\* Disable optimization for full signal visibility

\* Launch the waveform viewer



> \*\*Note:\*\* The design was developed using strict zero-initialization practices to prevent `'X'` propagation states during RTL simulation.



