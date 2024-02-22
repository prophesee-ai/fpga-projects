----------------------------------------------------------------------------------
-- Copyright 2015-2023 Prophesee
--
-- Company:        Prophesee
-- Module Name:    mipi_tx_reg_bank
-- Description:    MIPI TX Register Bank
-- Comment:        
--
-- Note:           File generated automatically by Prophesee's
--                 Register Map to AXI Lite tool.
--                 Please do not modify its contents.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

library work;
use work.mipi_tx_reg_bank_pkg.all;

-------------------------------
-- MIPI TX Register Bank
-------------------------------
entity mipi_tx_reg_bank is
  generic (
    -- FEATURES Register
    FEATURES_PADDING_PRESENT_DEFAULT         : std_logic_vector(1-1 downto 0) := "0";
    FEATURES_FIXED_FRAME_PRESENT_DEFAULT     : std_logic_vector(1-1 downto 0) := "0";

    -- AXI generics
    C_S_AXI_DATA_WIDTH                       : integer  := 32;
    C_S_AXI_ADDR_WIDTH                       : integer  := 32
  );
  port (
    -- CONTROL Register
    cfg_control_enable_o                     : out  std_logic_vector(1-1 downto 0);
    cfg_control_enable_packet_timeout_o      : out  std_logic_vector(1-1 downto 0);
    cfg_control_blocking_mode_o              : out  std_logic_vector(1-1 downto 0);
    cfg_control_padding_bypass_o             : out  std_logic_vector(1-1 downto 0);
    -- DATA_IDENTIFIER Register
    cfg_data_identifier_data_type_o          : out  std_logic_vector(6-1 downto 0);
    cfg_data_identifier_virtual_channel_o    : out  std_logic_vector(2-1 downto 0);
    -- FRAME_PERIOD Register
    cfg_frame_period_value_us_o              : out  std_logic_vector(16-1 downto 0);
    -- PACKET_TIMEOUT Register
    cfg_packet_timeout_value_us_o            : out  std_logic_vector(16-1 downto 0);
    -- PACKET_SIZE Register
    cfg_packet_size_value_o                  : out  std_logic_vector(14-1 downto 0);
    -- START_TIME Register
    cfg_start_time_value_o                   : out  std_logic_vector(16-1 downto 0);
    -- START_FRAME_TIME Register
    cfg_start_frame_time_value_o             : out  std_logic_vector(16-1 downto 0);
    -- END_FRAME_TIME Register
    cfg_end_frame_time_value_o               : out  std_logic_vector(16-1 downto 0);
    -- INTER_FRAME_TIME Register
    cfg_inter_frame_time_value_o             : out  std_logic_vector(16-1 downto 0);
    -- INTER_PACKET_TIME Register
    cfg_inter_packet_time_value_o            : out  std_logic_vector(16-1 downto 0);

    -- AXI LITE port in/out signals
    s_axi_aclk                               : in   std_logic;
    s_axi_aresetn                            : in   std_logic;
    s_axi_awaddr                             : in   std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_awprot                             : in   std_logic_vector(2 downto 0);
    s_axi_awvalid                            : in   std_logic;
    s_axi_awready                            : out  std_logic;
    s_axi_wdata                              : in   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_wstrb                              : in   std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    s_axi_wvalid                             : in   std_logic;
    s_axi_wready                             : out  std_logic;
    s_axi_bresp                              : out  std_logic_vector(1 downto 0);
    s_axi_bvalid                             : out  std_logic;
    s_axi_bready                             : in   std_logic;
    s_axi_araddr                             : in   std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_arprot                             : in   std_logic_vector(2 downto 0);
    s_axi_arvalid                            : in   std_logic;
    s_axi_arready                            : out  std_logic;
    s_axi_rdata                              : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_rresp                              : out  std_logic_vector(1 downto 0);
    s_axi_rvalid                             : out  std_logic;
    s_axi_rready                             : in   std_logic
  );
end mipi_tx_reg_bank;


