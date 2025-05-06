-- A VHDL implementation of the CASPER c_to_ri block.
-- @author: Talon Myburgh
-- @company: Mydon Solutions

-----------------------------------------------------------------------
-- institution  : RAL, UCB
-- Engineer     : Wei Liu
-- History      : V1.1 - set the input port width to 2 * g_bit_width.
-----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity c_to_ri is
  generic (
    g_async : boolean := FALSE;
    g_bit_width : natural := 8
  );
  port (
    clk : in std_logic;
    ce : in std_logic;
    c_in : in std_logic_vector(2 * g_bit_width - 1 downto 0);
    re_out : out std_logic_vector(g_bit_width - 1 downto 0);
    im_out : out std_logic_vector(g_bit_width - 1 downto 0)
  );
end c_to_ri;

architecture rtl of c_to_ri is
  constant c_c_in_len : natural := c_in'LENGTH;
  signal s_re_out : std_logic_vector(g_bit_width - 1 downto 0);
  signal s_im_out : std_logic_vector(g_bit_width - 1 downto 0);
  signal s_c_in : std_logic_vector(c_in'range);

begin
  assert g_bit_width <= c_c_in_len report "Cannot request a bit_width larger than c_in'RANGE" severity failure;
  --------------------------------------------------------
  -- Asynchronous operation
  --------------------------------------------------------
  async : if g_async = TRUE generate
    s_re_out <= c_in(c_c_in_len - 1 downto c_c_in_len - g_bit_width);
    s_im_out <= c_in(g_bit_width - 1 downto 0);
  end generate;

  --------------------------------------------------------
  -- Synchronous operation
  --------------------------------------------------------
  sync : if g_async = FALSE generate
    sync_process : process (clk, ce)
    begin
      s_c_in <= c_in;
      if rising_edge(clk) and ce = '1' then
        s_re_out <= s_c_in(c_c_in_len - 1 downto c_c_in_len - g_bit_width);
        s_im_out <= s_c_in(g_bit_width - 1 downto 0);
      end if;
    end process;
  end generate;

  re_out <= s_re_out;
  im_out <= s_im_out;

end architecture;