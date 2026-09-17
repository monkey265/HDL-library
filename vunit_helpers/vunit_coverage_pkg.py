"""Provides code coverage automation, merging, and HTML/XML reporting for VUnit and NVC/ModelSim."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Callable, Sequence
import xml.etree.ElementTree as ET

from vunit import VUnit, VUnitCLI


class vunit_coverage_pkg:
    """Automates code coverage collection, database merging, and reporting."""

    # ---------------------------------------------------------------------------
    # Simulator Detection & Configuration
    # ---------------------------------------------------------------------------
    @staticmethod
    def detect_simulator(explicit: str | None = None) -> str:
        """Detect the active simulator, prioritizing explicit argument, VUNIT_SIMULATOR, or PATH."""
        if explicit:
            return explicit.lower()

        env_sim = os.environ.get("VUNIT_SIMULATOR")
        if env_sim:
            return env_sim.lower()

        # Check installed binaries
        if shutil.which("nvc"):
            return "nvc"
        if shutil.which("vsim"):
            return "modelsim"
        if shutil.which("ghdl"):
            return "ghdl"
        return "nvc"

    @staticmethod
    def configure_coverage(
        vu: VUnit,
        lib,
        output_path: Path,
        simulator: str | None = None,
        spec_file: Path | None = None,
        cover_kinds: str | None = None,
    ):
        """Configure simulation options to collect code coverage."""
        sim = vunit_coverage_pkg.detect_simulator(simulator)
        cov_dir = (output_path / "coverage" / "ncdb").resolve()
        cov_dir.mkdir(parents=True, exist_ok=True)

        if sim == "nvc":
            cover_arg = f"--cover={cover_kinds}" if cover_kinds else "--cover"
            for tb in lib.get_test_benches():
                db_file = cov_dir / f"{tb.name}.ncdb"
                elab_flags = [cover_arg, f"--cover-file={db_file}"]
                if spec_file:
                    elab_flags.append(f"--cover-spec={spec_file}")
                tb.set_sim_option("nvc.elab_flags", elab_flags)

        elif sim in ("modelsim", "questasim"):
            vu.set_compile_option("modelsim.vcom_flags", ["+cover=sbceft"])
            for tb in lib.get_test_benches():
                ucdb_file = output_path / "coverage" / f"{tb.name}.ucdb"
                tb.set_sim_option("modelsim.vsim_flags", ["-coverage"])
                tb.set_sim_option(
                    "modelsim.vsim_flags.gui",
                    [f"-do", f"coverage save -onexit {ucdb_file}; run -all; exit"],
                )

        elif sim == "ghdl":
            vu.set_compile_option("ghdl.flags", ["-Wc,-fprofile-arcs", "-Wc,-ftest-coverage"])
            vu.set_sim_option("ghdl.flags", ["-Wl,-lgcov"])

    # ---------------------------------------------------------------------------
    # Pre-execution Cleanup
    # ---------------------------------------------------------------------------
    @staticmethod
    def clean_stale_coverage(output_path: Path):
        """Remove stale coverage databases and previous reports."""
        cov_dir = output_path / "coverage"
        if not cov_dir.exists():
            return

        # Clean individual test databases
        ncdb_dir = cov_dir / "ncdb"
        if ncdb_dir.exists():
            for f in ncdb_dir.glob("*.ncdb"):
                try:
                    f.unlink()
                except OSError:
                    pass

        # Clean merged and report files
        for name in ["merged.ncdb", "merged.ucdb", "cobertura.xml", "coverage_badge.svg"]:
            target = cov_dir / name
            if target.exists():
                try:
                    target.unlink()
                except OSError:
                    pass

    # ---------------------------------------------------------------------------
    # Merging & Report Generation
    # ---------------------------------------------------------------------------
    @staticmethod
    def find_coverage_databases(coverage_dir: Path, simulator: str = "nvc") -> list[Path]:
        """Locate generated coverage database files."""
        if simulator == "nvc":
            ncdb_dir = coverage_dir / "ncdb"
            if ncdb_dir.exists():
                return sorted(list(ncdb_dir.glob("*.ncdb")))
            return sorted(list(coverage_dir.glob("**/*.ncdb")))
        if simulator in ("modelsim", "questasim"):
            return sorted(list(coverage_dir.glob("**/*.ucdb")))
        return []

    @staticmethod
    def merge_coverage(
        coverage_dir: Path,
        simulator: str = "nvc",
        output_file: Path | None = None,
    ) -> Path | None:
        """Merge individual test coverage databases into a consolidated database."""
        dbs = vunit_coverage_pkg.find_coverage_databases(coverage_dir, simulator=simulator)
        if not dbs:
            return None

        if simulator == "nvc":
            merged_file = output_file or (coverage_dir / "merged.ncdb")
            merged_file.parent.mkdir(parents=True, exist_ok=True)
            cmd = ["nvc", "--cover-merge", "-o", str(merged_file)] + [str(db) for db in dbs]
            res = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if res.returncode != 0:
                print(f"[Coverage] NVC merge failed: {res.stderr}", file=sys.stderr)
                return None
            return merged_file

        return None

    @staticmethod
    def generate_html_report(
        merged_db: Path,
        report_dir: Path,
        simulator: str = "nvc",
    ) -> Path | None:
        """Generate an interactive HTML coverage report from the merged database."""
        report_dir.mkdir(parents=True, exist_ok=True)

        if simulator == "nvc":
            cmd = ["nvc", "--cover-report", str(merged_db), "-o", str(report_dir), "--per-file"]
            res = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if res.returncode != 0:
                print(f"[Coverage] HTML report generation failed: {res.stderr}", file=sys.stderr)
                return None
            index_html = report_dir / "index.html"
            return index_html if index_html.exists() else report_dir

        return None

    @staticmethod
    def generate_cobertura_xml(
        merged_db: Path,
        output_xml: Path,
        simulator: str = "nvc",
    ) -> Path | None:
        """Export coverage database to Cobertura XML format."""
        output_xml.parent.mkdir(parents=True, exist_ok=True)

        if simulator == "nvc":
            cmd = ["nvc", "--cover-export", "--format=cobertura", "-o", str(output_xml), str(merged_db)]
            res = subprocess.run(cmd, capture_output=True, text=True, check=False)
            if res.returncode != 0:
                print(f"[Coverage] Cobertura XML export failed: {res.stderr}", file=sys.stderr)
                return None
            return output_xml if output_xml.exists() else None

        return None

    # ---------------------------------------------------------------------------
    # Metrics Parsing & Summary Display
    # ---------------------------------------------------------------------------
    @staticmethod
    def parse_cobertura_xml(xml_path: Path) -> dict:
        """Parse Cobertura XML report and return structured coverage metrics."""
        if not xml_path.exists():
            return {}

        tree = ET.parse(xml_path)
        root = tree.getroot()

        total_line_rate = float(root.get("line-rate", "0.0")) * 100.0
        total_branch_rate = float(root.get("branch-rate", "0.0")) * 100.0
        lines_valid = int(root.get("lines-valid", "0"))
        lines_covered = int(root.get("lines-covered", "0"))
        branches_valid = int(root.get("branches-valid", "0"))
        branches_covered = int(root.get("branches-covered", "0"))

        files_data: dict[str, dict] = {}
        for cls_elem in root.findall(".//class"):
            filename = cls_elem.get("filename", "")
            name = cls_elem.get("name", "")
            base_name = Path(filename).name if filename else name

            lines = cls_elem.findall(".//line")
            f_lines_total = len(lines)
            f_lines_covered = sum(1 for l in lines if int(l.get("hits", "0")) > 0)
            f_line_rate = (f_lines_covered / f_lines_total * 100.0) if f_lines_total > 0 else 0.0

            branches = [l for l in lines if l.get("branch") == "true"]
            f_branch_total = len(branches)
            f_branch_rate = float(cls_elem.get("branch-rate", "0.0")) * 100.0

            files_data[base_name] = {
                "unit": name,
                "path": filename,
                "lines_total": f_lines_total,
                "lines_covered": f_lines_covered,
                "line_rate": f_line_rate,
                "branches_total": f_branch_total,
                "branch_rate": f_branch_rate,
            }

        return {
            "line_rate": total_line_rate,
            "branch_rate": total_branch_rate,
            "lines_valid": lines_valid,
            "lines_covered": lines_covered,
            "branches_valid": branches_valid,
            "branches_covered": branches_covered,
            "files": files_data,
        }

    @staticmethod
    def _color_rate(rate: float) -> str:
        """Format coverage percentage with ANSI color code."""
        if rate >= 90.0:
            return f"\033[92m{rate:5.1f}%\033[0m"  # Green
        if rate >= 75.0:
            return f"\033[93m{rate:5.1f}%\033[0m"  # Yellow
        return f"\033[91m{rate:5.1f}%\033[0m"  # Red

    @staticmethod
    def print_summary(metrics: dict, html_report: Path | None = None):
        """Print formatted coverage summary table and metrics."""
        if not metrics:
            return

        print("\n" + "=" * 90)
        print(f"{'CODE COVERAGE SUMMARY':^90}")
        print("=" * 90)
        print(f"{'Source / Unit':<35} | {'Lines':<14} | {'Line %':<16} | {'Branch %':<14}")
        print("-" * 90)

        files = metrics.get("files", {})
        for name, data in sorted(files.items()):
            lines_str = f"{data['lines_covered']}/{data['lines_total']}"
            line_pct_str = vunit_coverage_pkg._color_rate(data["line_rate"])
            branch_pct_str = vunit_coverage_pkg._color_rate(data["branch_rate"])
            print(f"{name:<35} | {lines_str:<14} | {line_pct_str:<25} | {branch_pct_str}")

        print("=" * 90)
        total_line_str = f"{metrics['lines_covered']}/{metrics['lines_valid']}"
        total_branch_str = f"{metrics['branches_covered']}/{metrics['branches_valid']}"
        tot_line_pct = vunit_coverage_pkg._color_rate(metrics["line_rate"])
        tot_branch_pct = vunit_coverage_pkg._color_rate(metrics["branch_rate"])

        print(
            f"{'OVERALL TOTAL':<35} | {total_line_str:<14} | {tot_line_pct:<25} | {tot_branch_pct}  (Branches: {total_branch_str})"
        )
        print("=" * 90)

        if html_report and html_report.exists():
            print(f"HTML Report: file://{html_report.resolve()}\n")

    # ---------------------------------------------------------------------------
    # SVG Badge Generator
    # ---------------------------------------------------------------------------
    @staticmethod
    def generate_badge(percentage: float, output_svg: Path) -> Path:
        """Generate a clean standalone SVG coverage badge."""
        output_svg.parent.mkdir(parents=True, exist_ok=True)
        rate = round(percentage, 1)

        if rate >= 90.0:
            color = "#44cc11"  # bright green
        elif rate >= 75.0:
            color = "#dfb317"  # yellow
        else:
            color = "#e05d44"  # red

        label = "coverage"
        value = f"{rate:.1f}%"

        svg_content = f"""<svg xmlns="http://www.w3.org/2000/svg" width="114" height="20" role="img" aria-label="{label}: {value}">
  <title>{label}: {value}</title>
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="r">
    <rect width="114" height="20" rx="3" fill="#fff"/>
  </clipPath>
  <g clip-path="url(#r)">
    <rect width="63" height="20" fill="#555"/>
    <rect x="63" width="51" height="20" fill="{color}"/>
    <rect width="114" height="20" fill="url(#s)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110">
    <text aria-hidden="true" x="325" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="530">{label}</text>
    <text x="325" y="140" transform="scale(.1)" fill="#fff" textLength="530">{label}</text>
    <text aria-hidden="true" x="875" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="410">{value}</text>
    <text x="875" y="140" transform="scale(.1)" fill="#fff" textLength="410">{value}</text>
  </g>
