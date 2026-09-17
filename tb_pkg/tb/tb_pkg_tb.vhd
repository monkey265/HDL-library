--------------------------------------------------------------------------------
-- Testbench : tb_pkg_tb
-- Purpose   : Unit tests for tb_pkg's conversion, scaling, random-stimulus,
--             timing, and file I/O subprograms.
--------------------------------------------------------------------------------

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.NUMERIC_STD.ALL;
  USE work.tb_pkg.ALL;

LIBRARY VUNIT_LIB;
  CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

ENTITY tb_pkg_tb IS
  GENERIC (
    runner_cfg : STRING
  );
END ENTITY tb_pkg_tb;

ARCHITECTURE tb OF tb_pkg_tb IS

  CONSTANT c_tolerance : REAL := 0.01;

  -- Real callers always pass a descending-range vector (e.g. (31 DOWNTO 0));
  -- a bare string literal would default to an ascending range instead and
  -- mask vec2string's bit-order behavior below.
  CONSTANT c_vec2string_input : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10110000";

  SIGNAL s_sig_strobe : STD_LOGIC := '0';
  SIGNAL s_clk        : STD_LOGIC := '0';
  SIGNAL s_rst_n      : STD_LOGIC := '1';

BEGIN

  s_clk <= NOT s_clk AFTER 5 ns; -- 100 MHz clock

  main_proc : PROCESS
    VARIABLE v_slv_data      : t_slv_array(0 TO 3)(7 DOWNTO 0);
    VARIABLE v_slv_readback  : t_slv_array(0 TO 3)(7 DOWNTO 0);
    VARIABLE v_real_data     : t_real_array(0 TO 3);
    VARIABLE v_real_readback : t_real_array(0 TO 3);
    VARIABLE v_t_start       : TIME;
    VARIABLE v_elapsed       : TIME;
    VARIABLE v_int           : INTEGER;
  BEGIN
    test_runner_setup(runner, runner_cfg);

    WHILE test_suite LOOP

      -- vec2string walks signal_in'RANGE and writes result(i+1) := signal_in(i),
      -- so for a descending vector the printed string is bit-reversed (LSB first).
      IF run("test_vec2string_bit_order") THEN
        check_equal(vec2string(c_vec2string_input), STRING'("00001101"), "vec2string emits bits LSB-first for a descending vector");

      ELSIF run("test_scale_round_trip") THEN
        check(ABS(scale_slv_to_real(scale_real_to_slv(0.0, 8)) - 0.0) < c_tolerance, "round trip should preserve 0.0");
        check(ABS(scale_slv_to_real(scale_real_to_slv(0.5, 8)) - 0.5) < c_tolerance, "round trip should preserve 0.5");
        check(ABS(scale_slv_to_real(scale_real_to_slv(-0.5, 8)) - (-0.5)) < c_tolerance, "round trip should preserve -0.5");
        check(ABS(scale_slv_to_real(scale_real_to_slv(1.0, 8)) - 1.0) < c_tolerance, "round trip should preserve 1.0");
        check(ABS(scale_slv_to_real(scale_real_to_slv(-1.0, 8)) - (-1.0)) < c_tolerance, "round trip should preserve -1.0");

      ELSIF run("test_scale_real_to_slv_clamps_out_of_range_input") THEN
        check_equal(scale_real_to_slv(2.0, 8), scale_real_to_slv(1.0, 8), "input above 1.0 should clamp to 1.0");
        check_equal(scale_real_to_slv(-2.0, 8), scale_real_to_slv(-1.0, 8), "input below -1.0 should clamp to -1.0");

      ELSIF run("test_rssi_half_db_to_dbm") THEN
        -- 400 half-dB -> 200 dB shifted, minus the 158 correction -> 42 dBm.
        check_equal(rssi_half_db_to_dbm(STD_LOGIC_VECTOR(TO_UNSIGNED(400, 16))), STD_LOGIC_VECTOR(TO_SIGNED(42, 16)), "normal-range rssi conversion");
        -- 0 half-dB -> -158 dBm, clamped to the -128 floor.
        check_equal(rssi_half_db_to_dbm(STD_LOGIC_VECTOR(TO_UNSIGNED(0, 16))), STD_LOGIC_VECTOR(TO_SIGNED(-128, 16)), "below-floor rssi conversion clamps to -128");

      ELSIF run("test_get_wait_cycles") THEN
        check_equal(get_wait_cycles(10 ns, 50 us), 5000, "50us / 10ns period should be 5000 cycles");

      ELSIF run("test_random_vector_is_deterministic_for_same_seeds") THEN
        check_equal(random_vector(16, 111, 222), random_vector(16, 111, 222), "same seeds should reproduce the same vector");

      ELSIF run("test_random_bit_is_deterministic_for_same_seeds") THEN
        check_equal(random_bit(111, 222), random_bit(111, 222), "same seeds should reproduce the same bit");

      ELSIF run("test_strobe_pulses_for_two_periods") THEN
        v_t_start := NOW;
        strobe(s_sig_strobe, 10 ns, '1');
        v_elapsed := NOW - v_t_start;
        check(v_elapsed = 20 ns, "strobe should hold active then inactive for one period_ns each");
        check_equal(s_sig_strobe, '0', "strobe should leave the signal deasserted (NOT active) when it returns");

      ELSIF run("test_file_round_trip_slv") THEN
        v_slv_data(0) := X"AA";
        v_slv_data(1) := X"BB";
        v_slv_data(2) := X"CC";
        v_slv_data(3) := X"DD";
        save_to_file(output_path(runner_cfg) & "slv_roundtrip.txt", v_slv_data);
        v_slv_readback := read_from_file(output_path(runner_cfg) & "slv_roundtrip.txt", 4, 8);
        check_equal(v_slv_readback(0), v_slv_data(0), "slv file round trip: word 0");
        check_equal(v_slv_readback(1), v_slv_data(1), "slv file round trip: word 1");
        check_equal(v_slv_readback(2), v_slv_data(2), "slv file round trip: word 2");
        check_equal(v_slv_readback(3), v_slv_data(3), "slv file round trip: word 3");

      ELSIF run("test_file_round_trip_real") THEN
        v_real_data(0) := 1.5;
        v_real_data(1) := -2.25;
        v_real_data(2) := 0.0;
        v_real_data(3) := 100.0;
        save_real_to_file(output_path(runner_cfg) & "real_roundtrip.txt", v_real_data);
        v_real_readback := read_real_from_file(output_path(runner_cfg) & "real_roundtrip.txt", 4);
        check(ABS(v_real_readback(0) - v_real_data(0)) < c_tolerance, "real file round trip: word 0");
        check(ABS(v_real_readback(1) - v_real_data(1)) < c_tolerance, "real file round trip: word 1");
        check(ABS(v_real_readback(2) - v_real_data(2)) < c_tolerance, "real file round trip: word 2");
        check(ABS(v_real_readback(3) - v_real_data(3)) < c_tolerance, "real file round trip: word 3");

      ELSIF run("test_my_is_equal_pass_path") THEN
        my_is_equal(X"5A", X"5A");
        check_equal(STD_LOGIC_VECTOR'(X"5A"), STD_LOGIC_VECTOR'(X"5A"), "my_is_equal pass path should not raise an error/failure severity");

      ELSIF run("test_debug_mode_toggle") THEN
        set_debug_mode(FALSE);
        check(NOT is_debug_mode, "debug mode should be FALSE initially or when disabled");
        debug_msg("This debug message is disabled");
        set_debug_mode(TRUE);
        check(is_debug_mode, "debug mode should be TRUE after enabling");
        debug_msg("This debug message is enabled");
        set_debug_mode(FALSE);
        check(NOT is_debug_mode, "debug mode should be restored to FALSE");

      ELSIF run("test_wait_cycles") THEN
        WAIT UNTIL RISING_EDGE(s_clk);
        v_t_start := NOW;
        wait_cycles(s_clk, 4);
        check_equal(NOW - v_t_start, 40 ns, "wait_cycles(4) on 10ns clock should wait 40ns");

      ELSIF run("test_pulse_reset") THEN
        pulse_reset(s_rst_n, s_clk, 3, TRUE);
        check_equal(s_rst_n, '1', "pulse_reset active-low should return deasserted high");

      ELSIF run("test_format_hex") THEN
        check_equal(format_hex(STD_LOGIC_VECTOR'(X"DEADBEEF")), STRING'("0xDEADBEEF"), "format_hex should format 32-bit hex with 0x prefix");

      ELSIF run("test_random_integer_in_range") THEN
        FOR i IN 1 TO 20 LOOP
          v_int := random_integer(10, 20, 100 + i, 200 + i);
          check(v_int >= 10 AND v_int <= 20, "random_integer must be within [10, 20]");
        END LOOP;

      ELSIF run("test_random_boolean") THEN
        check_equal(random_boolean(1.0, 100, 200), TRUE, "prob 1.0 must be true");
        check_equal(random_boolean(0.0, 100, 200), FALSE, "prob 0.0 must be false");

      END IF;

    END LOOP;

    test_runner_cleanup(runner);
  END PROCESS main_proc;

END ARCHITECTURE tb;
