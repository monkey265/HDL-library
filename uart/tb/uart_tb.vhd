--------------------------------------------------------------------------------
-- Testbench : uart_tb
-- Purpose   : Unit tests for uart_tx and uart_rx modules, verifying serial
--             transmission, reception, and loopback communication in accordance
--             with the project's VUnit style and VHDL guideline.
--------------------------------------------------------------------------------

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.NUMERIC_STD.ALL;

LIBRARY VUNIT_LIB;
  CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

ENTITY uart_tb IS
  GENERIC (
    runner_cfg : STRING
  );
END ENTITY uart_tb;

ARCHITECTURE tb OF uart_tb IS

  ------------------------------------------------------------------------------
  -- Timing & Configuration Constants
  ------------------------------------------------------------------------------
  CONSTANT c_clk_period : TIME := 10 ns; -- 100 MHz clock

  -- Divisor = 4 => (4 * 10 + 2) = 42 clock cycles per baud bit
  CONSTANT c_clk_div    : UNSIGNED(15 DOWNTO 0) := to_unsigned(4, 16);
  CONSTANT c_bit_clocks : NATURAL               := (TO_INTEGER(c_clk_div) * 10) + 2;
  CONSTANT c_bit_period : TIME                  := c_bit_clocks * c_clk_period;

  ------------------------------------------------------------------------------
  -- Shared Configuration Signals
  ------------------------------------------------------------------------------
  SIGNAL s_clk       : STD_LOGIC := '0';
  SIGNAL s_rst_n     : STD_LOGIC := '0';
  SIGNAL s_start_pol : STD_LOGIC := '0';
  SIGNAL s_par_en    : STD_LOGIC := '0';
  SIGNAL s_par_type  : STD_LOGIC := '0';
  SIGNAL s_char_len  : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";
  SIGNAL s_clk_div   : UNSIGNED(15 DOWNTO 0) := c_clk_div;

  ------------------------------------------------------------------------------
  -- Transmitter (UART TX) Signals
  ------------------------------------------------------------------------------
  SIGNAL s_tx_msg     : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_tx_msg_vld : STD_LOGIC := '0';
  SIGNAL s_tx         : STD_LOGIC;
  SIGNAL s_tx_busy    : STD_LOGIC;
  SIGNAL s_tx_done    : STD_LOGIC;

  ------------------------------------------------------------------------------
  -- Receiver (UART RX) Signals
  ------------------------------------------------------------------------------
  SIGNAL s_loopback_en    : STD_LOGIC := '0';
  SIGNAL s_manual_rx      : STD_LOGIC := '1';
  SIGNAL s_rx_in          : STD_LOGIC;
  SIGNAL s_rx_msg         : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_rx_msg_vld     : STD_LOGIC;
  SIGNAL s_rx_busy        : STD_LOGIC;
  SIGNAL s_rx_err_noise   : STD_LOGIC;
  SIGNAL s_rx_err_frame   : STD_LOGIC;
  SIGNAL s_rx_err_par     : STD_LOGIC;

  ------------------------------------------------------------------------------
  -- Low-level byte-write procedure (from diplomova-prace uart_tb)
  ------------------------------------------------------------------------------
  PROCEDURE uart_write_byte (
    data_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_serial : OUT STD_LOGIC;
    bit_period      : IN  TIME
  ) IS
  BEGIN
    -- Send Start Bit
    s_serial <= '0';
    WAIT FOR bit_period;

    -- Send Data Byte (LSB first)
    FOR i IN 0 TO 7 LOOP
      s_serial <= data_in(i);
      WAIT FOR bit_period;
    END LOOP;

    -- Send Stop Bit
    s_serial <= '1';
    WAIT FOR bit_period;
  END PROCEDURE uart_write_byte;

  ------------------------------------------------------------------------------
  -- Low-level byte-read / sampling procedure
  ------------------------------------------------------------------------------
  PROCEDURE uart_read_byte (
    SIGNAL s_serial : IN  STD_LOGIC;
    VARIABLE v_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    bit_period      : IN  TIME
  ) IS
  BEGIN
    -- Wait for start bit falling edge
    WAIT UNTIL falling_edge(s_serial);

    -- Advance to middle of start bit
    WAIT FOR bit_period / 2;

    -- Step to center of each data bit and sample
    FOR i IN 0 TO 7 LOOP
      WAIT FOR bit_period;
      v_data(i) := s_serial;
    END LOOP;

    -- Advance to center of stop bit
    WAIT FOR bit_period;
  END PROCEDURE uart_read_byte;

  ------------------------------------------------------------------------------
  -- Byte-read procedure with parity extraction
  ------------------------------------------------------------------------------
  PROCEDURE uart_read_byte_with_parity (
    SIGNAL s_serial   : IN  STD_LOGIC;
    VARIABLE v_data   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    VARIABLE v_parity : OUT STD_LOGIC;
    bit_period        : IN  TIME
  ) IS
  BEGIN
    -- Wait for start bit falling edge
    WAIT UNTIL falling_edge(s_serial);

    -- Advance to middle of start bit
    WAIT FOR bit_period / 2;

    -- Step to center of each data bit and sample
    FOR i IN 0 TO 7 LOOP
      WAIT FOR bit_period;
      v_data(i) := s_serial;
    END LOOP;

    -- Step to center of parity bit
    WAIT FOR bit_period;
    v_parity := s_serial;

    -- Advance to center of stop bit
    WAIT FOR bit_period;
  END PROCEDURE uart_read_byte_with_parity;

