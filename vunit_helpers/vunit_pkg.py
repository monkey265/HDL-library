"""Provides VUnit compatible utilities and wavedisp integration."""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

from vunit import VUnit, VUnitCLI


class vunit_pkg:
    """Provides VUnit compatible utilities and wavedisp waveform automation."""

    # ---------------------------------------------------------------------------
    # Original helper methods
    # ---------------------------------------------------------------------------
    @staticmethod
    def ensure_run_all(wave_file_path: Path):
        """Ensure wave file contains 'run -all'."""
        if not wave_file_path.exists():
            wave_file_path.parent.mkdir(parents=True, exist_ok=True)
            with open(wave_file_path, "w") as wave_file:
                wave_file.write("run -all\n")
        else:
            with open(wave_file_path, "r+") as wave_file:
                lines = wave_file.readlines()
                if not any(line.strip() == "run -all" for line in lines):
                    wave_file.write("run -all\n")

    @staticmethod
    def json_from_dict(input_dict: dict) -> str:
        """Convert dictionary to JSON string."""
        return json.dumps(input_dict, sort_keys=True, indent=4)

    @staticmethod
    def save_json_config(json_string: str, filename: str = "radio_config.json", path: str = "."):
        """Save JSON string to a file."""
        filepath = os.path.join(path, filename)
        with open(filepath, "w") as f:
            f.write(json_string)
        print(f"Configuration saved to {filepath}")

    @staticmethod
    def get_testbench_by_name(vunit_instance, library_name: str, tb_name: str):
        """Gives you specific testbench by name."""
        library = vunit_instance.library(library_name)
        for tb in library.get_test_benches():
            if tb.name == tb_name:
                return tb
        raise ValueError(f"Testbench '{tb_name}' not found in library '{library_name}'")

    # ---------------------------------------------------------------------------
    # Wavedisp integration & automation methods
    # ---------------------------------------------------------------------------
    @staticmethod
    def find_wave_file(tb_name: str, root: Path | None = None) -> Path | None:
        """Find a corresponding .wave.py description for a testbench."""
        root_dir = root or Path.cwd()
        candidates = [
            root_dir / tb_name.replace("_tb", "") / "tb" / f"{tb_name}.wave.py",
            root_dir / tb_name.replace("_tb", "") / f"{tb_name}.wave.py",
        ]
        candidates.extend(root_dir.glob(f"*/tb/{tb_name}.wave.py"))
        candidates.extend(root_dir.glob(f"*/{tb_name}.wave.py"))

        for c in candidates:
            if c.is_file():
                return c
        return None

    @staticmethod
    def generate_wave_script(
        wave_py: Path,
        target: str,
        output_file: Path,
        dump_file: Path | None = None,
        generator_kwargs: str | None = None,
    ) -> bool:
        """Run wavedisp CLI to generate a waveform script or savefile."""
        output_file.parent.mkdir(parents=True, exist_ok=True)
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
        cmd.append(str(wave_py))

        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        return res.returncode == 0 and output_file.exists()

    @staticmethod
    def configure_wavedisp(lib, output_path: Path, enable_dump: bool = False, root: Path | None = None):
        """Configure wavedisp GUI startup scripts and waveform dumping for all testbenches."""
        wavedisp_out = output_path / "wavedisp"

        for tb in lib.get_test_benches():
            wave_py = vunit_pkg.find_wave_file(tb.name, root=root)
            if wave_py:
                # Generate GTKWave startup script for NVC and GHDL
                gtkwave_tcl = wavedisp_out / f"{tb.name}.gtkwave.tcl"
                if vunit_pkg.generate_wave_script(wave_py, "gtkwave", gtkwave_tcl):
                    tb.set_sim_option("nvc.gtkwave_script.gui", str(gtkwave_tcl.resolve()))
                    tb.set_sim_option("ghdl.gtkwave_script.gui", str(gtkwave_tcl.resolve()))

                # Generate ModelSim / Riviera-PRO script
                modelsim_tcl = wavedisp_out / f"{tb.name}.modelsim.tcl"
                if vunit_pkg.generate_wave_script(wave_py, "modelsim", modelsim_tcl):
                    tb.set_sim_option("modelsim.init_file.gui", str(modelsim_tcl.resolve()))
                    tb.set_sim_option("rivierapro.init_file.gui", str(modelsim_tcl.resolve()))

            if enable_dump:
                dump_fst = output_path / f"{tb.name}.fst"
                dump_vcd = output_path / f"{tb.name}.vcd"
                tb.set_sim_option("nvc.sim_flags", [f"--wave={dump_fst}"])
                tb.set_sim_option("ghdl.sim_flags", [f"--vcd={dump_vcd}"])

    @staticmethod
    def handle_wave_target(lib, wave_target: str, root: Path | None = None) -> bool:
        """Generate layout files for all testbenches for a specified viewer target."""
        ext_map = {
            "gtkwave": "gtkwave.tcl",
            "surfer": "sucl",
            "modelsim": "modelsim.tcl",
            "rivierapro": "rivierapro.tcl",
            "gtkwave-savefile": "gtkw",
            "dot": "dot",
        }
        ext = ext_map.get(wave_target, wave_target)
        all_ok = True
        for tb in lib.get_test_benches():
            wave_py = vunit_pkg.find_wave_file(tb.name, root=root)
            if wave_py:
                out_file = wave_py.parent / f"{tb.name}.{ext}"
                ok = vunit_pkg.generate_wave_script(wave_py, wave_target, out_file)
                status = "OK" if ok else "FAIL"
                print(f"[{status}] Generated {wave_target} layout: {out_file}")
                if not ok:
                    all_ok = False
        return all_ok

    @staticmethod
    def handle_surfer(lib, output_path: Path, root: Path | None = None):
        """Launch Surfer on the generated waveform dump with the wavedisp command file."""
        if not shutil.which("surfer"):
            print("ERROR: surfer executable not found on PATH.", file=sys.stderr)
            return

        for tb in lib.get_test_benches():
            dump_fst = output_path / f"{tb.name}.fst"
            dump_vcd = output_path / f"{tb.name}.vcd"
            dump_file = dump_fst if dump_fst.exists() else (dump_vcd if dump_vcd.exists() else None)
            if dump_file:
                wave_py = vunit_pkg.find_wave_file(tb.name, root=root)
                if wave_py:
                    sucl_file = output_path / "wavedisp" / f"{tb.name}.sucl"
                    vunit_pkg.generate_wave_script(wave_py, "surfer", sucl_file)
                    cmd = ["surfer", str(dump_file), "--command-file", str(sucl_file)]
                    print(f"Launching Surfer: {' '.join(cmd)}")
                    subprocess.call(cmd)
                    break

    # ---------------------------------------------------------------------------
    # CLI and Runner conveniences
    # ---------------------------------------------------------------------------
    @staticmethod
    def create_cli() -> VUnitCLI:
        """Create a VUnitCLI instance extended with wavedisp options."""
        cli = VUnitCLI()
        cli.parser.add_argument(
            "--wave-target",
            choices=["gtkwave", "surfer", "modelsim", "rivierapro", "gtkwave-savefile", "dot"],
            default=None,
            help="Generate wavedisp layout files for testbenches targeting the specified viewer",
        )
        cli.parser.add_argument(
            "--dump-waves",
            action="store_true",
            default=False,
            help="Force dumping waveform files (.fst with NVC, .vcd with GHDL) during simulation",
        )
        cli.parser.add_argument(
            "--surfer",
            action="store_true",
            default=False,
            help="Run simulation and open waveform in Surfer using wavedisp layout",
        )
        return cli

    @staticmethod
    def main(vu: VUnit, lib, args, root: Path | None = None):
        """Run VUnit with automated wavedisp configuration and post-run handling."""
        out_path = Path(args.output_path) if args.output_path else ((root or Path.cwd()) / "vunit_out")
        vunit_pkg.configure_wavedisp(
            lib,
            out_path,
            enable_dump=(args.dump_waves or args.surfer),
            root=root,
        )

        if args.wave_target:
            vunit_pkg.handle_wave_target(lib, args.wave_target, root=root)

        def post_run_handler(results):
            if args.surfer:
                vunit_pkg.handle_surfer(lib, out_path, root=root)

        vu.main(post_run=post_run_handler if args.surfer else None)
