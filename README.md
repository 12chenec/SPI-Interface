# SPI Master-Slave Interface in Verilog

## Overview

This project implements a synthesizable 4-wire SPI master and slave interface in Verilog. The design supports configurable SPI modes, programmable clock division, 7-bit addressing, and single- or multi-byte read and write transactions.

The project was developed to practice RTL design, finite-state machines, datapath/controller organization, and simulation-based verification.

## Features

- Supports SPI Modes 0–3 through configurable CPOL and CPHA
- Full-duplex 4-wire SPI interface
- Read and write transactions
- 7-bit register addressing
- Up to 4 data bytes per transaction
- Programmable SPI clock divider
- MSB-first transmission
- Automatic address incrementing for multi-byte transfers
- Synthesizable Verilog RTL

The first transmitted byte contains the read/write bit followed by the 7-bit address. Subsequent bytes contain transaction data.

## Project Structure

```text
.
├── Master.v
├── Slave.v
├── System.v
├── System_test.v
└── SPI Report.docx
```

### `Master.v`

The master generates `SCLK`, controls active-low chip select, transmits address and write data through MOSI, and receives read data through MISO.

Its FSM contains four states:

```text
IDLE → ADDR → READ
            → WRITE
```

The master datapath includes:

- Transmit and receive shift registers
- Bit counter
- Remaining-byte counter
- Programmable clock divider
- SPI edge-detection logic

The generated `latch_en` and `cnt_en` signals select the correct sampling and shifting edges for each SPI mode.

### `Slave.v`

The slave receives the command and address byte, then enters either the `READ` or `WRITE` state.

It contains:

- Receive and transmit shift registers
- Bit counter
- Read/write address logic
- Automatic address incrementing
- 128-entry, 8-bit register file

During reads, register data is shifted onto MISO. During writes, received MOSI data is stored in the addressed register.

### `System.v`

The system module connects the master and slave through the four SPI signals:

- `SCLK`
- `CS`
- `MOSI`
- `MISO`

Configuration signals such as CPOL, CPHA, transfer length, address, write data, and clock-divider value are provided through the top-level system.

## SPI Modes

| Mode | CPOL | CPHA | Idle Clock | Sample Edge | Shift Edge |
|---|---:|---:|---|---|---|
| 0 | 0 | 0 | Low | Rising | Falling |
| 1 | 0 | 1 | Low | Falling | Rising |
| 2 | 1 | 0 | High | Falling | Rising |
| 3 | 1 | 1 | High | Rising | Falling |

The master generates mode-dependent sampling and shifting enables from CPOL and CPHA.

## Transaction Format

### Write

```text
[RW = 0 | 7-bit address] [data byte 0] [data byte 1] ...
```

The master sends the address byte first, followed by one or more write-data bytes. The slave stores each byte and increments the destination address after each transfer.

### Read

```text
Master MOSI: [RW = 1 | 7-bit address]
Slave MISO:                         [data byte 0] [data byte 1] ...
```

The master sends the read command and address, then samples data returned by the slave. The slave increments the read address during multi-byte transactions.

## Verification

`System_test.v` instantiates the complete master-slave system and provides reusable `read` and `write` tasks. It configures the transaction length and SPI mode, waits for completion, and compares expected and received data using assertions.

The testbench verifies:

- Single-byte reads
- Multi-byte reads
- Multi-byte writes
- Register address incrementing
- SPI timing behavior
- Multiple transfer lengths

Example verified transactions:

```text
1-byte read from address 3  → 0x03
3-byte read from address 3  → 0x030405
4-byte read from address 3  → 0x03040506
4-byte write                → 0x11111111
```

## Running the Simulation

1. Add `Master.v`, `Slave.v`, `System.v`, and `System_test.v` to the simulator.
2. Set `System_test` as the simulation top module.
3. Run behavioral simulation.
4. Review the console for assertion results.
5. Inspect `SCLK`, `CS`, `MOSI`, `MISO`, FSM states, and counters in the waveform viewer.

The project was developed and verified using Vivado XSim.

## Example Test Configuration

```verilog
localparam ADDR        = 7'd3;
localparam W_DATA      = 32'h11111111;
localparam CLK_DIV_VAL = 3'd4;
```

Transaction length, CPOL, CPHA, and read/write direction are configured before each operation.

## Future Improvements

- Add invalid-address error handling
- Expand automated testing across all SPI modes
- Add randomized testbench transactions
- Add configurable register-file initialization
- Add formal protocol assertions
- Support longer transfer lengths

## Documentation

The full project report includes FSM diagrams, datapath and controller diagrams, register descriptions, signal descriptions, transaction timing, testbench architecture, and waveform examples.

## Author

Christal Chen  
SiFirst Technologies Digital Design Internship, 2026
