-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

-- topOV7670 entity with correct inputs and outputs
entity topOV7670 is
    port (
		clk100  : in    std_logic;
		ovSIOC  : out   std_logic;
		ovSIOD  : inout std_logic;
		ovRESET : out   std_logic;
		ovPWDN  : out   std_logic;
		ovVSYNC : in    std_logic;
		ovHREF  : in    std_logic;
		ovPCLK  : in    std_logic;
		ovXCLK  : out   std_logic;
		ovD     : in    std_logic_vector(7 downto 0);

		led     : out    std_logic_vector(7 downto 0);

		vgaR      : out   std_logic_vector(3 downto 0);
		vgaG      : out   std_logic_vector(3 downto 0);
		vgaB      : out   std_logic_vector(3 downto 0);
		vgaHSYNC  : out   std_logic;
		vgaVSYNC  : out   std_logic;

		button 		: in    std_logic;
		switch0   : in    std_logic);
end topOV7670;

architecture Behavioral of topOV7670 is

	component debounce
	port(
		clk : in std_logic;
		i   : in std_logic;
		o   : out std_logic);
	end component;

    component clocking
    port
     (
      clk100         : in     std_logic;  -- Clock in ports
      clk50          : out    std_logic;  -- Clock out ports
      clk25          : out    std_logic);  -- Clock out ports
    end component;

  

end Behavioral;
