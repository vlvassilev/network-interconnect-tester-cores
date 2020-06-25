-- This module provides the common synchronization and reset signaling
-- logic and is closely based
-- on the example provided by Xilinx as part of the gig_ethernet_pcs_pma
-- IP core part of Vivado 2019.2

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;
library unisim;
    use unisim.vcomponents.all;
library xil_defaultlib;

entity gig_ethernet_pcs_pma_clock_reset is
    generic (
        example_simulation          : integer   := 0 ;      
        c_iobank                    : integer := 44
    );
    port (
        clockin             : in std_logic;
        clockin_se_out      : out std_logic; 
        resetin             : in std_logic;
        tx_dly_rdy          : in std_logic;
        tx_vtc_rdy          : in std_logic;
        tx_bsc_envtc       : out std_logic;
        tx_bs_envtc        : out std_logic;
        rx_dly_rdy          : in std_logic;
        rx_vtc_rdy          : in std_logic;
        rx_bsc_envtc       : out std_logic;
        rx_bs_envtc        : out std_logic;
        --
        tx_sysclk           : out std_logic;    --  156.25 mhz
        tx_wrclk            : out std_logic;    --  125.00 mhz
        tx_clkoutphy        : out std_logic;    -- 1250.00 mhz
        rx_sysclk           : out std_logic;    --  312.50 mhz
        rx_riuclk           : out std_logic;    --  156.25 mhz
        rx_clkoutphy        : out std_logic;    --  625.00 mhz
        --
        tx_locked           : out std_logic;
        tx_bs_rstdly        : out std_logic;
        tx_bs_rst           : out std_logic;
        tx_bsc_rst          : out std_logic;
        tx_logicrst         : out std_logic;
        rx_locked           : out std_logic;
        rx_bs_rstdly        : out std_logic;
        rx_bs_rst           : out std_logic;
        rx_bsc_rst          : out std_logic;
        rx_logicrst         : out std_logic;
        --
        riu_addr            : out std_logic_vector(5 downto 0);
        riu_wrdata          : out std_logic_vector(15 downto 0);
        riu_wr_en           : out std_logic;
        riu_nibble_sel      : out std_logic_vector(1 downto 0);
        riu_rddata_3        : in std_logic_vector(15 downto 0);
        riu_valid_3         : in std_logic;
        riu_prsnt_3         : in std_logic;
        riu_rddata_2        : in std_logic_vector(15 downto 0);
        riu_valid_2         : in std_logic;
        riu_prsnt_2         : in std_logic;
        riu_rddata_1        : in std_logic_vector(15 downto 0);
        riu_valid_1         : in std_logic;
        riu_prsnt_1         : in std_logic;
        riu_rddata_0        : in std_logic_vector(15 downto 0);
        riu_valid_0         : in std_logic;
        riu_prsnt_0         : in std_logic;
        --
        rx_btval_3          : out std_logic_vector(8 downto 0);
        rx_btval_2          : out std_logic_vector(8 downto 0);
        rx_btval_1          : out std_logic_vector(8 downto 0);
        rx_btval_0          : out std_logic_vector(8 downto 0);
        --
        debug_out           : out std_logic_vector(7 downto 0) 
    );
end gig_ethernet_pcs_pma_clock_reset;

architecture clock_reset_arch of gig_ethernet_pcs_pma_clock_reset is
constant low  : std_logic	:= '0';
constant lowvec : std_logic_vector(15 downto 0) := x"0000";
constant high : std_logic	:= '1';
   function int_to_bool (
      int_value : integer)
      return boolean is
      variable bool_value : boolean;
   begin
         if int_value = 1 then
            bool_value := true;
         else
            bool_value := false;
         end if;
      return bool_value;
   end int_to_bool;
constant in_simulation : boolean := false or int_to_bool(example_simulation)
--synthesis translate_off
                                    or true
--synthesis translate_on
;
   
component gig_ethernet_pcs_pma_reset_sync_ex

port (
   reset_in             : in  std_logic;
   clk                  : in  std_logic;
   reset_out            : out std_logic
);
end component;

