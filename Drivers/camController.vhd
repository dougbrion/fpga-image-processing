-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity camController is
    port ( clk        : in    std_logic;
			     resend     : in    std_logic;
			     configFin  : out   std_logic;
           sioc       : out   std_logic;
           siod       : inout std_logic;
           reset      : out   std_logic;
           pwdn       : out   std_logic;
			     xclk       : out   std_logic);
end camController;

architecture Behavioral of camController is
	component camRegisters
	port( clk      : in std_logic;
        advance  : in std_logic;
        resend   : in std_logic;
        command  : out std_logic_vector(15 downto 0);
        finished : out std_logic);
	end component;

	component i2c
	port(	clk   : in std_logic;
    		send  : in std_logic;
    		taken : out std_logic;
    		id    : in std_logic_vector(7 downto 0);
    		reg   : in std_logic_vector(7 downto 0);
    		value : in std_logic_vector(7 downto 0);
    		siod  : inout std_logic;
    		sioc  : out std_logic);
	end component;

	signal sys_clk  : std_logic := '0';
	signal command  : std_logic_vector(15 downto 0);
	signal finished : std_logic := '0';
	signal taken    : std_logic := '0';
	signal send     : std_logic;

	constant camera_address : std_logic_vector(7 downto 0) := x"42";
   configFin <= finished;

	send <= not finished;
	inst_i2c: i2c port map(
		clk   => clk,
		taken => taken,
		siod  => siod,
		sioc  => sioc,
		send  => send,
		id    => camera_address,
		reg   => command(15 downto 8),
		value => command(7 downto 0));

	reset <= '1'; 						-- Normal mode
	pwdn  <= '0'; 						-- Power device up
	xclk  <= sys_clk;

	inst_camRegisters: camRegisters port map(
		clk      => clk,
		advance  => taken,
		command  => command,
		finished => finished,
		resend   => resend);

	process(clk)
	begin
		if rising_edge(clk) then
			sys_clk <= not sys_clk;
		end if;
	end process;
end Behavioral;
