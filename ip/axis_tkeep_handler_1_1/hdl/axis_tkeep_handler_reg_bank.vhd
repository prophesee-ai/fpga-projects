-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
-- Unless required by applicable law or agreed to in writing, software distributed
-- under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied. See the License
-- for the specific language governing permissions and limitations under the License.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.axis_tkeep_handler_reg_bank_pkg.all;

-------------------------------
-- AXIS TKEEP HANDLER Register Bank
-------------------------------
entity axis_tkeep_handler_reg_bank is
  generic (
    -- AXI generics - AXI4-Lite supports a data bus width of 32-bit or 64-bit
    AXIL_DATA_WIDTH_G        : integer  := 32;
    AXIL_ADDR_WIDTH_G        : integer  := 32
  );
  port (
    -- CONTROL Register
    cfg_control_enable_o     : out  std_logic_vector(1-1 downto 0);
    cfg_control_bypass_o     : out  std_logic_vector(1-1 downto 0);
    cfg_control_clear_o      : out  std_logic_vector(1-1 downto 0);
    -- CONFIG Register
    cfg_config_word_order_o  : out  std_logic_vector(1-1 downto 0);

    -- Slave AXI4-Lite Interface
    s_axi_aclk               : in   std_logic;
    s_axi_aresetn            : in   std_logic;
    s_axi_awaddr             : in   std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
    s_axi_awprot             : in   std_logic_vector(2 downto 0);  -- NOT USED
    s_axi_awvalid            : in   std_logic;
    s_axi_awready            : out  std_logic;
    s_axi_wdata              : in   std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);  -- NOT USED
    s_axi_wstrb              : in   std_logic_vector((AXIL_DATA_WIDTH_G/8)-1 downto 0); -- NOT USED
    s_axi_wvalid             : in   std_logic;
    s_axi_wready             : out  std_logic;
    s_axi_bresp              : out  std_logic_vector(1 downto 0);
    s_axi_bvalid             : out  std_logic;
    s_axi_bready             : in   std_logic;
    s_axi_araddr             : in   std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
    s_axi_arprot             : in   std_logic_vector(2 downto 0);  -- NOT USED
    s_axi_arvalid            : in   std_logic;
    s_axi_arready            : out  std_logic;
    s_axi_rdata              : out  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
    s_axi_rresp              : out  std_logic_vector(1 downto 0);
    s_axi_rvalid             : out  std_logic;
    s_axi_rready             : in   std_logic
  );
end axis_tkeep_handler_reg_bank;


architecture arch_imp of axis_tkeep_handler_reg_bank is

  -- Constant declarations
  constant VERSION_MINOR_DEFAULT_C : std_logic_vector(16-1 downto 0) := "0000000000000001";
  constant VERSION_MAJOR_DEFAULT_C : std_logic_vector(16-1 downto 0) := "0000000000000001";

  constant REGISTER_NUMBER     : integer := 3;
  constant OPT_MEM_ADDR_BITS   : integer := integer(ceil(log2(real(REGISTER_NUMBER))));
  constant ADDR_LSB            : integer := (AXIL_DATA_WIDTH_G/32) + 1;
  constant ADDR_MSB            : integer := ADDR_LSB + OPT_MEM_ADDR_BITS - 1;

  -- AXI4LITE signals
  signal axi_awaddr            : std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
  signal axi_awready           : std_logic;
  signal axi_wready            : std_logic;
  signal axi_bresp             : std_logic_vector(1 downto 0);
  signal axi_bvalid            : std_logic;
  signal axi_araddr            : std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
  signal axi_arready           : std_logic;
  signal axi_rdata             : std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
  signal axi_rresp             : std_logic_vector(1 downto 0);
  signal axi_rvalid            : std_logic;

  -- Common signals
  signal awaddr_valid          : std_logic;

  -------------------------------------------
  -- Signals for user logic register space --
  -------------------------------------------

  -- VERSION Register
  signal cfg_version_minor_q                      : std_logic_vector(16-1 downto 0);
  signal cfg_version_major_q                      : std_logic_vector(16-1 downto 0);
  -- CONTROL Register
  signal cfg_control_enable_q                     : std_logic_vector(1-1 downto 0);
  signal cfg_control_bypass_q                     : std_logic_vector(1-1 downto 0);
  signal cfg_control_clear_q                      : std_logic_vector(1-1 downto 0);
  -- CONFIG Register
  signal cfg_config_word_order_q                  : std_logic_vector(1-1 downto 0);


