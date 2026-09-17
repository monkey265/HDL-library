from pathlib import Path

from vunit import VUnit
from vunit_helpers.vunit_pkg import vunit_pkg

ROOT = Path(__file__).parent

cli = vunit_pkg.create_cli()
args = cli.parse_args()

vu = VUnit.from_args(args=args, compile_builtins=False, vhdl_standard="2008")
vu.add_vhdl_builtins()

lib = vu.add_library("lib")
lib.add_source_files(ROOT / "*" / "*.vhd")
lib.add_source_files(ROOT / "*" / "tb" / "*.vhd")

vunit_pkg.main(vu, lib, args, root=ROOT)
