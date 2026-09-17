# HDL library

<!-- SHIELDS_START -->
[![CI](https://github.com/monkey265/HDL-library/actions/workflows/ci.yml/badge.svg)](https://github.com/monkey265/HDL-library/actions/workflows/ci.yml)
[![Tests](https://img.shields.io/badge/tests-31%20passed-brightgreen)](#test-results)
[![Coverage](https://img.shields.io/badge/coverage-40.0%25-red)](#code-coverage)
[![Simulator](https://img.shields.io/badge/simulator-NVC-blue)](#nvc)
<!-- SHIELDS_END -->

This is my personal library containing stuff I use repeatedly.
Everything is provided with VUnit testbench.

## Test Results

<!-- TEST_RESULTS_START -->
| Testbench | Tests | Passing | Failing | Status | Simulator |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `axi_pkg_tb` | 6 | 6 | 0 | :white_check_mark: Pass | NVC |
| `tb_pkg_tb` | 17 | 17 | 0 | :white_check_mark: Pass | NVC |
| `uart_tb` | 8 | 8 | 0 | :white_check_mark: Pass | NVC |

<details>
<summary><b>Detailed Test Cases (31 passed, 0 failed)</b></summary>

| Testbench | Test Case | Status | Duration |
| :--- | :--- | :---: | :---: |
| `axi_pkg_tb` | `test_axi_write_back_to_back` | :white_check_mark: Pass | 0.1s |
| `axi_pkg_tb` | `test_axi_write_drives_address_and_data` | :white_check_mark: Pass | 0.1s |
| `axi_pkg_tb` | `test_axis_pop` | :white_check_mark: Pass | 0.1s |
| `axi_pkg_tb` | `test_axis_push_handshake` | :white_check_mark: Pass | 0.1s |
| `axi_pkg_tb` | `test_axis_push_with_tlast` | :white_check_mark: Pass | 0.1s |
| `axi_pkg_tb` | `test_stream_wrappers` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_debug_mode_toggle` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_file_round_trip_real` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_file_round_trip_slv` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_format_hex` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_get_wait_cycles` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_my_is_equal_pass_path` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_pulse_reset` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_random_bit_is_deterministic_for_same_seeds` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_random_boolean` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_random_integer_in_range` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_random_vector_is_deterministic_for_same_seeds` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_rssi_half_db_to_dbm` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_scale_real_to_slv_clamps_out_of_range_input` | :white_check_mark: Pass | 0.5s |
| `tb_pkg_tb` | `test_scale_round_trip` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_strobe_pulses_for_two_periods` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_vec2string_bit_order` | :white_check_mark: Pass | 0.3s |
| `tb_pkg_tb` | `test_wait_cycles` | :white_check_mark: Pass | 0.1s |
| `uart_tb` | `test_uart_rx_receives_byte_cd` | :white_check_mark: Pass | 0.1s |
| `uart_tb` | `test_uart_tx_back_to_back` | :white_check_mark: Pass | 0.1s |
| `uart_tb` | `test_uart_tx_parity_even` | :white_check_mark: Pass | 0.1s |
| `uart_tb` | `test_uart_tx_parity_odd` | :white_check_mark: Pass | 0.1s |
| `uart_tb` | `test_uart_tx_reset_behavior` | :white_check_mark: Pass | 0.1s |
| `uart_tb` | `test_uart_tx_rx_loopback` | :white_check_mark: Pass | 0.1s |
| `uart_tb` | `test_uart_tx_sends_byte_ab` | :white_check_mark: Pass | 0.1s |
| `uart_tb` | `test_uart_write_byte_procedure` | :white_check_mark: Pass | 0.1s |

</details>
<!-- TEST_RESULTS_END -->

## Code Coverage

<!-- COVERAGE_START -->
| Source File | Lines | Line Coverage | Branch Coverage |
| :--- | :---: | :---: | :---: |
| `axi_pkg_tb.vhd` | 21 / 67 | 31.3% | 14.3% |
| `tb_pkg_tb.vhd` | 7 / 84 | 8.3% | 5.6% |
| `uart_tb.vhd` | 33 / 145 | 22.8% | 20.0% |
| **Overall Total** | **200 / 500** | **40.0%** | **42.4%** |
<!-- COVERAGE_END -->

## Roadmap / TODO

### Serial & Communication Protocols
- [x] **UART**: Configurable baud rate, character length, and parity (`uart_tx`, `uart_rx`)
- [ ] **I2C**: Standard (100 kHz) and Fast (400 kHz) modes (`i2c_master`, `i2c_slave`)
- [ ] **SPI**: Modes 0, 1, 2, 3 with configurable CPOL/CPHA Master & Slave
- [ ] **UART Stream Wrapper**: AXI4-Stream / FIFO wrapper around UART transceiver

### Buffering & Clock Domain Crossing (CDC)
- [ ] **Synchronous FIFO**: Parameterized width/depth with programmable almost-full & almost-empty flags
- [ ] **Asynchronous Dual-Clock FIFO**: Gray-coded read/write pointers for cross-domain transfers
- [ ] **CDC Primitives**: 2-FF/3-FF bit synchronizer, pulse toggle synchronizer, multi-bit handshake

### DSP & Arithmetic Primitives
- [ ] **NCO / DDS**: Direct digital frequency synthesizer with phase accumulator and sine LUT
- [ ] **CORDIC**: Vectoring (magnitude/phase) and rotation (sine/cosine) modes
- [ ] **Complex Multiplier**: Pipelined $I/Q$ complex multiplier
- [ ] **CIC / Moving Average Filter**: Multiplierless decimation filter

### Bus Infrastructure & Control
- [x] **AXI4 Bus Driver & Records**: Shared records and transaction procedures (`axi_pkg`)
- [ ] **AXI4-Lite Register Bank**: Memory-mapped Control and Status Register (CSR) slave core
- [ ] **AXI4-Stream Infrastructure**: Stream FIFO, packet buffer, and round-robin arbiter

### Hardware Utilities
- [x] **Testbench Utilities**: Timing, conversion, file I/O, and random stimulus helpers (`tb_pkg`)
- [ ] **CRC Generator / Checker**: Parameterized polynomial (CRC-8, CRC-16, CRC-32) calculation
- [ ] **Glitch Filter / Debouncer**: Multi-sample hysteresis filter for noisy input pins
- [ ] **PWM Controller**: High-resolution PWM generator with dead-time insertion

## Running the tests

Requires [`uv`](https://docs.astral.sh/uv/) and one of the simulators below on `PATH`.
`uv sync` (or just `uv run ...`, which syncs automatically) creates `.venv/` from
`pyproject.toml`/`uv.lock` and installs `vunit_hdl` into it.

### GHDL

```sh
VUNIT_SIMULATOR=ghdl uv run python run.py
```

Install `vunit_hdl` via `uv`/a project-local venv rather than `pip install
--user`. If `ghdl` is installed as a snap it runs under strict confinement and
cannot open files under top-level dot-directories of `$HOME` (e.g. `~/.local`,
where `--user` installs land) -- it can open `.venv/` fine since that's nested
inside the project, not a top-level `$HOME` dot-directory. If you see `ghdl`
error with `cannot open ...` pointing at a `site-packages/vunit/...` path,
this is that same restriction.

### NVC

```sh
VUNIT_SIMULATOR=nvc uv run python run.py
```

Requires `nvc` on `PATH` (or set `VUNIT_NVC_PATH`).

### Questa / ModelSim

```sh
VUNIT_SIMULATOR=modelsim uv run python run.py
```

Requires `vsim`, `vcom`, and `vlib` on `PATH` (or set `VUNIT_MODELSIM_PATH`).

### Common options

```sh
uv run python run.py -l          # list all test cases without running them
uv run python run.py <pattern>   # run only tests matching <pattern>
```

## Waveform Display & Viewer Integration (`wavedisp`)

Waveform layouts are described once in Python using [`wavedisp`](https://github.com/cclienti/wavedisp) and version-controlled alongside the RTL (`*.wave.py`). They can be rendered into save files/scripts for multiple waveform viewers:

- **GTKWave**: TCL startup script (`.gtkwave.tcl`) or `.gtkw` save file
- **Surfer**: Command file (`.sucl`)
- **ModelSim / Questa**: TCL script (`.modelsim.tcl`)
- **Aldec Riviera-PRO**: TCL script (`.rivierapro.tcl`)
- **Graphviz**: DOT hierarchy AST graph (`.dot`)

### Opening in GUI with VUnit

When running VUnit with `--gui` (`-g`), `run.py` automatically detects existing `*.wave.py` descriptions, generates the corresponding viewer script, and pre-loads the formatted waveforms (radix, colors, groups, dividers):

```sh
# NVC + GTKWave (auto-loads wavedisp layout)
VUNIT_SIMULATOR=nvc uv run python run.py --gui lib.uart_tb.test_uart_tx_sends_byte_ab

# GHDL + GTKWave
VUNIT_SIMULATOR=ghdl uv run python run.py --gui lib.uart_tb.test_uart_tx_sends_byte_ab
```

### Viewing with Surfer

[Surfer](https://gitlab.com/surfer-project/surfer) is a modern, extensible Rust-based waveform viewer supporting VCD and FST files.

#### Installation

Download prebuilt Linux binaries from [Surfer Releases](https://gitlab.com/surfer-project/surfer/-/releases) or build via Cargo:

```sh
# Copy downloaded binary to ~/.local/bin (ensure ~/.local/bin is on PATH):
install -m 755 surfer ~/.local/bin/surfer

# Verify installation:
surfer --version
```

#### Running Tests with Surfer

When `--surfer` is passed, `run.py` automatically enables waveform dumping during simulation, compiles the `.wave.py` layout into a Surfer command file (`.sucl`) using `wavedisp`, and launches Surfer:

```sh
VUNIT_SIMULATOR=nvc uv run python run.py --surfer lib.uart_tb.test_uart_tx_sends_byte_ab
```

Or manually:

```sh
# 1. Generate the Surfer command file
uv run wavedisp -t surfer -o uart/tb/uart_tb.sucl uart/tb/uart_tb.wave.py

# 2. Open waveform dump with the command file
surfer dump.fst --command-file uart/tb/uart_tb.sucl
```

#### Keybindings & Configuration

This repository includes a pre-configured [`.surfer/config.toml`](.surfer/config.toml) with Questa/ModelSim-style keybindings (`i`/`o` to zoom in/out, `f` for zoom to fit, `c` for zoom to cursor, `Home`/`End` to navigate start/end, and arrow keys for edge transitions). Surfer automatically loads this configuration when launched from the repository root.

### Generating & Validating Wave Descriptions


Generate layout files for all testbenches:

```sh
# Generate GTKWave scripts:
uv run python scripts/generate_waves.py -t gtkwave

# Generate Surfer command files:
uv run python scripts/generate_waves.py -t surfer
```

Validate all `*.wave.py` descriptions against live simulation dumps:

```sh
uv run python scripts/generate_waves.py --check-all
```

If any port or signal is renamed or missing in the dump, `wavedisp` reports the exact file and line number and exits with an error, preventing waveform layouts from silently drifting out of date.