begin

  -- AXI4-Lite output signals assignements
  s_axi_awready <= axi_awready;
  s_axi_wready  <= axi_wready;  -- axi_wready is identical to axi_awready, we could remove it
  s_axi_bresp   <= axi_bresp;
  s_axi_bvalid  <= axi_bvalid;
  s_axi_arready <= axi_arready;
  s_axi_rdata   <= axi_rdata;
  s_axi_rresp   <= axi_rresp;
  s_axi_rvalid  <= axi_rvalid;

  -- Assign register to output async
  cfg_control_enable_o                     <= cfg_control_enable_q;
  cfg_control_bypass_o                     <= cfg_control_bypass_q;
  cfg_control_clear_o                      <= cfg_control_clear_q;
  cfg_config_word_order_o                  <= cfg_config_word_order_q;

  ---------------------------
  -- Write address channel --
  ---------------------------

  -- axi_awready: Write address ready
  -- This signal indicates that the slave is ready to accept an address and associated control signals.
  -- It is asserted for one clock cycle when both s_axi_awvalid and s_axi_wvalid are asserted.
  -- It is de-asserted when reset is low.
  -- Note: aw_en = '1' has been replaced by (s_axi_bvalid = '0' or s_axi_bready = '1'), see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      -- The reset signal can be asserted asynchronously, but deassertion must be synchronous with a
      -- rising edge of s_axi_aclk
      if s_axi_aresetn = '0' then
        axi_awready <= '0';
      else
        if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and (axi_bvalid = '0' or s_axi_bready = '1')) then
          -- Slave is ready to accept write address when there is a valid write address and write data
          -- on the write address and data bus. This design expects no outstanding transactions.
          axi_awready <= '1';
        else
          axi_awready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- axi_awaddr: Write address
  -- The write address gives the address of the first transfer in a write transaction (no burst in AXI4-LITE).
  -- This process is used to latch the address when both s_axi_awvalid and s_axi_wvalid are valid.
  -- Note: aw_en = '1' has been replaced by (s_axi_bvalid = '0' or s_axi_bready = '1'), see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        axi_awaddr <= (others => '0');
      else
        if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and (axi_bvalid = '0' or s_axi_bready = '1')) then
          axi_awaddr <= s_axi_awaddr;
        end if;
      end if;
    end if;
  end process;

  ------------------------
  -- Write data channel --
  ------------------------

  -- axi_wready: Write ready
  -- This signal indicates that the slave can accept the write data.
  -- It is asserted for one s_axi_aclk clock cycle when both s_axi_awvalid and s_axi_wvalid are asserted.
  -- It is de-asserted when reset is low.
  -- Slave is ready to accept write data when there is a valid write address and write data
  -- on the write address and data bus. This design expects no outstanding transactions.
  -- Note: aw_en = '1' has been replaced by (s_axi_bvalid = '0' or s_axi_bready = '1'), see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        -- write ready
        axi_wready <= '0';
      else
        if (axi_wready = '0' and s_axi_wvalid = '1' and s_axi_awvalid = '1' and (axi_bvalid = '0' or s_axi_bready = '1')) then
          axi_wready <= '1';
        else
          axi_wready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Memmory mapped register select and write logic
  -- The write data is accepted and written to memory mapped registers when
  -- axi_awready, s_axi_awvalid, axi_wready and s_axi_wvalid are asserted.
  -- Write strobes are used to select byte enables of slave registers while writing.
  -- These registers are cleared when reset (active low) is applied.
  -- Slave register write enable is asserted when valid address and data are available
  -- and the slave is ready to accept the write address and write data.
  -- Note: s_axi_awvalid = '1' and axi_wready = '1' and s_axi_wvalid = '1' have been removed, see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        -- clear registers (values by default)
        cfg_control_enable_q <= CONTROL_ENABLE_DEFAULT;
        cfg_control_bypass_q <= CONTROL_BYPASS_DEFAULT;
        cfg_control_clear_q <= CONTROL_CLEAR_DEFAULT;
        cfg_config_word_order_q <= CONFIG_WORD_ORDER_DEFAULT;
      else
        if axi_awready = '1' then
          case axi_awaddr(ADDR_MSB downto ADDR_LSB) is
            when CONTROL_ADDR(ADDR_MSB downto ADDR_LSB) =>
              cfg_control_enable_q <= s_axi_wdata(CONTROL_ENABLE_MSB downto CONTROL_ENABLE_LSB);
              cfg_control_bypass_q <= s_axi_wdata(CONTROL_BYPASS_MSB downto CONTROL_BYPASS_LSB);
              cfg_control_clear_q  <= s_axi_wdata(CONTROL_CLEAR_MSB downto CONTROL_CLEAR_LSB);
              --axi_bresp   <= "00";
            when CONFIG_ADDR(ADDR_MSB downto ADDR_LSB) =>
              cfg_config_word_order_q <= s_axi_wdata(CONFIG_WORD_ORDER_MSB downto CONFIG_WORD_ORDER_LSB);
              --axi_bresp   <= "00";
            when others =>
              -- Unknown address
              cfg_control_enable_q <= cfg_control_enable_q;
              cfg_control_bypass_q <= cfg_control_bypass_q;
              cfg_control_clear_q <= cfg_control_clear_q;
              cfg_config_word_order_q <= cfg_config_word_order_q;
          end case;
        end if;
      end if;
    end if;
  end process;

  -- TODO: address decode for axi_bresp signal below
  awaddr_valid <= '1' when axi_awaddr(ADDR_MSB downto ADDR_LSB) = CONTROL_ADDR(ADDR_MSB downto ADDR_LSB) else
                  '1' when axi_awaddr(ADDR_MSB downto ADDR_LSB) = CONFIG_ADDR(ADDR_MSB downto ADDR_LSB) else
                  '0';

  ----------------------------
  -- Write response channel --
  ----------------------------

  -- axi_bvalid & axi_bresp: Write response
  -- The write response and response valid signals are asserted by the slave when
  -- axi_awready, s_axi_awvalid, axi_wready and s_axi_wvalid are asserted. This marks the acceptance of
  -- address and indicates the status of write transaction.
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        axi_bvalid  <= '0';
        axi_bresp   <= "00";
      else
        if (axi_awready = '1' and s_axi_awvalid = '1' and axi_wready = '1' and s_axi_wvalid = '1' and axi_bvalid = '0') then
          -- axi_bvalid: Write response valid
          -- This signal indicates that the channel is signaling a valid write response.
          axi_bvalid <= '1';
          -- axi_bresp: Write response
          -- This signal indicates the status of the write transaction.
          if (awaddr_valid = '1') then
            axi_bresp  <= "00";
          else
            axi_bresp  <= "10";  -- SLVERR
          end if;
        -- Check if bready is asserted while bvalid is high (there is a possibility that bready is always asserted high)
        elsif (s_axi_bready = '1' and axi_bvalid = '1') then
          axi_bvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  --------------------------
  -- Read address channel --
  --------------------------

  -- axi_arready: Read address ready
  -- This signal indicates that the slave is ready to accept an address and associated control signals.
  -- It is asserted for one s_axi_aclk clock cycle when s_axi_arvalid is asserted.
  -- It is de-asserted when reset (active low) is asserted.
  -- The read address is also latched when s_axi_arvalid is asserted.
  -- It is reset to zero on reset assertion.
  -- Note: (s_axi_rvalid = '0' or s_axi_rready = '1') has been added from the equation (see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html)
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        -- read ready
        axi_arready <= '0';
        axi_araddr  <= (others => '0');
      else
        if (axi_arready = '0' and s_axi_arvalid = '1' and (axi_rvalid = '0' or s_axi_rready = '1')) then
          -- Indicates that the slave has accepted the valid read address
          axi_arready <= '1';
          -- Read address latching
          axi_araddr  <= s_axi_araddr;
        else
          axi_arready <= '0';
        end if;
      end if;
    end if;
  end process;

  --------------------------
  -- Read address channel --
  --------------------------

  -- axi_rvalid: Read valid
  -- This signal indicates that the channel is signaling the required read data.
  -- It is asserted for one clock cycle when both s_axi_arvalid and axi_arready are asserted.
  -- The slave registers data are available on the axi_rdata bus at this instance. The assertion of
  -- axi_rvalid marks the validity of read data on the bus and axi_rresp indicates the status of the
  -- read transaction.
  -- axi_rvalid is deasserted on reset (active low).
  -- axi_rresp and axi_rdata are cleared to zero on reset (active low).
  -- Note: (not axi_rvalid) has been removed from the equation (see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html)
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        axi_rvalid <= '0';
        axi_rresp  <= "00";
        -- read data
        axi_rdata  <= (others => '0');
      else
        if (axi_arready = '1' and s_axi_arvalid = '1') then
          -- Valid read data is available at the read data bus
          axi_rvalid <= '1';
          -- By default the slave respond with an OKAY status, which will be overriden if the address is not recognized
          axi_rresp   <= "00";

          -- Fill the bits that are not used with zeros
          axi_rdata <= (others => '0');

          -- When there is a valid read address (s_axi_arvalid) with acceptance of read address by the
          -- slave (axi_arready), output the read dada

          -- Read address mux
          case axi_araddr(ADDR_MSB downto ADDR_LSB) is
            when VERSION_ADDR(ADDR_MSB downto ADDR_LSB) =>
              axi_rdata(VERSION_MINOR_MSB downto VERSION_MINOR_LSB) <= VERSION_MINOR_DEFAULT_C;
              axi_rdata(VERSION_MAJOR_MSB downto VERSION_MAJOR_LSB) <= VERSION_MAJOR_DEFAULT_C;
            when CONTROL_ADDR(ADDR_MSB downto ADDR_LSB) =>
              axi_rdata(CONTROL_ENABLE_MSB downto CONTROL_ENABLE_LSB) <= cfg_control_enable_q;
              axi_rdata(CONTROL_BYPASS_MSB downto CONTROL_BYPASS_LSB) <= cfg_control_bypass_q;
              axi_rdata(CONTROL_CLEAR_MSB downto CONTROL_CLEAR_LSB) <= cfg_control_clear_q;
            when CONFIG_ADDR(ADDR_MSB downto ADDR_LSB) =>
              axi_rdata(CONFIG_WORD_ORDER_MSB downto CONFIG_WORD_ORDER_LSB) <= cfg_config_word_order_q;
            when others =>
              -- unknown address
              axi_rresp <= "10";  -- SLVERR
          end case;

        elsif (axi_rvalid = '1' and s_axi_rready = '1') then
          -- Read data is accepted by the master
          axi_rvalid <= '0';
        end if;
      end if;
    end if;
  end process;

end arch_imp;
