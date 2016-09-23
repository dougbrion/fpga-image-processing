-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Debounce entity with correct inputs and outputs
entity debounce is
    Port ( clk : in  std_logic;
           i   : in  std_logic;
           o   : out std_logic);
end debounce;

-- Architecture for the entity just created :- Debounce
architecture Behavioral of debounce is
	signal c : unsigned(23 downto 0);
begin
	process(clk)
	begin
		if rising_edge(clk) then
		   if i = '1' then
		      if c = x"FFFFFF" then
					o <= '1';
				else
					o <= '0';
				end if;
				c <= c+1;
			else
				c <= (others => '0');
				o <= '0';
			end if;
		end if;
	end process;

end Behavioral;