signal inttx_fdbckclkin         : std_logic;
signal inttx_fdbckclkout        : std_logic;
signal inttx_clkout0            : std_logic;
signal inttx_clkout1            : std_logic;
signal inttx_locked             : std_logic;
signal inttx_sysclk             : std_logic;
signal inttx_wrclk              : std_logic;
signal inttx_dlyseqclk          : std_logic;
signal intrx_fdbckclkin         : std_logic;
signal intrx_fdbckclkout        : std_logic;
signal intrx_clkout0            : std_logic;
signal intrx_clkout1            : std_logic;
signal intrx_locked             : std_logic;
signal intrx_sysclk             : std_logic;
signal intrx_riuclk             : std_logic;
signal intrx_dlyseqclk          : std_logic;
signal inttx_dlyvtc_rdy         : std_logic;
signal intrx_dlyvtc_rdy         : std_logic;
signal inttx_enaclkbufs         : std_logic;
signal intrx_enaclkbufs         : std_logic;
signal inttx_logicrst           : std_logic;
signal intrx_logicrst           : std_logic;
--
signal intrx_dlyfivout          : std_logic;
signal inttx_dlyfivout          : std_logic;
--
signal intctrl_clk              : std_logic;
signal intctrl_state            : integer range 0 to 511 := 0;
signal intctrl_reset            : std_logic;
signal intctrl_txlocked         : std_logic_vector(1 downto 0);
signal intctrl_txdlyrdy         : std_logic_vector(1 downto 0);
signal intctrl_txvtcrdy         : std_logic_vector(1 downto 0);
signal intctrl_txpllrst         : std_logic;
signal intctrl_txpllclkoutphyen : std_logic;
signal intctrl_txlogicrst       : std_logic;
signal intctrl_rxlocked         : std_logic_vector(1 downto 0);
signal intctrl_rxdlyrdy         : std_logic_vector(1 downto 0);
signal intctrl_rxvtcrdy         : std_logic_vector(1 downto 0);
signal intctrl_rxpllrst         : std_logic;
signal intctrl_rxpllclkoutphyen : std_logic;
signal intctrl_rxlogicrst       : std_logic;

attribute async_reg : string;
    attribute async_reg of intctrl_txlocked  : signal is "true";
    attribute async_reg of intctrl_txdlyrdy  : signal is "true";
    attribute async_reg of intctrl_txvtcrdy  : signal is "true";
    attribute async_reg of intctrl_rxlocked  : signal is "true";
    attribute async_reg of intctrl_rxdlyrdy  : signal is "true";
    attribute async_reg of intctrl_rxvtcrdy  : signal is "true";
attribute dont_touch : string;
    attribute dont_touch of clock_reset_arch : architecture is "yes";
begin


bufg_ctrlclk : bufgce_div
    generic map (bufgce_divide => 4, is_ce_inverted => '0', is_i_inverted  => '0', is_clr_inverted => '0')
    port map (i => clockin, ce => '1', clr => '0', o  => intctrl_clk);

clk_rst_i_plle3_tx : plle3_adv
    generic map (
        clkfbout_phase      => 0.000,       -- real
        clkfbout_mult       => 2,          
        clkin_period        => 1.60,        -- real  
        clkoutphy_mode      => "vco",       -- string 
        clkout0_divide      => 8,           -- integer 
        clkout1_divide      => 10,          -- integer
        divclk_divide       => 1,           -- integer
        
        clkout0_duty_cycle  => 0.500,       -- real
        clkout0_phase       => 0.000,       -- real   
        clkout1_duty_cycle  => 0.500,       -- real
        clkout1_phase       => 0.000,       -- real

        compensation        => "auto",      -- string 
        is_clkfbin_inverted => '0',         -- std_ulogic
        is_clkin_inverted   => '0',         -- std_ulogic
        is_pwrdwn_inverted  => '0',         -- std_ulogic
        is_rst_inverted     => '0',         -- std_ulogic
        ref_jitter          => 0.010,       -- real
        startup_wait        => "false"      -- string
    )
    port map (
        clkin       => clockin, -- in 
        clkfbin     => inttx_fdbckclkin, -- in 
        rst         => intctrl_txpllrst, -- in 
        pwrdwn      => low, -- in 
        clkoutphyen => intctrl_txpllclkoutphyen, -- in 
        clkfbout    => inttx_fdbckclkout, -- out
        clkout0     => inttx_clkout0, -- out
        clkout0b    => open, -- out
        clkout1     => inttx_clkout1, -- out
        clkout1b    => open, -- out
        clkoutphy   => tx_clkoutphy, -- out
        dclk        => low, -- in 
        di          => lowvec(15 downto 0), -- in [15:0]        
        daddr       => lowvec(6 downto 0), -- in [6:0]
        den         => low, -- in 
        dwe         => low, -- in 
        do          => open, -- out [15:0]
        drdy        => open, -- out
        locked      => inttx_locked -- out
    );

inttx_fdbckclkin <= inttx_fdbckclkout;

clk_rst_i_bufg_txsysclk : bufgce
    generic map (ce_type => "sync", is_ce_inverted => '0', is_i_inverted  => '0')
    port map (i => inttx_clkout0, ce => inttx_locked, o  => inttx_sysclk);
