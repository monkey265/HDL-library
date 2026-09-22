-- -------------------------------------------------------------------------------------------------
-- Copyright (c) Lukas Vik. All rights reserved.
--
-- This file is part of the hdl-modules project, a collection of reusable, high-quality,
-- peer-reviewed VHDL building blocks.
-- https://hdl-modules.com
-- https://github.com/hdl-modules/hdl-modules
-- -------------------------------------------------------------------------------------------------
-- Package with constants/types/functions for generic register file ecosystem.
-- -------------------------------------------------------------------------------------------------

-- vsg_off
-- Vendored verbatim from hdl-modules (see header above); identifiers keep upstream naming
-- instead of this repo's s_/t_/c_ prefix convention, to stay diffable against upstream.

LIBRARY IEEE;
  USE ieee.math_real.ALL;
  USE ieee.numeric_std.ALL;
  USE ieee.std_logic_1164.ALL;


PACKAGE register_file_pkg IS

  CONSTANT register_width : positive := 32;
  SUBTYPE register_t IS std_ulogic_vector(register_width - 1 DOWNTO 0);
  CONSTANT register_init : register_t := (OTHERS => '0');
  TYPE register_vec_t IS ARRAY (integer RANGE <>) OF register_t;

  TYPE register_mode_t IS (
    -- Software can read a value that hardware provides.
    R,
    -- Software can write a value that is available for usage in hardware.
    W,
    -- Software can write a value and read it back. The written value is available for usage
    -- in hardware.
    R_W,
    -- Software can write a value that is asserted for one cycle in hardware.
    WPULSE,
    -- Software can read a value that hardware provides.
    -- Software can write a value that is asserted for one cycle in hardware.
    R_WPULSE
  );

  -- If it is a mode where software can read the register.
  FUNCTION is_read_mode(mode : register_mode_t) RETURN boolean;
  -- If it is a mode where software can write the register.
  FUNCTION is_write_mode(mode : register_mode_t) RETURN boolean;
  -- If it is a mode where software can write the register and the value shall be asserted for
  -- one clock cycle in hardware.
  FUNCTION is_write_pulse_mode(mode : register_mode_t) RETURN boolean;
  -- If it is a mode where the value that software can read is provided by the 'regs_up' port
  -- from the users' application.
  -- As opposed to for example Read-Write, where the read value is a loopback of the written value.
  FUNCTION is_application_gives_value_mode(mode : register_mode_t) RETURN boolean;

  TYPE register_definition_t IS RECORD
    -- The index of this register, within the list of registers.
    index : natural;
    -- The mode of this register.
    mode : register_mode_t;
    -- The number of data bits that are utilized in this register.
    -- Implementations can ignore other bits.
    utilized_width : natural RANGE 0 TO register_width;
  END RECORD;
  TYPE register_definition_vec_t IS ARRAY (natural RANGE <>) OF register_definition_t;

  -- Get the highest register index that is used in the list of registers.
  FUNCTION get_highest_index(registers : register_definition_vec_t) RETURN natural;

  -- Get the number of bits needed to represent the register indices.
  -- Note that this does not include the lowest two aligned bits.
  FUNCTION num_address_bits_needed(registers : register_definition_vec_t) RETURN positive;

END;

PACKAGE BODY register_file_pkg IS

  FUNCTION is_read_mode(mode : register_mode_t) RETURN boolean IS
  BEGIN
    RETURN mode = r OR mode = r_w OR mode = r_wpulse;
  END FUNCTION;

  FUNCTION is_write_mode(mode : register_mode_t) RETURN boolean IS
  BEGIN
    RETURN mode = w OR mode = r_w OR mode = wpulse OR mode = r_wpulse;
  END FUNCTION;

  FUNCTION is_write_pulse_mode(mode : register_mode_t) RETURN boolean IS
  BEGIN
    RETURN mode = wpulse OR mode = r_wpulse;
  END FUNCTION;

  FUNCTION is_application_gives_value_mode(mode : register_mode_t) RETURN boolean IS
  BEGIN
    RETURN mode = r OR mode = r_wpulse;
  END FUNCTION;

  FUNCTION get_highest_index(registers : register_definition_vec_t) RETURN natural IS
  BEGIN
    ASSERT registers(0).index = 0 SEVERITY failure;
    ASSERT registers(registers'HIGH).index = registers'LENGTH - 1 SEVERITY failure;
    RETURN registers(registers'HIGH).index;
  END FUNCTION;

  FUNCTION num_address_bits_needed(registers : register_definition_vec_t) RETURN positive IS
    CONSTANT max_index : natural := get_highest_index(registers);
  BEGIN
    IF max_index = 0 THEN
      RETURN 1;
    END IF;

    RETURN integer(ceil(log2(real(max_index + 1))));
  END FUNCTION;

END;
-- vsg_on
