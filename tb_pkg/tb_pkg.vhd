--------------------------------------------------------------------------------
-- Package : tb_pkg
-- Purpose : Shared testbench types, constants, and utility subprograms.
--------------------------------------------------------------------------------

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.NUMERIC_STD.ALL;
  USE IEEE.MATH_REAL.ALL;
  USE STD.TEXTIO.ALL;

PACKAGE tb_pkg IS

  ------------------------------------------------------------------------------
  -- Global configuration
  ------------------------------------------------------------------------------
  TYPE t_debug_cfg IS PROTECTED
    PROCEDURE set(enable : BOOLEAN);
    IMPURE FUNCTION is_enabled RETURN BOOLEAN;
  END PROTECTED t_debug_cfg;

  ------------------------------------------------------------------------------
  -- Clock period constants
  ------------------------------------------------------------------------------
  CONSTANT c_ad_clk_period     : TIME := 6.25 ns; -- 80  MHz
  CONSTANT c_div_clk_period    : TIME := 12.5 ns; -- 40  MHz
  CONSTANT c_wiz_clk_period    : TIME := 5 ns;     -- 100 MHz
  CONSTANT c_fpga_clk_period   : TIME := 5 ns;     -- 100 MHz, independent from others
  CONSTANT c_fpga10_clk_period : TIME := 50 ns;    -- 10  MHz, derived from fpga_clk

  -- Usage:
  -- ad_clk     <= NOT ad_clk     AFTER c_ad_clk_period;     -- 80MHz
  -- div_clk    <= NOT div_clk    AFTER c_div_clk_period;    -- 40MHz
  -- wiz_clk    <= NOT wiz_clk    AFTER c_wiz_clk_period;    -- 100MHz
  -- fpga_clk   <= NOT fpga_clk   AFTER c_fpga_clk_period;   -- 100MHz independent from others
  -- fpga10_clk <= NOT fpga10_clk AFTER c_fpga10_clk_period; -- 10MHz derived fpga_clk

  ------------------------------------------------------------------------------
  -- Misc constants
  ------------------------------------------------------------------------------
  CONSTANT c_rssi_correction : INTEGER := 158;
  CONSTANT c_timer_max       : NATURAL := 1000000;

  -- Memory constants
  CONSTANT c_num_tx_mem_slots : NATURAL := 8;
  CONSTANT c_num_tx_mem_words : NATURAL := 1024;

  ------------------------------------------------------------------------------
  -- Shared types
  ------------------------------------------------------------------------------
  TYPE t_alt_integer_array IS ARRAY (NATURAL RANGE <>) OF INTEGER;
  TYPE t_vector_array      IS ARRAY (NATURAL RANGE <>) OF STD_ULOGIC_VECTOR(31 DOWNTO 0);
  TYPE t_vector_array_8    IS ARRAY (NATURAL RANGE <>) OF STD_ULOGIC_VECTOR(7 DOWNTO 0);
  TYPE t_vector_array_64   IS ARRAY (NATURAL RANGE <>) OF STD_ULOGIC_VECTOR(63 DOWNTO 0);
  TYPE t_logic_array       IS ARRAY (NATURAL RANGE <>) OF STD_ULOGIC;
  TYPE t_real_array        IS ARRAY (NATURAL RANGE <>) OF REAL;
  TYPE t_slv_array         IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR;

  ------------------------------------------------------------------------------
  -- Custom datatypes for radio toplevel
  ------------------------------------------------------------------------------

  -- Input signals record
  TYPE t_block_inputs IS RECORD
    -- Clocks
    ad_clk     : STD_LOGIC;
    div_clk    : STD_LOGIC;
    wiz_clk    : STD_LOGIC;
    fpga_clk   : STD_LOGIC;
    fpga10_clk : STD_LOGIC;

    -- Resets
    aresetn : STD_LOGIC;

    -- Bram TX
    tx_addra : STD_LOGIC_VECTOR(31 DOWNTO 0);
    tx_dina  : STD_LOGIC_VECTOR(63 DOWNTO 0);
    tx_ena   : STD_LOGIC;
    tx_rsta  : STD_LOGIC;
    tx_wea   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    tx_clka  : STD_LOGIC;

    -- Bram RX
    rx_addrb : STD_LOGIC_VECTOR(31 DOWNTO 0);
    rx_dinb  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    rx_enb   : STD_LOGIC;
    rx_rstb  : STD_LOGIC;
    rx_web   : STD_LOGIC_VECTOR(3 DOWNTO 0);
    rx_clkb  : STD_LOGIC;
  END RECORD;

  -- Output signals record
  TYPE t_block_outputs IS RECORD
    -- Bram TX
    tx_douta : STD_LOGIC_VECTOR(63 DOWNTO 0);

    -- Bram RX
    rx_doutb : STD_LOGIC_VECTOR(31 DOWNTO 0);
    irq      : STD_LOGIC;
  END RECORD;

  TYPE t_block_inputs_array  IS ARRAY (NATURAL RANGE <>) OF t_block_inputs;
  TYPE t_block_outputs_array IS ARRAY (NATURAL RANGE <>) OF t_block_outputs;

  -- Configuration for a single radio
  TYPE t_radio_config IS RECORD
    enable        : BOOLEAN;
    num_packets   : INTEGER;
    packet_len    : INTEGER;
    packet_period : INTEGER;
    mcs           : INTEGER RANGE 0 TO 7;
    mode          : INTEGER RANGE 0 TO 5;
    pos_x         : REAL;
    pos_y         : REAL;
    pos_z         : REAL;
    start_delay   : INTEGER;
    check_fcs     : BOOLEAN;
  END RECORD;

  -- Array of radio configurations (one per radio)
  TYPE t_radio_config_array IS ARRAY (NATURAL RANGE <>) OF t_radio_config;

  TYPE t_axi_debug IS RECORD
    tx_ctrl_reg_1   : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    tx_ctrl_reg_2   : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    ofdm_rx_reg     : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    rx_ctrl_reg_1   : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    rx_ctrl_reg_2   : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    rx_ctrl_reg_3   : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    rx_ctrl_reg_4   : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    rssi_reg        : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    dac_sample_reg  : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    adc_sample_reg  : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    ad9361_reg      : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    timestamp_reg_1 : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    timestamp_reg_2 : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    wdg_event_cntr  : STD_ULOGIC_VECTOR(31 DOWNTO 0);
    last_read_reg   : STD_ULOGIC_VECTOR(31 DOWNTO 0);
  END RECORD;

  TYPE t_axi_debug_array IS ARRAY (NATURAL RANGE <>) OF t_axi_debug;

  ------------------------------------------------------------------------------
  -- Procedures and functions
  ------------------------------------------------------------------------------
  PROCEDURE info_msg (str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns);
  PROCEDURE pass_msg (str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns);
  PROCEDURE warn_msg (str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns);
  PROCEDURE fail_msg (str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns);
  PROCEDURE error_msg(str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns);
  PROCEDURE debug_msg(str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns);
  PROCEDURE log_msg  (str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns);

  PROCEDURE set_debug_mode(enable : BOOLEAN);
  IMPURE FUNCTION is_debug_mode RETURN BOOLEAN;

  FUNCTION vec2string(signal_in : STD_LOGIC_VECTOR) RETURN STRING;

  PROCEDURE my_is_equal(
    tested_data   : STD_LOGIC_VECTOR;
    expected_data : STD_LOGIC_VECTOR;
    check_name    : STRING := ""
  );

  PROCEDURE strobe(
    SIGNAL   sig       : OUT STD_LOGIC;
    CONSTANT period_ns : TIME;
    CONSTANT active    : STD_LOGIC := '1'
  );

  IMPURE FUNCTION random_vector(
    len            : INTEGER;
    CONSTANT seed1 : IN INTEGER;
    CONSTANT seed2 : IN INTEGER
  ) RETURN STD_LOGIC_VECTOR;

  IMPURE FUNCTION random_bit(CONSTANT seed1 : IN INTEGER; CONSTANT seed2 : IN INTEGER) RETURN STD_LOGIC;

  FUNCTION randnf(seed1 : POSITIVE := 13579) RETURN REAL;

  FUNCTION scale_slv_to_real(input : STD_LOGIC_VECTOR) RETURN REAL;
  FUNCTION scale_real_to_slv(input : REAL; width : INTEGER) RETURN STD_LOGIC_VECTOR;

  -- Converts rssi half db to dbm
  FUNCTION rssi_half_db_to_dbm(rssi_half_db : STD_LOGIC_VECTOR(15 DOWNTO 0)) RETURN STD_LOGIC_VECTOR;

  -- Calculates the number of clock cycles to wait for a given amount of time.
  FUNCTION get_wait_cycles(CONSTANT clk_period : TIME; CONSTANT wait_time : TIME) RETURN NATURAL;

  -- Reads a file of hex-encoded STD_LOGIC_VECTOR words into a t_slv_array.
  IMPURE FUNCTION read_from_file(
    file_name : STRING;
    depth     : POSITIVE;
    width     : POSITIVE
  ) RETURN t_slv_array;

  -- Writes a t_slv_array to file as hex-encoded words.
  PROCEDURE save_to_file(
    file_name : STRING;
    data      : t_slv_array
  );

  -- Reads a file of REAL values into a t_real_array.
  IMPURE FUNCTION read_real_from_file(
    file_name : STRING;
    depth     : POSITIVE
  ) RETURN t_real_array;

  -- Writes a t_real_array to file.
  PROCEDURE save_real_to_file(
    file_name : STRING;
    data      : t_real_array
  );

