library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity processing is
        Port ( r : in STD_LOGIC_VECTOR (3 downto 0);
               g : in STD_LOGIC_VECTOR (3 downto 0);
               b : in STD_LOGIC_VECTOR (3 downto 0);
               vga_red_pr : out STD_LOGIC_VECTOR (3 downto 0);
               vga_green_pr : out STD_LOGIC_VECTOR (3 downto 0);
               vga_blue_pr : out STD_LOGIC_VECTOR (3 downto 0);
               clk25 : in STD_LOGIC;
               blanking : in std_logic;
               hsync_in : in std_logic;
               vsync_in : in std_logic;
               hsync_out : out std_logic;
               vsync_out : out std_logic;
               sw_sobel : in std_logic
               );
    end processing;

architecture Behavioral of processing is

signal red : std_logic_vector (3 downto 0);
signal green : std_logic_vector (3 downto 0);
signal blue : std_logic_vector (3 downto 0);

signal hsync : std_logic;
signal vsync : std_logic;

-- red 2
-- green 1
-- blue 0
type pixel is array(2 downto 0) of std_logic_vector(3 downto 0);
type window is array(2 downto 0, 2 downto 0) of pixel;

type kernel is array(2 downto 0, 2 downto 0) of signed(15 downto 0);

component c_shift_ram_0 IS
  PORT (
    D : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    CLK : IN STD_LOGIC;
    CE : IN STD_LOGIC;
    Q : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  );
END component;

function pix_to_vec(pix : pixel)
    return std_logic_vector is
    variable tmp_vec : std_logic_vector(11 downto 0);
begin
    tmp_vec := pix(2) & pix(1) & pix(0);
    return tmp_vec;
end pix_to_vec;

function vec_to_pix(vec : std_logic_vector(11 downto 0))
    return pixel is
    variable tmp_pix : pixel;
begin
    tmp_pix(2) := vec(11 downto 8);
    tmp_pix(1) := vec(7 downto 4);
    tmp_pix(0) := vec(3 downto 0);
    return tmp_pix;
end vec_to_pix;

function intensity(pix : pixel)
    return unsigned is
    variable inten : unsigned(3 downto 0);
begin
    inten := resize(shift_right(resize(unsigned(pix(2)), 6) + resize(unsigned(pix(1)), 6) + resize(unsigned(pix(1)), 6) + resize(unsigned(pix(0)), 6), 2), 4);
    return inten;
end intensity;

function max(a : signed; b : signed)
    return signed is
begin
    if (a > b) then
        return a;
    else
        return b;
    end if;
end max;

function sobel(win : window)
    return window is
    variable result : window;
    variable sum_LR : signed(6 downto 0) := to_signed(0, 7);
    variable sum_UD : signed(6 downto 0) := to_signed(0, 7);

    constant sobel_LR : kernel := (
                                (to_signed(-1, 3), to_signed(0, 3), to_signed(1, 3)),
                                (to_signed(-2, 3), to_signed(0, 3), to_signed(2, 3)),
                                (to_signed(-1, 3), to_signed(0, 3), to_signed(1, 3))
                               );
    constant sobel_UD : kernel := (
                               (to_signed(-1, 3), to_signed(-2, 3), to_signed(-1, 3)),
                               (to_signed(0, 3), to_signed(0, 3), to_signed(0, 3)),
                               (to_signed(1, 3), to_signed(2, 3), to_signed(1, 3))
                              );
begin
    for y in 0 to 2 loop
        for x in 0 to 2 loop
            sum_LR := sum_LR + resize(signed(resize(intensity(win(x,y)), 7)) * sobel_LR(x,y), 7);
            sum_UD := sum_UD + resize(signed(resize(intensity(win(x,y)), 7)) * sobel_UD(x,y), 7);
        end loop;
    end loop;
    result(1,1) := (others => std_logic_vector(resize(shift_right(abs(max(sum_LR, sum_UD)), 2), 4)));
    return result;
end sobel;

function harris(win: window)
    return window is
    variable result : window;

    variable sumx : signed(15 downto 0) := to_signed(0, 16);
    variable sumy : signed(15 downto 0) := to_signed(0, 16);

    variable imx : signed(3 downto 0) := to_signed(0, 4);
    variable imy : signed(3 downto 0) := to_signed(0, 4);


    constant harris_x : kernel := (
                                (to_signed(33, 12), to_signed(0, 12), to_signed(-33, 12)),
                                (to_signed(1831, 12), to_signed(0, 12), to_signed(-1831, 12)),
                                (to_signed(33, 12), to_signed(0, 12), to_signed(-33, 12))
                               );
    constant harris_y : kernel := (
                               (to_signed(33, 12), to_signed(1831, 12), to_signed(33, 12)),
                               (to_signed(0, 12), to_signed(0, 12), to_signed(0, 12)),
                               (to_signed(-33, 12), to_signed(-1831, 12), to_signed(-33, 12))
                              );
