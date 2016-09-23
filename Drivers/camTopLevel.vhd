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
    vsync_in  : in std_logic;
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
 	port(
 		clk25     : in std_logic;
 		vga_red   : out std_logic_vector(3 downto 0);
 		vga_green : out std_logic_vector(3 downto 0);
 		vga_blue  : out std_logic_vector(3 downto 0);
 		vga_hsync : out std_logic;
 		vga_vsync : out std_logic;
 		blanking  : out std_logic;

 		frame_addr  : out std_logic_vector(18 downto 0);
 		frame_pixel : in  std_logic_vector(11 downto 0));
 	end component;

 	signal frame_addr      : std_logic_vector(18 downto 0);
 	signal frame_pixel     : std_logic_vector(11 downto 0);

 	signal capture_addr    : std_logic_vector(18 downto 0);
 	signal capture_data    : std_logic_vector(11 downto 0);
  signal capture_we      : std_logic_vector(0 downto 0);
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

 button_debounce: debounce port MAP(
 		clk => clk50,
 		i   => button,
 		o   => resend
 	);

 	inst_vga: vga port MAP(
 		clk25       => clk25,
 		vga_red     => red,
 		vga_green   => green,
 		vga_blue    => blue,
 		vga_hsync   => hsync,
 		vga_vsync   => vsync,
 		frame_addr  => frame_addr,
 		frame_pixel => frame_pixel,
 		blanking => blanking
 	);

 fb : blk_mem_gen_0
   port MAP (
     clka  => ovPCLK,
     wea   => capture_we,
     addra => capture_addr,
     dina  => capture_data,

     clkb  => clk50,
     addrb => frame_addr,
     doutb => frame_pixel
   );

   led <= "0000000" & finConfig;

 capture: ovCapture port MAP(
 		pclk  => ovPCLK,
 		vsync => ovVSYNC,
 		href  => ovHREF,
 		d     => ovD,
 		addr  => capture_addr,
 		dout  => capture_data,
 		we    => capture_we(0)
 	);

 controller: ovController port MAP(
 		clk   => clk50,
 		sioc  => ovSIOC,
 		resend => resend,
 		finConfig => finConfig,
 		siod  => ovSIOD,
 		pwdn  => ovPWDN,
 		reset => ovRESET,
 		xclk  => ovXCLK
 	);

 clocking_inst : clocking
   port map
    (-- Clock in ports
     clk100 => clk100,
     -- Clock out ports
     clk50 => clk50,
     clk25 => clk25);

     processing_inst : processing
     port map
     (
         clk25 => clk25,
         r => red,
         g => green,
         b => blue,
         vgaPrR => vga_red,
         vgaPrG => vga_green,
         vgaPrB => vga_blue,
         blanking => blanking,
         inHSYNC => hsync,
         vsync_in => vsync,
         outHSYNC => vga_hsync,
         outVSYNC => vga_vsync,
         swSobel => switch0
     );

end Behavioral;
