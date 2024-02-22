-------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Benoit Michel (bmichel@prophesee.ai)
-- Create Date:    November 3, 2023
-- Module Name:    axis_tkeep_handler_core
-- Target Devices:
-- Tool versions:  Xilinx Vivado 2022.2
-- Description:    AXI4-Stream tkeep handler core
--                 Reorder incomplete data words using tkeep signal.
--                 Incomplete words can only half words (32-bits in case of a
--                 64-bits data bus).
--                 It is possible to change the order of the half words (first
--                 word can be the MSB or the LSB) with word_order_i signal.
--                 The handler can be bypassed, in that case the input stream
--                 is directly connected to the output stream (no buffering
--                 stage but word order can still be modified).
--                 Buffers can be emptied with the buffer_clear_i signal.
-------------------------------------------------------------------------------

--     input                                              output
--                                     buffers
--
-- msb       lsb
--  +----+----+                                         +----+----+
--  | A1 | A2 |   tkeep = 0xff                          | A1 | A2 |
--  +----+----+                                         +----+----+
--                                buf1   buf2   buf3
--  +----+----+                  +----+ +----+ +----+
--  |    | B2 |   tkeep = 0x0f   | B2 | |    | |    |
--  +----+----+                  +----+ +----+ +----+
--
--                output ready
--  +----+----+                  +----+ +----+ +----+  +----+----+
--  | C2 | B1 |                  |    | | C2 | |    |  | B1 | B2 |
--  +----+----+                  +----+ +----+ +----+  +----+----+
--
--                output not ready
--  +----+----+                  +----+ +----+ +----+
--  | C2 | B1 |                  | B2 | | B1 | | C2 |
--  +----+----+                  +----+ +----+ +----+


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

----------------------------
-- AXI4-Stream TKEEP Handler
entity axis_tkeep_handler_core is
  generic (
    AXIS_TDATA_WIDTH_G : positive := 64
  );
  port (
    clk               : in  std_logic;
    rst               : in  std_logic;

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
    in_first_i        : in  std_logic;
    in_last_i         : in  std_logic;

    -- Output Data Stream
    out_ready_i       : in  std_logic;
    out_valid_o       : out std_logic;
    out_data_o        : out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    out_keep_o        : out std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    out_first_o       : out std_logic;
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

  signal in_ready_s      : std_logic;
  signal out_valid_s     : std_logic;
  signal out_data_s      : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);

  -- Internal buffers: 3 half words (3 * AXIS_TDATA_WIDTH_G/2)
  signal buffer_data_1_s : std_logic_vector((AXIS_TDATA_WIDTH_G/2)-1 downto 0);
  signal buffer_data_2_s : std_logic_vector((AXIS_TDATA_WIDTH_G/2)-1 downto 0);
  signal buffer_data_3_s : std_logic_vector((AXIS_TDATA_WIDTH_G/2)-1 downto 0);

  signal buffer_first_s  : std_logic;
  signal buffer_last_s   : std_logic;

  -- Buffer valid
  signal buffer_valid_s  : std_logic;
  signal buffer_ptr_s    : std_logic_vector(2 downto 0); -- indicates the next LSB
  signal buffer_full_s   : std_logic_vector(2 downto 0); -- indicates if there is data in the buffers

