----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       ROBIN Ladislas (lrobin@prophesee.ai)
--
-- Create Date:    Aug. 7, 2023
-- Design Name:    axi_lite_master_bfm
-- Module Name:    axi_lite_master_bfm
-- Project Name:   axi_lite_master_bfm
-- Target Devices:
-- Tool versions:  Xilinx Vivado 2022.2.1
-- Description:    AXI Lite Master BFM
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

use work.ccam_utils.all;

entity axi_lite_master_bfm is
  generic (
    BUS_ADDR_WIDTH_G : positive := 32;
    BUS_DATA_WIDTH_G : positive := 32;
    PATTERN_FILE_G   : string   := "axil_bfm_file.pat";
    USE_TASK_CTL_G   : boolean  := false;
    WHOIAM_G         : string   := "ICN Master BFM"
  );
  port (
    -- Clock and Reset
    clk              : in  std_logic;
    rst              : in  std_logic;

    -- BFM Control Interface
    bfm_run_step_i   : in  std_logic;
    bfm_busy_o       : out std_logic;
    bfm_end_o        : out std_logic;

    -- AXI4-Lite Master Interface
    axil_m_araddr_o  : out std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
    axil_m_arprot_o  : out std_logic_vector(2 downto 0);
    axil_m_arready_i : in  std_logic;
    axil_m_arvalid_o : out std_logic;
    axil_m_rready_o  : out std_logic;
    axil_m_rresp_i   : in  std_logic_vector(1 downto 0);
    axil_m_rvalid_i  : in  std_logic;
    axil_m_bready_o  : out std_logic;
    axil_m_bresp_i   : in  std_logic_vector(1 downto 0);
    axil_m_bvalid_i  : in  std_logic;
    axil_m_rdata_i   : in  std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
    axil_m_awaddr_o  : out std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
    axil_m_awprot_o  : out std_logic_vector(2 downto 0);
    axil_m_awready_i : in  std_logic;
    axil_m_awvalid_o : out std_logic;
    axil_m_wdata_o   : out std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
    axil_m_wready_i  : in  std_logic;
    axil_m_wstrb_o   : out std_logic_vector(3 downto 0);
    axil_m_wvalid_o  : out std_logic
  );
end axi_lite_master_bfm;

