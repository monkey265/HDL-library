from pathlib import Path

from vunit import VUnit

ROOT = Path(__file__).parent

vu = VUnit.from_argv(compile_builtins=False, vhdl_standard="2008")
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files(ROOT / "*" / "*.vhd")
lib.add_source_files(ROOT / "*" / "tb" / "*.vhd")

vu.main()
