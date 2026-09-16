"""Waveform display definition for tb_pkg_tb."""

from wavedisp.ast import Disp, Divider, Hierarchy


def generator():
    """Generate waveform display AST for tb_pkg_tb."""
    testbench = Hierarchy('tb_pkg_tb')

    testbench.add(Divider('Clock & Reset'))
    testbench.add(Disp(['s_clk', 's_rst_n']))

    testbench.add(Divider('Testbench Signals'))
    testbench.add(Disp('sig_strobe'))

    return testbench
