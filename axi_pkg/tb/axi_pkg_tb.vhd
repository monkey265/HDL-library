--------------------------------------------------------------------------------
-- Testbench : axi_pkg_tb
-- Purpose   : Unit tests for axi_pkg's records and axi_write bus-driver
--             procedure. Exercised against an always-ready AXI4 slave stub
--             (no DUT -- axi_pkg is a package, not an entity).
--------------------------------------------------------------------------------

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE work.axi_pkg.ALL;

LIBRARY VUNIT_LIB;
  CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

ENTITY axi_pkg_tb IS
  GENERIC (
    runner_cfg : STRING
  );
END ENTITY axi_pkg_tb;

ARCHITECTURE tb OF axi_pkg_tb IS

  CONSTANT c_clk_period : TIME := 10 ns;

  SIGNAL clk     : STD_LOGIC := '0';
  SIGNAL axi_in  : t_axi_ports_in;
  SIGNAL axi_out : t_axi_ports_out;

  -- Smoke check that the array types elaborate correctly.
  SIGNAL axi_in_array  : t_axi_ports_in_array(0 TO 1);
  SIGNAL axi_out_array : t_axi_ports_out_array(0 TO 1);

BEGIN

  clk <= NOT clk AFTER c_clk_period / 2;

  -- Always-ready AXI4 slave stub: accepts every phase on the cycle it is
  -- requested and always responds OKAY.
  axi_out.S_AXI_AWREADY <= axi_in.S_AXI_AWVALID;
  axi_out.S_AXI_WREADY  <= axi_in.S_AXI_WVALID;
  axi_out.S_AXI_BVALID  <= axi_in.S_AXI_BREADY;
  axi_out.S_AXI_BRESP   <= "00"; -- OKAY

  main : PROCESS
  BEGIN
    test_runner_setup(runner, runner_cfg);

    WHILE test_suite LOOP

      IF run("test_axi_write_drives_address_and_data") THEN
        axi_write(X"001234", X"DEADBEEF", clk, axi_in, axi_out);
        WAIT FOR 0 ns; -- let axi_write's final signal assignments settle

        check_equal(STD_LOGIC_VECTOR(axi_in.S_AXI_AWADDR), STD_LOGIC_VECTOR'(X"001234"), "AWADDR should hold the written address");
        check_equal(STD_LOGIC_VECTOR(axi_in.S_AXI_WDATA), STD_LOGIC_VECTOR'(X"DEADBEEF"), "WDATA should hold the written data");
        check_equal(axi_in.S_AXI_AWVALID, '0', "AWVALID should be deasserted after the handshake");
        check_equal(axi_in.S_AXI_WVALID, '0', "WVALID should be deasserted after the handshake");
        check_equal(axi_in.S_AXI_BREADY, '0', "BREADY should be deasserted after the write response");

      ELSIF run("test_axi_write_back_to_back") THEN
        axi_write(X"000010", X"11111111", clk, axi_in, axi_out);
        axi_write(X"000020", X"22222222", clk, axi_in, axi_out);
        WAIT FOR 0 ns; -- let axi_write's final signal assignments settle

        check_equal(STD_LOGIC_VECTOR(axi_in.S_AXI_AWADDR), STD_LOGIC_VECTOR'(X"000020"), "Second AWADDR should overwrite the first");
        check_equal(STD_LOGIC_VECTOR(axi_in.S_AXI_WDATA), STD_LOGIC_VECTOR'(X"22222222"), "Second WDATA should overwrite the first");

      END IF;

    END LOOP;

    test_runner_cleanup(runner);
  END PROCESS main;

  test_runner_watchdog(runner, 1 us);

END ARCHITECTURE tb;
