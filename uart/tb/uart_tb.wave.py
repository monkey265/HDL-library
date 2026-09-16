"""Waveform display definition for uart_tb."""

from wavedisp.ast import Disp, Divider, Group, Hierarchy


def generator(internals: bool = False):
    """Generate waveform display AST for uart_tb.

    :param internals: When True, include internal signals for DUT instances.
    """
    testbench = Hierarchy('uart_tb')

    # Clocks & Reset
    testbench.add(Divider('Clock & Reset'))
    testbench.add(Disp(['s_clk', 's_rst_n']))

    # Configuration & Serial Channel
    testbench.add(Divider('Configuration & Channel'))
    testbench.add(Disp(['s_start_pol', 's_par_en', 's_par_type', 's_char_len']))
    testbench.add(Disp('s_clk_div', radix='unsigned'))
    testbench.add(Disp(['s_loopback_en', 's_manual_rx', 's_rx_in', 's_tx']))

    # Testbench Stimulus & Monitor
    tb_grp = testbench.add(Group('Testbench Stimuli'))
    tb_grp.add(Disp(['s_tx_msg_vld', 's_tx_msg'], radix='hexadecimal'))
    tb_grp.add(Disp(['s_tx_busy', 's_tx_done']))
    tb_grp.add(Disp(['s_rx_msg_vld', 's_rx_msg'], radix='hexadecimal'))
    tb_grp.add(Disp('s_rx_busy'))
    tb_grp.add(Disp(['s_rx_err_noise', 's_rx_err_frame', 's_rx_err_par'], color='red'))

    # DUT Instances
    tx_inst = testbench.add(Hierarchy('u_uart_tx'))
    tx_inst.include('../uart_tx.wave.py', internals=internals)

    rx_inst = testbench.add(Hierarchy('u_uart_rx'))
    rx_inst.include('../uart_rx.wave.py', internals=internals)

    return testbench
