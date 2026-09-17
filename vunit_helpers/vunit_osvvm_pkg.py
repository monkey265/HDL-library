"""Provides OSVVM requirements tracking, parsing, and reporting utilities for VUnit."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Callable, Sequence

from vunit import VUnit


class vunit_osvvm_pkg:
    """Provides OSVVM requirements tracking, parsing, and reporting utilities."""

    DEFAULT_VCOM_FLAGS = ["-2008", "-assertdebug", "-fsmdebug", "-pslext"]
    DEFAULT_VSIM_GUI_FLAGS = ["-debugdb=+acc", "-psl", "-assertdebug", "-msgmode both"]

    # ---------------------------------------------------------------------------
    # Configuration & Setup
    # ---------------------------------------------------------------------------
    @staticmethod
    def configure_osvvm(
        vu: VUnit,
        lib=None,
        compile_flags: list[str] | None = None,
        sim_flags_gui: list[str] | None = None,
        wave_dir: Path | None = None,
    ):
        """Configure VUnit instance with OSVVM, VHDL builtins, and ModelSim options."""
        vu.add_vhdl_builtins()
        vu.add_osvvm()

        vcom_flags = compile_flags or vunit_osvvm_pkg.DEFAULT_VCOM_FLAGS
        vsim_gui = sim_flags_gui or vunit_osvvm_pkg.DEFAULT_VSIM_GUI_FLAGS

        vu.set_compile_option("modelsim.vcom_flags", vcom_flags)
        vu.set_sim_option("modelsim.vsim_flags.gui", vsim_gui)

        if lib is not None and wave_dir is not None:
            vunit_osvvm_pkg.configure_tb_waves(lib, wave_dir=wave_dir, sim_flags_gui=vsim_gui)

    @staticmethod
    def configure_tb_waves(lib, wave_dir: Path, sim_flags_gui: list[str] | None = None):
        """Configure GUI waveform .do files and simulation options for all testbenches."""
        flags = sim_flags_gui or vunit_osvvm_pkg.DEFAULT_VSIM_GUI_FLAGS
        for tb in lib.get_test_benches():
            wave_file = wave_dir / f"{tb.name}_wave.do"
            tb.set_sim_option("modelsim.init_file.gui", str(wave_file))
            tb.set_sim_option("modelsim.vsim_flags.gui", flags)

    # ---------------------------------------------------------------------------
    # Pre-execution Cleanup
    # ---------------------------------------------------------------------------
    @staticmethod
    def clean_stale_requirements(vunit_out_dir: Path):
        """Clean up stale OSVVM requirement YAML files and merged summary before test run."""
        modelsim_dir = vunit_out_dir / "modelsim"
        candidate_dirs = [modelsim_dir, vunit_out_dir]

        for d in candidate_dirs:
            if d.exists():
                for req_file in d.glob("*_req.yaml"):
                    try:
                        req_file.unlink()
                    except OSError:
                        pass

        # Also search recursively in case simulator placed them in test output subdirectories
        if vunit_out_dir.exists():
            for req_file in vunit_out_dir.glob("**/*_req.yaml"):
                if req_file.name != "osvvm_reqs_merged.yaml":
                    try:
                        req_file.unlink()
                    except OSError:
                        pass

            merged_summary = vunit_out_dir / "osvvm_reqs_merged.yaml"
            if merged_summary.exists():
                try:
                    merged_summary.unlink()
                except OSError:
                    pass

    # ---------------------------------------------------------------------------
    # Requirements Parsing & Merging
    # ---------------------------------------------------------------------------
    @staticmethod
    def load_descriptions(req_csv_path: Path) -> dict[str, str]:
        """Load requirement descriptions from CSV (format: req_id, description)."""
        descriptions: dict[str, str] = {}
        if not req_csv_path.exists():
            return descriptions

        for line in req_csv_path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("--") or line.startswith("#"):
                continue
            parts = [p.strip().strip('"') for p in line.split(",")]
            if len(parts) >= 2:
                descriptions[parts[0]] = parts[1]
        return descriptions

    @staticmethod
    def find_requirement_files(vunit_out_dir: Path) -> list[Path]:
        """Find all generated OSVVM *_req.yaml files in the output directories."""
        req_files: list[Path] = []
        modelsim_dir = vunit_out_dir / "modelsim"

        # Check modelsim directory first
        if modelsim_dir.exists():
            req_files.extend(modelsim_dir.glob("*_req.yaml"))

        # Check top-level vunit_out
        if vunit_out_dir.exists():
            for f in vunit_out_dir.glob("*_req.yaml"):
                if f not in req_files and f.name != "osvvm_reqs_merged.yaml":
                    req_files.append(f)

            # Check subdirectories
            for f in vunit_out_dir.glob("**/*_req.yaml"):
                if f not in req_files and f.name != "osvvm_reqs_merged.yaml":
                    req_files.append(f)

        return req_files

    @staticmethod
    def parse_and_merge(req_files: Sequence[Path]) -> dict[str, dict]:
        """Parse individual OSVVM requirement YAML files and merge statistics."""
        merged_reqs: dict[str, dict] = {}
        for req_file in req_files:
            try:
                lines = req_file.read_text().splitlines()
            except OSError:
                continue

            for line in lines[1:]:  # Skip header line
                line = line.strip()
                if not line:
                    continue
                parts = [p.strip() for p in line.split(",")]
                if len(parts) >= 4:
                    try:
                        req_id = parts[0]
                        goal = int(parts[1])
                        passed_cnt = int(parts[2])
                        failures = int(parts[3])
                    except ValueError:
                        continue

                    if req_id not in merged_reqs:
                        merged_reqs[req_id] = {
                            "goal": goal,
                            "passed_cnt": 0,
                            "failures": 0,
                            "tests": set(),
                        }
                    merged_reqs[req_id]["passed_cnt"] += passed_cnt
                    merged_reqs[req_id]["failures"] += failures
                    if passed_cnt > 0:
                        merged_reqs[req_id]["tests"].add(req_file.stem.replace("_req", ""))

        return merged_reqs

    # ---------------------------------------------------------------------------
    # Reporting & Export
    # ---------------------------------------------------------------------------
    @staticmethod
    def print_summary(merged_reqs: dict[str, dict], descriptions: dict[str, str] | None = None) -> tuple[int, int]:
        """Print formatted colorized ASCII table of OSVVM requirement coverage."""
        descs = descriptions or {}
        print("\n" + "=" * 100)
        print(f"{'OSVVM REQUIREMENTS COVERAGE SUMMARY':^100}")
        print("=" * 100)
        print(f"{'Requirement ID':<20} | {'Goal':<5} | {'Count':<5} | {'Status':<10} | {'Description'}")
        print("-" * 100)

        passed_count = 0
        total_count = len(merged_reqs)

        for req_id, data in sorted(merged_reqs.items()):
            goal = data["goal"]
            cnt = data["passed_cnt"]
            fails = data["failures"]
            desc = descs.get(req_id, "")
            if len(desc) > 52:
                desc = desc[:49] + "..."

            if fails > 0:
                status = "\033[91mFAILED\033[0m"
            elif cnt >= goal:
                status = "\033[92mPASSED\033[0m"
                passed_count += 1
            elif cnt > 0:
                status = "\033[93mPARTIAL\033[0m"
            else:
                status = "\033[90mUNCOVERED\033[0m"

            print(f"{req_id:<20} | {goal:<5} | {cnt:<5} | {status:<19} | {desc}")

        pct = (passed_count / total_count * 100) if total_count > 0 else 0
        print("=" * 100)
        print(f"Summary: {passed_count}/{total_count} Requirements Met ({pct:.1f}%)\n")
        return passed_count, total_count

    @staticmethod
    def save_merged_yaml(
        merged_reqs: dict[str, dict],
        descriptions: dict[str, str],
        output_file: Path,
        passed_count: int | None = None,
        total_count: int | None = None,
    ) -> Path:
        """Write merged OSVVM requirements summary to a YAML file."""
        output_file.parent.mkdir(parents=True, exist_ok=True)
        total = total_count if total_count is not None else len(merged_reqs)
        passed = (
            passed_count
            if passed_count is not None
            else sum(1 for d in merged_reqs.values() if d["failures"] == 0 and d["passed_cnt"] >= d["goal"])
        )

        with open(output_file, "w") as f:
            f.write(f"# Merged OSVVM Requirements Summary ({passed}/{total} passed)\n")
            for req_id, data in sorted(merged_reqs.items()):
                if data["failures"] > 0:
                    status_str = "FAILED"
                elif data["passed_cnt"] >= data["goal"]:
                    status_str = "PASSED"
                elif data["passed_cnt"] > 0:
                    status_str = "PARTIAL"
                else:
                    status_str = "UNTESTED"

                f.write(f"{req_id}:\n")
                f.write(f"  goal: {data['goal']}\n")
                f.write(f"  passed_count: {data['passed_cnt']}\n")
                f.write(f"  failures: {data['failures']}\n")
                f.write(f"  status: {status_str}\n")
                f.write(f"  description: \"{descriptions.get(req_id, '')}\"\n")
                f.write(f"  tests: {sorted(list(data['tests']))}\n")

        return output_file

    # ---------------------------------------------------------------------------
    # Post-Run Handler & Callbacks
    # ---------------------------------------------------------------------------
    @staticmethod
    def process_requirements(
        vunit_out_dir: Path,
        req_csv_path: Path | None = None,
    ) -> dict[str, dict]:
        """Execute full post-run requirements processing: find, merge, print summary, and save YAML."""
        descriptions = vunit_osvvm_pkg.load_descriptions(req_csv_path) if req_csv_path else {}
        req_files = vunit_osvvm_pkg.find_requirement_files(vunit_out_dir)
        if not req_files:
            return {}

        merged_reqs = vunit_osvvm_pkg.parse_and_merge(req_files)
        if not merged_reqs:
            return {}

        passed_count, total_count = vunit_osvvm_pkg.print_summary(merged_reqs, descriptions)
        merged_yaml = vunit_out_dir / "osvvm_reqs_merged.yaml"
        vunit_osvvm_pkg.save_merged_yaml(
            merged_reqs, descriptions, merged_yaml, passed_count=passed_count, total_count=total_count
        )
        return merged_reqs

    @staticmethod
    def create_post_run(
        vunit_out_dir: Path,
        req_csv_path: Path | None = None,
        chained_post_run: Callable[[object], None] | None = None,
    ) -> Callable[[object], None]:
        """Create a VUnit post_run callback function."""

        def post_func(results):
            vunit_osvvm_pkg.process_requirements(vunit_out_dir, req_csv_path=req_csv_path)
            if chained_post_run is not None:
                chained_post_run(results)

        return post_func

    @staticmethod
    def chain_post_run(
        func1: Callable[[object], None] | None,
        func2: Callable[[object], None] | None,
    ) -> Callable[[object], None] | None:
        """Helper to combine two post_run callbacks into a single callback."""
        if func1 is None:
            return func2
        if func2 is None:
            return func1

        def combined(results):
            func1(results)
            func2(results)

        return combined
