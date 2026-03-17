# Elevator Controller – Verilog RTL

## Overview

This project implements a **single-car elevator controller** in **Verilog RTL**. The design uses a **finite state machine (FSM)** plus a **SCAN-style scheduling policy** to serve floor requests efficiently.

The controller accepts floor requests as a bitmask, stores pending requests internally, moves the elevator **one floor per clock cycle**, and opens the door for a fixed number of cycles when a requested floor is reached.

This repository is intended for learning and demonstrating:

- RTL design in Verilog
- FSM-based control logic
- request scheduling with a floor-request bitmap
- self-checking simulation
- waveform analysis in ModelSim

---

## Simulation Tool

Simulation is performed using **ModelSim FPGA Standard Edition**.

> [Download ModelSim FPGA Standard Edition (v20.1.1)](https://www.altera.com/downloads/simulation-tools/modelsim-fpgas-standard-edition-software-version-20-1-1)

---

## Design Summary

### Main behavior

The controller performs the following functions:

- accepts floor requests through `floor_req`
- stores active requests in an internal pending queue
- detects whether requests exist above or below the current floor
- keeps moving in the current direction while requests still exist in that direction
- opens the door when arriving at a requested floor
- holds the door open for `DOOR_OPEN` clock cycles

This is similar to the classic **SCAN / elevator algorithm**, where requests are serviced in the current travel direction before reversing.

### FSM states

| State | Description |
|---|---|
| `STATE_IDLE` | Elevator is stationary and waits for new requests |
| `STATE_UP` | Elevator moves upward one floor per clock cycle |
| `STATE_DOWN` | Elevator moves downward one floor per clock cycle |
| `STATE_DOOR` | Door remains open for a fixed number of cycles |

### Key features

- FSM-based controller
- Configurable number of floors
- Bitmask-based floor request input
- Internal pending-request queue
- One-floor-per-cycle motion
- Fixed door-open timing
- Reset support
- Self-checking testbench

---

## Repository Structure

| Path | Purpose |
|---|---|
| [rtl/elevator.v](rtl/elevator.v) | Main elevator controller RTL |
| [testbench/elevator_tb.v](testbench/elevator_tb.v) | Self-checking simulation testbench |
| [scripts/wave.do](scripts/wave.do) | ModelSim waveform setup script |
| [docs/Report.md](docs/Report.md) | Project report and waveform explanation |
| [docs/images](docs/images) | Waveform screenshots and RTL schematic |
| [Makefile](Makefile) | Compile, run, and waveform targets |

---

## Main Signals

| Signal | Direction | Description |
|---|---|---|
| `clk` | Input | System clock |
| `rst` | Input | Reset signal |
| `floor_req[FLOORS-1:0]` | Input | Bitmask of floor requests |
| `floor_pos` | Output | Current elevator floor |
| `door_open` | Output | High while door is open |
| `moving_up` | Output | High while elevator is moving up |
| `moving_down` | Output | High while elevator is moving down |

---

## Verification

The design is verified with a custom Verilog testbench. The testbench generates the system clock, applies reset, injects floor requests, and checks that the elevator reaches expected floors within a timeout.

### Test scenarios covered

The current testbench covers these cases:

1. request at the current floor
2. upward movement to a higher floor
3. downward movement to a lower floor
4. multiple simultaneous requests
5. full travel to the top floor
6. full travel back to the bottom floor
7. requests on both sides while moving (SCAN behavior)
8. reset during travel
9. door reopen / door timer restart on re-press

Detailed explanation and waveform screenshots are available in [docs/Report.md](docs/Report.md).

---

## Running the Project

This project is set up for ModelSim / Questa-style commands through the [Makefile](Makefile).

### Compile

Build the RTL and testbench:

- `make compile`

### Run simulation in console

Compile and run the testbench in command-line mode:

- `make run`

### Open waveform view

Compile and launch ModelSim with the prepared waveform layout:

- `make wave`

### Clean generated files

- `make clean`

---

## Waveform Support

The waveform setup script [scripts/wave.do](scripts/wave.do) adds the main signals needed for debugging and analysis, including:

- clock and reset
- floor request input
- elevator outputs
- FSM state
- pending request queue
- door counter
- direction helper signals

This makes it easier to inspect controller behavior visually in ModelSim.

---

## Documentation

Additional documentation is available here:

- [docs/Report.md](docs/Report.md) — detailed report with waveform explanation
- [docs/images/overview_waveform.png](docs/images/overview_waveform.png) — main waveform overview
- [docs/images/elevator_schematic.png](docs/images/elevator_schematic.png) — RTL schematic reference

---

## Limitations and Future Improvements

- Supports only one elevator car
- Uses a simple SCAN-style scheduler
- No emergency stop, overload, or maintenance mode
- No external display / call-panel model

Possible future improvements:

- add cabin and hall call separation
- add emergency handling and safety logic
- improve scheduling policy
- support multiple elevators
- add more formal assertions or coverage metrics

---

## Conclusion

This project demonstrates a complete small RTL workflow: controller design, self-checking testbench creation, waveform-based debugging, and documentation of simulation results.