begin
    for y in 0 to 2 loop
        for x in 0 to 2 loop
            sumx := sumx +
        end loop;
    end loop;
end harris;


function gaussian_blur(win: window)
    return window is
    variable result : window;
    variable sum_r : unsigned(7 downto 0) := to_unsigned(0, 8);
    variable sum_g : unsigned(7 downto 0) := to_unsigned(0, 8);
    variable sum_b : unsigned(7 downto 0) := to_unsigned(0, 8);

    constant gauss : kernel := (
                                (to_signed(1, 4), to_signed(2, 4), to_signed(1, 4)),
                                (to_signed(2, 4), to_signed(4, 4), to_signed(2, 4)),
                                (to_signed(1, 4), to_signed(2, 4), to_signed(1, 4))
                               );

begin
    result := win;
    for y in 0 to 2 loop
        for x in 0 to 2 loop
            sum_r := sum_r + resize(resize(unsigned(pix_to_vec(result(x,y))(11 downto 8)), 8) * resize(unsigned(gauss(x, y)), 8), 8);
            sum_g := sum_g + resize(resize(unsigned(pix_to_vec(result(x,y))(7 downto 4)), 8) * resize(unsigned(gauss(x, y)), 8), 8);
            sum_b := sum_b + resize(resize(unsigned(pix_to_vec(result(x,y))(3 downto 0)), 8) * resize(unsigned(gauss(x, y)), 8), 8);
        end loop;
    end loop;
        result(1,1)(2) := std_logic_vector(resize(shift_right(sum_r, 3), 4));
        result(1,1)(1) := std_logic_vector(resize(shift_right(sum_g, 3), 4));
        result(1,1)(0) := std_logic_vector(resize(shift_right(sum_b, 3), 4));

        return result;
end gaussian_blur;

signal notblanking : std_logic;

signal pixel_line_1 : std_logic_vector(11 downto 0);
signal pixel_line_2 : std_logic_vector(11 downto 0);
signal pixel_line_3 : std_logic_vector(11 downto 0);

signal active_window : window;

signal bnw_intensity : std_logic_vector(11 downto 0);

begin

    process(clk25)
    begin
        if rising_edge(clk25) then
            hsync <= hsync_in;
            vsync <= vsync_in;

            red <= r;
            green <= g;
            blue <= b;

        end if;
    end process;

    notblanking <= not blanking;

    pixel_line_1 <= red & green & blue;

    line_1 : c_shift_ram_0 port map (
        d => pixel_line_1,
        q => pixel_line_2,
        clk => clk25,
        ce => notblanking
    );

    line_2 : c_shift_ram_0 port map (
            d => pixel_line_2,
            q => pixel_line_3,
            clk => clk25,
            ce => notblanking
    );

    process(clk25)
    begin
        if rising_edge(clk25) then
            for x in 2 downto 1 loop
                for y in 0 to 2 loop
                    active_window(x, y) <= active_window(x - 1, y);
                end loop;
            end loop;

            active_window(0, 0) <= vec_to_pix(pixel_line_1);
            active_window(0, 1) <= vec_to_pix(pixel_line_2);
            active_window(0, 2) <= vec_to_pix(pixel_line_3);
        end if;
    end process;

    process(clk25)
        variable gauss_window : window;
        variable sobel_window : window;
        variable harris_window : window;
    begin
        if rising_edge(clk25) then


            gauss_window := gaussian_blur(active_window);
            --sobel_window := sobel(gauss_window);
            harris_window := harris(gauss_window);

            if sw_sobel = '0' then
              --Color Edge Detection Code
--                if unsigned(pix_to_vec(harris_window(1,1))(11 downto 8)) > 1 then
--                    vga_red_pr <= red;
--                    vga_green_pr <= green;
--                    vga_blue_pr <= blue;
--                else
--                    vga_red_pr <= (others => '0');
--                    vga_green_pr <= (others => '0');
--                    vga_blue_pr <= (others => '0');
--                end if;
                vga_red_pr <= harris_window(1,1)(2);
                vga_green_pr <= harris_window(1,1)(1);
                vga_blue_pr <= harris_window(1,1)(0);

            else
                vga_red_pr <= red;
                vga_green_pr <= green;
                vga_blue_pr <= blue;
            end if;

            hsync_out <= hsync;
            vsync_out <= vsync;
        end if;
    end process;

end Behavioral;
