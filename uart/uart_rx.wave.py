"""Waveform display definition for uart_rx."""

from wavedisp.ast import Block, Disp, Divider, Group


def generator(internals: bool = False):
    """Generate waveform display AST for uart_rx.

    :param internals: When True, include internal FSM, sampling, and counter signals.
    """
    block = Block()

    # Control & Inputs
    block.add(Disp(['clk_in', 'rst_n_in']))
    block.add(Disp(['rx_in', 'start_pol_in', 'par_en_in', 'par_type_in', 'char_len_in']))
    block.add(Disp('clk_div_in', radix='unsigned'))

    # Outputs
    block.add(Divider('RX Outputs'))
    block.add(Disp('msg_out', radix='hexadecimal'))
    block.add(Disp(['msg_vld_strb_out', 'busy_out']))
    block.add(Disp(['err_noise_strb_out', 'err_frame_strb_out', 'err_par_strb_out'], color='red'))

    # Optional internal state & sampling
    if internals:
        grp = block.add(Group('internals'))
        grp.add(Disp('s_state', radix='symbolic', color='SteelBlue'))
        grp.add(Disp(['s_counter_start', 's_counter_done']))
        grp.add(Disp('s_bit_cnt', radix='unsigned'))
        grp.add(Disp('s_rx_sample', radix='binary'))
        grp.add(Disp(['s_rx_sample_val', 's_rx_sample_stb']))

    return block
