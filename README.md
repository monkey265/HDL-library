# HDL library

<!-- SHIELDS_START -->
[![CI](https://github.com/monkey265/HDL-library/actions/workflows/ci.yml/badge.svg)](https://github.com/monkey265/HDL-library/actions/workflows/ci.yml)
[![Tests](https://img.shields.io/badge/tests-22%20passed-brightgreen)](#test-results)
[![Simulator](https://img.shields.io/badge/simulator-NVC-blue)](#nvc)
<!-- SHIELDS_END -->

This is my personal library containing stuff I use repeatedly.
Everything is provided with VUnit testbench.

## Test Results

<!-- TEST_RESULTS_START -->
| Testbench | Tests | Passing | Failing | Status | Simulator |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `axi_pkg_tb` | 2 | 2 | 0 | :white_check_mark: Pass | NVC |
| `tb_pkg_tb` | 12 | 12 | 0 | :white_check_mark: Pass | NVC |
| `uart_tb` | 8 | 8 | 0 | :white_check_mark: Pass | NVC |

<details>
<summary><b>Detailed Test Cases (22 passed, 0 failed)</b></summary>

| Testbench | Test Case | Status | Duration |
| :--- | :--- | :---: | :---: |
| `axi_pkg_tb` | `test_axi_write_back_to_back` | :white_check_mark: Pass | 0.2s |
| `axi_pkg_tb` | `test_axi_write_drives_address_and_data` | :white_check_mark: Pass | 0.3s |
| `tb_pkg_tb` | `test_debug_mode_toggle` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_file_round_trip_real` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_file_round_trip_slv` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_get_wait_cycles` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_my_is_equal_pass_path` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_random_bit_is_deterministic_for_same_seeds` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_random_vector_is_deterministic_for_same_seeds` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_rssi_half_db_to_dbm` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_scale_real_to_slv_clamps_out_of_range_input` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_scale_round_trip` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_strobe_pulses_for_two_periods` | :white_check_mark: Pass | 0.1s |
| `tb_pkg_tb` | `test_vec2string_bit_order` | :white_check_mark: Pass | 0.8s |
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
