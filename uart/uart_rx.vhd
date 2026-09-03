-- ==============================================================================
-- UART RX
-- ==============================================================================
-- Author:  Josef Cada
-- Date:    03-09-2026
-- Revision: 1.0
-- Description:
-- UART receiver implementation
-- ==============================================================================

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------------
--#ANCHOR - ENTITY
----------------------------------------------------------------------------------------
ENTITY uart_rx IS
  GENERIC (
    g_msg_width  : POSITIVE := 8; -- Message width in bits
    g_smpl_width : POSITIVE := 8  -- RX line sample width
  );
  PORT (
    -- Inputs
    clk_in             : IN  STD_LOGIC;                                  -- Clock signal (e.g. 100MHz)
    rst_n_in           : IN  STD_LOGIC;                                  -- Synchronous reset, active low
    rx_in              : IN  STD_LOGIC;                                  -- Serial RX input pin
    start_pol_in       : IN  STD_LOGIC := '0';                          -- Polarity of start bit (negation of stop bit)
    par_en_in          : IN  STD_LOGIC := '0';                          -- Parity bit enable
    par_type_in        : IN  STD_LOGIC := '0';                          -- Parity type (0: ODD, 1: EVEN)
    char_len_in        : IN  STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";       -- Character length (5 + x bits)
    clk_div_in         : IN  UNSIGNED(15 DOWNTO 0) := x"0300";           -- Clock divisor for baud rate (def = 7.3728 MHz => ~9600)

    -- Outputs
    msg_out            : OUT STD_LOGIC_VECTOR(g_msg_width - 1 DOWNTO 0); -- Received data message
    msg_vld_strb_out   : OUT STD_LOGIC;                                  -- Message valid output strobe
    busy_out           : OUT STD_LOGIC;                                  -- Receiver busy flag
    err_noise_strb_out : OUT STD_LOGIC;                                  -- Noise error strobe
    err_frame_strb_out : OUT STD_LOGIC;                                  -- Framing error strobe
    err_par_strb_out   : OUT STD_LOGIC                                   -- Parity error strobe
  );
END ENTITY uart_rx;

----------------------------------------------------------------------------------------
--#SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
ARCHITECTURE rtl OF uart_rx IS

  --------------------------------------------------------------------------------------
  --#ANCHOR - TYPES & ENUMS
  --------------------------------------------------------------------------------------
  TYPE t_state IS (
    ST_IDLE,
    ST_DELAY,
    ST_RECEIVE,
    ST_PARITY,
    ST_TERMINATE
  );

  --------------------------------------------------------------------------------------
  --#ANCHOR - SIGNALS
  --------------------------------------------------------------------------------------
  SIGNAL s_state         : t_state := ST_IDLE; -- State of receiver
  SIGNAL s_counter_start : STD_LOGIC;          -- Start signal for baud rate division counter
  SIGNAL s_counter_done  : STD_LOGIC;          -- Division counter finish strobe
  SIGNAL s_bit_cnt       : NATURAL RANGE 0 TO g_msg_width; -- Received bit counter

  SIGNAL s_rx_sample     : STD_LOGIC_VECTOR(g_smpl_width - 1 DOWNTO 0); -- Sample shift buffer of RX line
  SIGNAL s_rx_sample_val : STD_LOGIC;                                   -- Majority-voted value of RX line
  SIGNAL s_rx_sample_stb : STD_LOGIC;                                   -- Stability indicator of RX line

  --------------------------------------------------------------------------------------
  --#ANCHOR - ATTRIBUTES
  --------------------------------------------------------------------------------------
  ATTRIBUTE fsm_safe_state : STRING;
  ATTRIBUTE fsm_safe_state OF s_state : SIGNAL IS "default_state";

  ATTRIBUTE mark_debug : STRING;
  ATTRIBUTE mark_debug OF s_counter_done  : SIGNAL IS "TRUE";
  ATTRIBUTE mark_debug OF s_rx_sample_val : SIGNAL IS "TRUE";
  ATTRIBUTE mark_debug OF s_rx_sample_stb : SIGNAL IS "TRUE";
  ATTRIBUTE mark_debug OF s_counter_start : SIGNAL IS "TRUE";
  ATTRIBUTE mark_debug OF s_state         : SIGNAL IS "TRUE";

