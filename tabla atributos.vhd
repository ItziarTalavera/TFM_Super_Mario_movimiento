----------------------------------------------------------------------------------
--                            Tabla de atributos                                --
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library WORK;
use WORK.VGA_PKG.ALL;

entity tabla_atributos is
	port (
	--Puertos de entrada
	clk          	     : in std_logic;
	dir_tabla_atributos  : in std_logic_vector(6-1 downto 0); --64 posiciones de memoria
 	--Puertos de salida
	dato_tabla_atributos : out std_logic_vector(8-1 downto 0)
);
end tabla_atributos;

architecture behavioral of tabla_atributos is

signal dir_int_img : natural range 0 to 2**6-1;
type img is array (natural range<>) of std_logic_vector(8-1 downto 0);
constant title : img := (
    "00000000",
    "00000000",
    "00000000", 
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "01010000",
    "00010000",
    "00000000",
    "01000000",
    "01010000",
    "00010000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "01010000",
    "00010000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "00000000",
    "01011010",
    "01010010",
    "01010000",
    "01010000",
    "01010000",
    "01010000",
    "01010000",
    "01010000",
    "00000101",
    "00000101",
    "00000101",
    "00000101",
    "00000101",
    "00000101",
    "00000101",
    "00000101"
);

begin

dir_int_img <= to_integer(unsigned(dir_tabla_atributos));

P_img: process (clk)
begin
	if clk'event and clk='1' then
		dato_tabla_atributos <= title(dir_int_img);
	end if;
end process;

end behavioral;