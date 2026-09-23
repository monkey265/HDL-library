"""Waveform display definition for axi_lite_pri_arbiter_tb."""

from wavedisp.ast import Disp, Divider, Hierarchy


def _add_m2s(parent, sig_name):
    """Add every axi_lite_m2s_t field under a Hierarchy for sig_name."""
    hier = parent.add(Hierarchy(sig_name))
    hier.add(Disp(['write.aw.valid', 'write.w.valid', 'write.b.ready']))
    hier.add(Disp('write.aw.addr', radix='hexadecimal'))
    hier.add(Disp('write.w.data', radix='hexadecimal'))
    hier.add(Disp('write.w.strb', radix='hexadecimal'))
    hier.add(Disp(['read.ar.valid', 'read.r.ready']))
    hier.add(Disp('read.ar.addr', radix='hexadecimal'))
    return hier


def _add_s2m(parent, sig_name):
    """Add every axi_lite_s2m_t field under a Hierarchy for sig_name."""
    hier = parent.add(Hierarchy(sig_name))
    hier.add(Disp(['write.aw.ready', 'write.w.ready', 'write.b.valid']))
    hier.add(Disp('write.b.resp', radix='hexadecimal'))
    hier.add(Disp(['read.ar.ready', 'read.r.valid']))
    hier.add(Disp('read.r.data', radix='hexadecimal'))
    hier.add(Disp('read.r.resp', radix='hexadecimal'))
    return hier


def generator(internals: bool = False):
    """Generate waveform display AST for axi_lite_pri_arbiter_tb.

    The DUT's record-typed input ports (a_m2s_in, b_m2s_in, slave_s2m_in) get no
    trace of their own inside the instance scope (see axi_lite_pri_arbiter.wave.py)
    -- they're added here instead, under this testbench's own connecting signals.

    :param internals: When True, include the DUT's internal ownership FSM signals.
    """
    testbench = Hierarchy('axi_lite_pri_arbiter_tb')

    # Clock & Reset
    testbench.add(Divider('Clock & Reset'))
    testbench.add(Disp(['s_clk_in', 's_arst_n_in']))

    # Master A / B requests, and the slave's response -- driven by this testbench
    testbench.add(Divider('Master A (driven)'))
    _add_m2s(testbench, 's_a_m2s_in')

    testbench.add(Divider('Master B (driven)'))
    _add_m2s(testbench, 's_b_m2s_in')

    testbench.add(Divider('Slave response (driven)'))
    _add_s2m(testbench, 's_slave_s2m_in')

    # DUT Instance (its own output ports, clock/reset, and internal FSM state)
    dut_inst = testbench.add(Hierarchy('u_axi_lite_pri_arbiter'))
    dut_inst.include('../axi_lite_pri_arbiter.wave.py', internals=internals)

    return testbench