-- -------------------------------------------------------------------------------------------------
-- Copyright (c) Lukas Vik. All rights reserved.
--
-- This file is part of the hdl-modules project, a collection of reusable, high-quality,
-- peer-reviewed VHDL building blocks.
-- https://hdl-modules.com
-- https://github.com/hdl-modules/hdl-modules
-- -------------------------------------------------------------------------------------------------
-- Data types for working with AXI4-Lite interfaces.
-- Based on the document "ARM IHI 0022E (ID022613): AMBA AXI and ACE Protocol Specification"
-- Available here: http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ihi0022e/
-- -------------------------------------------------------------------------------------------------

-- vsg_off
-- Vendored verbatim from hdl-modules (see header above); identifiers keep upstream naming
-- instead of this repo's s_/t_/c_ prefix convention, to stay diffable against upstream.

LIBRARY IEEE;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;


PACKAGE axi_lite_pkg IS

  ------------------------------------------------------------------------------
  -- A (Address Read and Address Write) channels
  ------------------------------------------------------------------------------

  -- Address field (ARADDR or AWADDR).
  -- The width value below is a max value, implementation should only take into regard the bits
  -- that are actually used.
  SUBTYPE axi_lite_address_width_t IS positive RANGE 1 TO 64;

  -- Record for the AR/AW signals in the master-to-slave direction.
  TYPE axi_lite_m2s_a_t IS RECORD
    valid : std_ulogic;
    addr : u_unsigned(axi_lite_address_width_t'HIGH - 1 DOWNTO 0);
    -- Excluded members: prot
    -- These are typically not changed on a transfer-to-transfer basis.
  END RECORD;

  CONSTANT axi_lite_m2s_a_init : axi_lite_m2s_a_t := (valid => '0', addr => (OTHERS => '0'));
  FUNCTION axi_lite_m2s_a_sz(addr_width : axi_lite_address_width_t) RETURN positive;

  -- Record for the AR/AW signals in the slave-to-master direction.
  TYPE axi_lite_s2m_a_t IS RECORD
    ready : std_ulogic;
  END RECORD;

  CONSTANT axi_lite_s2m_a_init : axi_lite_s2m_a_t := (ready => '0');


  ------------------------------------------------------------------------------
  -- W (Write Data) channels
  ------------------------------------------------------------------------------

  -- Data field (RDATA or WDATA).
  -- The width value below is a max value, implementation should only take into regard the bits
  -- that are actually used.
  CONSTANT axi_lite_data_sz : positive := 64;
  SUBTYPE axi_lite_data_width_t IS positive RANGE 8 TO axi_lite_data_sz;

  -- Check that a provided data width is valid to be used with AXI-Lite.
  -- Return 'true' if everything is okay, otherwise 'false'.
  FUNCTION sanity_check_axi_lite_data_width(data_width : integer) RETURN boolean;

  -- Write data strobe field (WSTRB).
  -- The width value below is a max value, implementation should only take into regard the bits
  -- that are actually used.
  CONSTANT axi_lite_w_strb_sz : positive := axi_lite_data_sz / 8;

  FUNCTION to_axi_lite_strb(
    data_width : axi_lite_data_width_t
  ) RETURN std_ulogic_vector;

  -- Record for the W signals in the master-to-slave direction.
  TYPE axi_lite_m2s_w_t IS RECORD
    valid : std_ulogic;
    data : std_ulogic_vector(axi_lite_data_sz - 1 DOWNTO 0);
    strb : std_ulogic_vector(axi_lite_w_strb_sz - 1 DOWNTO 0);
  END RECORD;

  CONSTANT axi_lite_m2s_w_init : axi_lite_m2s_w_t :=
 (
    valid => '0',
 data => (OTHERS => '-'),
 strb => (OTHERS => '0')
  );
  FUNCTION axi_lite_m2s_w_sz(data_width : axi_lite_data_width_t) RETURN positive;

  FUNCTION to_slv(
    data : axi_lite_m2s_w_t; data_width : axi_lite_data_width_t
  ) RETURN std_ulogic_vector;
  FUNCTION to_axi_lite_m2s_w(
    data : std_ulogic_vector; data_width : axi_lite_data_width_t
  ) RETURN axi_lite_m2s_w_t;

  -- Record for the W signals in the slave-to-master direction.
  TYPE axi_lite_s2m_w_t IS RECORD
    ready : std_ulogic;
  END RECORD;

  CONSTANT axi_lite_s2m_w_init : axi_lite_s2m_w_t := (ready => '0');


  ------------------------------------------------------------------------------
  -- B (Write Response) channels
  ------------------------------------------------------------------------------

  -- Record for the B signals in the master-to-slave direction.
  TYPE axi_lite_m2s_b_t IS RECORD
    ready : std_ulogic;
  END RECORD;

  CONSTANT axi_lite_m2s_b_init : axi_lite_m2s_b_t := (ready => '0');

  -- Response field (RRESP or BRESP).
  CONSTANT axi_resp_sz : positive := 2;
  SUBTYPE axi_lite_resp_t IS std_ulogic_vector(axi_resp_sz - 1 DOWNTO 0);

  CONSTANT axi_lite_resp_okay : axi_lite_resp_t := "00";
  CONSTANT axi_lite_resp_exokay : axi_lite_resp_t := "01";
  CONSTANT axi_lite_resp_slverr : axi_lite_resp_t := "10";
  CONSTANT axi_lite_resp_decerr : axi_lite_resp_t := "11";

  -- Record for the B signals in the slave-to-master direction.
  TYPE axi_lite_s2m_b_t IS RECORD
    valid : std_ulogic;
    resp : axi_lite_resp_t;
  END RECORD;

  CONSTANT axi_lite_s2m_b_init : axi_lite_s2m_b_t := (valid => '0', resp => (OTHERS => '-'));
  -- Excluded member: valid
  CONSTANT axi_lite_s2m_b_sz : positive := axi_resp_sz;


  ------------------------------------------------------------------------------
  -- R (Read Data) channels
  ------------------------------------------------------------------------------

  -- Record for the R signals in the master-to-slave direction.
  TYPE axi_lite_m2s_r_t IS RECORD
    ready : std_ulogic;
  END RECORD;

  CONSTANT axi_lite_m2s_r_init : axi_lite_m2s_r_t := (ready => '0');

  -- Record for the R signals in the slave-to-master direction.
  TYPE axi_lite_s2m_r_t IS RECORD
    valid : std_ulogic;
    data : std_ulogic_vector(axi_lite_data_sz - 1 DOWNTO 0);
    resp : axi_lite_resp_t;
  END RECORD;

  CONSTANT axi_lite_s2m_r_init : axi_lite_s2m_r_t :=
 (
    valid => '0',
 data => (OTHERS => '-'),
 resp => (OTHERS => '-')
  );
  FUNCTION axi_lite_s2m_r_sz(data_width : axi_lite_data_width_t) RETURN positive;

  FUNCTION to_slv(
    data : axi_lite_s2m_r_t; data_width : axi_lite_data_width_t
  ) RETURN std_ulogic_vector;
  FUNCTION to_axi_lite_s2m_r(
    data : std_ulogic_vector; data_width : axi_lite_data_width_t
  ) RETURN axi_lite_s2m_r_t;


  ------------------------------------------------------------------------------
  -- The complete buses
  ------------------------------------------------------------------------------

  TYPE axi_lite_read_m2s_t IS RECORD
    ar : axi_lite_m2s_a_t;
    r : axi_lite_m2s_r_t;
  END RECORD;
  TYPE axi_lite_read_m2s_vec_t IS ARRAY (integer RANGE <>) OF axi_lite_read_m2s_t;

  CONSTANT axi_lite_read_m2s_init : axi_lite_read_m2s_t :=
 (
    ar => axi_lite_m2s_a_init,
    r => axi_lite_m2s_r_init
  );

  TYPE axi_lite_read_s2m_t IS RECORD
    ar : axi_lite_s2m_a_t;
    r : axi_lite_s2m_r_t;
  END RECORD;
  TYPE axi_lite_read_s2m_vec_t IS ARRAY (integer RANGE <>) OF axi_lite_read_s2m_t;

  CONSTANT axi_lite_read_s2m_init : axi_lite_read_s2m_t :=
 (
    ar => axi_lite_s2m_a_init,
    r => axi_lite_s2m_r_init
  );

  TYPE axi_lite_write_m2s_t IS RECORD
    aw : axi_lite_m2s_a_t;
    w : axi_lite_m2s_w_t;
    b : axi_lite_m2s_b_t;
  END RECORD;
  TYPE axi_lite_write_m2s_vec_t IS ARRAY (integer RANGE <>) OF axi_lite_write_m2s_t;

  CONSTANT axi_lite_write_m2s_init : axi_lite_write_m2s_t :=
 (
    aw => axi_lite_m2s_a_init,
    w => axi_lite_m2s_w_init,
    b => axi_lite_m2s_b_init
  );

  TYPE axi_lite_write_s2m_t IS RECORD
    aw : axi_lite_s2m_a_t;
    w : axi_lite_s2m_w_t;
    b : axi_lite_s2m_b_t;
  END RECORD;
  TYPE axi_lite_write_s2m_vec_t IS ARRAY (integer RANGE <>) OF axi_lite_write_s2m_t;

  CONSTANT axi_lite_write_s2m_init : axi_lite_write_s2m_t :=
 (
    aw => axi_lite_s2m_a_init,
    w => axi_lite_s2m_w_init,
    b => axi_lite_s2m_b_init
  );

  TYPE axi_lite_m2s_t IS RECORD
    read : axi_lite_read_m2s_t;
    write : axi_lite_write_m2s_t;
  END RECORD;
  TYPE axi_lite_m2s_vec_t IS ARRAY (integer RANGE <>) OF axi_lite_m2s_t;

  CONSTANT axi_lite_m2s_init : axi_lite_m2s_t :=
 (
    read => axi_lite_read_m2s_init,
    write => axi_lite_write_m2s_init
  );

  TYPE axi_lite_s2m_t IS RECORD
    read : axi_lite_read_s2m_t;
    write : axi_lite_write_s2m_t;
  END RECORD;
  TYPE axi_lite_s2m_vec_t IS ARRAY (integer RANGE <>) OF axi_lite_s2m_t;

  CONSTANT axi_lite_s2m_init : axi_lite_s2m_t :=
 (
    read => axi_lite_read_s2m_init,
    write => axi_lite_write_s2m_init
  );

END;

PACKAGE BODY axi_lite_pkg IS

  ------------------------------------------------------------------------------
  FUNCTION axi_lite_m2s_a_sz(addr_width : axi_lite_address_width_t) RETURN positive IS
  BEGIN
    -- Excluded member: valid.
    RETURN addr_width;
  END FUNCTION;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  FUNCTION sanity_check_axi_lite_data_width(data_width : integer) RETURN boolean IS
    CONSTANT message : string := ". Got data_width=" & integer'IMAGE(data_width) & ".";
  BEGIN
    IF data_width /= 32 AND data_width /= 64 THEN
      REPORT "AXI-Lite data width must be either 32 OR 64" & message;
      RETURN false;
    END IF;

    RETURN true;
  END FUNCTION;

  FUNCTION to_axi_lite_strb(
    data_width : axi_lite_data_width_t
  ) RETURN std_ulogic_vector IS
    VARIABLE result : std_ulogic_vector(axi_lite_w_strb_sz - 1 DOWNTO 0) := (OTHERS => '0');
  BEGIN
    ASSERT sanity_check_axi_lite_data_width(data_width)
      REPORT "Invalid data width, see printout above."
      SEVERITY failure;

    result(data_width / 8 - 1 DOWNTO 0) := (OTHERS => '1');

    RETURN result;
  END FUNCTION;

  FUNCTION axi_w_strb_width(data_width : axi_lite_data_width_t) RETURN positive IS
  BEGIN
    ASSERT sanity_check_axi_lite_data_width(data_width)
      REPORT "Invalid data width, see printout above."
      SEVERITY failure;

    RETURN data_width / 8;
  END FUNCTION;

  FUNCTION axi_lite_m2s_w_sz(data_width : axi_lite_data_width_t) RETURN positive IS
  BEGIN
    ASSERT sanity_check_axi_lite_data_width(data_width)
      REPORT "Invalid data width, see printout above."
      SEVERITY failure;

    -- Excluded member: valid
    RETURN data_width + axi_w_strb_width(data_width);
  END FUNCTION;

  FUNCTION to_slv(
    data : axi_lite_m2s_w_t; data_width : axi_lite_data_width_t
  ) RETURN std_ulogic_vector IS
    VARIABLE result : std_ulogic_vector(axi_lite_m2s_w_sz(data_width) - 1 DOWNTO 0);
    VARIABLE lo, hi : natural := 0;
  BEGIN
    lo := 0;
    hi := lo + data_width - 1;
    result(hi DOWNTO lo) := data.data(data_width - 1 DOWNTO 0);

    lo := hi + 1;
    hi := lo + axi_w_strb_width(data_width) - 1;
    result(hi DOWNTO lo) := data.strb(axi_w_strb_width(data_width) - 1 DOWNTO 0);

    ASSERT hi = result'HIGH;

    RETURN result;
  END FUNCTION;

  FUNCTION to_axi_lite_m2s_w(
    data : std_ulogic_vector; data_width : axi_lite_data_width_t
  ) RETURN axi_lite_m2s_w_t IS
    VARIABLE result : axi_lite_m2s_w_t := axi_lite_m2s_w_init;
    VARIABLE lo, hi : natural := 0;
  BEGIN
    lo := 0;
    hi := lo + data_width - 1;
    result.data(data_width - 1 DOWNTO 0) := data(hi DOWNTO lo);

    lo := hi + 1;
    hi := lo + axi_w_strb_width(data_width) - 1;
    result.strb(axi_w_strb_width(data_width) - 1 DOWNTO 0) := data(hi DOWNTO lo);

    ASSERT hi = data'HIGH;

    RETURN result;
  END FUNCTION;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  FUNCTION axi_lite_s2m_r_sz(data_width : axi_lite_data_width_t)  RETURN positive IS
  BEGIN
    ASSERT sanity_check_axi_lite_data_width(data_width)
      REPORT "Invalid data width, see printout above."
      SEVERITY failure;

    -- Excluded member: valid
    RETURN data_width + axi_resp_sz;
  END FUNCTION;

  FUNCTION to_slv(
    data : axi_lite_s2m_r_t; data_width : axi_lite_data_width_t
  ) RETURN std_ulogic_vector IS
    VARIABLE result : std_ulogic_vector(axi_lite_s2m_r_sz(data_width) - 1 DOWNTO 0);
    VARIABLE lo, hi : natural := 0;
  BEGIN
    lo := 0;
    hi := lo + data_width - 1;
    result(hi DOWNTO lo) := data.data(data_width - 1 DOWNTO 0);

    lo := hi + 1;
    hi := lo + axi_resp_sz - 1;
    result(hi DOWNTO lo) := data.resp;

    ASSERT hi = result'HIGH;

    RETURN result;
  END FUNCTION;

  FUNCTION to_axi_lite_s2m_r(
    data : std_ulogic_vector; data_width : axi_lite_data_width_t
  ) RETURN axi_lite_s2m_r_t IS
    VARIABLE result : axi_lite_s2m_r_t := axi_lite_s2m_r_init;
    VARIABLE lo, hi : natural := 0;
  BEGIN
    lo := 0;
    hi := lo + data_width - 1;
    result.data(data_width - 1 DOWNTO 0) := data(hi DOWNTO lo);

    lo := hi + 1;
    hi := lo + axi_resp_sz - 1;
    result.resp := data(hi DOWNTO lo);

    ASSERT hi = data'HIGH;

    RETURN result;
  END FUNCTION;
  ------------------------------------------------------------------------------

END;
-- vsg_on