END PACKAGE tb_pkg;

PACKAGE BODY tb_pkg IS

  ------------------------------------------------------------------------------
  -- Global configuration protected body & instance
  ------------------------------------------------------------------------------
  TYPE t_debug_cfg IS PROTECTED BODY
    VARIABLE v_enable : BOOLEAN := FALSE;

    PROCEDURE set(enable : BOOLEAN) IS
    BEGIN
      v_enable := enable;
    END PROCEDURE set;

    IMPURE FUNCTION is_enabled RETURN BOOLEAN IS
    BEGIN
      RETURN v_enable;
    END FUNCTION is_enabled;
  END PROTECTED BODY t_debug_cfg;

  SHARED VARIABLE v_debug_cfg : t_debug_cfg;

  ------------------------------------------------------------------------------
  -- Message logging procedures
  ------------------------------------------------------------------------------
  PROCEDURE info_msg(str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns) IS
  BEGIN
    timestamp_if : IF timestamp THEN
      WRITE(output, ">> INFO  : " & str & " | time: " & TO_STRING(NOW, unit) & LF);
    ELSE
      WRITE(output, ">> INFO  : " & str & LF);
    END IF timestamp_if;
  END PROCEDURE info_msg;

  PROCEDURE pass_msg(str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns) IS
  BEGIN
    timestamp_if : IF timestamp THEN
      WRITE(output, ">> PASSED: " & str & " | time: " & TO_STRING(NOW, unit) & LF);
    ELSE
      WRITE(output, ">> PASSED: " & str & LF);
    END IF timestamp_if;
  END PROCEDURE pass_msg;

  PROCEDURE warn_msg(str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns) IS
  BEGIN
    timestamp_if : IF timestamp THEN
      WRITE(output, ">> " & SEVERITY_LEVEL'IMAGE(WARNING) & " : " & str & " | time: " & TO_STRING(NOW, unit) & LF);
    ELSE
      WRITE(output, ">> " & SEVERITY_LEVEL'IMAGE(WARNING) & " : " & str & LF);
    END IF timestamp_if;
    ASSERT FALSE REPORT str SEVERITY WARNING;
  END PROCEDURE warn_msg;

  PROCEDURE fail_msg(str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns) IS
  BEGIN
    timestamp_if : IF timestamp THEN
      WRITE(output, ">> " & SEVERITY_LEVEL'IMAGE(FAILURE) & " : " & str & " | time: " & TO_STRING(NOW, unit) & LF);
    ELSE
      WRITE(output, ">> " & SEVERITY_LEVEL'IMAGE(FAILURE) & " : " & str & LF);
    END IF timestamp_if;
    ASSERT FALSE REPORT str SEVERITY FAILURE;
  END PROCEDURE fail_msg;

  PROCEDURE error_msg(str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns) IS
  BEGIN
    timestamp_if : IF timestamp THEN
      WRITE(output, ">> " & SEVERITY_LEVEL'IMAGE(ERROR) & " : " & str & " | time: " & TO_STRING(NOW, unit) & LF);
    ELSE
      WRITE(output, ">> " & SEVERITY_LEVEL'IMAGE(ERROR) & " : " & str & LF);
    END IF timestamp_if;
    ASSERT FALSE REPORT str SEVERITY ERROR;
  END PROCEDURE error_msg;

  PROCEDURE debug_msg(str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns) IS
  BEGIN
    debug_enabled_if : IF v_debug_cfg.is_enabled THEN
      timestamp_if : IF timestamp THEN
        WRITE(output, ">> DEBUG : " & str & " | time: " & TO_STRING(NOW, unit) & LF);
      ELSE
        WRITE(output, ">> DEBUG : " & str & LF);
      END IF timestamp_if;
    END IF debug_enabled_if;
  END PROCEDURE debug_msg;

  PROCEDURE log_msg(str : STRING; timestamp : BOOLEAN := FALSE; unit : TIME := ns) IS
  BEGIN
    timestamp_if : IF timestamp THEN
      WRITE(output, ">> LOG   : " & str & " | time: " & TO_STRING(NOW, unit) & LF);
    ELSE
      WRITE(output, ">> LOG   : " & str & LF);
    END IF timestamp_if;
  END PROCEDURE log_msg;

  ------------------------------------------------------------------------------
  -- Conversion and comparison helpers
  ------------------------------------------------------------------------------

  -- Converts a STD_LOGIC_VECTOR to STRING for cases where TO_STRING is unavailable.
  FUNCTION vec2string(signal_in : STD_LOGIC_VECTOR) RETURN STRING IS
    VARIABLE v_result : STRING(1 TO signal_in'LENGTH);
  BEGIN
    bit_loop : FOR i IN signal_in'RANGE LOOP
      bit_value_if : IF signal_in(i) = '1' THEN
        v_result(i + 1) := '1';
      ELSE
        v_result(i + 1) := '0';
      END IF bit_value_if;
    END LOOP bit_loop;
    RETURN v_result;
  END FUNCTION vec2string;

  PROCEDURE my_is_equal(
    tested_data   : STD_LOGIC_VECTOR;
    expected_data : STD_LOGIC_VECTOR;
    check_name    : STRING := ""
  ) IS
  BEGIN
    equal_if : IF tested_data = expected_data THEN
      REPORT "------- Passed -------" SEVERITY NOTE;
      REPORT "Expected data: " & vec2string(expected_data) & " Real data: " & vec2string(tested_data) SEVERITY NOTE;
    ELSE
      REPORT "Expected data: " & vec2string(expected_data) & " Real data: " & vec2string(tested_data) SEVERITY ERROR;
      REPORT "------- Failed -------" SEVERITY ERROR;
    END IF equal_if;
  END PROCEDURE my_is_equal;

  ------------------------------------------------------------------------------
  -- Stimulus and bus-access helpers
  ------------------------------------------------------------------------------

  PROCEDURE strobe(
    SIGNAL   sig       : OUT STD_LOGIC;
    CONSTANT period_ns : TIME;
    CONSTANT active    : STD_LOGIC := '1'
  ) IS
  BEGIN
    sig <= active;
    WAIT FOR period_ns;
    sig <= NOT active;
    WAIT FOR period_ns;
  END PROCEDURE strobe;

  ------------------------------------------------------------------------------
  -- Random stimulus helpers (simulation-only, uses IEEE.MATH_REAL at runtime)
  ------------------------------------------------------------------------------

  IMPURE FUNCTION random_vector(
    len            : INTEGER;
    CONSTANT seed1 : IN INTEGER;
    CONSTANT seed2 : IN INTEGER
  ) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_r      : REAL;
    VARIABLE v_slv    : STD_LOGIC_VECTOR(len - 1 DOWNTO 0);
    VARIABLE v_seed1  : INTEGER;
    VARIABLE v_seed2  : INTEGER;
  BEGIN
    v_seed1 := seed1;
    v_seed2 := seed2;
    random_bits_loop : FOR i IN v_slv'RANGE LOOP
      UNIFORM(v_seed1, v_seed2, v_r);
      v_slv(i) := '1' WHEN v_r > 0.5 ELSE '0';
    END LOOP random_bits_loop;
    RETURN v_slv;
  END FUNCTION random_vector;

  IMPURE FUNCTION random_bit(CONSTANT seed1 : IN INTEGER; CONSTANT seed2 : IN INTEGER) RETURN STD_LOGIC IS
    VARIABLE v_r      : REAL;
    VARIABLE v_seed1  : INTEGER;
    VARIABLE v_seed2  : INTEGER;
    VARIABLE v_result : STD_LOGIC;
  BEGIN
    v_seed1 := seed1;
    v_seed2 := seed2;
    UNIFORM(v_seed1, v_seed2, v_r);

    v_result := '1' WHEN v_r > 0.5 ELSE '0';
    RETURN v_result;
  END FUNCTION random_bit;

  FUNCTION randnf(seed1 : POSITIVE := 13579) RETURN REAL IS
    VARIABLE v_u1, v_u2 : REAL;
    VARIABLE v_result    : REAL;
    VARIABLE v_seed2     : POSITIVE := 13579; -- seeds for uniform
    VARIABLE v_seed1     : POSITIVE := seed1;
  BEGIN
    -- Generate uniform random numbers in (0,1)
    UNIFORM(v_seed1, v_seed2, v_u1);
    UNIFORM(v_seed1, v_seed2, v_u2);

    -- Box-Muller transform
    v_result := SQRT(-2.0 * LOG(v_u1)) * COS(2.0 * MATH_PI * v_u2);

    RETURN v_result;
  END FUNCTION randnf;

  ------------------------------------------------------------------------------
  -- Fixed-point <-> real scaling helpers
  ------------------------------------------------------------------------------

  -- Scale signed STD_LOGIC_VECTOR to real [-1.0, 1.0]
  FUNCTION scale_slv_to_real(input : STD_LOGIC_VECTOR) RETURN REAL IS
    VARIABLE v_signed_input : SIGNED(input'LENGTH - 1 DOWNTO 0);
    VARIABLE v_int_value    : INTEGER;
    VARIABLE v_real_result  : REAL;
    CONSTANT c_divisor      : REAL := 2.0 ** (input'LENGTH - 1);
  BEGIN
    -- Convert to signed
    v_signed_input := SIGNED(input);

    -- Convert to integer
    v_int_value := TO_INTEGER(v_signed_input);

    -- Scale to [-1.0, 1.0]
    v_real_result := REAL(v_int_value) / c_divisor;

    -- Clamp result to [-1.0, 1.0]
    clamp_if : IF v_real_result > 1.0 THEN
      v_real_result := 1.0;
    ELSIF v_real_result < -1.0 THEN
      v_real_result := -1.0;
    END IF clamp_if;

    RETURN v_real_result;
  END FUNCTION scale_slv_to_real;

  -- Scale real [-1.0, 1.0] to signed STD_LOGIC_VECTOR
  FUNCTION scale_real_to_slv(input : REAL; width : INTEGER) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_clamped_input : REAL;
    VARIABLE v_int_value     : INTEGER;
    CONSTANT c_max_val       : REAL := 2.0 ** (width - 1) - 1.0;
    CONSTANT c_min_val       : REAL := 2.0 ** (width - 1);
  BEGIN
    -- Clamp input to [-1.0, 1.0]
    clamp_input_if : IF input > 1.0 THEN
      v_clamped_input := 1.0;
    ELSIF input < -1.0 THEN
      v_clamped_input := -1.0;
    ELSE
      v_clamped_input := input;
    END IF clamp_input_if;

    -- Scale to integer range
    sign_if : IF v_clamped_input >= 0.0 THEN
      v_int_value := INTEGER(v_clamped_input * c_max_val);
    ELSE
      v_int_value := INTEGER(v_clamped_input * c_min_val);
    END IF sign_if;

    -- Convert to STD_LOGIC_VECTOR
    RETURN STD_LOGIC_VECTOR(TO_SIGNED(v_int_value, width));
  END FUNCTION scale_real_to_slv;

  -- Calculates the number of clock cycles to wait for a given amount of time and clock period.
  FUNCTION get_wait_cycles(CONSTANT clk_period : TIME; CONSTANT wait_time : TIME) RETURN NATURAL IS
  BEGIN
    invalid_period_if : IF clk_period <= 0 ns THEN
      REPORT "ERROR: clk_period must be positive." SEVERITY FAILURE;
      RETURN 0;
    END IF invalid_period_if;
    RETURN INTEGER(wait_time / clk_period); -- e.g. 50 us wait / 10 ns period (100MHz) = 5000 cycles
  END FUNCTION get_wait_cycles;

  -- Setter implementation
  PROCEDURE set_debug_mode(enable : BOOLEAN) IS
  BEGIN
    v_debug_cfg.set(enable);
  END PROCEDURE set_debug_mode;

  -- Getter implementation
  IMPURE FUNCTION is_debug_mode RETURN BOOLEAN IS
  BEGIN
    RETURN v_debug_cfg.is_enabled;
  END FUNCTION is_debug_mode;

  -- Converts rssi half db to dbm
  FUNCTION rssi_half_db_to_dbm(rssi_half_db : STD_LOGIC_VECTOR(15 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_shifted : INTEGER;
    VARIABLE v_calc     : INTEGER;
    VARIABLE v_rssi_dbm : SIGNED(15 DOWNTO 0);
  BEGIN
    v_shifted := TO_INTEGER(UNSIGNED(rssi_half_db)) / 2; -- dividing by 2 is same as logical shift right
    v_calc    := v_shifted - c_rssi_correction;

    clamp_if : IF v_calc < -128 THEN
      v_calc := -128;
    END IF clamp_if;

    v_rssi_dbm := TO_SIGNED(v_calc, 16);
    RETURN STD_LOGIC_VECTOR(v_rssi_dbm);
  END FUNCTION rssi_half_db_to_dbm;

  ------------------------------------------------------------------------------
  -- File I/O helpers
  ------------------------------------------------------------------------------

  IMPURE FUNCTION read_from_file(
    file_name : STRING;
    depth     : POSITIVE;
    width     : POSITIVE
  ) RETURN t_slv_array IS
    FILE input_file        : TEXT;
    VARIABLE v_input_line   : LINE;
    -- Temporary variable with the exact width required
    VARIABLE v_temp_vector  : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    -- Result array sized to the requested depth
    VARIABLE v_result_mem   : t_slv_array(0 TO depth - 1)(width - 1 DOWNTO 0) := (OTHERS => (OTHERS => '0'));
    VARIABLE v_addr         : INTEGER := 0;
    VARIABLE v_status       : FILE_OPEN_STATUS;
  BEGIN
    FILE_OPEN(v_status, input_file, file_name, READ_MODE);

    open_error_if : IF v_status /= OPEN_OK THEN
      REPORT "FILE ERROR: Could not open " & file_name SEVERITY FAILURE;
    END IF open_error_if;

    read_lines_loop : WHILE NOT ENDFILE(input_file) AND v_addr < depth LOOP
      READLINE(input_file, v_input_line);

      skip_empty_line_if : IF v_input_line'LENGTH > 0 THEN
        HREAD(v_input_line, v_temp_vector);
        v_result_mem(v_addr) := v_temp_vector;
        v_addr := v_addr + 1;
      END IF skip_empty_line_if;
    END LOOP read_lines_loop;

    FILE_CLOSE(input_file);
    REPORT "SUCCESS: Loaded " & INTEGER'IMAGE(v_addr) & " entries from " & file_name;

    RETURN v_result_mem;
  END FUNCTION read_from_file;

  PROCEDURE save_to_file(
    file_name : STRING;
    data      : t_slv_array
  ) IS
    FILE output_file       : TEXT;
    VARIABLE v_output_line : LINE;
    VARIABLE v_status      : FILE_OPEN_STATUS;
  BEGIN
    FILE_OPEN(v_status, output_file, file_name, WRITE_MODE);

    open_error_if : IF v_status /= OPEN_OK THEN
      REPORT "FILE ERROR: Could not open " & file_name & " for writing" SEVERITY FAILURE;
    END IF open_error_if;

    write_lines_loop : FOR i IN data'RANGE LOOP
      HWRITE(v_output_line, data(i));
      WRITELINE(output_file, v_output_line);
    END LOOP write_lines_loop;

    FILE_CLOSE(output_file);
    REPORT "SUCCESS: Saved " & INTEGER'IMAGE(data'LENGTH) & " entries to " & file_name;
  END PROCEDURE save_to_file;

  IMPURE FUNCTION read_real_from_file(
    file_name : STRING;
    depth     : POSITIVE
  ) RETURN t_real_array IS
    FILE input_file       : TEXT;
    VARIABLE v_input_line : LINE;
    VARIABLE v_temp_real  : REAL;
    VARIABLE v_result_mem : t_real_array(0 TO depth - 1) := (OTHERS => 0.0);
    VARIABLE v_addr       : INTEGER := 0;
    VARIABLE v_status     : FILE_OPEN_STATUS;
  BEGIN
    FILE_OPEN(v_status, input_file, file_name, READ_MODE);

    open_error_if : IF v_status /= OPEN_OK THEN
      REPORT "FILE ERROR: Could not open " & file_name SEVERITY FAILURE;
    END IF open_error_if;

    read_lines_loop : WHILE NOT ENDFILE(input_file) AND v_addr < depth LOOP
      READLINE(input_file, v_input_line);

      skip_empty_line_if : IF v_input_line'LENGTH > 0 THEN
        READ(v_input_line, v_temp_real);
        v_result_mem(v_addr) := v_temp_real;
        v_addr := v_addr + 1;
      END IF skip_empty_line_if;
    END LOOP read_lines_loop;

    FILE_CLOSE(input_file);
    REPORT "SUCCESS: Loaded " & INTEGER'IMAGE(v_addr) & " real entries from " & file_name;

    RETURN v_result_mem;
  END FUNCTION read_real_from_file;

  PROCEDURE save_real_to_file(
    file_name : STRING;
    data      : t_real_array
  ) IS
    FILE output_file       : TEXT;
    VARIABLE v_output_line : LINE;
    VARIABLE v_status      : FILE_OPEN_STATUS;
  BEGIN
    FILE_OPEN(v_status, output_file, file_name, WRITE_MODE);

    open_error_if : IF v_status /= OPEN_OK THEN
      REPORT "FILE ERROR: Could not open " & file_name & " for writing" SEVERITY FAILURE;
    END IF open_error_if;

    write_lines_loop : FOR i IN data'RANGE LOOP
      WRITE(v_output_line, data(i));
      WRITELINE(output_file, v_output_line);
    END LOOP write_lines_loop;

    FILE_CLOSE(output_file);
    REPORT "SUCCESS: Saved " & INTEGER'IMAGE(data'LENGTH) & " real entries to " & file_name;
  END PROCEDURE save_real_to_file;

END PACKAGE BODY tb_pkg;