begin

  ----------------
  -- Assertions --
  ----------------


  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  in_ready_o  <= in_ready_s;
  out_valid_o <= out_valid_s;

  -- The word_order_i input can be used to change the word order when using systems that
  -- send half words on the bus
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
      if (rst = '1') then
        in_ready_s      <= '0';

        out_valid_s     <= '0';
        out_data_s      <= (others => '0');
        out_keep_o      <= (others => '0');
        out_first_o     <= '0';
        out_last_o      <= '0';

        buffer_valid_s  <= '0';
        buffer_data_1_s <= (others => '0');
        buffer_data_2_s <= (others => '0');
        buffer_data_3_s <= (others => '0');
        buffer_ptr_s    <= (others => '0');
        buffer_full_s   <= (others => '0');
        buffer_first_s  <= '0';
        buffer_last_s   <= '0';

      else
        if (enable_i = '0') then
          in_ready_s  <= '0';
          out_valid_s <= '0';
          out_data_s  <= (others => '0');
          out_keep_o  <= (others => '0');
          out_first_o <= '0';
          out_last_o  <= '0';
        else
          if (bypass_i = '1') then
            -- Connect directly the input port to the output port
            in_ready_s  <= out_ready_i;
            out_valid_s <= in_valid_i;
            out_data_s  <= in_data_i;
            out_keep_o  <= in_keep_i;
            out_first_o <= in_first_i;
            out_last_o  <= in_last_i;
          else
            if (buffer_clear_i = '1') then
              -- If the buffers are cleared, the block is ready to receive data
              in_ready_s      <= '1';

              out_valid_s     <= '0';
              out_data_s      <= (others => '0');
              out_keep_o      <= (others => '0');
              out_first_o     <= '0';
              out_last_o      <= '0';

              buffer_valid_s  <= '0';
              buffer_data_1_s <= (others => '0');
              buffer_data_2_s <= (others => '0');
              buffer_data_3_s <= (others => '0');
              buffer_ptr_s    <= (others => '0');
              buffer_full_s   <= (others => '0');
              buffer_first_s  <= '0';
              buffer_last_s   <= '0';
            else
              -- #1: Check if there is a slot for transmission, data can be sent out when there is no data (out_valid_s = 0), or when the receiver is ready (out_ready_i = 1)
              if ((out_valid_s = '0') or (out_ready_i = '1')) then
                -- #2: There is a slot for transmission, check if an input data was previously stored in the internal buffer
                if (buffer_valid_s = '1') then
                  -- #3: In that case local buffer must be flushed out first
                  in_ready_s  <= '0';

                  out_valid_s <= '1';
                  out_keep_o  <= (others => '1');
                  out_first_o <= buffer_first_s;
                  out_last_o  <= buffer_last_s;

                  case buffer_ptr_s is
                    when "001" =>
                      out_data_s(DATA_BUS_LOW_C) <= buffer_data_1_s;
                      out_data_s(DATA_BUS_HIGH_C) <= buffer_data_2_s;
                      buffer_full_s <= buffer_full_s and "100";
                      buffer_ptr_s  <= "100";

                    when "010" =>
                      out_data_s(DATA_BUS_LOW_C) <= buffer_data_2_s;
                      out_data_s(DATA_BUS_HIGH_C) <= buffer_data_3_s;
                      buffer_full_s <= buffer_full_s and "001";
                      buffer_ptr_s  <= "001";

                    when "100" =>
                      out_data_s(DATA_BUS_LOW_C) <= buffer_data_3_s;
                      out_data_s(DATA_BUS_HIGH_C) <= buffer_data_1_s;
                      buffer_full_s <= buffer_full_s and "010";
                      buffer_ptr_s  <= "010";

                    when others => assert true report "Invalid condition detected" severity FAILURE;
                  end case;

                  buffer_valid_s <= '0';

                else
                  -- #4 buffer_valid_s is '0', there is no data in the buffers or there is only one buffer full
                  -- Check if there is data on the input port
                  if (in_ready_s = '1') and (in_valid_i = '1') then
                    --  #5:  There is data on the input port, check if there is data in the internal buffers
                    case buffer_full_s is

                      -- #6: There is no data in the buffers
                      when "000" =>
                        in_ready_s <= '1';

                        if (in_keep_i = (in_keep_i'range => '1')) then
                          -- If this is a complete word put the incoming data on the output port
                          out_valid_s <= '1';
                          out_data_s(AXIS_TDATA_WIDTH_G-1 downto 0) <= in_data_i(AXIS_TDATA_WIDTH_G-1 downto 0);
                          out_first_o <= in_first_i;
                          out_last_o  <= in_last_i;
                        else
                          assert to_integer(unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          -- This is a half word
                          out_valid_s     <= '0';
                          buffer_valid_s  <= '0';
                          buffer_data_1_s <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_s   <= "001";
                          buffer_ptr_s    <= "001";
                          buffer_first_s  <= in_first_i;
                          buffer_last_s   <= in_last_i;
                        end if;

                      -- #7: There is already some data in the buffer, which can be put on the output port along with the buffer content
                      when "001" =>
                        in_ready_s  <= '1';
                        out_valid_s <= '1';
                        out_data_s(DATA_BUS_LOW_C) <= buffer_data_1_s(DATA_BUS_LOW_C);
                        out_first_o <= buffer_first_s or in_first_i;
                        out_last_o  <= buffer_last_s or in_last_i;

                        buffer_first_s <= in_first_i;
                        buffer_last_s  <= in_last_i;

                        if (in_keep_i = (in_keep_i'range => '1')) then
                          out_data_s(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_2_s <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_s <= "010";
                          buffer_ptr_s  <= "010";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          out_data_s(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_s <= "000";
                        end if;

                      when "010" =>
                        in_ready_s  <= '1';
                        out_valid_s <= '1';
                        out_data_s(DATA_BUS_LOW_C) <= buffer_data_2_s(DATA_BUS_LOW_C);
                        out_first_o <= buffer_first_s or in_first_i;
                        out_last_o  <= buffer_last_s or in_last_i;

                        buffer_first_s <= in_first_i;
                        buffer_last_s  <= in_last_i;

                        if (in_keep_i = (in_keep_i'range => '1')) then
                          out_data_s(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_3_s <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_s <= "100";
                          buffer_ptr_s  <= "100";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          out_data_s(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_s <= "000";
                        end if;

                      when "100" =>
                        in_ready_s  <= '1';
                        out_valid_s <= '1';
                        out_data_s(DATA_BUS_LOW_C) <= buffer_data_3_s(DATA_BUS_LOW_C);
                        out_first_o <= buffer_first_s or in_first_i;
                        out_last_o  <= buffer_last_s or in_last_i;

                        if (in_keep_i = (in_keep_i'range => '1')) then
                          out_data_s(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_1_s <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_s   <= "001";
                          buffer_ptr_s    <= "001";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          out_data_s(DATA_BUS_HIGH_C) <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_s <= "000";
                        end if;

                        buffer_first_s <= in_first_i;
                        buffer_last_s  <= in_last_i;

                      when others =>
                        -- There can not be 2 buffers filled with data because we don't know if the incoming data will be a half or a complete word
                        assert true report "Invalid condition detected" severity FAILURE;
                    end case;

                  else
                    -- #8: No data on the input
                    in_ready_s  <= '1';
                    out_valid_s <= '0';
                  end if;
                end if;
              else
                -- #9: No slot for transmission. If input ready and valid are asserted on the current cyle, data must be stored in the local buffer
                if (in_ready_s = '1') then
                  if (in_valid_i = '1') then
                    -- #10: There is data on the input

                    -- Buffer should not be valid
                    assert buffer_valid_s = '0' report "Data valid already asserted" severity FAILURE;

                    buffer_first_s <= in_first_i;
                    buffer_last_s  <= in_last_i;

                    case buffer_full_s is
                      when "000" =>
                        -- There is no data in the buffers, store the incoming data in the first buffer
                        if (in_keep_i = (in_keep_i'range => '1')) then
                          -- If this is a complete word
                          buffer_data_1_s <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_2_s <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_valid_s  <= '1';
                          buffer_full_s   <= "011";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          -- This is a half word
                          buffer_data_1_s <= in_data_i(DATA_BUS_LOW_C);
                          buffer_valid_s  <= '0';
                          buffer_full_s   <= "001";
                        end if;
                        buffer_ptr_s <= "001";

                      -- There is already some data in the buffer, this is the lower part of a half word
                      when "001" =>
                        if (in_keep_i = (in_keep_i'range => '1')) then
                          buffer_data_2_s <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_3_s <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_s   <= "111";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          buffer_data_2_s <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_s   <= "011";
                        end if;
                        buffer_valid_s <= '1';
                        -- Verify the pointer value
                        assert buffer_ptr_s = "001" report "Unusual pointer value" severity ERROR;

                      when "010" =>
                        if (in_keep_i = (in_keep_i'range => '1')) then
                          buffer_data_3_s <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_1_s <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_s   <= "111";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          buffer_data_3_s <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_s   <= "110";
                        end if;
                        buffer_valid_s <= '1';
                        -- Verify the pointer value
                        assert buffer_ptr_s = "010" report "Unusual pointer value" severity ERROR;

                      when "100" =>
                        if (in_keep_i = (in_keep_i'range => '1')) then
                          buffer_data_1_s <= in_data_i(DATA_BUS_LOW_C);
                          buffer_data_2_s <= in_data_i(DATA_BUS_HIGH_C);
                          buffer_full_s   <= "111";
                        else
                          assert (unsigned(in_keep_i)) = 2**((AXIS_TDATA_WIDTH_G/8)/2)-1 report "Unusual value on tkeep" severity ERROR;
                          buffer_data_1_s <= in_data_i(DATA_BUS_LOW_C);
                          buffer_full_s   <= "101";
                        end if;
                        buffer_valid_s <= '1';
                        -- Verify the pointer value
                        assert buffer_ptr_s = "100" report "Unusual pointer value" severity ERROR;

                      when others =>
                        -- There can not be 2 buffers filled with data because we don't know if the incoming data will be a half or a complete word
                        assert true report "Invalid condition detected" severity FAILURE;
                    end case;
                  else
                    -- #11: There is no data on the input
                    buffer_valid_s <= '0';
                  end if;
                end if;
                -- New data cannot be accepted until a new transmission slot is available
                in_ready_s <= '0';
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process tkeep_handler_core_p;

end rtl;
