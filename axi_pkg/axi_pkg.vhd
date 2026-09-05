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

  -- Drives a single AXI4-Stream transaction (valid/ready handshake).
  PROCEDURE axis_push(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   tvalid   : OUT STD_LOGIC;
    SIGNAL   tready   : IN  STD_LOGIC;
    SIGNAL   tdata    : OUT STD_LOGIC_VECTOR;
    CONSTANT data_val : IN  STD_LOGIC_VECTOR
  );

  -- Drives a single AXI4-Stream transaction with tlast.
  PROCEDURE axis_push(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   tvalid   : OUT STD_LOGIC;
    SIGNAL   tready   : IN  STD_LOGIC;
    SIGNAL   tdata    : OUT STD_LOGIC_VECTOR;
    CONSTANT data_val : IN  STD_LOGIC_VECTOR;
    SIGNAL   tlast    : OUT STD_LOGIC;
    CONSTANT last_val : IN  STD_LOGIC
  );

  -- Captures a single AXI4-Stream transaction (valid/ready handshake).
  PROCEDURE axis_pop(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   tvalid   : IN  STD_LOGIC;
    SIGNAL   tready   : OUT STD_LOGIC;
    SIGNAL   tdata    : IN  STD_LOGIC_VECTOR;
    VARIABLE data_val : OUT STD_LOGIC_VECTOR
  );

  -- Captures a single AXI4-Stream transaction with tlast.
  PROCEDURE axis_pop(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   tvalid   : IN  STD_LOGIC;
    SIGNAL   tready   : OUT STD_LOGIC;
    SIGNAL   tdata    : IN  STD_LOGIC_VECTOR;
    VARIABLE data_val : OUT STD_LOGIC_VECTOR;
    SIGNAL   tlast    : IN  STD_LOGIC;
    VARIABLE last_val : OUT STD_LOGIC
  );

  -- Generic stream aliases
  PROCEDURE push_stream(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   valid    : OUT STD_LOGIC;
    SIGNAL   ready    : IN  STD_LOGIC;
    SIGNAL   data_out : OUT STD_LOGIC_VECTOR;
    CONSTANT data_val : IN  STD_LOGIC_VECTOR
  );

  PROCEDURE pop_stream(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   valid    : IN  STD_LOGIC;
    SIGNAL   ready    : OUT STD_LOGIC;
    SIGNAL   data_in  : IN  STD_LOGIC_VECTOR;
    VARIABLE data_val : OUT STD_LOGIC_VECTOR
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

  PROCEDURE axis_push(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   tvalid   : OUT STD_LOGIC;
    SIGNAL   tready   : IN  STD_LOGIC;
    SIGNAL   tdata    : OUT STD_LOGIC_VECTOR;
    CONSTANT data_val : IN  STD_LOGIC_VECTOR
  ) IS
  BEGIN
    WAIT UNTIL RISING_EDGE(clk);
    tdata  <= data_val;
    tvalid <= '1';
    handshake_loop : LOOP
      WAIT UNTIL RISING_EDGE(clk);
      EXIT handshake_loop WHEN tready = '1';
    END LOOP handshake_loop;
    tvalid <= '0';
    WAIT FOR 0 ns;
  END PROCEDURE axis_push;

  PROCEDURE axis_push(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   tvalid   : OUT STD_LOGIC;
    SIGNAL   tready   : IN  STD_LOGIC;
    SIGNAL   tdata    : OUT STD_LOGIC_VECTOR;
    CONSTANT data_val : IN  STD_LOGIC_VECTOR;
    SIGNAL   tlast    : OUT STD_LOGIC;
    CONSTANT last_val : IN  STD_LOGIC
  ) IS
  BEGIN
    WAIT UNTIL RISING_EDGE(clk);
    tdata  <= data_val;
    tlast  <= last_val;
    tvalid <= '1';
    handshake_loop : LOOP
      WAIT UNTIL RISING_EDGE(clk);
      EXIT handshake_loop WHEN tready = '1';
    END LOOP handshake_loop;
    tvalid <= '0';
    tlast  <= '0';
    WAIT FOR 0 ns;
  END PROCEDURE axis_push;

  PROCEDURE axis_pop(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   tvalid   : IN  STD_LOGIC;
    SIGNAL   tready   : OUT STD_LOGIC;
    SIGNAL   tdata    : IN  STD_LOGIC_VECTOR;
    VARIABLE data_val : OUT STD_LOGIC_VECTOR
  ) IS
  BEGIN
    WAIT UNTIL RISING_EDGE(clk);
    tready <= '1';
    capture_loop : LOOP
      WAIT UNTIL RISING_EDGE(clk);
      capture_check_if : IF tvalid = '1' THEN
        data_val := tdata;
        EXIT capture_loop;
      END IF capture_check_if;
    END LOOP capture_loop;
    tready <= '0';
    WAIT FOR 0 ns;
  END PROCEDURE axis_pop;

  PROCEDURE axis_pop(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   tvalid   : IN  STD_LOGIC;
    SIGNAL   tready   : OUT STD_LOGIC;
    SIGNAL   tdata    : IN  STD_LOGIC_VECTOR;
    VARIABLE data_val : OUT STD_LOGIC_VECTOR;
    SIGNAL   tlast    : IN  STD_LOGIC;
    VARIABLE last_val : OUT STD_LOGIC
  ) IS
  BEGIN
    WAIT UNTIL RISING_EDGE(clk);
    tready <= '1';
    capture_loop : LOOP
      WAIT UNTIL RISING_EDGE(clk);
      capture_check_if : IF tvalid = '1' THEN
        data_val := tdata;
        last_val := tlast;
        EXIT capture_loop;
      END IF capture_check_if;
    END LOOP capture_loop;
    tready <= '0';
    WAIT FOR 0 ns;
  END PROCEDURE axis_pop;

  PROCEDURE push_stream(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   valid    : OUT STD_LOGIC;
    SIGNAL   ready    : IN  STD_LOGIC;
    SIGNAL   data_out : OUT STD_LOGIC_VECTOR;
    CONSTANT data_val : IN  STD_LOGIC_VECTOR
  ) IS
  BEGIN
    axis_push(clk, valid, ready, data_out, data_val);
  END PROCEDURE push_stream;

  PROCEDURE pop_stream(
    SIGNAL   clk      : IN  STD_LOGIC;
    SIGNAL   valid    : IN  STD_LOGIC;
    SIGNAL   ready    : OUT STD_LOGIC;
    SIGNAL   data_in  : IN  STD_LOGIC_VECTOR;
    VARIABLE data_val : OUT STD_LOGIC_VECTOR
  ) IS
  BEGIN
    axis_pop(clk, valid, ready, data_in, data_val);
  END PROCEDURE pop_stream;

END PACKAGE BODY axi_pkg;
