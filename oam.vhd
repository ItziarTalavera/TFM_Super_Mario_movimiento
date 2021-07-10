----------------------------------------------------------------------------------
--                         		   OAM      	  		                        --
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library WORK;
use WORK.VGA_PKG.ALL;

entity OAM is
	port (
	--Puertos de entrada
	clk      : in std_logic;
	dir_OAM  : in std_logic_vector(8-1 downto 0);
	dir_entrada_OAM : in std_logic_vector(8-1 downto 0);
	dato_entrada_OAM : in std_logic_vector(8-1 downto 0);
	wea : in std_logic;
 	--Puertos de salida
	dato_OAM : out std_logic_vector(8-1 downto 0)
);
end OAM;

architecture behavioral of OAM is

signal dir_int_entrada_OAM : natural range 0 to 2**8-1;		
signal dir_int_img : natural range 0 to 2**8-1;
type img is array (natural range<>) of std_logic_vector(8-1 downto 0);
signal imagen : img(0 to 2**8-1); 

begin

dir_int_entrada_OAM <= to_integer(unsigned(dir_entrada_OAM));
dir_int_img <= to_integer(unsigned(dir_OAM));

P_OAM: process(clk)
begin
if clk'event and clk='1' then
	if wea = '1' then   -- si se escribe en a
		imagen(dir_int_entrada_OAM) <= dato_entrada_OAM;
	end if;
	dato_OAM <= imagen(dir_int_img);
end if;
end process;

end behavioral;