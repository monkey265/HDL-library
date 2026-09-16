"""Waveform display definition for uart_tx."""

from wavedisp.ast import Block, Disp, Divider, Group


def generator(internals: bool = False):
    """Generate waveform display AST for uart_tx.

    :param internals: When True, include internal FSM and counter signals.
    """
    block = Block()

    # Control & Inputs
    block.add(Disp(['clk_in', 'rst_n_in']))
    block.add(Disp(['start_pol_in', 'par_en_in', 'par_type_in', 'char_len_in']))
    block.add(Disp('clk_div_in', radix='unsigned'))
    block.add(Disp(['msg_vld_in', 'msg_in'], radix='hexadecimal'))

    # Outputs
    block.add(Divider('TX Outputs'))
    block.add(Disp(['tx_out', 'busy_out', 'tx_done_out']))

    # Optional internal state & counters
    if internals:
        grp = block.add(Group('internals'))
        grp.add(Disp('s_state', radix='symbolic', color='SteelBlue'))
        grp.add(Disp(['s_counter_start', 's_counter_done', 's_msg_valid_int']))
        grp.add(Disp('s_bit_cnt', radix='unsigned'))

    return block
