-- ==============================================================================
-- UART TX
-- ==============================================================================
-- Author:  Josef Cada
-- Date:    03-09-2026
-- Revision: 1.0
-- Description:
-- UART transmitter implementation
-- ==============================================================================

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;
  USE IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------------
--#ANCHOR - ENTITY
----------------------------------------------------------------------------------------
ENTITY uart_tx IS
  GENERIC (
    g_msg_width  : POSITIVE := 8; -- Message width in bits
    g_smpl_width : POSITIVE := 8  -- RX line sample width (reserved for compatibility)
  );
  PORT (
    -- Inputs
    clk_in       : IN  STD_LOGIC;                                  -- Clock signal (e.g. 100MHz)
    rst_n_in     : IN  STD_LOGIC;                                  -- Synchronous reset, active low
    msg_in       : IN  STD_LOGIC_VECTOR(g_msg_width - 1 DOWNTO 0); -- Data input message
    msg_vld_in   : IN  STD_LOGIC;                                  -- Message valid strobe signal
    start_pol_in : IN  STD_LOGIC := '0';                           -- Polarity of start bit (negation of stop bit)
    par_en_in    : IN  STD_LOGIC := '0';                           -- Parity bit enable
    par_type_in  : IN  STD_LOGIC := '0';                           -- Parity type (0: ODD, 1: EVEN)
    char_len_in  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";       -- Character length (5 + x bits)
    clk_div_in   : IN  UNSIGNED(15 DOWNTO 0) := x"0300";           -- Clock divisor for baud rate (def = 7.3728 MHz => ~9600)

    -- Outputs
    tx_out       : OUT STD_LOGIC;                                  -- Serial TX output pin
    busy_out     : OUT STD_LOGIC;                                  -- Transmitter busy flag
    tx_done_out  : OUT STD_LOGIC                                   -- Transmission complete strobe
  );
END ENTITY uart_tx;

----------------------------------------------------------------------------------------
--#SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
ARCHITECTURE rtl OF uart_tx IS

  --------------------------------------------------------------------------------------
  --#ANCHOR - TYPES & ENUMS
  --------------------------------------------------------------------------------------
  TYPE t_state IS (
    ST_IDLE,
    ST_START,
    ST_DATA,
    ST_PARITY,
    ST_TERMINATE,
    ST_TAIL
  );

  --------------------------------------------------------------------------------------
  --#ANCHOR - SIGNALS
  --------------------------------------------------------------------------------------
  SIGNAL s_state         : t_state := ST_IDLE; -- State of transmitter
  SIGNAL s_counter_start : STD_LOGIC;          -- Start signal for baud rate division counter
  SIGNAL s_counter_done  : STD_LOGIC;          -- Division counter finish strobe
  SIGNAL s_msg_valid_int : STD_LOGIC;          -- Internal message valid net for debug
  SIGNAL s_bit_cnt       : NATURAL RANGE 0 TO g_msg_width; -- Transmitted bit counter

  --------------------------------------------------------------------------------------
  --#ANCHOR - ATTRIBUTES
  --------------------------------------------------------------------------------------
  ATTRIBUTE fsm_safe_state : STRING;
  ATTRIBUTE fsm_safe_state OF s_state : SIGNAL IS "default_state";

  ATTRIBUTE mark_debug : STRING;
  ATTRIBUTE mark_debug OF s_msg_valid_int : SIGNAL IS "TRUE";

BEGIN

  --------------------------------------------------------------------------------------
  -- Concurrent assignments
  --------------------------------------------------------------------------------------
  busy_out        <= '0' WHEN s_state = ST_IDLE ELSE '1';
  s_msg_valid_int <= msg_vld_in;

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
  --#SECTION - MAIN TX FSM PROCESS
  --------------------------------------------------------------------------------------
  tx_main_proc : PROCESS (clk_in) IS
    VARIABLE v_parity_chck : STD_LOGIC;
    VARIABLE v_msg_buff    : STD_LOGIC_VECTOR(g_msg_width - 1 DOWNTO 0);
  BEGIN
    clk_edge_if : IF RISING_EDGE(clk_in) THEN
      reset_if : IF rst_n_in = '0' THEN
        tx_out          <= NOT start_pol_in;
        s_counter_start <= '0';
        s_bit_cnt       <= 0;
        tx_done_out     <= '0';
        s_state         <= ST_IDLE;
      ELSE
        fsm_case : CASE s_state IS
          WHEN ST_IDLE =>
            tx_out          <= NOT start_pol_in;
            s_counter_start <= '0';
            v_parity_chck   := par_type_in;
            tx_done_out     <= '0';
            msg_valid_if : IF s_msg_valid_int = '1' THEN
              v_msg_buff := msg_in;
              s_state    <= ST_START;
            END IF msg_valid_if;

          WHEN ST_START =>
            tx_out          <= start_pol_in;
            s_counter_start <= '1';
            s_bit_cnt       <= 0;
            s_state         <= ST_DATA;

          WHEN ST_DATA =>
            cnt_done_if : IF s_counter_done = '1' THEN
              bit_len_if : IF s_bit_cnt < (TO_INTEGER(UNSIGNED(char_len_in)) + 5) THEN
                tx_out        <= v_msg_buff(s_bit_cnt);
                v_parity_chck := (v_parity_chck XOR v_msg_buff(s_bit_cnt));
                s_bit_cnt     <= s_bit_cnt + 1;
              ELSE
                par_enable_if : IF par_en_in = '1' THEN
                  s_state <= ST_PARITY;
                ELSE
                  s_state <= ST_TERMINATE;
                END IF par_enable_if;
              END IF bit_len_if;
            END IF cnt_done_if;

          WHEN ST_PARITY =>
            tx_out <= v_parity_chck;
            parity_done_if : IF s_counter_done = '1' THEN
              s_state <= ST_TERMINATE;
            END IF parity_done_if;

          WHEN ST_TERMINATE =>
            tx_done_out <= '1';
            tx_out      <= NOT start_pol_in;
            term_done_if : IF s_counter_done = '1' THEN
              s_state <= ST_TAIL;
            END IF term_done_if;

          WHEN ST_TAIL =>
            s_counter_start <= '0';
            tail_done_if : IF s_counter_done = '1' THEN
              s_state <= ST_IDLE;
            END IF tail_done_if;

          WHEN OTHERS =>
            s_state <= ST_IDLE;
        END CASE fsm_case;
      END IF reset_if;
    END IF clk_edge_if;
  END PROCESS tx_main_proc;
  --#!SECTION

END ARCHITECTURE rtl;
--#!SECTION