clk_rst_i_bufg_txwrclk : bufgce
    generic map (ce_type => "sync", is_ce_inverted => '0', is_i_inverted  => '0')
    port map (i => inttx_clkout1, ce => inttx_locked, o  => inttx_wrclk);

tx_sysclk         <= inttx_sysclk;
tx_wrclk          <= inttx_wrclk;
tx_locked         <= inttx_locked;

clk_rst_i_plle3_rx : plle3_adv
    generic map (
        clkfbout_phase      => 0.000,       -- real
        clkout0_duty_cycle  => 0.500,       -- real
        clkout0_phase       => 0.000,       -- real
        clkout1_duty_cycle  => 0.500,       -- real
        clkout1_phase       => 0.000,       -- real
        clkin_period        => 1.60,        -- real    
        clkfbout_mult       => 2,           -- integer 
        clkoutphy_mode      => "vco_half",  -- string 
        clkout0_divide      => 4,           -- integer
        clkout1_divide      => 8,           -- integer
        divclk_divide       => 1,           -- integer
        
        
        compensation        => "auto",      -- string 
        is_clkfbin_inverted => '0',         -- std_ulogic
        is_clkin_inverted   => '0',         -- std_ulogic
        is_pwrdwn_inverted  => '0',         -- std_ulogic
        is_rst_inverted     => '0',         -- std_ulogic
        ref_jitter          => 0.010,       -- real
        startup_wait        => "false"      -- string
    )
    port map (
        clkin       => clockin, -- in 
        clkfbin     => intrx_fdbckclkin, -- in 
        rst         => resetin, -- in 
        pwrdwn      => low, -- in 
        clkoutphyen => intctrl_rxpllclkoutphyen, -- in 
        clkfbout    => intrx_fdbckclkout, -- out
        clkout0     => intrx_clkout0, -- out
        clkout0b    => open, -- out
        clkout1     => intrx_clkout1, -- out
        clkout1b    => open, -- out
        clkoutphy   => rx_clkoutphy, -- out
        dclk        => low, -- in 
        di          => lowvec(15 downto 0), -- in [15:0]        
        daddr       => lowvec(6 downto 0), -- in [6:0]
        den         => low, -- in 
        dwe         => low, -- in 
        do          => open, -- out [15:0]
        drdy        => open, -- out
        locked      => intrx_locked -- out
    );

intrx_fdbckclkin  <= intrx_fdbckclkout;
clockin_se_out    <= clockin;

clk_rst_i_bufg_rxsysclk : bufgce
    generic map (ce_type => "sync", is_ce_inverted => '0', is_i_inverted  => '0')
    port map (i => intrx_clkout0, ce => intrx_locked, o  => intrx_sysclk);

rx_sysclk         <= intrx_sysclk;
rx_riuclk         <= intctrl_clk;
rx_locked         <= intrx_locked;

   
reset_sync_tx_cdc_rst : gig_ethernet_pcs_pma_reset_sync_ex
port map(
   clk               => inttx_wrclk,
   reset_in          => intctrl_txlogicrst,
   reset_out         => inttx_logicrst 
);
tx_logicrst <= inttx_logicrst;

   
reset_sync_rx_cdc_rst : gig_ethernet_pcs_pma_reset_sync_ex
port map(
   clk               => intrx_sysclk,
   reset_in          => intctrl_rxlogicrst,
   reset_out         => intrx_logicrst 
);
rx_logicrst <= intrx_logicrst;
   
reset_sync_ctrl_rst : gig_ethernet_pcs_pma_reset_sync_ex
port map(
   clk               => intctrl_clk,
   reset_in          => resetin,
   reset_out         => intctrl_reset 
);
ctrl_cdc_gen : process (intctrl_clk)
begin
    if (rising_edge(intctrl_clk)) then
        intctrl_txlocked(1 downto 0) <= (intctrl_txlocked(0 downto 0) & inttx_locked);
        intctrl_txdlyrdy(1 downto 0) <= (intctrl_txdlyrdy(0 downto 0) & tx_dly_rdy);
        intctrl_txvtcrdy(1 downto 0) <= (intctrl_txvtcrdy(0 downto 0) & tx_vtc_rdy);
        intctrl_rxlocked(1 downto 0) <= (intctrl_rxlocked(0 downto 0) & intrx_locked);
        intctrl_rxdlyrdy(1 downto 0) <= (intctrl_rxdlyrdy(0 downto 0) & rx_dly_rdy);
        intctrl_rxvtcrdy(1 downto 0) <= (intctrl_rxvtcrdy(0 downto 0) & rx_vtc_rdy);
    end if;