BEGIN

  ------------------------------------------------------------------------------
  -- Clock Generation (100 MHz)
  ------------------------------------------------------------------------------
  s_clk <= NOT s_clk AFTER c_clk_period / 2;

  ------------------------------------------------------------------------------
  -- RX Input Mux (Loopback or Manual Generator)
  ------------------------------------------------------------------------------
  s_rx_in <= s_tx WHEN s_loopback_en = '1' ELSE s_manual_rx;

  ------------------------------------------------------------------------------
  -- DUT Instantiations
  ------------------------------------------------------------------------------
  u_uart_tx : ENTITY work.uart_tx(rtl)
    GENERIC MAP (
      g_msg_width  => 8,
      g_smpl_width => 8
    )
    PORT MAP (
      clk_in       => s_clk,
      rst_n_in     => s_rst_n,
      msg_in       => s_tx_msg,
      msg_vld_in   => s_tx_msg_vld,
      start_pol_in => s_start_pol,
      par_en_in    => s_par_en,
      par_type_in  => s_par_type,
      char_len_in  => s_char_len,
      clk_div_in   => s_clk_div,
      tx_out       => s_tx,
      busy_out     => s_tx_busy,
      tx_done_out  => s_tx_done
    );

  u_uart_rx : ENTITY work.uart_rx(rtl)
    GENERIC MAP (
      g_msg_width  => 8,
      g_smpl_width => 8
    )
    PORT MAP (
      clk_in             => s_clk,
      rst_n_in           => s_rst_n,
      rx_in              => s_rx_in,
      start_pol_in       => s_start_pol,
      par_en_in          => s_par_en,
      par_type_in        => s_par_type,
      char_len_in        => s_char_len,
      clk_div_in         => s_clk_div,
      msg_out            => s_rx_msg,
      msg_vld_strb_out   => s_rx_msg_vld,
      busy_out           => s_rx_busy,
      err_noise_strb_out => s_rx_err_noise,
      err_frame_strb_out => s_rx_err_frame,
      err_par_strb_out   => s_rx_err_par
    );

  ------------------------------------------------------------------------------
  -- Main Test Process
  ------------------------------------------------------------------------------
  main_proc : PROCESS
    VARIABLE v_rx_byte   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    VARIABLE v_rx_parity : STD_LOGIC;
  BEGIN
    test_runner_setup(runner, runner_cfg);

    WHILE test_suite LOOP

      -- Synchronous reset before each test case
      s_rst_n       <= '0';
      s_tx_msg_vld  <= '0';
      s_tx_msg      <= (OTHERS => '0');
      s_start_pol   <= '0';
      s_par_en      <= '0';
      s_par_type    <= '0';
      s_char_len    <= "11";
      s_clk_div     <= c_clk_div;
      s_loopback_en <= '0';
      s_manual_rx   <= '1';
      WAIT UNTIL rising_edge(s_clk);
      WAIT UNTIL rising_edge(s_clk);
      s_rst_n       <= '1';
      WAIT UNTIL rising_edge(s_clk);

      test_case_select_if : IF run("test_uart_tx_sends_byte_ab") THEN
        -- Send command byte 0xAB (matches diplomova-prace uart_tb)
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg     <= X"AB";
        s_tx_msg_vld <= '1';
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg_vld <= '0';

        -- Capture serial bits on tx_out
        uart_read_byte(s_tx, v_rx_byte, c_bit_period);
        check_equal(v_rx_byte, STD_LOGIC_VECTOR'(X"AB"), "Captured byte should match 0xAB");

        WAIT UNTIL s_tx_busy = '0';
        check_equal(s_tx_busy, '0', "Transmitter should return to idle after transmission");

      ELSIF run("test_uart_tx_back_to_back") THEN
        -- Send first byte (0xAB)
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg     <= X"AB";
        s_tx_msg_vld <= '1';
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg_vld <= '0';

        uart_read_byte(s_tx, v_rx_byte, c_bit_period);
        check_equal(v_rx_byte, STD_LOGIC_VECTOR'(X"AB"), "First transmitted byte should match 0xAB");
        WAIT UNTIL s_tx_busy = '0';

        -- Send second byte (0xCD)
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg     <= X"CD";
        s_tx_msg_vld <= '1';
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg_vld <= '0';

        uart_read_byte(s_tx, v_rx_byte, c_bit_period);
        check_equal(v_rx_byte, STD_LOGIC_VECTOR'(X"CD"), "Second transmitted byte should match 0xCD");
        WAIT UNTIL s_tx_busy = '0';

      ELSIF run("test_uart_tx_parity_odd") THEN
        -- Send byte 0xAB with ODD parity (5 ones => parity bit should be '1')
        s_par_en   <= '1';
        s_par_type <= '0';
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg     <= X"AB";
        s_tx_msg_vld <= '1';
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg_vld <= '0';

        uart_read_byte_with_parity(s_tx, v_rx_byte, v_rx_parity, c_bit_period);
        check_equal(v_rx_byte, STD_LOGIC_VECTOR'(X"AB"), "Data byte should match 0xAB");
        check_equal(v_rx_parity, '1', "ODD parity bit for 0xAB (5 ones) should be '1'");
        WAIT UNTIL s_tx_busy = '0';

      ELSIF run("test_uart_tx_parity_even") THEN
        -- Send byte 0xAB with EVEN parity (5 ones => parity bit should be '0')
        s_par_en   <= '1';
        s_par_type <= '1';
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg     <= X"AB";
        s_tx_msg_vld <= '1';
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg_vld <= '0';

        uart_read_byte_with_parity(s_tx, v_rx_byte, v_rx_parity, c_bit_period);
        check_equal(v_rx_byte, STD_LOGIC_VECTOR'(X"AB"), "Data byte should match 0xAB");
        check_equal(v_rx_parity, '0', "EVEN parity bit for 0xAB (5 ones) should be '0'");
        WAIT UNTIL s_tx_busy = '0';

      ELSIF run("test_uart_write_byte_procedure") THEN
        -- Verify uart_write_byte standalone procedure
        uart_write_byte(X"CD", s_manual_rx, c_bit_period);
        WAIT FOR 0 ns;
        check_equal(s_manual_rx, '1', "Serial line should remain idle high after stop bit");

      ELSIF run("test_uart_tx_reset_behavior") THEN
        -- Verify reset defaults
        s_rst_n <= '0';
        WAIT UNTIL rising_edge(s_clk);
        WAIT FOR 0 ns;

        check_equal(s_tx, '1', "tx_out should default to idle high during reset");
        check_equal(s_tx_busy, '0', "busy_out should be '0' during reset");
        check_equal(s_tx_done, '0', "tx_done_out should be '0' during reset");

      ELSIF run("test_uart_rx_receives_byte_cd") THEN
        -- Test RX receiving 0xCD via uart_write_byte (matches diplomova-prace uart_tb)
        uart_write_byte(X"CD", s_manual_rx, c_bit_period);
        WAIT FOR c_bit_period;
        WAIT UNTIL rising_edge(s_clk);

        check_equal(s_rx_msg, STD_LOGIC_VECTOR'(X"CD"), "RX should receive byte 0xCD correctly");
        check_equal(s_rx_busy, '0', "RX should return to idle after receiving");
        check_equal(s_rx_err_frame, '0', "Framing error should not be asserted");
        check_equal(s_rx_err_par, '0', "Parity error should not be asserted");

      ELSIF run("test_uart_tx_rx_loopback") THEN
        -- Enable direct loopback from TX output to RX input
        s_loopback_en <= '1';
        WAIT UNTIL rising_edge(s_clk);

        -- Transmit byte 0x5A through TX
        s_tx_msg     <= X"5A";
        s_tx_msg_vld <= '1';
        WAIT UNTIL rising_edge(s_clk);
        s_tx_msg_vld <= '0';

        -- Wait for RX to receive and validate the looped back byte
        WAIT UNTIL s_rx_msg_vld = '1';
        check_equal(s_rx_msg, STD_LOGIC_VECTOR'(X"5A"), "Loopback byte should match 0x5A");
        check_equal(s_rx_err_frame, '0', "Loopback should have no framing error");

        WAIT UNTIL s_tx_busy = '0';
        check_equal(s_tx_busy, '0', "TX should be idle after transmission");

      END IF test_case_select_if;

    END LOOP;

    test_runner_cleanup(runner);
  END PROCESS main_proc;

  test_runner_watchdog(runner, 1 ms);

END ARCHITECTURE tb;
