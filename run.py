from pathlib import Path
import shutil
import subprocess
import sys

from vunit import VUnit, VUnitCLI

ROOT = Path(__file__).parent


def find_wave_file(tb_name: str) -> Path | None:
    """Find a corresponding .wave.py description for a testbench."""
    candidates = [
        ROOT / tb_name.replace("_tb", "") / "tb" / f"{tb_name}.wave.py",
        ROOT / tb_name.replace("_tb", "") / f"{tb_name}.wave.py",
    ]
    candidates.extend(ROOT.glob(f"*/tb/{tb_name}.wave.py"))
    candidates.extend(ROOT.glob(f"*/{tb_name}.wave.py"))

    for c in candidates:
        if c.is_file():
            return c
    return None


def generate_wave_script(wave_py: Path, target: str, output_file: Path) -> bool:
    """Run wavedisp CLI to generate the waveform script/savefile."""
    output_file.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        sys.executable,
        "-m",
        "wavedisp.cli",
        "-t",
        target,
        "-o",
        str(output_file),
        str(wave_py),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, check=False)
    return res.returncode == 0 and output_file.exists()


def configure_wavedisp(lib, output_path: Path, enable_dump: bool = False):
    """Configure wavedisp GUI scripts and optional waveform dumping for all testbenches."""
    wavedisp_out = output_path / "wavedisp"

    for tb in lib.get_test_benches():
        wave_py = find_wave_file(tb.name)
        if wave_py:
            # Generate GTKWave startup script for NVC and GHDL
            gtkwave_tcl = wavedisp_out / f"{tb.name}.gtkwave.tcl"
            if generate_wave_script(wave_py, "gtkwave", gtkwave_tcl):
                tb.set_sim_option("nvc.gtkwave_script.gui", str(gtkwave_tcl.resolve()))
                tb.set_sim_option("ghdl.gtkwave_script.gui", str(gtkwave_tcl.resolve()))

            # Generate ModelSim / Riviera-PRO script
            modelsim_tcl = wavedisp_out / f"{tb.name}.modelsim.tcl"
            if generate_wave_script(wave_py, "modelsim", modelsim_tcl):
                tb.set_sim_option("modelsim.init_file.gui", str(modelsim_tcl.resolve()))
                tb.set_sim_option("rivierapro.init_file.gui", str(modelsim_tcl.resolve()))

        if enable_dump:
            dump_fst = output_path / f"{tb.name}.fst"
            dump_vcd = output_path / f"{tb.name}.vcd"
            tb.set_sim_option("nvc.sim_flags", [f"--wave={dump_fst}"])
            tb.set_sim_option("ghdl.sim_flags", [f"--vcd={dump_vcd}"])


# Add custom arguments to VUnit CLI
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

args = cli.parse_args()

vu = VUnit.from_args(args=args, compile_builtins=False, vhdl_standard="2008")
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files(ROOT / "*" / "*.vhd")
lib.add_source_files(ROOT / "*" / "tb" / "*.vhd")

out_path = Path(args.output_path) if args.output_path else (ROOT / "vunit_out")
configure_wavedisp(lib, out_path, enable_dump=(args.dump_waves or args.surfer))

if args.wave_target:
    ext_map = {
        "gtkwave": "gtkwave.tcl",
        "surfer": "sucl",
        "modelsim": "modelsim.tcl",
        "rivierapro": "rivierapro.tcl",
        "gtkwave-savefile": "gtkw",
        "dot": "dot",
    }
    ext = ext_map.get(args.wave_target, args.wave_target)
    for tb in lib.get_test_benches():
        wave_py = find_wave_file(tb.name)
        if wave_py:
            out_file = wave_py.parent / f"{tb.name}.{ext}"
            ok = generate_wave_script(wave_py, args.wave_target, out_file)
            status = "OK" if ok else "FAIL"
            print(f"[{status}] Generated {args.wave_target} layout: {out_file}")


def post_run_handler(results):
    if args.surfer:
        if not shutil.which("surfer"):
            print("ERROR: surfer executable not found on PATH.", file=sys.stderr)
            return

        for tb in lib.get_test_benches():
            dump_fst = out_path / f"{tb.name}.fst"
            dump_vcd = out_path / f"{tb.name}.vcd"
            dump_file = dump_fst if dump_fst.exists() else (dump_vcd if dump_vcd.exists() else None)
            if dump_file:
                wave_py = find_wave_file(tb.name)
                if wave_py:
                    sucl_file = out_path / "wavedisp" / f"{tb.name}.sucl"
                    generate_wave_script(wave_py, "surfer", sucl_file)
                    cmd = ["surfer", str(dump_file), "--command-file", str(sucl_file)]
                    print(f"Launching Surfer: {' '.join(cmd)}")
                    subprocess.call(cmd)
                    break


vu.main(post_run=post_run_handler if args.surfer else None)