end process;

ctrl_sm : process (intctrl_clk)
begin
   if (rising_edge(intctrl_clk)) then
      if (intctrl_reset = '1') then
         intctrl_state  <= 0;
         --
         riu_addr         <= "000000";
         riu_wrdata       <=x"0000";
         riu_wr_en        <= '0';
         riu_nibble_sel   <= "00";
         --
         tx_bsc_envtc     <= '0';
         tx_bsc_rst       <= '1';
         tx_bs_envtc      <= '1';
         tx_bs_rstdly     <= '1';
         tx_bs_rst        <= '1';
         intctrl_txlogicrst       <= '1';
         intctrl_txpllclkoutphyen <= '0';
         intctrl_txpllrst <= '0';
         --
         rx_bsc_envtc     <= '0';
         rx_bsc_rst       <= '1';
         rx_bs_envtc      <= '1';
         rx_bs_rstdly     <= '1';
         rx_bs_rst        <= '1';
         intctrl_rxlogicrst       <= '1';
         intctrl_rxpllclkoutphyen <= '0';
         intctrl_rxpllrst <= '0';
         --
         rx_btval_3     <= (others => '0');
         rx_btval_2     <= (others => '0');
         rx_btval_1     <= (others => '0');
         rx_btval_0     <= (others => '0');
      else 
         case (intctrl_state) is
            when  0 =>    -- reset seq step 1
                 tx_bs_envtc <= '1';
                 rx_bs_envtc <= '1';
                 intctrl_state <= intctrl_state + 1;
            when  4 =>    -- reset seq step 2
                 -- bitslice_control.self_calibrate = enable
                 intctrl_state <= intctrl_state + 1;
            when  8 =>    -- reset seq step 3  
                 intctrl_txpllrst   <= '1';
                 intctrl_rxpllrst   <= '1';
                 intctrl_state <= intctrl_state + 1;
            when 16 =>    -- reset seq step 4
                 tx_bs_rst    <= '1';
                 tx_bs_rstdly <= '1';
                 tx_bsc_rst   <= '1';
                 rx_bs_rst    <= '1';
                 rx_bs_rstdly <= '1';
                 rx_bsc_rst   <= '1';
                 intctrl_state <= intctrl_state + 1;
            when 20 =>    -- reset seq step 5/6
                 intctrl_txpllrst   <= '0';
                 intctrl_rxpllrst   <= '0';
                 intctrl_state <= intctrl_state + 1;
            when 24 =>    -- reset seq step 7
                 if (intctrl_txlocked(1) = '1' and intctrl_rxlocked(1) = '1') then
                    intctrl_state <= intctrl_state + 1;
                 end if;
            when 56 =>     -- reset seq step  8 -- wait 32 cycles
                 tx_bs_rstdly <= '0';
                 rx_bs_rstdly <= '0';
                 intctrl_state <= intctrl_state + 1;
            when 60 =>     -- reset seq step  8 -- wait  4 cycles
                 tx_bs_rst   <= '0';
                 rx_bs_rst   <= '0';
                 intctrl_state <= intctrl_state + 1;
            when 64 =>     -- reset seq step  8 -- wait  4 cycles
                 tx_bsc_rst  <= '0';
                 rx_bsc_rst  <= '0';
                 intctrl_state <= intctrl_state + 1;
            when 128 =>    -- reset seq step  9 -- wait 64 cycles
                 intctrl_txpllclkoutphyen <= '1';
                 intctrl_rxpllclkoutphyen <= '1';
                 intctrl_state <= intctrl_state + 1;
            when 172 =>    -- post reset seq step 1 -- wait 64 cycles
                 if (intctrl_txdlyrdy(1) = '1' and intctrl_rxdlyrdy(1) = '1' ) then 
                   tx_bsc_envtc <= '1';
                   rx_bsc_envtc <= '0';
                   intctrl_state<= intctrl_state + 1;
                 end if;
            when 176 =>    -- post reset seq step 3 -- wait 4 cycles
                 if (intctrl_txvtcrdy(1) = '1') then 
                   intctrl_state<= intctrl_state + 1;
                 end if;
            when 180 =>    -- post reset seq step   -- wait 4 cycles
                 riu_addr       <= "000010"; -- addr 0x02 - calib_ctrl
                 riu_wrdata     <=x"0000";
                 riu_wr_en      <= '0'; -- don't write
                 riu_nibble_sel <= "01";
                 intctrl_txlogicrst <= '0';
                 intctrl_state <= intctrl_state + 1;
            when 181 =>    -- bisc read calibration register
                 riu_addr       <= "000010"; -- addr 0x02 - calib_ctrl
                 riu_wrdata     <=x"0000";
                 riu_wr_en      <= '0'; -- don't write
                 riu_nibble_sel <= "01";
                 --
                 -- wait for fixdly_rdy
                 --
                 if ((riu_rddata_3(11) = '1' or riu_prsnt_3 = '0') and (riu_rddata_2(11) = '1' or riu_prsnt_2 = '0') and 
                     (riu_rddata_1(11) = '1' or riu_prsnt_1 = '0') and (riu_rddata_0(11) = '1' or riu_prsnt_0 = '0')) then
                     rx_bsc_envtc  <= '0';
                     rx_bs_envtc   <= '0';
                     intctrl_state <= intctrl_state + 1;
                 end if;
            when 182 =>    -- bisc write to debug index          
                 riu_addr       <= "111000"; -- addr 0x38 - dbg_rw_index
                 riu_wrdata     <=x"000c";  -- write=0, read=12
                 riu_wr_en      <= '1';
                 riu_nibble_sel <= "01";
                 intctrl_state  <= intctrl_state + 1;
            when 186 =>    -- bisc wait 4 cyles then pre-read halft_dqsm data
                 riu_addr       <= "111001"; -- addr 0x39 - dbg_rd_status
                 riu_wrdata     <=x"0000";   -- 8'h00, 8'h00
                 riu_wr_en      <= '0';
                 riu_nibble_sel <= "01";
                 intctrl_state  <= intctrl_state + 1;
            when 187 =>    -- bisc read data and wait for valid halft_dqsm data
                 riu_addr       <= "111001"; -- addr 0x39 - dbg_rd_status
                 riu_wrdata     <=x"0000";   -- 8'h00, 8'h00
                 riu_wr_en      <= '0';
                 riu_nibble_sel <= "01";
                 if ((riu_rddata_3 /= "00000000000" or riu_prsnt_3 = '0') and
                     (riu_rddata_2 /= "00000000000" or riu_prsnt_2 = '0') and
                     (riu_rddata_1 /= "00000000000" or riu_prsnt_1 = '0') and
                     (riu_rddata_0 /= "00000000000" or riu_prsnt_0 = '0')) then
                     rx_btval_3     <= riu_rddata_3(9 downto 1);  -- divide by two for ddr clock
                     rx_btval_2     <= riu_rddata_2(9 downto 1);
                     rx_btval_1     <= riu_rddata_1(9 downto 1);
                     rx_btval_0     <= riu_rddata_0(9 downto 1);
                     intctrl_state  <= intctrl_state + 1;
                 elsif (in_simulation ) then
                     --
                     -- simulation behavioral model of bitslice_control does not support
                     -- read of the self calibrated tap value stored in halft_dqsm
                     --
                     rx_btval_3     <= "010100000";  -- 160 
                     rx_btval_2     <= "010100000";  -- 160
                     rx_btval_1     <= "010100000";  -- 160
                     rx_btval_0     <= "010100000";  -- 160
                     intctrl_state  <= intctrl_state + 1;
                 end if;
            when 188 =>    -- rx pll clkoutphy deassert
                 riu_addr       <= "000000"; -- addr 0x00 - default
                 riu_wrdata     <=x"0000";  -- 8'h00, 8'00
                 riu_wr_en      <= '0';
                 riu_nibble_sel <= "00";
                 intctrl_rxpllclkoutphyen <= '0';
                 intctrl_state            <= intctrl_state + 1;
            when 252 =>   --  rx bitslice reset assert - wait 64 cycles
                 rx_bs_rst      <= '1';
                 intctrl_state  <= intctrl_state + 1;
            when 316 =>   --  rx bitslice reset deassert - wait 64 cycles
                 rx_bs_rst      <= '0';
                 intctrl_state  <= intctrl_state + 1;
            when 380 =>   -- rx pll clkoutphy assert - wait 64 cyles
                 intctrl_rxpllclkoutphyen <= '1';
                 intctrl_state            <= intctrl_state + 1;
            when 511 =>   -- rx logicreset deassert - wait 131 cycles
                 intctrl_rxlogicrst <= '0';
                 intctrl_state      <= 511;   -- stall state
            when others => 
                 riu_addr       <= "000000";  -- addr 0x00 - default
                 riu_wrdata     <=x"0000";  -- 8'h00, 8'00
                 riu_wr_en      <= '0';
                 riu_nibble_sel <= "00";
                 intctrl_state  <= intctrl_state + 1;
         end case;
      end if;
   end if;
end process;
debug_out <= conv_std_logic_vector(intctrl_state,8);
end clock_reset_arch;

