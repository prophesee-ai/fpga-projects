-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------
-- AXI4-Stream TKEEP Handler
-- Reorder incomplete data words.
-- Incomplete words can only half words (32-bits in case of a 64-bits data bus).
-- It is possible to change the order of the half words (first word can be the MSB
-- or the LSB) with the word_order bit in the config register.
-- The handler can be bypassed, in that case the input stream is directly connected
-- to the output stream (no buffering stage but word order can still be modified).
-- Buffers can be emptied with the clear bit in the control register.
entity axis_tkeep_handler_core is
  generic (
    AXIS_TDATA_WIDTH_G : positive := 64;
    AXIS_TUSER_WIDTH_G : positive := 1
  );
  port (
    clk               : in  std_logic;
    rstn              : in  std_logic;

    -- Control Signals
    enable_i          : in  std_logic;
    bypass_i          : in  std_logic;
    buffer_clear_i    : in  std_logic;
    word_order_i      : in  std_logic;

    -- Input Data Stream
    in_ready_o        : out std_logic;
    in_valid_i        : in  std_logic;
    in_data_i         : in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    in_keep_i         : in  std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    in_user_i         : in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
    in_last_i         : in  std_logic;

    -- Output Data Stream
    out_ready_i       : in  std_logic;
    out_valid_o       : out std_logic;
    out_data_o        : out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    out_keep_o        : out std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    out_user_o        : out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
    out_last_o        : out std_logic
  );
end axis_tkeep_handler_core;

