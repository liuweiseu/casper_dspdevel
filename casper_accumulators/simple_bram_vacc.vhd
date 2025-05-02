-- A VHDL implementation of the CASPER simple_bram_vacc.
-- @author: Talon Myburgh
-- @company: Mydon Solutions

-----------------------------------------------------------
-- institution  : RAL, UCB
-- Engineer     : Wei Liu
-- History      : V1.1 - delayed one clk on the bram out,
--                       to get the bram out aligned to valid.
-----------------------------------------------------------

library IEEE, common_pkg_lib,
casper_misc_lib, common_components_lib, casper_adder_lib,
casper_delay_lib;
use IEEE.std_logic_1164.all;
use common_pkg_lib.common_pkg.all;

entity simple_bram_vacc is
  generic (
    g_vector_length : natural := 16;
    g_output_type : string := "SIGNED";
    g_bit_w : natural := 32
  );
  port (
    clk : in std_logic;
    ce : in std_logic;
    new_acc : in std_logic;
    -- din         : IN std_logic_vector;
    din : in std_logic_vector(g_bit_w - 1 downto 0) := (others => '0');
    valid : out std_logic := '0';
    dout : out std_logic_vector(g_bit_w - 1 downto 0) := (others => '0')
  );
end simple_bram_vacc;

architecture rtl of simple_bram_vacc is
  signal s_pulse_ext_out : std_logic;
  signal s_a : std_logic_vector(g_bit_w - 1 downto 0);
  signal s_delay_bram_in : std_logic_vector(g_bit_w - 1 downto 0);
  signal s_delay_bram_out : std_logic_vector(g_bit_w - 1 downto 0);
  signal s_mux_out : std_logic_vector(g_bit_w - 1 downto 0);

begin

  --------------------------------------------------------------
  -- pulse extend new_acc signal
  --------------------------------------------------------------
  pulse_ext : entity casper_misc_lib.pulse_ext
    generic map(
      g_extension => g_vector_length
    )
    port map
    (
      clk => clk,
      ce => ce,
      i_pulse => new_acc,
      o_pulse => s_pulse_ext_out
    );

  --------------------------------------------------------------
  -- mux block
  --------------------------------------------------------------
  s_mux_out <= s_delay_bram_out when s_pulse_ext_out = '0' else
    (others => '0') when s_pulse_ext_out = '1' else
    (others => 'X');

  --------------------------------------------------------------
  -- resize din signal
  --------------------------------------------------------------
  s_a <= RESIZE_SVEC(din, g_bit_w) when g_output_type = "SIGNED" else
    RESIZE_UVEC(din, g_bit_w);

  --------------------------------------------------------------
  -- adder block
  --------------------------------------------------------------
  add_a_b : entity casper_adder_lib.common_add_sub
    generic map(
      g_direction => "ADD",
      g_representation => g_output_type,
      g_pipeline_input => 0,
      g_pipeline_output => 2,
      g_in_dat_w => g_bit_w,
      g_out_dat_w => g_bit_w
    )
    port map
    (
      clk => clk,
      clken => ce,
      in_a => s_a,
      in_b => s_mux_out,
      result => s_delay_bram_in
    );

  --------------------------------------------------------------
  -- delay bram
  --------------------------------------------------------------
  delay_bram_blk : entity casper_delay_lib.delay_bram
    generic map(
      g_delay => g_vector_length - 2,
      g_ram_primitive => "block",
      g_ram_latency => 2
    )
    port map
    (
      clk => clk,
      ce => ce,
      din => s_delay_bram_in,
      dout => s_delay_bram_out
    );

  --------------------------------------------------------------
  -- set up output signals
  --------------------------------------------------------------
  one_clk_delay : process (clk) begin
    if rising_edge(clk) then
      dout <= s_delay_bram_out;
    end if;
  end process;

  --   dout <= s_delay_bram_out;
  valid <= s_pulse_ext_out;

end rtl;