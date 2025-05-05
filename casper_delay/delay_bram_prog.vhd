-- A VHDL implementation of the CASPER delay_bram_prog block.
-- @author: Talon Myburgh
-- @company: Mydon Solutions

-------------------------------------------------------------
-- institution  : RAL, UCB
-- Engineer     : Wei Liu
-- History      : V1.1 - delayed the output and we for 1 clk,
--                       to match the casper block.
-------------------------------------------------------------
library IEEE, common_pkg_lib, casper_counter_lib, casper_ram_lib, casper_adder_lib, common_components_lib;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use common_pkg_lib.common_pkg.all;
use casper_ram_lib.common_ram_pkg.all;
use common_components_lib.common_components_pkg.all;

entity delay_bram_prog is
  generic (
    g_max_delay : natural := 7; -- 2^g_max_delay
    g_ram_primitive : string := "block"; -- bram primitive
    g_ram_latency : natural := 2 -- bram latency. Anything in excess of 2 will be in a delay block
  );
  port (
    clk : in std_logic;
    ce : in std_logic;
    din : in std_logic_vector; -- signal to delay
    delay : in std_logic_vector; -- variable delay
    dout : out std_logic_vector -- delayed signal
  );
end entity;

architecture rtl of delay_bram_prog is
  constant c_dat_w : natural := din'LENGTH;
  constant c_mem_ram : t_c_mem := (latency => g_ram_latency,
  adr_w => g_max_delay,
  dat_w => c_dat_w,
  nof_dat => 2 ** g_max_delay,
  init_sl => '0');

  signal s_count_val : std_logic_vector(g_max_delay - 1 downto 0);
  signal s_ram_out : std_logic_vector(din'range);
  signal s_subtrahend : std_logic_vector(g_max_delay - 1 downto 0) := TO_SVEC((g_ram_latency + 1), g_max_delay);
  signal s_minuend : std_logic_vector(g_max_delay - 1 downto 0);
  signal s_difference : std_logic_vector(g_max_delay - 1 downto 0);
  signal s_count_rst : std_logic := '0';
  signal s_ram_out_d1 : std_logic_vector(din'range);
begin
  s_minuend <= RESIZE_SVEC(delay, g_max_delay);
  --   ASSERT c_max_cnt > 0 REPORT "Delay value must be greater than BRAM latency + 1!" severity FAILURE;

  --------------------------------------------------------
  -- Subtraction
  --------------------------------------------------------
  delay_latency_diff : entity casper_adder_lib.common_add_sub
    generic map(
      g_direction => "SUB",
      g_pipeline_output => 2,
      g_in_dat_w => g_max_delay,
      g_out_dat_w => g_max_delay
    )
    port map
    (
      clk => clk,
      clken => ce,
      in_a => s_minuend,
      in_b => s_subtrahend,
      result => s_difference
    );

  --------------------------------------------------------
  -- a >= b
  --------------------------------------------------------
  s_count_rst <= '1' when unsigned(s_count_val) >= unsigned(s_difference) else
    '0';

  --------------------------------------------------------
  -- Counter
  --------------------------------------------------------
  addr_cntr : entity casper_counter_lib.free_run_counter
    generic map(
      g_cnt_w => g_max_delay,
      g_cnt_signed => FALSE
    )
    port map
    (
      clk => clk,
      ce => ce,
      reset => s_count_rst,
      count => s_count_val
    );

  --------------------------------------------------------
  -- Single Port Ram
  --------------------------------------------------------
  delay_spram : entity casper_ram_lib.common_ram_r_w
    generic map(
      g_ram => c_mem_ram,
      g_true_dual_port => FALSE,
      g_ram_primitive => g_ram_primitive,
      g_write_mode_a => "read_first",
      g_write_mode_b => "read_first"
    )
    port map
    (
      clk => clk,
      clken => ce,
      wr_en => '1',
      wr_adr => s_count_val,
      wr_dat => din,
      rd_en => '1',
      rd_adr => s_count_val,
      rd_dat => s_ram_out,
      rd_val => open
    );

  --------------------------------------------------------
  -- Send value out
  --------------------------------------------------------
  one_clk_delay : process (clk)
  begin
    if rising_edge(clk) then
      s_ram_out_d1 <= s_ram_out;
    end if;
  end process;
  dout <= s_ram_out_d1;
end architecture;