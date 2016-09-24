-- Import the necessary libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- captureOV7670 entity with correct inputs and outputs
entity captureOV7670 is
    Port ( pclk       : in   std_logic;
           res160x120 : in std_logic;
           res320x240 : in std_logic;
           vsync      : in   std_logic;
           href       : in   std_logic;
           d          : in   std_logic_vector (7 downto 0);
           addr       : out  std_logic_vector (18 downto 0);
           dout       : out  std_logic_vector (11 downto 0);
           we         : out  std_logic);
end captureOV7670;

-- Architecture for the entity just created :- captureOV7670
architecture Behavioral of captureOV7670 is
   signal dLatch        : std_logic_vector(15 downto 0) := (others => '0');
   signal address       : std_logic_vector(18 downto 0) := (others => '0');
   signal line          : std_logic_vector(1 downto 0)  := (others => '0');
   signal hrefLast      : std_logic_vector(6 downto 0)  := (others => '0');
   signal weReg         : std_logic := '0';
   signal hrefHold      : std_logic := '0';
   signal latchedVsync  : std_logic := '0';
   signal latchedHref   : std_logic := '0';
   signal latchedD      : std_logic_vector (7 downto 0) := (others => '0');
begin
   addr   <= address;
   we     <= weReg;
   dout   <= dLatch(15 downto 12) & dLatch(10 downto 7) & dLatch(4 downto 1);

capture_process: process(pclk)
   begin
      if rising_edge(pclk) then
         if weReg = '1' then
            address <= std_logic_vector(unsigned(address) + 1);
         end if;

         -- The HREF pixel transfer takes 3 cycles
         --        input   | state after clock tick

         --         href   | wr_hold    d latch           d out             we address  next address
         -- cycle -1  x    |    xx      xxxxxxxxxxxxxxxx  xxxxxxxxxxxx  x   xxxx        xxxx
         -- cycle 0   1    |    x1      xxxxxxxxRRRRRGGG  xxxxxxxxxxxx  x   xxxx        addr
         -- cycle 1   0    |    10      RRRRRGGGGGGBBBBB  xxxxxxxxxxxx  x   addr        addr
         -- cycle 2   x    |    0x      GGGBBBBBxxxxxxxx  RRRRGGGGBBBB  1   addr        addr + 1

         -- For the start of the scan line detect the rising edge of href
         if hrefHold = '0' and latchedHref = '1' then
            case line is
               when "00"   => line <= "01";
               when "01"   => line <= "10";
               when "10"   => line <= "11";
               when others => line <= "00";
            end case;
         end if;
         hrefHold <= latchedHref;

         -- Capturing the 12bit RGB data from the camera (OV7670)
         if latchedHref = '1' then
            dLatch <= dLatch( 7 downto 0) & latchedD;
         end if;
         weReg  <= '0';

         -- Restarts the capturing if need be
         if latchedVsync = '1' then
            address      <= (others => '0');
            hrefLast     <= (others => '0');
            line         <= (others => '0');
         else
            -- If not, to capture a pixel we need to set the write enable
            if (res160x120 = '1' and hrefLast(6) = '1') or
               (res320x240 = '1' and hrefLast(2) = '1') or
               (res160x120 = '0' and res320x240  = '0' and hrefLast(0) = '1') then

               if res160x120 = '1' then
                  if line = "10" then
                     weReg <= '1';
                   end if;
               elsif res320x240 = '1' then
                  if line(1) = '1' then
                     weReg <= '1';
                   end if;
               else
                   weReg <= '1';
               end if;
               hrefLast <= (others => '0');
            else
               hrefLast <= hrefLast(hrefLast'high - 1 downto 0) & latchedHref;
            end if;
         end if;
      end if;
      if falling_edge(pclk) then
         latchedD     <= d;
         latchedHref  <= href;
         latchedVsync <= vsync;
      end if;
   end process;
end Behavioral;