BEGIN


  --------------------------------------------------------------------------------------
  -- Concurrent assignments
  --------------------------------------------------------------------------------------
  busy_out <= '0' WHEN s_state = ST_IDLE ELSE '1';

  --------------------------------------------------------------------------------------
  --#SECTION - SAMPLER
  --------------------------------------------------------------------------------------
  sampler_proc : PROCESS (clk_in) IS
    VARIABLE v_active : NATURAL RANGE 0 TO g_smpl_width;
  BEGIN
    clk_edge_if : IF RISING_EDGE(clk_in) THEN
      reset_if : IF rst_n_in = '0' THEN
        s_rx_sample     <= (OTHERS => '0');
        s_rx_sample_val <= '0';
        s_rx_sample_stb <= '1';
      ELSE
        s_rx_sample_val <= '0';
        s_rx_sample_stb <= '1';
        s_rx_sample     <= s_rx_sample(g_smpl_width - 2 DOWNTO 0) & rx_in;
        v_active        := 0;

        sample_cnt_for : FOR i IN s_rx_sample'RANGE LOOP
          bit_is_one_if : IF s_rx_sample(i) = '1' THEN
            v_active := v_active + 1;
          END IF bit_is_one_if;
        END LOOP sample_cnt_for;

        maj_check_if : IF v_active > (g_smpl_width / 2) THEN
          s_rx_sample_val <= '1';
        END IF maj_check_if;

        stab_check_if : IF 1 >= ABS(v_active - (g_smpl_width / 2)) THEN
          s_rx_sample_stb <= '0';
        END IF stab_check_if;
      END IF reset_if;
    END IF clk_edge_if;
  END PROCESS sampler_proc;
  --#!SECTION

  --------------------------------------------------------------------------------------
  --#SECTION - CLOCK DIVIDER (COUNTER)
  --------------------------------------------------------------------------------------
  clk_div_proc : PROCESS (clk_in) IS
    VARIABLE v_cnt   : UNSIGNED(15 DOWNTO 0);
    VARIABLE v_div10 : NATURAL RANGE 0 TO 10;
    VARIABLE v_run   : BOOLEAN;
  BEGIN
    clk_edge_if : IF RISING_EDGE(clk_in) THEN
      reset_if : IF rst_n_in = '0' THEN
        v_cnt          := (OTHERS => '0');
        s_counter_done <= '0';
        v_run          := FALSE;
        v_div10        := 0;
      ELSE
        run_check_if : IF v_run THEN
          cnt_check_if : IF v_cnt < clk_div_in THEN
            div10_tick_if : IF v_div10 = 10 THEN
              v_cnt := v_cnt + 1;
            END IF div10_tick_if;
          ELSE
            s_counter_done <= '1';
            v_run          := FALSE;
          END IF cnt_check_if;

          div10_inc_if : IF v_div10 < 10 THEN
            v_div10 := v_div10 + 1;
          ELSE
            v_div10 := 1;
          END IF div10_inc_if;
        ELSE
          s_counter_done <= '0';
          start_check_if : IF s_counter_start = '1' THEN
            v_run   := TRUE;
            v_cnt   := (OTHERS => '0');
            v_div10 := 0;
          END IF start_check_if;
        END IF run_check_if;
      END IF reset_if;
    END IF clk_edge_if;
  END PROCESS clk_div_proc;
  --#!SECTION

  --------------------------------------------------------------------------------------
  --#SECTION - MAIN RX FSM PROCESS
  --------------------------------------------------------------------------------------
  rx_main_proc : PROCESS (clk_in) IS
    VARIABLE v_msg_buffer  : STD_LOGIC_VECTOR(g_msg_width - 1 DOWNTO 0);
    VARIABLE v_delay_cnt   : NATURAL RANGE 0 TO 262143;
    VARIABLE v_stab_cnt    : NATURAL RANGE 0 TO g_msg_width;
    VARIABLE v_parity_chck : STD_LOGIC;
    VARIABLE v_parity_res  : BOOLEAN;
  BEGIN
    clk_edge_if : IF RISING_EDGE(clk_in) THEN
      -- Default strobe deassertions
      msg_vld_strb_out   <= '0';
      err_noise_strb_out <= '0';
      err_frame_strb_out <= '0';
      err_par_strb_out   <= '0';

      reset_if : IF rst_n_in = '0' THEN
        msg_out         <= (OTHERS => '0');
        s_state         <= ST_IDLE;
        v_msg_buffer    := (OTHERS => '0');
        s_counter_start <= '0';
        s_bit_cnt       <= 0;
        v_delay_cnt     := 1;
        v_stab_cnt      := 0;
        v_parity_chck   := '0';
        v_parity_res    := TRUE;
      ELSE
        fsm_case : CASE s_state IS
          WHEN ST_IDLE =>
            v_delay_cnt     := 1;
            v_stab_cnt      := 0;
            s_counter_start <= '0';
            s_bit_cnt       <= 0;
            v_parity_chck   := par_type_in;
            start_detect_if : IF rx_in = start_pol_in THEN
              s_state <= ST_DELAY;
            END IF start_detect_if;

          WHEN ST_DELAY =>
            delay_done_if : IF v_delay_cnt < TO_INTEGER(UNSIGNED(clk_div_in & "00")) THEN
              v_delay_cnt := v_delay_cnt + 1;
            ELSE
              s_bit_cnt       <= 0;
              s_counter_start <= '1';
              s_state         <= ST_RECEIVE;
            END IF delay_done_if;

          WHEN ST_RECEIVE =>
            v_parity_res    := TRUE;
            s_counter_start <= '1';
            bit_limit_if : IF s_bit_cnt < (5 + TO_INTEGER(UNSIGNED(char_len_in))) THEN
              tick_if : IF s_counter_done = '1' THEN
                v_msg_buffer    := s_rx_sample_val & v_msg_buffer(g_msg_width - 1 DOWNTO 1);
                v_parity_chck   := (s_rx_sample_val XOR v_parity_chck);
                s_bit_cnt       <= s_bit_cnt + 1;
                stab_tally_if : IF s_rx_sample_stb = '1' THEN
                  v_stab_cnt := v_stab_cnt + 1;
                END IF stab_tally_if;
              END IF tick_if;
            ELSIF s_bit_cnt < g_msg_width THEN
              v_msg_buffer := '0' & v_msg_buffer(g_msg_width - 1 DOWNTO 1);
              s_bit_cnt    <= s_bit_cnt + 1;
            ELSE
              msg_out <= v_msg_buffer;
              par_check_if : IF par_en_in = '1' THEN
                s_state <= ST_PARITY;
              ELSE
                s_state <= ST_TERMINATE;
              END IF par_check_if;
            END IF bit_limit_if;

          WHEN ST_PARITY =>
            parity_tick_if : IF s_counter_done = '1' THEN
              v_parity_res := (s_rx_sample_val = v_parity_chck);
              s_state      <= ST_TERMINATE;
            END IF parity_tick_if;

          WHEN ST_TERMINATE =>
            s_counter_start <= '0';
            term_tick_if : IF s_counter_done = '1' THEN
              frame_err_if : IF s_rx_sample_val = start_pol_in THEN
                err_frame_strb_out <= '1';
              END IF frame_err_if;

              noise_err_if : IF v_stab_cnt < (g_msg_width - 1) THEN
                err_noise_strb_out <= '1';
              END IF noise_err_if;

              par_err_if : IF NOT v_parity_res THEN
                err_par_strb_out <= '1';
              END IF par_err_if;

              msg_vld_strb_out <= '1';
              s_state          <= ST_IDLE;
            END IF term_tick_if;

          WHEN OTHERS =>
            s_state <= ST_IDLE;
        END CASE fsm_case;
      END IF reset_if;
    END IF clk_edge_if;
  END PROCESS rx_main_proc;
  --#!SECTION

END ARCHITECTURE rtl;
--#!SECTION