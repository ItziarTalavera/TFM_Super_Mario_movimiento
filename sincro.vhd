----------------------------------------------------------------------------------
--                                  Sincro                                      --
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.VGA_PKG.ALL;

entity sincro is
Port (
	-- Puertos de entrada
	clk 	: in  STD_LOGIC;
    rst	    : in  STD_LOGIC;
    -- Puertos de salida
	col     : out unsigned(9 downto 0); 					
	fila    : out unsigned(9 downto 0);
	visible : out std_logic;
	hsync   : out std_logic;
	vsync   : out std_logic
);
end sincro;

architecture Behavioral of sincro is

--VARIABLES PARA LOS CONTADORES--

--Señales para contar 40 ns (4 ciclos de reloj, 1 pixel)
constant c_fin_cuenta : natural := 4;

signal conta1px : unsigned(1 downto 0);   		--2 bits
signal cont_clk : std_logic;

--Señales para contar 800 pixeles, una línea
signal conta800 : unsigned(9 downto 0); 					--10 bits
signal cont_pxl : std_logic;

--Señales para contar 520 líneas, la pantalla
signal conta520 : unsigned(9 downto 0); 					--10 bits
signal cont_line : std_logic;


--Señales visibles
signal visible_pxl : std_logic;
signal visible_line : std_logic;

begin

-- PROCESOS CONTADORES--

--Proceso que genera la señal periódica de 40 ns, 4 ciclos de reloj, 1 pixel
P_cont_clk: Process (rst, clk)
begin
	if rst = '1' then
		conta1px <= (others => '0');
	elsif clk'event and clk = '1' then
		if cont_clk = '1' then
			conta1px <= (others => '0');
		else
			conta1px <= conta1px + 1;
		end if;
	end if;
end process;

--Sentencia concurrente de fin de cuenta
cont_clk <= '1' when conta1px = c_fin_cuenta -1 else '0';

--Proceso que cuenta las columnas (800 pixeles),una línea
P_cont_pxl: Process (rst, clk)
begin
	if rst = '1' then
		conta800 <= (others => '0');
	elsif clk'event and clk = '1' then
		if cont_clk = '1' then
			if cont_pxl = '1' then
				conta800 <= (others => '0');
			else
				conta800 <= conta800 + 1;
			end if;
		end if;
	end if;
end process;

cont_pxl <= '1' when conta800 = 799 and cont_clk = '1' else '0';

--Proceso que cuenta las línas (520 líneas), la pantalla
P_cont_line: Process (rst, clk)
begin
	if rst = '1' then
		conta520 <= (others => '0');
	elsif clk'event and clk = '1' then
		if cont_pxl = '1' then
			if cont_line = '1' then
				conta520 <= (others => '0');
			else
				conta520 <= conta520 + 1;
			end if;
		end if;
	end if;
end process;

cont_line <= '1' when conta520 = 519 and cont_pxl = '1' else '0';

--PROCESOS PARA LAS SEÑALES VISIBLES

--Señales columnas y filas
col <= conta800;
fila <= conta520;

--Señales visibles
visible_pxl <= '1' when conta800 < c_pxl_visible else '0';
visible_line <= '1' when conta520 < c_line_visible else '0';
visible <= '1' when visible_pxl = '1' and visible_line = '1' else '0';
hsync <= '1' when conta800 > c_pxl_2_fporch and conta800 <= c_pxl_2_synch else '0';
vsync <= '1' when conta520 >  c_line_2_fporch and conta520 <= c_line_2_synch else '0';

end Behavioral;
