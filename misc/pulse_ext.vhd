-- A VHDL implementation of the CASPER pulse_ext block.
-- @author: Talon Myburgh
-- @company: Mydon Solutions

-------------------------------------------------------
-- institution  : RAL, UCB
-- Engineer     : Wei Liu
-- History      : V1.1 - delayed the output for 1 clk,
--                       to match the casper block.
-------------------------------------------------------

library IEEE, casper_counter_lib, common_pkg_lib;
use IEEE.std_logic_1164.all;
use common_pkg_lib.common_pkg.all;

entity pulse_ext is
  generic (
    g_extension : natural := 4;
    g_rising_not_falling_edge_detect : boolean := TRUE
  );
  port (
    clk : in std_logic := '1';
    ce : in std_logic := '1';

    i_pulse : in std_logic;
    o_pulse : out std_logic
  );
end entity;

architecture rtl of pulse_ext is
  constant c_counter_bit_w : natural := ceil_log2(g_extension + 1);

  signal s_pulse : std_logic_vector(0 downto 0);
  signal s_count_rst : std_logic_vector(0 downto 0);

  signal s_count : std_logic_vector(c_counter_bit_w - 1 downto 0);
  signal s_counted : std_logic;
begin

  s_pulse(0) <= i_pulse;

  u_rising_edge : entity work.edge_detect
    generic map(
      g_edge_type => sel_a_b(g_rising_not_falling_edge_detect, "rising", "falling"),
      g_output_pol => "high"
    )
    port map
    (
      clk => clk,
      ce => ce,
      in_sig => s_pulse,
      out_sig => s_count_rst
    );

  u_counter : entity casper_counter_lib.free_run_counter
    generic map(
      g_cnt_w => c_counter_bit_w
    )
    port map
    (
      clk => clk,
      ce => ce and s_counted,
      reset => s_count_rst(0),
      count => s_count
    );

  gen_rising_edge_out : if g_rising_not_falling_edge_detect generate
    -- when extending rising_edge, o_pulse is forced to be g_extension clks long after edge
    s_counted <= '1' when s_count /= TO_UVEC(g_extension - 1, c_counter_bit_w) else
      '0';
  end generate;
  gen_falling_edge_out : if not g_rising_not_falling_edge_detect generate
    -- when extending falling_edge, o_pulse is extended to be higher for g_extension clks longer after edge
    --  but counter has latency of 1, so account for it.
    s_counted <= '1' when s_count /= TO_UVEC(g_extension - 1, c_counter_bit_w) else
      i_pulse;
  end generate;

  one_clk_delay : process (clk)
  begin
    if rising_edge(clk) then
      o_pulse <= s_counted;
    end if;
  end process;

end architecture;
