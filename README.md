# AXI4-to-APB4 Bridge RTL Design and Verification

## Overview

This project implements an **AXI4-to-APB4 Bridge** using Verilog/SystemVerilog RTL. The bridge enables communication between high-performance AXI4-based systems and low-speed APB4 peripherals by converting AXI4 transactions into APB4 transactions.

The design supports multiple outstanding transactions, transaction buffering using FIFOs, and communication with multiple APB slaves. A UVM-based verification environment is developed to verify the functionality and correctness of the bridge.

## Key Features

- AXI4-to-APB4 protocol conversion.
- Supports up to **4 outstanding transactions**.
- Supports up to **10 APB slaves**.
- Multiple FIFOs for transaction buffering and flow control.
- Handles AXI4 read and write transactions.
- APB4 peripheral access through address-based slave selection.
- UVM-based verification of RTL functionality and protocol behavior.

## Design Architecture

The bridge acts as an interface between an AXI4 master and multiple APB4 slaves.

**Transaction flow:**

1. The AXI4 master initiates a read or write transaction.
2. The bridge captures and buffers the transaction information.
3. The bridge converts the AXI4 transaction into the corresponding APB4 transfer.
4. The appropriate APB slave is selected based on the address.
5. The bridge manages the APB transfer and captures the response.
6. The response is returned to the AXI4 master through the corresponding AXI4 response channel.

## Verification

A UVM-based testbench is used to verify the RTL design.

Verification focuses on:

- AXI4 read and write transaction handling.
- AXI4-to-APB4 transaction conversion.
- Address decoding and APB slave selection.
- FIFO operation and transaction buffering.
- Handling of multiple outstanding transactions.
- Read and write data integrity.
- Response handling and protocol compliance.

## Tools and Technologies

- **HDL:** Verilog, SystemVerilog
- **Verification Methodology:** UVM
- **Protocols:** AXI4, APB4
- **Simulation:** Compatible SystemVerilog/UVM simulator

## Project Objectives

- Understand and implement AXI4 and APB4 protocol interaction.
- Design a reusable RTL bridge for connecting high-performance buses to peripheral buses.
- Develop a UVM verification environment for functional verification.
- Validate transaction handling, buffering, and protocol behavior.

## Future Improvements

- Expand constrained-random testing and functional coverage.
- Add assertions for AXI4 and APB4 protocol checks.
- Perform regression testing across different transaction scenarios.
- Integrate the bridge into a larger SoC design.

## Author

**C. Sai Charan**

M.Tech – VLSI and Embedded Systems

> **Note:** Update this README with the actual module names, simulation commands, supported transaction configurations, and test results before publishing the repository.
