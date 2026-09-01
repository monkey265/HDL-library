# HDL library

This is my personal library containing stuff I use repeatedly.
Everything is provided with VUnit testbench.

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
