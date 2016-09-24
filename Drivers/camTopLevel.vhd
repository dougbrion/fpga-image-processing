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

-- Architecture for the entity just created :- topOV7670
architecture Behavioral of topOV7670 is

	component debounce
	port (
		clk : in std_logic;
		i   : in std_logic;
		o   : out std_logic);
	end component;

  component clocking
  port (
    clk100         : in     std_logic;  -- Clock in ports
    clk50          : out    std_logic;  -- Clock out ports
    clk25          : out    std_logic);  -- Clock out ports
  end component;

  component processing is
  port (
    r         : in std_logic_vector (3 downto 0);
    g         : in std_logic_vector (3 downto 0);
    b         : in std_logic_vector (3 downto 0);
    vgaPrR    : out std_logic_vector (3 downto 0);
    vgaPrG    : out std_logic_vector (3 downto 0);
    vgaPrB    : out std_logic_vector (3 downto 0);
    clk25     : in std_logic;
    blanking  : in std_logic;
    inHSYNC   : in std_logic;
    inVSYNC  : in std_logic;
    outHSYNC  : out std_logic;
    outVSYNC  : out std_logic;
    swSobel   : in std_logic);
  end component;

 	component ovController
 	port (
 		clk        : in    std_logic;
 		resend     : in    std_logic;
 		finConfig  : out   std_logic;
 		siod       : inout std_logic;
 		sioc       : out   std_logic;
 		reset      : out   std_logic;
 		pwdn       : out   std_logic;
 		xclk       : out   std_logic);
 	end component;

 	component blk_mem_gen_0
 	port (
 		clka  : in  std_logic;
 		wea   : in  std_logic_vector(0 downto 0);
 		addra : in  std_logic_vector(18 downto 0);
 		dina  : in  std_logic_vector(11 downto 0);
 		clkb  : in  std_logic;
 		addrb : in  std_logic_vector(18 downto 0);
 		doutb : out std_logic_vector(11 downto 0));
 	end component;

 	component ovCapture
 	port (
 		pclk : in std_logic;
 		vsync : in std_logic;
 		href  : in std_logic;
 		d     : in std_logic_vector(7 downto 0);
 		addr  : out std_logic_vector(18 downto 0);
 		dout  : out std_logic_vector(11 downto 0);
 		we    : out std_logic);
 	end component;


 	component vga
 	port (
 		clk25     : in std_logic;
 		vgaR   : out std_logic_vector(3 downto 0);
 		vgaG : out std_logic_vector(3 downto 0);
 		vgaB  : out std_logic_vector(3 downto 0);
 		vgaHSYNC : out std_logic;
 		vgaVSYNC : out std_logic;
 		blanking  : out std_logic;

 		frameAddress  : out std_logic_vector(18 downto 0);
 		framePixel : in  std_logic_vector(11 downto 0));
 	end component;

 	signal frameAddress      : std_logic_vector(18 downto 0);
 	signal framePixel     : std_logic_vector(11 downto 0);

 	signal captureAddress    : std_logic_vector(18 downto 0);
 	signal captureData    : std_logic_vector(11 downto 0);
  signal captureWe      : std_logic_vector(0 downto 0);
 	signal resend          : std_logic;
 	signal finConfig : std_logic;

 	signal clk_feedback  : std_logic;
 	signal clk50u        : std_logic;
 	signal clk50         : std_logic;
 	signal clk25u        : std_logic;
 	signal clk25         : std_logic;
 	signal buffered_pclk : std_logic;

 	signal red : std_logic_vector(3 downto 0);
 	signal green : std_logic_vector(3 downto 0);
 	signal blue : std_logic_vector(3 downto 0);

 	signal hsync : std_logic;
 	signal vsync : std_logic;

 	signal blanking : std_logic;

 begin

 button_debounce: debounce
 port map (
 		clk => clk50,
 		i   => button,
 		o   => resend);

 	inst_vga: vga
  port map (
 		clk25       => clk25,
 		vgaR     => red,
 		vgaG   => green,
 		vgaB    => blue,
 		vgaHSYNC   => hsync,
 		vgaVSYNC   => vsync,
 		frameAddress  => frameAddress,
 		framePixel => framePixel,
 		blanking => blanking);

 fb : blk_mem_gen_0
   port map (
     clka  => ovPCLK,
     wea   => captureWe,
     addra => captureAddress,
     dina  => captureData,

     clkb  => clk50,
     addrb => frameAddress,
     doutb => framePixel);

 led <= "0000000" & finConfig;

 capture: ovCapture
 port map (
 		pclk  => ovPCLK,
 		vsync => ovVSYNC,
 		href  => ovHREF,
 		d     => ovD,
 		addr  => captureAddress,
 		dout  => captureData,
 		we    => captureWe(0));

 controller: ovController
 port map (
 		clk   => clk50,
 		sioc  => ovSIOC,
 		resend => resend,
 		finConfig => finConfig,
 		siod  => ovSIOD,
 		pwdn  => ovPWDN,
 		reset => ovRESET,
 		xclk  => ovXCLK);

 clocking_inst : clocking
   port map (
     clk100 => clk100, -- Clock in ports
     clk50 => clk50,   -- Clock out ports
     clk25 => clk25);  -- Clock out ports

     processing_inst : processing
     port map (
         clk25 => clk25,
         r => red,
         g => green,
         b => blue,
         vgaPrR => vgaR,
         vgaPrG => vgaG,
         vgaPrB => vgaB,
         blanking => blanking,
         inHSYNC => hsync,
         inVSYNC => vsync,
         outHSYNC => vgaHSYNC,
         outVSYNC => vgaVSYNC,
         swSobel => switch0);
end Behavioral;
