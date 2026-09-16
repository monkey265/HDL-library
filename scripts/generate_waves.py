#!/usr/bin/env python3
"""Waveform display generator and validator using wavedisp.

Generates wave layouts for GTKWave, Surfer, ModelSim, Riviera-PRO, and Graphviz (dot),
and validates wave descriptions against actual simulation dumps.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).parent.parent

EXT_MAP = {
    "gtkwave": "gtkwave.tcl",
    "surfer": "sucl",
    "modelsim": "modelsim.tcl",
    "rivierapro": "rivierapro.tcl",
    "gtkwave-savefile": "gtkw",
    "dot": "dot",
}


def find_wave_files() -> list[Path]:
    """Return all .wave.py description files in the repository."""
    return sorted(ROOT.glob("**/*.wave.py"))


def generate_wave(
    wave_file: Path,
    target: str,
    output_file: Path,
    dump_file: Path | None = None,
    generator_kwargs: str | None = None,
) -> bool:
    """Generate a waveform layout file using wavedisp CLI."""
    cmd = [
        sys.executable,
        "-m",
        "wavedisp.cli",
        "-t",
        target,
        "-o",
        str(output_file),
    ]
    if dump_file is not None:
        cmd.extend(["-D", str(dump_file)])
    if generator_kwargs:
        cmd.extend(["-a", generator_kwargs])
    cmd.append(str(wave_file))

    res = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if res.returncode != 0:
        print(f"ERROR generating {target} for {wave_file}:", file=sys.stderr)
        if res.stdout:
            print(res.stdout, file=sys.stderr)
        if res.stderr:
            print(res.stderr, file=sys.stderr)
        return False
    return True


def check_dump(wave_file: Path, dump_file: Path, generator_kwargs: str | None = None) -> bool:
    """Check that all signals in a wave description exist in the simulation dump."""
    # Write to a temporary output file to validate
    tmp_out = ROOT / "vunit_out" / "wavedisp" / f"{wave_file.stem}_check.tmp"
    tmp_out.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        sys.executable,
        "-m",
        "wavedisp.cli",
        "-o",
        str(tmp_out),
        "-D",
        str(dump_file),
    ]
    if generator_kwargs:
        cmd.extend(["-a", generator_kwargs])
    cmd.append(str(wave_file))

    res = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if tmp_out.exists():
        tmp_out.unlink()

    if res.returncode != 0:
        print(f"FAILED check for {wave_file} against {dump_file}:", file=sys.stderr)
        if res.stdout:
            print(res.stdout, file=sys.stderr)
        if res.stderr:
            print(res.stderr, file=sys.stderr)
        return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate and validate wavedisp layouts")
    parser.add_argument(
        "-t",
        "--target",
        choices=list(EXT_MAP.keys()),
        default="gtkwave",
        help="Target waveform viewer (default: gtkwave)",
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        type=Path,
        default=None,
        help="Directory to save generated layouts (defaults to next to the .wave.py file)",
    )
    parser.add_argument(
        "-a",
        "--kwargs",
        type=str,
        default=None,
        help="JSON kwargs passed to the generator function (e.g. '{\"internals\": true}')",
    )
    parser.add_argument(
        "-D",
        "--dump",
        type=Path,
        default=None,
        help="Simulation dump (.fst / .vcd) to check signals against",
    )
    parser.add_argument(
        "--check-all",
        action="store_true",
        help="Run simulations and verify all testbench wave descriptions against dumps",
    )
    parser.add_argument(
        "files",
        nargs="*",
        type=Path,
        help="Specific .wave.py files to process (default: all .wave.py files)",
    )

    args = parser.parse_args()

    wave_files = [p.resolve() for p in args.files] if args.files else find_wave_files()
    if not wave_files:
        print("No .wave.py files found.", file=sys.stderr)
        return 1

    if args.check_all:
        print("Validating all testbench wave descriptions against live simulation dumps...")
        success = True
        for wf in wave_files:
            # Only testbenches (*_tb.wave.py) have top-level dumps
            if not wf.stem.endswith("_tb.wave"):
                continue
            tb_name = wf.stem.removesuffix(".wave")
            dump_file = ROOT / "vunit_out" / "wavedisp" / f"{tb_name}.fst"
            dump_file.parent.mkdir(parents=True, exist_ok=True)

            # Run single test in NVC to produce FST dump
            sim_cmd = [
                "uv",
                "run",
                "python",
                "run.py",
                "--dump-waves",
                f"lib.{tb_name}.*",
            ]
            sim_env = {"VUNIT_SIMULATOR": "nvc"}
            import os
            env = dict(os.environ)
            env.update(sim_env)
            # Run one test from this testbench
            sim_res = subprocess.run(
                ["uv", "run", "python", "-c", f"""
from pathlib import Path
from vunit import VUnit

vu = VUnit.from_argv(compile_builtins=False, vhdl_standard='2008')
vu.add_vhdl_builtins()
lib = vu.add_library('lib')
lib.add_source_files(Path('{ROOT}') / '*' / '*.vhd')
lib.add_source_files(Path('{ROOT}') / '*' / 'tb' / '*.vhd')
tb = lib.test_bench('{tb_name}')
tb.set_sim_option('nvc.sim_flags', ['--wave={dump_file}'])
vu.main()
""", f"lib.{tb_name}.*"],
                cwd=str(ROOT),
                capture_output=True,
                text=True,
                env=env,
                check=False,
            )
            if not dump_file.exists():
                print(f"[ERROR] Could not produce dump for {tb_name}", file=sys.stderr)
                success = False
                continue

            # Validate against dump
            ok = check_dump(wf, dump_file, args.kwargs)
            if ok:
                print(f"  [PASS] {wf.name} verified against {dump_file.name}")
            else:
                print(f"  [FAIL] {wf.name} has missing signals in {dump_file.name}", file=sys.stderr)
                success = False
        return 0 if success else 1

    success = True
    ext = EXT_MAP[args.target]
    for wf in wave_files:
        stem = wf.stem.removesuffix(".wave")
        out_name = f"{stem}.{ext}"
        out_dir = args.output_dir if args.output_dir else wf.parent
        out_file = out_dir / out_name

        ok = generate_wave(
            wf,
            args.target,
            out_file,
            dump_file=args.dump,
            generator_kwargs=args.kwargs,
        )
        status = "OK" if ok else "FAIL"
        print(f"[{status}] {wf.relative_to(ROOT)} -> {out_file.relative_to(ROOT) if out_file.is_relative_to(ROOT) else out_file}")
        if not ok:
            success = False

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
