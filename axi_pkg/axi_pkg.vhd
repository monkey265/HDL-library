--------------------------------------------------------------------------------
-- Package : axi_pkg
-- Purpose : AXI4 slave-port record types and testbench bus-driver procedures.
--------------------------------------------------------------------------------

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE axi_pkg IS

  TYPE t_axi_ports_in IS RECORD
    -- Write address channel
    S_AXI_AWVALID : STD_ULOGIC;
    S_AXI_AWADDR  : STD_ULOGIC_VECTOR(23 DOWNTO 0);
    S_AXI_AWLEN   : STD_ULOGIC_VECTOR(7 DOWNTO 0);

    -- Write data channel
    S_AXI_WVALID : STD_ULOGIC;
    S_AXI_WDATA  : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    S_AXI_WLAST  : STD_ULOGIC;

    -- Write response channel
    S_AXI_BREADY : STD_ULOGIC;

    -- Read address channel
    S_AXI_ARVALID : STD_ULOGIC;
    S_AXI_ARADDR  : STD_ULOGIC_VECTOR(23 DOWNTO 0);
    S_AXI_ARLEN   : STD_ULOGIC_VECTOR(7 DOWNTO 0);

    -- Read data channel
    S_AXI_RREADY : STD_ULOGIC;
  END RECORD;

  TYPE t_axi_ports_out IS RECORD
    -- Write address channel
    S_AXI_AWREADY : STD_ULOGIC;

    -- Write data channel
    S_AXI_WREADY : STD_ULOGIC;

    -- Write response channel
    S_AXI_BID    : STD_ULOGIC_VECTOR(2 DOWNTO 0);
    S_AXI_BVALID : STD_ULOGIC;
    S_AXI_BRESP  : STD_ULOGIC_VECTOR(1 DOWNTO 0);

    -- Read address channel
    S_AXI_ARREADY : STD_ULOGIC;

    -- Read data channel
    S_AXI_RID    : STD_ULOGIC_VECTOR(2 DOWNTO 0);
    S_AXI_RVALID : STD_ULOGIC;
    S_AXI_RDATA  : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    S_AXI_RLAST  : STD_ULOGIC;
    S_AXI_RRESP  : STD_ULOGIC_VECTOR(1 DOWNTO 0);
  END RECORD;

  TYPE t_axi_ports_in_array  IS ARRAY (NATURAL RANGE <>) OF t_axi_ports_in;
  TYPE t_axi_ports_out_array IS ARRAY (NATURAL RANGE <>) OF t_axi_ports_out;

  -- Drives a single AXI4 write transaction (address, data, and response phases).
  PROCEDURE axi_write(
    CONSTANT addr    : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
    CONSTANT data    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL   clk     : IN  STD_LOGIC;
    SIGNAL   axi_in  : OUT t_axi_ports_in;
    SIGNAL   axi_out : IN  t_axi_ports_out
  );

END PACKAGE axi_pkg;

PACKAGE BODY axi_pkg IS

  PROCEDURE axi_write(
    CONSTANT addr    : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
    CONSTANT data    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL   clk     : IN  STD_LOGIC;
    SIGNAL   axi_in  : OUT t_axi_ports_in;
    SIGNAL   axi_out : IN  t_axi_ports_out
  ) IS
  BEGIN
    REPORT "Writing AXI address: " & TO_HSTRING(addr) & " data: " & TO_HSTRING(data);

    -- Write address phase
    WAIT UNTIL RISING_EDGE(clk);
    axi_in.S_AXI_AWADDR  <= STD_ULOGIC_VECTOR(addr);
    axi_in.S_AXI_AWVALID <= '1';
    axi_in.S_AXI_AWLEN   <= (OTHERS => '0');
    WAIT UNTIL RISING_EDGE(clk) AND axi_out.S_AXI_AWREADY = '1';
    axi_in.S_AXI_AWVALID <= '0';

    -- Write data phase
    axi_in.S_AXI_WDATA  <= STD_ULOGIC_VECTOR(data);
    axi_in.S_AXI_WLAST  <= '1';
    axi_in.S_AXI_WVALID <= '1';
    WAIT UNTIL RISING_EDGE(clk) AND axi_out.S_AXI_WREADY = '1';
    axi_in.S_AXI_WVALID <= '0';
    axi_in.S_AXI_WLAST  <= '0';

    -- Write response phase
    axi_in.S_AXI_BREADY <= '1';
    WAIT UNTIL RISING_EDGE(clk) AND axi_out.S_AXI_BVALID = '1';
    axi_in.S_AXI_BREADY <= '0';
  END PROCEDURE axi_write;

END PACKAGE BODY axi_pkg;
