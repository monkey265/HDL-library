-- ==============================================================================
-- AXI-Lite Fixed-Priority Master Arbiter
-- ==============================================================================
-- Author:  Josef Cada
-- Date:    03-09-2026
-- Revision: 1.0
-- Description:
-- Grants a single AXI-Lite slave port to one of two masters. Master A always
-- wins when both have a pending transaction; master B is held off (its valid
-- signals are not forwarded to the slave) until master A is idle. Read and
-- write channels are arbitrated independently, so a master's read can be in
-- flight at the same time as the other master's write.
--
-- Ownership of a channel is latched for the whole transaction (grant until the
-- response is accepted), so two masters' requests are never interleaved on the
-- same channel. Assumes a registered slave (no same-cycle valid->ready).
-- ==============================================================================

LIBRARY IEEE;
  USE IEEE.STD_LOGIC_1164.ALL;

-- axi_lite_pkg lives in this repo's single flat "lib" library, not a separate "axi_lite" one
  USE work.axi_lite_pkg.ALL;

ENTITY axi_lite_pri_arbiter IS
  PORT (
    clk_in    : IN STD_LOGIC;
    arst_n_in : IN STD_LOGIC;

    -- Master A (higher priority)
    a_m2s_in  : IN  axi_lite_m2s_t := axi_lite_m2s_init;
    a_s2m_out : OUT axi_lite_s2m_t := axi_lite_s2m_init;

    -- Master B (lower priority)
    b_m2s_in  : IN  axi_lite_m2s_t := axi_lite_m2s_init;
    b_s2m_out : OUT axi_lite_s2m_t := axi_lite_s2m_init;

    -- Single downstream slave
    slave_m2s_out : OUT axi_lite_m2s_t := axi_lite_m2s_init;
    slave_s2m_in  : IN  axi_lite_s2m_t := axi_lite_s2m_init
  );
END ENTITY axi_lite_pri_arbiter;

ARCHITECTURE rtl OF axi_lite_pri_arbiter IS

  TYPE t_owner IS (OWNER_NONE, OWNER_A, OWNER_B);
  SIGNAL s_wr_owner : t_owner := OWNER_NONE;
  SIGNAL s_rd_owner : t_owner := OWNER_NONE;

BEGIN

  -- ===========================================================================
  -- Write channel ownership (aw/w granted together, held until b is accepted)
  -- ===========================================================================
  wr_arb_proc : PROCESS (clk_in, arst_n_in)
  BEGIN
    IF arst_n_in = '0' THEN
      s_wr_owner <= OWNER_NONE;
    ELSIF RISING_EDGE(clk_in) THEN
      CASE s_wr_owner IS
        WHEN OWNER_NONE =>
          IF a_m2s_in.write.aw.valid = '1' OR a_m2s_in.write.w.valid = '1' THEN
            s_wr_owner <= OWNER_A;
          ELSIF b_m2s_in.write.aw.valid = '1' OR b_m2s_in.write.w.valid = '1' THEN
            s_wr_owner <= OWNER_B;
          END IF;

        WHEN OWNER_A =>
          IF slave_s2m_in.write.b.valid = '1' AND a_m2s_in.write.b.ready = '1' THEN
            s_wr_owner <= OWNER_NONE;
          END IF;

        WHEN OWNER_B =>
          IF slave_s2m_in.write.b.valid = '1' AND b_m2s_in.write.b.ready = '1' THEN
            s_wr_owner <= OWNER_NONE;
          END IF;
      END CASE;
    END IF;
  END PROCESS wr_arb_proc;

  -- ===========================================================================
  -- Read channel ownership (ar granted, held until r is accepted)
  -- ===========================================================================
  rd_arb_proc : PROCESS (clk_in, arst_n_in)
  BEGIN
    IF arst_n_in = '0' THEN
      s_rd_owner <= OWNER_NONE;
    ELSIF RISING_EDGE(clk_in) THEN
      CASE s_rd_owner IS
        WHEN OWNER_NONE =>
          IF a_m2s_in.read.ar.valid = '1' THEN
            s_rd_owner <= OWNER_A;
          ELSIF b_m2s_in.read.ar.valid = '1' THEN
            s_rd_owner <= OWNER_B;
          END IF;

        WHEN OWNER_A =>
          IF slave_s2m_in.read.r.valid = '1' AND a_m2s_in.read.r.ready = '1' THEN
            s_rd_owner <= OWNER_NONE;
          END IF;

        WHEN OWNER_B =>
          IF slave_s2m_in.read.r.valid = '1' AND b_m2s_in.read.r.ready = '1' THEN
            s_rd_owner <= OWNER_NONE;
          END IF;
      END CASE;
    END IF;
  END PROCESS rd_arb_proc;

  -- ===========================================================================
  -- Combinational routing
  -- ===========================================================================
  slave_m2s_out.write <= a_m2s_in.write WHEN s_wr_owner = OWNER_A ELSE
                          b_m2s_in.write WHEN s_wr_owner = OWNER_B ELSE
                          axi_lite_write_m2s_init;

  slave_m2s_out.read <= a_m2s_in.read WHEN s_rd_owner = OWNER_A ELSE
                         b_m2s_in.read WHEN s_rd_owner = OWNER_B ELSE
                         axi_lite_read_m2s_init;

  a_s2m_out.write <= slave_s2m_in.write WHEN s_wr_owner = OWNER_A ELSE axi_lite_write_s2m_init;
  b_s2m_out.write <= slave_s2m_in.write WHEN s_wr_owner = OWNER_B ELSE axi_lite_write_s2m_init;

  a_s2m_out.read <= slave_s2m_in.read WHEN s_rd_owner = OWNER_A ELSE axi_lite_read_s2m_init;
  b_s2m_out.read <= slave_s2m_in.read WHEN s_rd_owner = OWNER_B ELSE axi_lite_read_s2m_init;

END ARCHITECTURE rtl;