architecture rtl of axis_tkeep_handler_core is

  -- Define the higher and the lower part of the data bus for easier reading of the code
  subtype DATA_BUS_HIGH_C is integer range AXIS_TDATA_WIDTH_G-1 downto AXIS_TDATA_WIDTH_G/2;
  subtype DATA_BUS_LOW_C  is integer range (AXIS_TDATA_WIDTH_G/2)-1 downto 0;

  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  signal in_ready_q      : std_logic;
  signal out_valid_q     : std_logic;
  signal out_data_s      : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
  signal out_data_q      : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
  signal out_keep_q      : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
  signal out_user_q      : std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
  signal out_last_q      : std_logic;

  -- Internal buffers: 3 half words (3 * AXIS_TDATA_WIDTH_G/2)
  signal buffer_data_1_q : std_logic_vector((AXIS_TDATA_WIDTH_G/2)-1 downto 0);
  signal buffer_data_2_q : std_logic_vector((AXIS_TDATA_WIDTH_G/2)-1 downto 0);
  signal buffer_data_3_q : std_logic_vector((AXIS_TDATA_WIDTH_G/2)-1 downto 0);

  signal buffer_user_q   : std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
  signal buffer_last_q   : std_logic;

  -- Buffer valid and pointer
  signal buffer_valid_q  : std_logic;
  signal buffer_ptr_q    : std_logic_vector(2 downto 0); -- indicates the next LSB
  signal buffer_full_q   : std_logic_vector(2 downto 0); -- indicates if there is data in the buffers

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Core in bypass: connect directly the input port to the output port
  -- Bypass is possible only when the enable is set
  in_ready_o  <= out_ready_i when (enable_i = '1' and bypass_i = '1') else in_ready_q;
  out_valid_o <= in_valid_i  when (enable_i = '1' and bypass_i = '1') else out_valid_q;
  out_data_s  <= in_data_i   when (enable_i = '1' and bypass_i = '1') else out_data_q;
  out_keep_o  <= in_keep_i   when (enable_i = '1' and bypass_i = '1') else out_keep_q;
  out_user_o  <= in_user_i   when (enable_i = '1' and bypass_i = '1') else out_user_q;
  out_last_o  <= in_last_i   when (enable_i = '1' and bypass_i = '1') else out_last_q;

  -- The word_order_i input can be used to switch the top and bottom halves of outgoing data
  out_data_o  <= out_data_s(AXIS_TDATA_WIDTH_G-1 downto 0) when word_order_i = '0' else
                 out_data_s(DATA_BUS_LOW_C) & out_data_s(DATA_BUS_HIGH_C);


  ---------------
  -- Processes --
  ---------------

  tkeep_handler_core_p : process(clk)
    variable msb_select_v : std_logic_vector(2 downto 0);
    variable lsb_select_v : std_logic_vector(2 downto 0);
  begin
    if (rising_edge(clk)) then
      if (rstn = '0') then
        in_ready_q      <= '0';
        out_valid_q     <= '0';
        out_data_q      <= (others => '0');
        out_keep_q      <= (others => '0');
        out_user_q      <= (others => '0');
        out_last_q      <= '0';

        buffer_valid_q  <= '0';
        buffer_data_1_q <= (others => '0');
        buffer_data_2_q <= (others => '0');
        buffer_data_3_q <= (others => '0');
        buffer_ptr_q    <= (others => '0');
        buffer_full_q   <= (others => '0');
        buffer_user_q   <= (others => '0');
        buffer_last_q   <= '0';
      else
        if (buffer_clear_i = '1') then
          -- Buffers should be cleared even if core is disabled
          in_ready_q      <= '0';
          out_valid_q     <= '0';
          out_data_q      <= (others => '0');
          out_keep_q      <= (others => '0');
          out_user_q      <= (others => '0');
          out_last_q      <= '0';

          buffer_valid_q  <= '0';
          buffer_data_1_q <= (others => '0');
          buffer_data_2_q <= (others => '0');
          buffer_data_3_q <= (others => '0');
          buffer_ptr_q    <= (others => '0');
          buffer_full_q   <= (others => '0');
          buffer_user_q   <= (others => '0');
          buffer_last_q   <= '0';
        else
          if (bypass_i = '0') then
            -- In bypass, do not toggle the registers to save power
            if (enable_i = '0') then
              -- Core is disabled
              in_ready_q  <= '0';
              out_valid_q <= '0';
              out_data_q  <= (others => '0');
              out_keep_q  <= (others => '0');
              out_user_q  <= (others => '0');
              out_last_q  <= '0';
            else
              -- Regular behavior (buffer_clear = '0' and enable = '1' and bypass = '0')
              -- #1: Check if there is a slot for transmission, data can be sent out when there is no data (out_valid_q = 0), or when the receiver is ready (out_ready_i = 1)
              if ((out_valid_q = '0') or (out_ready_i = '1')) then
                -- #2: There is a slot for transmission, check if an input data was previously stored in the internal buffer
                if (buffer_valid_q = '1') then
                  -- #3: In that case local buffer must be flushed out first
                  in_ready_q  <= '0';

                  out_valid_q <= '1';
                  out_keep_q  <= (others => '1');
                  out_user_q  <= buffer_user_q;
                  out_last_q  <= buffer_last_q;

                  case buffer_ptr_q is
                    when "001" =>
                      out_data_q(DATA_BUS_LOW_C) <= buffer_data_1_q;
                      out_data_q(DATA_BUS_HIGH_C) <= buffer_data_2_q;
                      buffer_full_q <= buffer_full_q and "100";
                      buffer_ptr_q  <= "100";

                    when "010" =>
                      out_data_q(DATA_BUS_LOW_C) <= buffer_data_2_q;
                      out_data_q(DATA_BUS_HIGH_C) <= buffer_data_3_q;
                      buffer_full_q <= buffer_full_q and "001";
                      buffer_ptr_q  <= "001";

                    when "100" =>
                      out_data_q(DATA_BUS_LOW_C) <= buffer_data_3_q;
                      out_data_q(DATA_BUS_HIGH_C) <= buffer_data_1_q;
                      buffer_full_q <= buffer_full_q and "010";
                      buffer_ptr_q  <= "010";

                    when others => assert true report "Invalid condition detected" severity FAILURE;
                  end case;

                  buffer_valid_q <= '0';

                else
                  -- #4 buffer_valid_q is '0', there is no data in the buffers or there is only one buffer full
                  -- Check if there is data on the input port
                  if (in_ready_q = '1') and (in_valid_i = '1') then
                    --  #5:  There is data on the input port, check if there is data in the internal buffers
                    case buffer_full_q is

                      -- #6: There is no data in the buffers
                      when "000" =>
                        in_ready_q <= '1';

                        if (in_keep_i = (in_keep_i'range => '1')) then
                          -- If this is a complete word put the incoming data on the output port
                          out_valid_q <= '1';
                          out_data_q(AXIS_TDATA_WIDTH_G-1 downto 0) <= in_data_i(AXIS_TDATA_WIDTH_G-1 downto 0);
                          out_keep_q  <= (others => '1');
                          out_user_q  <= in_user_i;
                          out_last_q  <= in_last_i;
                        else
                          assert to_integer(unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          -- This is a half word
                          out_valid_q     <= '0';
                          buffer_valid_q  <= '0';
                          buffer_data_1_q <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_q   <= "001";
                          buffer_ptr_q    <= "001";
                          buffer_user_q   <= in_user_i;
                          buffer_last_q   <= in_last_i;
                        end if;

                      -- #7: There is already some data in the buffer, which can be put on the output port along with the buffer content
                      when "001" =>
                        in_ready_q  <= '1';
                        out_valid_q <= '1';
                        out_data_q(DATA_BUS_LOW_C) <= buffer_data_1_q;
                        out_keep_q  <= (others => '1');
                        out_user_q  <= buffer_user_q or in_user_i;
                        out_last_q  <= buffer_last_q or in_last_i;

                        buffer_user_q <= in_user_i;
                        buffer_last_q <= in_last_i;

                        if (in_keep_i = (in_keep_i'range => '1')) then
                          out_data_q(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_2_q <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_q <= "010";
                          buffer_ptr_q  <= "010";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          out_data_q(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_q <= "000";
                        end if;

                      when "010" =>
                        in_ready_q  <= '1';
                        out_valid_q <= '1';
                        out_data_q(DATA_BUS_LOW_C) <= buffer_data_2_q;
                        out_keep_q  <= (others => '1');
                        out_user_q  <= buffer_user_q or in_user_i;
                        out_last_q  <= buffer_last_q or in_last_i;

                        buffer_user_q <= in_user_i;
                        buffer_last_q <= in_last_i;

                        if (in_keep_i = (in_keep_i'range => '1')) then
                          out_data_q(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_3_q <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_q <= "100";
                          buffer_ptr_q  <= "100";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          out_data_q(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_q <= "000";
                        end if;

                      when "100" =>
                        in_ready_q  <= '1';
                        out_valid_q <= '1';
                        out_data_q(DATA_BUS_LOW_C) <= buffer_data_3_q;
                        out_keep_q  <= (others => '1');
                        out_user_q  <= buffer_user_q or in_user_i;
                        out_last_q  <= buffer_last_q or in_last_i;

                        if (in_keep_i = (in_keep_i'range => '1')) then
                          out_data_q(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_1_q <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_q   <= "001";
                          buffer_ptr_q    <= "001";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          out_data_q(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_q <= "000";
                        end if;

                        buffer_user_q <= in_user_i;
                        buffer_last_q <= in_last_i;

                      when others =>
                        -- There can not be 2 buffers filled with data because we don't know if the incoming data will be a half or a complete word
                        assert true report "Invalid condition detected" severity FAILURE;
                    end case;

                  else
                    -- #8: No data on the input
                    in_ready_q  <= '1';
                    out_valid_q <= '0';
                  end if;
                end if;
              else
                -- #9: No slot for transmission. If input ready and valid are asserted on the current cyle, data must be stored in the local buffer
                if (in_ready_q = '1') then
                  if (in_valid_i = '1') then
                    -- #10: There is data on the input

                    -- Buffer should not be valid
                    assert buffer_valid_q = '0' report "Data valid already asserted" severity FAILURE;

                    buffer_user_q <= in_user_i;
                    buffer_last_q <= in_last_i;

                    case buffer_full_q is
                      when "000" =>
                        -- There is no data in the buffers, store the incoming data in the first buffer
                        if (in_keep_i = (in_keep_i'range => '1')) then
                          -- If this is a complete word
                          buffer_data_1_q <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_2_q <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_valid_q  <= '1';
                          buffer_full_q   <= "011";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          -- This is a half word
                          buffer_data_1_q <= in_data_i(DATA_BUS_LOW_C);
                          buffer_valid_q  <= '0';
                          buffer_full_q   <= "001";
                        end if;
                        buffer_ptr_q <= "001";

                      -- There is already some data in the buffer, this is the lower part of a half word
                      when "001" =>
                        if (in_keep_i = (in_keep_i'range => '1')) then
                          buffer_data_2_q <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_3_q <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_q   <= "111";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          buffer_data_2_q <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_q   <= "011";
                        end if;
                        buffer_valid_q <= '1';
                        -- Verify the pointer value
                        assert buffer_ptr_q = "001" report "Unusual pointer value" severity ERROR;

                      when "010" =>
                        if (in_keep_i = (in_keep_i'range => '1')) then
                          buffer_data_3_q <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_1_q <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_q   <= "111";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          buffer_data_3_q <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_q   <= "110";
                        end if;
                        buffer_valid_q <= '1';
                        -- Verify the pointer value
                        assert buffer_ptr_q = "010" report "Unusual pointer value" severity ERROR;

                      when "100" =>
                        if (in_keep_i = (in_keep_i'range => '1')) then
                          buffer_data_1_q <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_2_q <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_q   <= "111";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          buffer_data_1_q <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_q   <= "101";
                        end if;
                        buffer_valid_q <= '1';
                        -- Verify the pointer value
                        assert buffer_ptr_q = "100" report "Unusual pointer value" severity ERROR;

                      when others =>
                        -- There can not be 2 buffers filled with data because we don't know if the incoming data will be a half or a complete word
                        assert true report "Invalid condition detected" severity FAILURE;
                    end case;
                  else
                    -- #11: There is no data on the input
                    buffer_valid_q <= '0';
                  end if;
                end if;
                -- New data cannot be accepted until a new transmission slot is available
                in_ready_q <= '0';
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process tkeep_handler_core_p;

end rtl;
