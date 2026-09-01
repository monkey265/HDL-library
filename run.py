from pathlib import Path

from vunit import VUnit

ROOT = Path(__file__).parent

vu = VUnit.from_argv(vhdl_standard="2008")
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files(ROOT / "*" / "*.vhd")
lib.add_source_files(ROOT / "*" / "tb" / "*.vhd")

# tb_pkg's debug-enable flag is a plain (non-protected) SHARED VARIABLE, which
# GHDL only accepts under -frelaxed. ModelSim/Questa accept it by default.
lib.set_compile_option("ghdl.a_flags", ["-frelaxed"])
vu.set_sim_option("ghdl.elab_flags", ["-frelaxed"])

vu.main()
