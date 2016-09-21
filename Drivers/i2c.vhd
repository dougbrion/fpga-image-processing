-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- I^2C sender entity with correct inputs and outputs
entity i2c is
    Port (
    clk   : in  std_logic;
    siod  : inout  std_logic;
    sioc  : out  std_logic;
		taken : out  std_logic;
		send  : in  std_logic;
    id    : in  std_logic_vector (7 downto 0);
    reg   : in  std_logic_vector (7 downto 0);
    value : in  std_logic_vector (7 downto 0));
end i2c;

-- Architecture for the entity just created :- I^2C sender
architecture Behavioral of i2c is
	signal   divider  : unsigned (7 downto 0) := "00000001"; -- The value here (in this case 254) sets the pause until the first value is sent
	signal   busySr  : std_logic_vector(31 downto 0) := (others => '0');
	signal   dataSr  : std_logic_vector(31 downto 0) := (others => '1');
begin
	process(busySr, dataSr(31))
	begin
		if busySr(11 downto 10) = "10" or
		   busySr(20 downto 19) = "10" or
		   busySr(29 downto 28) = "10"  then
			siod <= 'Z';
		else
			siod <= dataSr(31);
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			taken <= '0';
			if busySr(31) = '0' then
				sioc <= '1';
				if send = '1' then
					if divider = "00000000" then
						dataSr <= "100" &   id & '0'  &   reg & '0' & value & '0' & "01";
						busySr <= "111" & "111111111" & "111111111" & "111111111" & "11";
						taken <= '1';
					else
						divider <= divider + 1; -- Occurs on startup
					end if;
				end if;
			else

				case busySr(32 - 1 downto 32 - 3) & busySr(2 downto 0) is
					when "111" & "111" => -- Seq #1 start
						case divider(7 downto 6) is
							when "00"   => sioc <= '1';
							when "01"   => sioc <= '1';
							when "10"   => sioc <= '1';
							when others => sioc <= '1';
						end case;

					when "111" & "110" => -- Seq #2 start
						case divider(7 downto 6) is
							when "00"   => sioc <= '1';
							when "01"   => sioc <= '1';
							when "10"   => sioc <= '1';
							when others => sioc <= '1';
						end case;

					when "111" & "100" => -- Seq #3 start
						case divider(7 downto 6) is
							when "00"   => sioc <= '0';
							when "01"   => sioc <= '0';
							when "10"   => sioc <= '0';
							when others => sioc <= '0';
						end case;
					when "110" & "000" => -- Seq #1 end
						case divider(7 downto 6) is
							when "00"   => sioc <= '0';
							when "01"   => sioc <= '1';
							when "10"   => sioc <= '1';
							when others => sioc <= '1';
						end case;

					when "100" & "000" => -- Seq #2 end
						case divider(7 downto 6) is
							when "00"   => sioc <= '1';
							when "01"   => sioc <= '1';
							when "10"   => sioc <= '1';
							when others => sioc <= '1';
						end case;

					when "000" & "000" => -- Idle
						case divider(7 downto 6) is
							when "00"   => sioc <= '1';
							when "01"   => sioc <= '1';
							when "10"   => sioc <= '1';
							when others => sioc <= '1';
						end case;

					when others =>
						case divider(7 downto 6) is
							when "00"   => sioc <= '0';
							when "01"   => sioc <= '1';
							when "10"   => sioc <= '1';
							when others => sioc <= '0';
						end case;
				end case;

				if divider = "11111111" then
					busySr <= busySr(32 - 2 downto 0) & '0';
					dataSr <= dataSr(32 - 2 downto 0) & '1';
					divider <= (others => '0');
				else
					divider <= divider + 1;
				end if;
			end if;
		end if;
	end process;
end Behavioral;
