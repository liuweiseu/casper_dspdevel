-- A VHDL implementation of the CASPER armed_trigger block.
-- @author: Talon Myburgh
-- @company: Mydon Solutions

-----------------------------------------------------------
-- institution  : RAL, UCB
-- Engineer     : Wei Liu
-- History      : V1.1 - fixed the bug in the armed_trigger
-----------------------------------------------------------

library IEEE, common_pkg_lib;
use IEEE.std_logic_1164.all;
use common_pkg_lib.common_pkg.all;

entity armed_trigger is
  port (
    clk : in std_logic;
    ce : in std_logic;
    arm : in std_logic;
    trig_in : in std_logic;
    trig_out : out std_logic
  );
end armed_trigger;

architecture rtl of armed_trigger is
  signal s_reg_d : std_logic := '0';
  signal s_arm : std_logic_vector(0 downto 0);
  signal s_edge_out : std_logic_vector(0 downto 0);
  signal s_rst : std_logic;
  signal s_q : std_logic := '1';
  signal s_en : std_logic := '0';
  signal s_trig_out : std_logic;
begin

  --------------------------------------------------------------
  -- rising edge detect on arm signal
  --------------------------------------------------------------
  rising_edge_det : entity work.edge_detect
    generic map(
      g_edge_type => "rising",
      g_output_pol => "high"
    )
    port map
    (
      clk => clk,
      ce => ce,
      in_sig => s_arm,
      out_sig => s_edge_out
    );
  --make std_logic_vector
  s_arm(0) <= arm;
  --make std_logic
  s_rst <= s_edge_out(0);

  --------------------------------------------------------------
  -- synchronous register to pass out triggered boolean value
  --------------------------------------------------------------
  registered_proc : process (clk, ce)
  begin
    if rising_edge(clk) and ce = '1' then
      --   if s_en = '1' then
      --     if s_rst = '0' then
      --       s_q <= s_reg_d;
      --     else
      --       s_q <= '1';
      --     end if;
      --   end if;
      if s_rst = '1' then
        s_q <= '1';
      elsif s_en = '1' then
        s_q <= s_reg_d;
      else
        s_q <= s_q;
      end if;
    end if;
  end process;

  --------------------------------------------------------------
  -- AND
  --------------------------------------------------------------
  s_trig_out <= trig_in and s_q;

  --------------------------------------------------------------
  -- Feedback loop
  --------------------------------------------------------------
  s_en <= s_trig_out;
  trig_out <= s_trig_out;

end architecture;