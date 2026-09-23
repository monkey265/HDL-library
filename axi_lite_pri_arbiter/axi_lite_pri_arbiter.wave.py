"""Waveform display definition for axi_lite_pri_arbiter."""

from wavedisp.ast import Block, Disp, Divider, Group, Hierarchy


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
    """Generate waveform display AST for axi_lite_pri_arbiter.

    :param internals: When True, include internal ownership FSM signals.
    """
    block = Block()

    # Control
    block.add(Disp(['clk_in', 'arst_n_in']))

    # Master A (higher priority)
    block.add(Divider('Master A'))
    _add_s2m(block, 'a_s2m_out')

    # Master B (lower priority)
    block.add(Divider('Master B'))
    _add_s2m(block, 'b_s2m_out')

    # Downstream slave
    block.add(Divider('Slave'))
    _add_m2s(block, 'slave_m2s_out')

    # Optional internal ownership state
    if internals:
        grp = block.add(Group('internals'))
        grp.add(
            Disp(['s_wr_owner', 's_rd_owner'], radix='symbolic', color='SteelBlue')
        )

    return block
