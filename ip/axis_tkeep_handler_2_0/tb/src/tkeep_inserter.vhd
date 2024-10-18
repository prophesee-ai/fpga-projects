-- Copyright (c) Prophesee S.A.
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-----------------------------
-- AXI4-Stream tkeep Inserter
entity tkeep_inserter is
  generic (
    AXIS_TDATA_WIDTH_G : positive := 64;
    AXIS_TUSER_WIDTH_G : positive := 1;
    TKEEP_RATIO_G      : real     := 0.01
  );
  port (
    clk                : in  std_logic;
    rst                : in  std_logic;

    -- Input Data Stream
    s_axis_tready      : out std_logic;
    s_axis_tvalid      : in  std_logic;
    s_axis_tdata       : in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    s_axis_tkeep       : in  std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    s_axis_tuser       : in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
    s_axis_tlast       : in  std_logic;

    -- Output Data Stream
    m_axis_tready      : in  std_logic;
    m_axis_tvalid      : out std_logic;
    m_axis_tdata       : out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    m_axis_tkeep       : out std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    m_axis_tuser       : out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
    m_axis_tlast       : out std_logic
  );
end tkeep_inserter;

architecture behavioral of tkeep_inserter is

  ---------------
  -- Constants --
  ---------------
  constant TKEEP_LEN_C   : integer := 12;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Master AXI4-Stream registered outputs
  signal m_axis_tvalid_q : std_logic;
  signal m_axis_tdata_q  : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
  signal m_axis_tkeep_q  : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
  signal m_axis_tuser_q  : std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
  signal m_axis_tlast_q  : std_logic;

  -- Slave AXI4-Stream ready internal signal and registered output
  signal s_axis_tready_q : std_logic;

  -- Internal skid buffer
  signal buffer_valid_q  : std_logic;
  signal buffer_data_q   : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
  signal buffer_keep_q   : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
  signal buffer_user_q   : std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
  signal buffer_last_q   : std_logic;

  -- tkeep buffer: used to keep the part of the data that is not sent when a tkeep is inserted
  signal tkeep_active_q  : std_logic;
  signal tkeep_buffer_q  : std_logic_vector((AXIS_TDATA_WIDTH_G/2)-1 downto 0);

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Slave AXI4-Stream registered ready
  s_axis_tready <= s_axis_tready_q;

  -- Master AXI4-Stream registered output interface assignment
  m_axis_tvalid <= m_axis_tvalid_q;
  m_axis_tdata  <= m_axis_tdata_q;
  m_axis_tkeep  <= m_axis_tkeep_q;
  m_axis_tuser  <= m_axis_tuser_q;
  m_axis_tlast  <= m_axis_tlast_q;

  -------------
  -- Process --
  -------------

  process(clk)
    variable seed1           : positive  := 786;
    variable seed2           : positive  := 324;
    variable rand            : real;
    variable insert_tkeep_v  : boolean;
    variable tkeep_counter_v : integer;
  begin
    if (rising_edge(clk)) then
      if (rst  = '1') then
        s_axis_tready_q <= '1';

        m_axis_tvalid_q <= '0';
        m_axis_tdata_q  <= (others => '0');
        m_axis_tkeep_q  <= (others => '0');
        m_axis_tuser_q  <= (others => '0');
        m_axis_tlast_q  <= '0';

        buffer_valid_q  <= '0';
        buffer_data_q   <= (others => '0');
        buffer_keep_q   <= (others => '0');
        buffer_user_q   <= (others => '0');
        buffer_last_q   <= '0';

        insert_tkeep_v  := false;
        tkeep_counter_v := 0;
        tkeep_active_q  <= '0';
        tkeep_buffer_q  <= (others => '0');
      else
        -- Get a random real-number value in range 0 to 1.0 to determine if a partial tkeep should be generated
        uniform(seed1, seed2, rand);
        if (insert_tkeep_v = false and rand <= TKEEP_RATIO_G) then
          insert_tkeep_v := true;
        else
          insert_tkeep_v := false;
        end if;

        -- Check if there is a slot for transmission
        if (m_axis_tvalid_q = '0' or m_axis_tready = '1') then
          -- Check if the tkeep buffer should be used
          if (tkeep_active_q = '1') then
            -- Check if there is data in the buffer
            if (buffer_valid_q = '1') then
              -- Buffer is full, flush it
              m_axis_tvalid_q <= buffer_valid_q;
              m_axis_tdata_q(AXIS_TDATA_WIDTH_G-1 downto AXIS_TDATA_WIDTH_G/2) <= buffer_data_q((AXIS_TDATA_WIDTH_G/2)-1 downto 0);
              m_axis_tdata_q((AXIS_TDATA_WIDTH_G/2)-1 downto 0)                <= tkeep_buffer_q;
              m_axis_tkeep_q  <= x"FF";
              m_axis_tuser_q  <= buffer_user_q;
              m_axis_tlast_q  <= buffer_last_q;

              tkeep_buffer_q  <= buffer_data_q(AXIS_TDATA_WIDTH_G-1 downto (AXIS_TDATA_WIDTH_G/2));

              buffer_valid_q  <= '0';
              s_axis_tready_q <= '0';

            -- Buffer is empty, check if there is valid data on the input
            elsif (s_axis_tready_q = '1' and s_axis_tvalid = '1') then
              m_axis_tvalid_q <= s_axis_tvalid;
              m_axis_tdata_q(AXIS_TDATA_WIDTH_G-1 downto AXIS_TDATA_WIDTH_G/2) <= s_axis_tdata((AXIS_TDATA_WIDTH_G/2)-1 downto 0);
              m_axis_tdata_q((AXIS_TDATA_WIDTH_G/2)-1 downto 0)                <= tkeep_buffer_q;
              m_axis_tkeep_q  <= x"FF";
              m_axis_tuser_q  <= s_axis_tuser;
              m_axis_tlast_q  <= s_axis_tlast;

              tkeep_buffer_q  <= s_axis_tdata(AXIS_TDATA_WIDTH_G-1 downto (AXIS_TDATA_WIDTH_G/2));

              s_axis_tready_q <= '0';

            else
              -- Transmission slot is available, send the tkeep buffer if it has been active long enough
              if (tkeep_counter_v = TKEEP_LEN_C) then
                m_axis_tvalid_q <= '1';
                m_axis_tdata_q(AXIS_TDATA_WIDTH_G-1 downto AXIS_TDATA_WIDTH_G/2) <= (others => '1');
                m_axis_tdata_q((AXIS_TDATA_WIDTH_G/2)-1 downto 0)                <= tkeep_buffer_q;
                m_axis_tkeep_q  <= x"0F";
                m_axis_tuser_q  <= (others => '0');
                m_axis_tlast_q  <= '1';

                s_axis_tready_q <= '0';

                tkeep_active_q  <= '0';
                tkeep_counter_v := 0;
              else
                s_axis_tready_q <= '1';
                m_axis_tvalid_q <= '0';

                tkeep_counter_v := tkeep_counter_v + 1;
              end if;
            end if;

          else
            -- Check if there is data in the buffer
            if (buffer_valid_q = '1') then
              -- Buffer is full, flush it
              m_axis_tvalid_q <= buffer_valid_q;
              m_axis_tdata_q  <= buffer_data_q;
              m_axis_tkeep_q  <= buffer_keep_q;
              m_axis_tuser_q  <= buffer_user_q;
              m_axis_tlast_q  <= buffer_last_q;

              buffer_valid_q  <= '0';
              s_axis_tready_q <= '0';

            -- Buffer is empty, check if there is valid data on the input
            elsif (s_axis_tready_q = '1' and s_axis_tvalid = '1') then
              if (insert_tkeep_v = true) then
                m_axis_tvalid_q <= s_axis_tvalid;
                m_axis_tdata_q(AXIS_TDATA_WIDTH_G-1 downto AXIS_TDATA_WIDTH_G/2) <= (others => '1');
                m_axis_tdata_q((AXIS_TDATA_WIDTH_G/2)-1 downto 0)                <= s_axis_tdata((AXIS_TDATA_WIDTH_G/2)-1 downto 0);
                m_axis_tkeep_q  <= x"0F";
                m_axis_tuser_q  <= s_axis_tuser;
                m_axis_tlast_q  <= s_axis_tlast;

                tkeep_buffer_q((AXIS_TDATA_WIDTH_G/2)-1 downto 0) <= s_axis_tdata(AXIS_TDATA_WIDTH_G-1 downto AXIS_TDATA_WIDTH_G/2);

                s_axis_tready_q <= '0';

                tkeep_active_q  <= '1';
              else
                m_axis_tvalid_q <= s_axis_tvalid;
                m_axis_tdata_q  <= s_axis_tdata;
                m_axis_tkeep_q  <= s_axis_tkeep;
                m_axis_tuser_q  <= s_axis_tuser;
                m_axis_tlast_q  <= s_axis_tlast;

                s_axis_tready_q <= '1';
              end if;
            else
              s_axis_tready_q <= '1';
              m_axis_tvalid_q <= '0';
            end if;

          end if;

        else
          -- No slot for transmission, if there is valid data on the input store it in the buffer
          -- To simplify the design, there cannot be a partial tkeep in this case
          if (s_axis_tready_q = '1' and s_axis_tvalid = '1') then
            buffer_valid_q <= s_axis_tvalid;
            buffer_data_q  <= s_axis_tdata;
            buffer_keep_q  <= s_axis_tkeep;
            buffer_user_q  <= s_axis_tuser;
            buffer_last_q  <= s_axis_tlast;
          end if;

          -- Do not accept incoming data
          s_axis_tready_q <= '0';

        end if;
      end if;
    end if;
  end process;

end behavioral;
