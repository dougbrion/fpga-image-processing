-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Create VGA entity with correct inputs and outputs
entity vga is
    Port (
		clk25         : in  std_logic;
		vgaRed        : out std_logic_vector(3 downto 0);
		vgaGreen      : out std_logic_vector(3 downto 0);
		vgaBlue       : out std_logic_vector(3 downto 0);
		vgaHSync      : out std_logic;
		vgaVSync      : out std_logic;
		frameAddress  : out std_logic_vector(18 downto 0);
		framePixel    : in  std_logic_vector(11 downto 0);
		blanking      : out std_logic
	 );
end vga;

-- Create architecture for entity just create: VGA
architecture Behavioral of vga is

   -- Set the timing constants for the display
   constant hRez       : natural := 640; -- 640
   constant hStartSync : natural := 656; -- 640 + 16
   constant hEndSync   : natural := 752; -- 640 + 16 + 96
   constant hMaxCount  : natural := 800; -- 800

   constant vRez       : natural := 480; -- 480
   constant vStartSync : natural := 490; -- 480 + 10
   constant vEndSync   : natural := 492; -- 480 + 10 + 2
   constant vMaxCount  : natural := 525; -- 480 + 10 + 2 + 33

   -- Set hSync and vSync to 0
	 constant hSyncActive : std_logic := '0';
	 constant vSyncActive : std_logic := '0';

   signal hCounter : unsigned( 9 downto 0) := (others => '0');
   signal vCounter : unsigned( 9 downto 0) := (others => '0');
	 signal address  : unsigned(18 downto 0) := (others => '0');
	 signal blank    : std_logic := '1';

begin

   blanking <= blank;

	 frameAddress <= std_logic_vector(address);

   process(clk25)
   begin
		if rising_edge(clk25) then
			-- Counting the lines and rows
			if hCounter = hMaxCount - 1 then
				hCounter <= (others => '0');
				if vCounter = vMaxCount - 1 then
					vCounter <= (others => '0');
				else
					vCounter <= vCounter + 1;
				end if;
			else
				hCounter <= hCounter + 1;
			end if;

			if blank = '0' then
				vgaRed   <= framePixel(11 downto 8);
				vgaGreen <= framePixel( 7 downto 4);
				vgaBlue  <= framePixel( 3 downto 0);
			else
				vgaRed   <= (others => '0');
				vgaGreen <= (others => '0');
				vgaBlue  <= (others => '0');
			end if;

			if vCounter  >= vRez then
				address <= (others => '0');
				blank <= '1';
			else
				if hCounter  < 640 then
					blank <= '0';
					address <= address + 1;
				else
					blank <= '1';
				end if;
			end if;

			-- Check to see if we are in a hSync pulse
			if hCounter > hStartSync and hCounter <= hEndSync then
				vgaHSync <= hSyncActive;
			else
				vgaHSync <= not hSyncActive;
			end if;

			-- Now check to see if we are in a vSync pulse
			if vCounter >= vStartSync and vCounter < vEndSync then
				vgaVSync <= vSyncActive;
			else
				vgaVSync <= not vSyncActive;
			end if;
		end if;
	end process;
end Behavioral;
