----------------------------------------------------------------------------------
--                            Tabla de las paletas                              --
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library WORK;
use WORK.VGA_PKG.ALL;

entity tabla_paletas is
	port (
	--Puertos de entrada
	clk          	   : in std_logic;
	dir_tabla_paletas  : in std_logic_vector(5-1 downto 0); --32 posiciones de memoria
 	--Puertos de salida
	dato_tabla_paletas : out std_logic_vector(8-1 downto 0)
);
end tabla_paletas;

architecture behavioral of tabla_paletas is

signal dir_int_img : natural range 0 to 2**5-1;
type img is array (natural range<>) of std_logic_vector(8-1 downto 0);
constant title : img := (
	"00010001",
	"00100001",
	"00100000",
	"00001101",
	"00010001",
	"00010110",
	"00100110",
	"00001101",
	"00010001",
	"00001001",
	"00011010",
	"00001101",
	"00100010",
	"00100111",
	"00010111",
	"00001111",
	"00010001",
	"00100111",
	"00010110",
	"00011000",
	"00010001",
	"00100111",
	"00001101",
	"00010110",
	"00100010",
	"00010110",
	"00110000",
	"00100111",
	"00100010",
	"00001111",
	"00110110",
	"00010111"
);

begin

dir_int_img <= to_integer(unsigned(dir_tabla_paletas));

P_img: process (clk)
begin
	if clk'event and clk='1' then
		dato_tabla_paletas <= title(dir_int_img);
	end if;
end process;

end behavioral;