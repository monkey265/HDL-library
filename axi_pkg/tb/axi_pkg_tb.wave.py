"""Waveform display definition for axi_pkg_tb."""

from wavedisp.ast import Disp, Divider, Group, Hierarchy


def generator():
    """Generate waveform display AST for axi_pkg_tb."""
    testbench = Hierarchy('axi_pkg_tb')

    # Clock
    testbench.add(Divider('Clock'))
    testbench.add(Disp('s_clk'))

    # AXI4 Write Address & Data Channels (Master -> Slave)
    axi_in = testbench.add(Group('AXI4 Inputs (s_axi_in)'))
    axi_in_hier = axi_in.add(Hierarchy('s_axi_in'))
    axi_in_hier.add(Disp(['s_axi_awvalid', 's_axi_awlen']))
    axi_in_hier.add(Disp('s_axi_awaddr', radix='hexadecimal'))
    axi_in_hier.add(Disp(['s_axi_wvalid', 's_axi_wlast']))
    axi_in_hier.add(Disp('s_axi_wdata', radix='hexadecimal'))
    axi_in_hier.add(Disp('s_axi_bready'))
    axi_in_hier.add(Disp(['s_axi_arvalid', 's_axi_arlen']))
    axi_in_hier.add(Disp('s_axi_araddr', radix='hexadecimal'))
    axi_in_hier.add(Disp('s_axi_rready'))

    # AXI4 Outputs & Responses (Slave -> Master)
    axi_out = testbench.add(Group('AXI4 Outputs (s_axi_out)'))
    axi_out_hier = axi_out.add(Hierarchy('s_axi_out'))
    axi_out_hier.add(Disp('s_axi_awready'))
    axi_out_hier.add(Disp('s_axi_wready'))
    axi_out_hier.add(Disp(['s_axi_bvalid', 's_axi_bid']))
    axi_out_hier.add(Disp('s_axi_bresp', radix='hexadecimal'))
    axi_out_hier.add(Disp('s_axi_arready'))
    axi_out_hier.add(Disp(['s_axi_rvalid', 's_axi_rlast', 's_axi_rid']))
    axi_out_hier.add(Disp('s_axi_rdata', radix='hexadecimal'))
    axi_out_hier.add(Disp('s_axi_rresp', radix='hexadecimal'))

    # AXI4-Stream Signals
    axis = testbench.add(Group('AXI4-Stream'))
    axis.add(Disp(['s_axis_tvalid', 's_axis_tready', 's_axis_tlast']))
    axis.add(Disp('s_axis_tdata', radix='hexadecimal'))

    return testbench