architecture arch_imp of mipi_tx_reg_bank is

  -- AXI4LITE signals
  signal axi_awaddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_awready  : std_logic;
  signal axi_wready   : std_logic;
  signal axi_bresp    : std_logic_vector(1 downto 0);
  signal axi_bvalid   : std_logic;
  signal axi_araddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_arready  : std_logic;
  signal axi_rdata    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal axi_rresp    : std_logic_vector(1 downto 0);
  signal axi_rvalid   : std_logic;

  -- Constant declarations
  constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
  constant REGISTER_NUMBER : integer := 11;
  constant OPT_MEM_ADDR_BITS : integer := integer(ceil(log2(real(REGISTER_NUMBER))));
  constant BUS_ADDR_ERROR_CODE : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (1 downto 0 => '0', others => '1');

  -- common signals
  signal write_addr_error_q : std_logic;
  signal read_addr_error_q  : std_logic;
  
  signal slv_reg_rden       : std_logic;
  signal slv_reg_wren       : std_logic;
  signal byte_index         : integer;
  signal aw_en              : std_logic;

  ------------------------------------------------
  ---- Signals for user logic register space
  ------------------------------------------------

  -- CONTROL Register
  signal cfg_control_enable_q                     : std_logic_vector(1-1 downto 0);
  signal cfg_control_enable_packet_timeout_q      : std_logic_vector(1-1 downto 0);
  signal cfg_control_blocking_mode_q              : std_logic_vector(1-1 downto 0);
  signal cfg_control_padding_bypass_q             : std_logic_vector(1-1 downto 0);
  -- DATA_IDENTIFIER Register
  signal cfg_data_identifier_data_type_q          : std_logic_vector(6-1 downto 0);
  signal cfg_data_identifier_virtual_channel_q    : std_logic_vector(2-1 downto 0);
  -- FRAME_PERIOD Register
  signal cfg_frame_period_value_us_q              : std_logic_vector(16-1 downto 0);
  -- PACKET_TIMEOUT Register
  signal cfg_packet_timeout_value_us_q            : std_logic_vector(16-1 downto 0);
  -- PACKET_SIZE Register
  signal cfg_packet_size_value_q                  : std_logic_vector(14-1 downto 0);
  -- START_TIME Register
  signal cfg_start_time_value_q                   : std_logic_vector(16-1 downto 0);
  -- START_FRAME_TIME Register
  signal cfg_start_frame_time_value_q             : std_logic_vector(16-1 downto 0);
  -- END_FRAME_TIME Register
  signal cfg_end_frame_time_value_q               : std_logic_vector(16-1 downto 0);
  -- INTER_FRAME_TIME Register
  signal cfg_inter_frame_time_value_q             : std_logic_vector(16-1 downto 0);
  -- INTER_PACKET_TIME Register
  signal cfg_inter_packet_time_value_q            : std_logic_vector(16-1 downto 0);
  -- FEATURES Register
  signal cfg_features_padding_present_q           : std_logic_vector(1-1 downto 0);
  signal cfg_features_fixed_frame_present_q       : std_logic_vector(1-1 downto 0);


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------
  
  -- AXI4LITE Async signals assignements
  s_axi_awready    <= axi_awready;
  s_axi_wready     <= axi_wready;
  s_axi_bresp      <= axi_bresp;
  s_axi_bvalid     <= axi_bvalid;
  s_axi_arready    <= axi_arready;
  s_axi_rdata      <= axi_rdata;
  s_axi_rresp      <= axi_rresp;
  s_axi_rvalid     <= axi_rvalid;

  slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;
  slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;
  
  -- Assign register to output async
  cfg_control_enable_o                     <= cfg_control_enable_q;
  cfg_control_enable_packet_timeout_o      <= cfg_control_enable_packet_timeout_q;
  cfg_control_blocking_mode_o              <= cfg_control_blocking_mode_q;
  cfg_control_padding_bypass_o             <= cfg_control_padding_bypass_q;
  cfg_data_identifier_data_type_o          <= cfg_data_identifier_data_type_q;
  cfg_data_identifier_virtual_channel_o    <= cfg_data_identifier_virtual_channel_q;
  cfg_frame_period_value_us_o              <= cfg_frame_period_value_us_q;
  cfg_packet_timeout_value_us_o            <= cfg_packet_timeout_value_us_q;
  cfg_packet_size_value_o                  <= cfg_packet_size_value_q;
  cfg_start_time_value_o                   <= cfg_start_time_value_q;
  cfg_start_frame_time_value_o             <= cfg_start_frame_time_value_q;
  cfg_end_frame_time_value_o               <= cfg_end_frame_time_value_q;
  cfg_inter_frame_time_value_o             <= cfg_inter_frame_time_value_q;
  cfg_inter_packet_time_value_o            <= cfg_inter_packet_time_value_q;


  process (s_axi_aclk)
    variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
    begin
      if rising_edge(s_axi_aclk) then 
        if s_axi_aresetn = '0' then
          -- address write
          axi_awready <= '0';
          aw_en <= '1';
          axi_awaddr <= (others => '0');
          -- write ready
          axi_wready <= '0';
          -- write response
          axi_bvalid  <= '0';
          axi_bresp   <= "00";
          -- read ready
          axi_arready <= '0';
          axi_araddr  <= (others => '1');
          -- read response
          axi_rvalid <= '0';
          axi_rresp  <= "00";
          -- read data
          axi_rdata  <= (others => '0');
          -- clear registers (values by default)
          cfg_control_enable_q <= CONTROL_ENABLE_DEFAULT;
          cfg_control_enable_packet_timeout_q <= CONTROL_ENABLE_PACKET_TIMEOUT_DEFAULT;
          cfg_control_blocking_mode_q <= CONTROL_BLOCKING_MODE_DEFAULT;
          cfg_control_padding_bypass_q <= CONTROL_PADDING_BYPASS_DEFAULT;
          cfg_data_identifier_data_type_q <= DATA_IDENTIFIER_DATA_TYPE_DEFAULT;
          cfg_data_identifier_virtual_channel_q <= DATA_IDENTIFIER_VIRTUAL_CHANNEL_DEFAULT;
          cfg_frame_period_value_us_q <= FRAME_PERIOD_VALUE_US_DEFAULT;
          cfg_packet_timeout_value_us_q <= PACKET_TIMEOUT_VALUE_US_DEFAULT;
          cfg_packet_size_value_q <= PACKET_SIZE_VALUE_DEFAULT;
          cfg_start_time_value_q <= START_TIME_VALUE_DEFAULT;
          cfg_start_frame_time_value_q <= START_FRAME_TIME_VALUE_DEFAULT;
          cfg_end_frame_time_value_q <= END_FRAME_TIME_VALUE_DEFAULT;
          cfg_inter_frame_time_value_q <= INTER_FRAME_TIME_VALUE_DEFAULT;
          cfg_inter_packet_time_value_q <= INTER_PACKET_TIME_VALUE_DEFAULT;
          cfg_features_padding_present_q <= FEATURES_PADDING_PRESENT_DEFAULT;
          cfg_features_fixed_frame_present_q <= FEATURES_FIXED_FRAME_PRESENT_DEFAULT;

          -- error signals
          read_addr_error_q     <= '0';
          write_addr_error_q     <= '0';
          
        else
          -- default value for signals
          axi_bresp   <= "00"; --need to work more on the responses
          axi_rresp   <= "00";
        
          -- Trigger Register (reset to default value every clock cycle)

        
          -- Register the inputs into the local signals

                    
          -- Reset clear flags

        
          -- implement axi_awready generation
          -- axi_awready is asserted for one s_axi_aclk clock cycle when both
          -- s_axi_awvalid and s_axi_wvalid are asserted. axi_awready is
          -- de-asserted when reset is low.
          if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and aw_en = '1') then
            -- slave is ready to accept write address when
            -- there is a valid write address and write data
            -- on the write address and data bus. this design 
            -- expects no outstanding transactions. 
            axi_awready <= '1';
            aw_en <= '0';
          elsif (s_axi_bready = '1' and axi_bvalid = '1') then
            aw_en <= '1';
            axi_awready <= '0';
          else
            axi_awready <= '0';
          end if; 
          
          -- implement axi_awaddr latching
          -- this process is used to latch the address when both 
          -- s_axi_awvalid and s_axi_wvalid are valid.  
          if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and aw_en = '1') then
            -- write address latching
            axi_awaddr <= s_axi_awaddr;
          end if;
          
          -- implement axi_wready generation
          -- axi_wready is asserted for one s_axi_aclk clock cycle when both
          -- s_axi_awvalid and s_axi_wvalid are asserted. axi_wready is 
          -- de-asserted when reset is low.         
          if (axi_wready = '0' and s_axi_wvalid = '1' and s_axi_awvalid = '1' and aw_en = '1') then
            -- slave is ready to accept write data when 
            -- there is a valid write address and write data
            -- on the write address and data bus. this design 
            -- expects no outstanding transactions.           
            axi_wready <= '1';
          else
            axi_wready <= '0';
          end if;
          
          -- implement memory mapped register select and write logic generation
          -- the write data is accepted and written to memory mapped registers when
          -- axi_awready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted. write strobes are used to
          -- select byte enables of slave registers while writing.
          -- these registers are cleared when reset (active low) is applied.
          -- slave register write enable is asserted when valid address and data are available
          -- and the slave is ready to accept the write address and write data.
          loc_addr := axi_awaddr(addr_lsb + opt_mem_addr_bits downto addr_lsb);
          if (slv_reg_wren = '1') then
            case loc_addr is
              when CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_control_enable_q <= S_AXI_WDATA(CONTROL_ENABLE_MSB downto CONTROL_ENABLE_LSB);
              when DATA_IDENTIFIER_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_data_identifier_data_type_q <= S_AXI_WDATA(DATA_IDENTIFIER_DATA_TYPE_MSB downto DATA_IDENTIFIER_DATA_TYPE_LSB);
              when FRAME_PERIOD_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_frame_period_value_us_q <= S_AXI_WDATA(FRAME_PERIOD_VALUE_US_MSB downto FRAME_PERIOD_VALUE_US_LSB);
              when PACKET_TIMEOUT_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_packet_timeout_value_us_q <= S_AXI_WDATA(PACKET_TIMEOUT_VALUE_US_MSB downto PACKET_TIMEOUT_VALUE_US_LSB);
              when PACKET_SIZE_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_packet_size_value_q <= S_AXI_WDATA(PACKET_SIZE_VALUE_MSB downto PACKET_SIZE_VALUE_LSB);
              when START_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_start_time_value_q <= S_AXI_WDATA(START_TIME_VALUE_MSB downto START_TIME_VALUE_LSB);
              when START_FRAME_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_start_frame_time_value_q <= S_AXI_WDATA(START_FRAME_TIME_VALUE_MSB downto START_FRAME_TIME_VALUE_LSB);
              when END_FRAME_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_end_frame_time_value_q <= S_AXI_WDATA(END_FRAME_TIME_VALUE_MSB downto END_FRAME_TIME_VALUE_LSB);
              when INTER_FRAME_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_inter_frame_time_value_q <= S_AXI_WDATA(INTER_FRAME_TIME_VALUE_MSB downto INTER_FRAME_TIME_VALUE_LSB);
              when INTER_PACKET_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_inter_packet_time_value_q <= S_AXI_WDATA(INTER_PACKET_TIME_VALUE_MSB downto INTER_PACKET_TIME_VALUE_LSB);

              when others =>
                -- unknown address
                write_addr_error_q <= '1';
                axi_bresp <= "10";  -- SLVERR
                axi_rdata  <= BUS_ADDR_ERROR_CODE; --error code on the read data bus (not aligned with valid signal)
                
                cfg_control_enable_q <= cfg_control_enable_q;
                cfg_control_enable_packet_timeout_q <= cfg_control_enable_packet_timeout_q;
                cfg_control_blocking_mode_q <= cfg_control_blocking_mode_q;
                cfg_control_padding_bypass_q <= cfg_control_padding_bypass_q;
                cfg_data_identifier_data_type_q <= cfg_data_identifier_data_type_q;
                cfg_data_identifier_virtual_channel_q <= cfg_data_identifier_virtual_channel_q;
                cfg_frame_period_value_us_q <= cfg_frame_period_value_us_q;
                cfg_packet_timeout_value_us_q <= cfg_packet_timeout_value_us_q;
                cfg_packet_size_value_q <= cfg_packet_size_value_q;
                cfg_start_time_value_q <= cfg_start_time_value_q;
                cfg_start_frame_time_value_q <= cfg_start_frame_time_value_q;
                cfg_end_frame_time_value_q <= cfg_end_frame_time_value_q;
                cfg_inter_frame_time_value_q <= cfg_inter_frame_time_value_q;
                cfg_inter_packet_time_value_q <= cfg_inter_packet_time_value_q;

            end case;
          end if;
          
          -- implement write response logic generation
          -- the write response and response valid signals are asserted by the slave 
          -- when axi_wready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted.  
          -- this marks the acceptance of address and indicates the status of 
          -- write transaction.
          if (axi_awready = '1' and s_axi_awvalid = '1' and axi_wready = '1' and s_axi_wvalid = '1' and axi_bvalid = '0'  ) then
            axi_bvalid <= '1';
            
            if (write_addr_error_q = '1') then
              axi_bresp  <= "10";  -- SLVERR
            end if;
          elsif (s_axi_bready = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
            axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
            write_addr_error_q <= '0';
          end if;
          
          -- implement axi_arready generation
          -- axi_arready is asserted for one s_axi_aclk clock cycle when
          -- s_axi_arvalid is asserted. axi_awready is 
          -- de-asserted when reset (active low) is asserted. 
          -- the read address is also latched when s_axi_arvalid is 
          -- asserted. axi_araddr is reset to zero on reset assertion.
          if (axi_arready = '0' and s_axi_arvalid = '1') then
            -- indicates that the slave has acceped the valid read address
            axi_arready <= '1';
            -- read address latching 
            axi_araddr  <= s_axi_araddr;           
          else
            axi_arready <= '0';
          end if;
          
          -- implement axi_arvalid generation
          -- axi_rvalid is asserted for one s_axi_aclk clock cycle when both 
          -- s_axi_arvalid and axi_arready are asserted. the slave registers 
          -- data are available on the axi_rdata bus at this instance. the 
          -- assertion of axi_rvalid marks the validity of read data on the 
          -- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
          -- is deasserted on reset (active low). axi_rresp and axi_rdata are 
          -- cleared to zero on reset (active low).  
          if (axi_arready = '1' and s_axi_arvalid = '1' and axi_rvalid = '0') then
            -- valid read data is available at the read data bus
            axi_rvalid <= '1';
            
            -- when there is a valid read address (s_axi_arvalid) with 
            -- acceptance of read address by the slave (axi_arready), 
            -- output the read dada 
            -- Read address mux
            loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
            case loc_addr is
              when CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(CONTROL_ENABLE_MSB downto CONTROL_ENABLE_LSB) <= cfg_control_enable_q;
                axi_rdata(CONTROL_ENABLE_PACKET_TIMEOUT_MSB downto CONTROL_ENABLE_PACKET_TIMEOUT_LSB) <= cfg_control_enable_packet_timeout_q;
                axi_rdata(CONTROL_BLOCKING_MODE_MSB downto CONTROL_BLOCKING_MODE_LSB) <= cfg_control_blocking_mode_q;
                axi_rdata(CONTROL_PADDING_BYPASS_MSB downto CONTROL_PADDING_BYPASS_LSB) <= cfg_control_padding_bypass_q;
              when DATA_IDENTIFIER_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(DATA_IDENTIFIER_DATA_TYPE_MSB downto DATA_IDENTIFIER_DATA_TYPE_LSB) <= cfg_data_identifier_data_type_q;
                axi_rdata(DATA_IDENTIFIER_VIRTUAL_CHANNEL_MSB downto DATA_IDENTIFIER_VIRTUAL_CHANNEL_LSB) <= cfg_data_identifier_virtual_channel_q;
              when FRAME_PERIOD_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(FRAME_PERIOD_VALUE_US_MSB downto FRAME_PERIOD_VALUE_US_LSB) <= cfg_frame_period_value_us_q;
              when PACKET_TIMEOUT_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(PACKET_TIMEOUT_VALUE_US_MSB downto PACKET_TIMEOUT_VALUE_US_LSB) <= cfg_packet_timeout_value_us_q;
              when PACKET_SIZE_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(PACKET_SIZE_VALUE_MSB downto PACKET_SIZE_VALUE_LSB) <= cfg_packet_size_value_q;
              when START_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(START_TIME_VALUE_MSB downto START_TIME_VALUE_LSB) <= cfg_start_time_value_q;
              when START_FRAME_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(START_FRAME_TIME_VALUE_MSB downto START_FRAME_TIME_VALUE_LSB) <= cfg_start_frame_time_value_q;
              when END_FRAME_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(END_FRAME_TIME_VALUE_MSB downto END_FRAME_TIME_VALUE_LSB) <= cfg_end_frame_time_value_q;
              when INTER_FRAME_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(INTER_FRAME_TIME_VALUE_MSB downto INTER_FRAME_TIME_VALUE_LSB) <= cfg_inter_frame_time_value_q;
              when INTER_PACKET_TIME_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(INTER_PACKET_TIME_VALUE_MSB downto INTER_PACKET_TIME_VALUE_LSB) <= cfg_inter_packet_time_value_q;
              when FEATURES_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(FEATURES_PADDING_PRESENT_MSB downto FEATURES_PADDING_PRESENT_LSB) <= cfg_features_padding_present_q;
                axi_rdata(FEATURES_FIXED_FRAME_PRESENT_MSB downto FEATURES_FIXED_FRAME_PRESENT_LSB) <= cfg_features_fixed_frame_present_q;

              when others =>
                -- unknown address
                axi_rdata  <= BUS_ADDR_ERROR_CODE;
                read_addr_error_q <= '1';
                axi_rresp <= "10";  -- SLVERR
            end case; 
          
            if (read_addr_error_q = '1') then
              axi_rresp  <= "10";  -- SLVERR
            end if;
          elsif (axi_rvalid = '1' and s_axi_rready = '1') then
            -- Read data is accepted by the master
            axi_rvalid <= '0';
            read_addr_error_q <= '0';
          end if;  
        end if;
      end if;
    end process;

end arch_imp;