architecture sim of axi_lite_master_bfm is


  -----------------------
  -- Type Declarations --
  -----------------------

  type file_state_t is (START_OF_FILE, FILE_OPENED, END_OF_FILE);
  signal file_state_s : file_state_t;

  -- AXI Protected Type Record
  type axi_prot_t is record
    privileged_access_f  : std_logic; -- AxPROT[2]: (1 => Privileged Access,  0 => Unprivileged Access)
    non_secure_access_f  : std_logic; -- AxPROT[1]: (1 => Non-Secure Access,  0 => Secure Access      )
    instruction_access_f : std_logic; -- AxPROT[0]: (1 => Instruction Access, 0 => Data Access        )
  end record axi_prot_t;

  subtype axi_prot_data_t is std_logic_vector(2 downto 0);

   -- Converts AXI Protection std_logic_vector-based data type to record type
  function to_axi_prot_data_t(axi_prot_v : axi_prot_t) return axi_prot_data_t is
    variable axi_prot_data_v : axi_prot_data_t;
    variable i_v             : integer;
  begin
    axi_prot_data_v := (others => 'U');
    i_v := 0;
    pack(axi_prot_data_v, i_v, axi_prot_v.instruction_access_f);
    pack(axi_prot_data_v, i_v, axi_prot_v.non_secure_access_f);
    pack(axi_prot_data_v, i_v, axi_prot_v.privileged_access_f);
    return axi_prot_data_v;
  end function to_axi_prot_data_t;

  -- Converts AXI Protection record type to std_logic_vector-based data type
  function to_axi_prot_t(axi_prot_data_v : axi_prot_data_t) return axi_prot_t is
    variable axi_prot_v : axi_prot_t;
    variable i_v        : integer;
  begin
    i_v := 0;
    unpack(axi_prot_data_v, i_v, axi_prot_v.instruction_access_f);
    unpack(axi_prot_data_v, i_v, axi_prot_v.non_secure_access_f);
    unpack(axi_prot_data_v, i_v, axi_prot_v.privileged_access_f);
    return axi_prot_v;
  end function to_axi_prot_t;

  ---------------------------
  -- Constant Declarations --
  ---------------------------
  constant PATTERN_FILE_C   : string  := iff(PATTERN_FILE_G="NULL", "", PATTERN_FILE_G);
  
  -- AXIL_M_AWPROT protection: (0: Data access, 1: Non-secure access, 0: Unprivileged access)
  constant AXIL_M_AWPROT_C      : axi_prot_t      := (privileged_access_f  => '0',
                                                      non_secure_access_f  => '1',
                                                      instruction_access_f => '0');
  constant AXIL_M_AWPROT_DATA_C : axi_prot_data_t := to_axi_prot_data_t(AXIL_M_AWPROT_C);

  -- AXIL_M_ARPROT protection: (0: Data access, 1: Non-secure access, 0: Unprivileged access)
  constant AXIL_M_ARPROT_C      : axi_prot_t      := (privileged_access_f  => '0',
                                                      non_secure_access_f  => '1',
                                                      instruction_access_f => '0');
  constant AXIL_M_ARPROT_DATA_C : axi_prot_data_t := to_axi_prot_data_t(AXIL_M_ARPROT_C);

  -------------------------
  -- Signal Declarations --
  -------------------------

  signal bfm_busy_s       : std_logic;
  signal bfm_end_s        : std_logic;
  signal end_of_pattern_s : std_logic;
  
  -- AXI4-Lite internal signals
  signal axil_m_araddr_s  : std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
  signal axil_m_arprot_s  : std_logic_vector(2 downto 0);
  signal axil_m_arvalid_s : std_logic;
  signal axil_m_rready_s  : std_logic;
  signal axil_m_bready_s  : std_logic;
  signal axil_m_awaddr_s  : std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
  signal axil_m_awprot_s  : std_logic_vector(2 downto 0);
  signal axil_m_awvalid_s : std_logic;
  signal axil_m_wdata_s   : std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
  signal axil_m_wstrb_s   : std_logic_vector(3 downto 0);
  signal axil_m_wvalid_s  : std_logic;

  signal check_mask_s     : std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
  signal halt_s           : integer;
  signal time_s           : integer;
  signal ready_addr_done  : std_logic;
  signal ready_data_done  : std_logic;
  signal resp_data_done   : std_logic;

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  bfm_busy_o       <= bfm_busy_s;
  bfm_end_o        <= bfm_end_s;
  
  axil_m_araddr_o  <= axil_m_araddr_s ;
  axil_m_arprot_o  <= axil_m_arprot_s ;
  axil_m_arvalid_o <= axil_m_arvalid_s;
  axil_m_rready_o  <= axil_m_rready_s ;
  axil_m_bready_o  <= axil_m_bready_s ;
  axil_m_awaddr_o  <= axil_m_awaddr_s ;
  axil_m_awprot_o  <= axil_m_awprot_s ;
  axil_m_awvalid_o <= axil_m_awvalid_s;
  axil_m_wdata_o   <= axil_m_wdata_s  ;
  axil_m_wstrb_o   <= axil_m_wstrb_s  ;
  axil_m_wvalid_o  <= axil_m_wvalid_s ;

  ---------------
  -- Processes --
  ---------------

  main : process
    variable address_v     : std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
    variable char_v        : character;
    variable cmd_v         : character;
    variable data_v        : std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
    variable check_mask_v  : std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
    variable halt_v        : integer;
    variable line_v        : line;
    variable line_idx_v    : integer;
    variable msg_v         : line;
    variable out_line_v    : line;
    variable time_v        : integer;

    -- Auxiliary variables for reading files
    file     file_v        : text;
    variable file_path_v   : string(PATTERN_FILE_C'low to PATTERN_FILE_C'high) := PATTERN_FILE_C;
    variable file_status_v : file_open_status;
    variable file_state_v  : file_state_t;
    variable print_line_v  : line;
    
  begin
  
    end_of_pattern_s <= '0';
    bfm_busy_s       <= '0';
    bfm_end_s        <= '0';
    
    -- read address
    axil_m_araddr_s  <= (others => '0');
    axil_m_arprot_s  <= AXIL_M_ARPROT_DATA_C;
    axil_m_arvalid_s <= '0';
    
    -- ready for read/write responses
    axil_m_rready_s  <= '0';
    axil_m_bready_s  <= '0';
    
    -- write address
    axil_m_awaddr_s  <= (others => '0');
    axil_m_awprot_s  <= AXIL_M_AWPROT_DATA_C;
    axil_m_awvalid_s <= '0';
    
    -- write data
    axil_m_wdata_s   <= (others => '0');
    axil_m_wstrb_s   <= (others => '0');
    axil_m_wvalid_s  <= '0';
    
    check_mask_s     <= (others => '1');
    halt_s           <= 0;
    time_s           <= 0;
    ready_addr_done  <= '0';
    ready_data_done  <= '0';
    resp_data_done   <= '0'; 

    file_state_v := START_OF_FILE;

    -- If the file has not yet been opened, open file.
    if (file_state_v = START_OF_FILE) then
      file_open(file_status_v, file_v, file_path_v, READ_MODE);

      if (file_status_v /= OPEN_OK) then
        if (file_path_v = "") then
          write(print_line_v, WHOIAM_G & string'(": File name is empty. No data will be processed."));
          writeline(output, print_line_v);
          file_state_v := END_OF_FILE;
        else
          write(print_line_v, WHOIAM_G & string'(": File '") & file_path_v & string'("' not found."));
          writeline(output, print_line_v);
          report "End of Simulation." severity failure;
        end if;
      else
        write(print_line_v, WHOIAM_G & string'(": File '") & file_path_v & string'("' opened successfully."));
        writeline(output, print_line_v);
        file_state_v := FILE_OPENED;
      end if;
    end if;

    -- Wait for Reset to complete
    if (rst /= '1') then
      wait until rst = '1';
    end if;
    wait until rst = '0';

    line_idx_v := 0;

    while ((file_state_v = FILE_OPENED) and (not endfile(file_v)) and (end_of_pattern_s = '0')) loop

      -- If not busy wait for external triggers
      if ((bfm_busy_s = '0') and USE_TASK_CTL_G) then
        if (bfm_run_step_i = '0') then
          wait until bfm_run_step_i = '1';
        end if;

        -- BFM busy
        bfm_busy_s <= '1';

        if (bfm_run_step_i = '1') then
          wait until bfm_run_step_i = '0';
        end if;
      end if;

      -- Read digital data from input file
      -- Event time base reading
      readline(file_v, line_v);
      line_idx_v := line_idx_v + 1;

      -- Read command
      read(line_v, cmd_v);

      -- Decode Command
      case cmd_v is

      -- Synchronization Command
      when 'S' =>
        -- Synchronisation step waiting run step from tb
        bfm_busy_s <= '0';

      -- Comment Command
      when 'C' =>
        -- printing commumicatio/debug message
        write(out_line_v, string'("ICN Master BFM: "));
        while ((line_v /= NULL) and (line_v'length > 0)) loop
          read(line_v, char_v);
          write(out_line_v, char_v);
        end loop;
        writeline(output, out_line_v);

      -- End of File Command
      when 'E' =>
        end_of_pattern_s <= '1';
        bfm_busy_s       <= '0';
        file_state_v     := END_OF_FILE;

        if not USE_TASK_CTL_G then
          assert false report "End of Test with Success" severity failure;
        end if;

      -- Read or Write Commands
      when 'R'| 'W' =>
        hread(line_v, address_v);
        hread(line_v, data_v);  

        -- Manage Delay Patfile Attribute
        time_v := 0;
        if (line_v'length > 0) then
          read(line_v, time_v); -- Delay
        end if;
        time_s <= time_v;

        -- Manage Halt Patfile Attribute
        halt_v := 0;
        if (line_v'length > 0) then
          read(line_v, halt_v);
        end if;
        halt_s <= halt_v;

        -- For read get CheckMask attribute
        check_mask_v := (others => '1');
        if (cmd_v = 'R') then
          if (line_v'length > 0) then
            hread(line_v, check_mask_v);
          end if;
        end if;
        check_mask_s <= check_mask_v;

        -- Apply Delay Patfile Attribute
        while (time_v > 0) loop
          wait until rising_edge(clk);
          time_v := time_v - 1;
          time_s <= time_v;
        end loop;

        wait until rising_edge(clk);
        
        -- Write procedure
        -- Addr and Data are sent at the same time, waiting for ready to close transaction
        -- Response ready is up at the same time, waiting for valid from bus
        if (cmd_v = 'W') then 

          axil_m_awaddr_s  <= address_v;
          axil_m_wdata_s   <= data_v;
          -- WSTRB : full bytes asserted, no byte masking
          axil_m_wstrb_s   <= (others => '1');
          
          axil_m_awvalid_s <= '1';
          axil_m_wvalid_s  <= '1';
          
          -- ready for response
          axil_m_bready_s  <= '1';
          
          -- Wait for Address and Data handshake by AXI Lite slave
          while (ready_addr_done = '0' or ready_data_done = '0' or resp_data_done = '0') loop
          
            wait until rising_edge(clk);
            if (axil_m_awready_i = '1' and axil_m_awvalid_s = '1') then
              ready_addr_done  <= '1';
              axil_m_awvalid_s <= '0';
            end if;
            
            if (axil_m_wready_i = '1' and axil_m_wvalid_s = '1') then
              ready_data_done  <= '1';
              axil_m_wvalid_s  <= '0';
            end if;    
            
            if (axil_m_bvalid_i = '1' and axil_m_bready_s = '1') then
            
              write(msg_v, string'("ICN Master BFM:  Write Response 0x"));
              hwrite(msg_v, axil_m_bresp_i);
              writeline(output, msg_v);
          
              resp_data_done   <= '1';
              axil_m_bready_s  <= '0';
            end if;
          end loop; 
          
          ready_addr_done  <= '0';
          ready_data_done  <= '0';
          resp_data_done   <= '0';    
        end if;
        
        -- Read procedure
        -- Addr is sent valid, waiting for a ready from slave to close address transation
        -- Read response is ready at the same time, waiting for valid data
        if (cmd_v = 'R') then
          axil_m_araddr_s  <= address_v;  
          axil_m_arvalid_s <= '1';
          
          -- ready for response
          axil_m_rready_s  <= '1';
          
          wait until (axil_m_arready_i = '1');                  
          wait until rising_edge(clk);
          axil_m_arvalid_s <= '0';  
          
          wait until (axil_m_rvalid_i = '1');
          -- Read Response and Read Data are valid
          if ( (data_v and check_mask_v) /= (axil_m_rdata_i and check_mask_v) ) then
            write(msg_v, string'("ICN Master BFM: Error line "));
            write(msg_v, line_idx_v);
            write(msg_v, string'(", output read differs from expected: @0x"));
            hwrite(msg_v, address_v);
  
            write(msg_v, string'(" => 0x"));
            hwrite(msg_v, axil_m_rdata_i and check_mask_v);
            write(msg_v, string'(" /= 0x"));
            hwrite(msg_v, data_v and check_mask_v);
  
            write(msg_v, string'(" (check_mask: "));
            hwrite(msg_v, check_mask_v);
            write(msg_v, string'(",read_data: "));
            hwrite(msg_v, axil_m_rdata_i);
            write(msg_v, string'(", exp_data: "));
            hwrite(msg_v, data_v);
            write(msg_v, string'(")"));
  
            writeline(output, msg_v);
            assert false report "ICN Master BFM, Output Error during simulation" severity failure;
          end if;
          
          write(msg_v, string'("ICN Master BFM:  Read Response 0x"));
          hwrite(msg_v, axil_m_rresp_i);  
          writeline(output, msg_v);        
          
          wait until rising_edge(clk);
          axil_m_rready_s  <= '0';
        end if;

        -- Apply Halt Patfile Attribute
        while (halt_v > 0) loop
          wait until rising_edge(clk);
          halt_v := halt_v - 1;
          halt_s <= halt_v;
        end loop;

      -- Unknown Command
      when others =>
        -- Skip
        null;

      end case; -- End of Command Decoding

      wait until rising_edge(clk);
    end loop;

    bfm_end_s <= '1';
    wait;
  end process;


end sim;
