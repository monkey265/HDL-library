--------------------------------------------------------------------------------
-- Testbench   : axi_lite_pri_arbiter_tb
-- Description : Unit tests for the module, verifying ...
--------------------------------------------------------------------------------

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.NUMERIC_STD.ALL;

LIBRARY VUNIT_LIB;
  CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

  USE work.axi_lite_pkg.ALL;
  USE work.tb_pkg.ALL;
  USE work.axi_pkg.ALL;

ENTITY axi_lite_pri_arbiter_tb IS
  GENERIC (
    runner_cfg : STRING
  );
END ENTITY axi_lite_pri_arbiter_tb;

ARCHITECTURE tb OF axi_lite_pri_arbiter_tb IS

  CONSTANT c_clk_period : TIME := 10 ns; -- 100 MHz clock

  SIGNAL s_clk_in    : STD_LOGIC := '0';
  SIGNAL s_arst_n_in : STD_LOGIC := '0';

  SIGNAL s_a_m2s_in  : axi_lite_m2s_t;
  SIGNAL s_a_s2m_out : axi_lite_s2m_t;

  SIGNAL s_b_m2s_in  : axi_lite_m2s_t;
  SIGNAL s_b_s2m_out : axi_lite_s2m_t;

  SIGNAL s_slave_m2s_out : axi_lite_m2s_t;
  SIGNAL s_slave_s2m_in  : axi_lite_s2m_t;


BEGIN

  s_clk_in <= NOT s_clk_in AFTER c_clk_period / 2;

  u_axi_lite_pri_arbiter : ENTITY work.axi_lite_pri_arbiter(rtl)
    PORT MAP (
      clk_in        => s_clk_in,
      arst_n_in     => s_arst_n_in,

      -- Master A (higher priority)
      a_m2s_in      => s_a_m2s_in,
      a_s2m_out     => s_a_s2m_out,

      -- Master B (lower priority)
      b_m2s_in      => s_b_m2s_in,
      b_s2m_out     => s_b_s2m_out,

      -- Single downstream slave
      slave_m2s_out => s_slave_m2s_out,
      slave_s2m_in  => s_slave_s2m_in
    );

  main_proc : PROCESS
  BEGIN
    test_runner_setup(runner, runner_cfg);

    WHILE test_suite LOOP

      -- Synchronous reset before each test case
      strobe(s_arst_n_in, 100 ns, '0');

      IF run("test_basic") THEN
        -- master A tx
        axi_lite_write(X"00000010", X"DEADC0DE", s_clk_in, s_a_m2s_in, s_a_s2m_out);
        WAIT UNTIL RISING_EDGE(s_clk_in);

      END IF;

    END LOOP;

    test_runner_cleanup(runner);
  END PROCESS main_proc;

  test_runner_watchdog(runner, 1 ms);

END ARCHITECTURE tb;