</svg>"""
        output_svg.write_text(svg_content, encoding="utf-8")
        return output_svg

    # ---------------------------------------------------------------------------
    # Full Process Pipeline & Post-Run Hook
    # ---------------------------------------------------------------------------
    @staticmethod
    def process_coverage(
        output_path: Path,
        simulator: str | None = None,
        generate_html: bool = True,
        generate_xml: bool = True,
        generate_badge: bool = True,
    ) -> dict:
        """Run complete post-simulation coverage pipeline: merge, report, XML, summary, badge."""
        sim = vunit_coverage_pkg.detect_simulator(simulator)
        cov_dir = output_path / "coverage"

        merged = vunit_coverage_pkg.merge_coverage(cov_dir, simulator=sim)
        if not merged:
            return {}

        html_file = None
        if generate_html:
            html_file = vunit_coverage_pkg.generate_html_report(merged, cov_dir / "html", simulator=sim)

        xml_file = None
        if generate_xml:
            xml_file = vunit_coverage_pkg.generate_cobertura_xml(
                merged, cov_dir / "cobertura.xml", simulator=sim
            )

        metrics = {}
        if xml_file and xml_file.exists():
            metrics = vunit_coverage_pkg.parse_cobertura_xml(xml_file)
            vunit_coverage_pkg.print_summary(metrics, html_report=html_file)

            if generate_badge and "line_rate" in metrics:
                badge_file = cov_dir / "coverage_badge.svg"
                vunit_coverage_pkg.generate_badge(metrics["line_rate"], badge_file)

        return metrics

    @staticmethod
    def create_post_run(
        output_path: Path,
        simulator: str | None = None,
        generate_html: bool = True,
        generate_xml: bool = True,
        generate_badge: bool = True,
        chained_post_run: Callable[[object], None] | None = None,
    ) -> Callable[[object], None]:
        """Create a VUnit post_run callback function for coverage processing."""

        def post_func(results):
            vunit_coverage_pkg.process_coverage(
                output_path,
                simulator=simulator,
                generate_html=generate_html,
                generate_xml=generate_xml,
                generate_badge=generate_badge,
            )
            if chained_post_run is not None:
                chained_post_run(results)

        return post_func

    # ---------------------------------------------------------------------------
    # CLI Integration
    # ---------------------------------------------------------------------------
    @staticmethod
    def add_cli_options(cli: VUnitCLI):
        """Add coverage command line arguments to a VUnitCLI instance."""
        cli.parser.add_argument(
            "--coverage",
            action="store_true",
            default=False,
            help="Enable code coverage collection, merge databases, and generate reports",
        )
        cli.parser.add_argument(
            "--coverage-spec",
            type=Path,
            default=None,
            help="Path to coverage specification file for fine-grained filtering (NVC)",
        )
        cli.parser.add_argument(
            "--no-coverage-html",
            action="store_true",
            default=False,
            help="Skip HTML coverage report generation",
        )
