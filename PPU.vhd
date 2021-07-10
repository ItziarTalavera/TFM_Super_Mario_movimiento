----------------------------------------------------------------------------------
--                                 PPU                                          --
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;
library WORK;
use WORK.VGA_PKG.ALL; 

entity PPU is
port(
   -- Puertos de entrada
	rst	    : in  std_logic;
	clk   	 : in  std_logic;
	derecho   : in std_logic;	 
	izquierdo : in std_logic;
	arriba    : in std_logic;
	abajo  	 : in std_logic;
	comenzar  : in std_logic;
	-- Puertos de salida
	rojo  : out std_logic_vector(c_nb_red-1 downto 0);
	verde : out std_logic_vector(c_nb_green-1 downto 0);
	azul  : out std_logic_vector(c_nb_blue-1 downto 0);
	hsync : out std_logic;
	vsync : out std_logic
);
end PPU;

architecture estructural of PPU is

---- Declaración de componentes de sincro -------------------------------------------------------------------------------
component sincro
port(
	-- Puertos de entrada
	clk 	  : in  STD_LOGIC;
   rst	  : in  STD_LOGIC;
    -- Puertos de salida
	col     : out unsigned(9 downto 0); 					
	fila    : out unsigned(9 downto 0);
	visible : out std_logic;
	hsync   : out std_logic;
	vsync   : out std_logic
);
end component;

---- Declaración de componentes de CPU -------------------------------------------------------------------------------
component CPU
port(
	--Puertos de entrada
	clk 				 		: in std_logic;
	rst 				 		: in std_logic;
	visible 			 		: in std_logic;
	col 				 		: in unsigned(9 downto 0);
	fila 			     		: in unsigned(9 downto 0);
	dato_tabla_nombre	   : in std_logic_vector(8-1 downto 0);
	dato_tabla_patrones  : in std_logic_vector(8-1 downto 0);
	dato_tabla_atributos : in std_logic_vector(8-1 downto 0);
	dato_tabla_paletas   : in std_logic_vector(8-1 downto 0);
	dato_paletas 		 	: in std_logic_vector(12-1 downto 0);
	dato_OAM 			 	: in std_logic_vector(8-1 downto 0);
	derecho 					: in std_logic;
	izquierdo 				: in std_logic;
	abajo 					: in std_logic;
	arriba 					: in std_logic;
	comenzar 				: in std_logic;
	--Puertos de salida
	dir_tabla_nombre 	 	: out std_logic_vector(10-1 downto 0);
	dir_tabla_patrones   : out std_logic_vector(13-1 downto 0);
	dir_tabla_atributos  : out std_logic_vector(6-1 downto 0);
	dir_tabla_paletas    : out std_logic_vector(5-1 downto 0);
	dir_paletas 		 	: out std_logic_vector(6-1 downto 0);
	wea 						: out std_logic;
	dir_OAM  				: out std_logic_vector(8-1 downto 0);
	dato_entrada_OAM 		: out std_logic_vector(8-1 downto 0);
	dir_entrada_OAM 		: out std_logic_vector(8-1 downto 0);
	rojo 				 		: out std_logic_vector(4-1 downto 0);
	verde 				 	: out std_logic_vector(4-1 downto 0);
	azul 				 		: out std_logic_vector(4-1 downto 0)
);
end component;

---- Declaración de componentes de tabla_nombre -------------------------------------------------------------------------------
component tabla_nombre
port(
	--Puertos de entrada
	clk          	  	: in std_logic;
	dir_tabla_nombre  : in std_logic_vector(10-1 downto 0); --960 posiciones de memoria
 	--Puertos de salida
	dato_tabla_nombre : out std_logic_vector(8-1 downto 0)
);
end component;

---- Declaracion de componentes de tabla_patrones -------------------------------------------------------------------------------
component tabla_patrones
port(
	--Puertos de entrada
	clk                 : in std_logic;
	dir_tabla_patrones  : in std_logic_vector(13-1 downto 0); --8192 posiciones de memoria (8 KiB)
 	--Puertos de salida
	dato_tabla_patrones : out std_logic_vector(8-1 downto 0)
);
end component;

---- Declaracion de componentes de tabla_atributos-------------------------------------------------------------------------------
component tabla_atributos
port(
	--Puertos de entrada
	clk          	     	: in std_logic;
	dir_tabla_atributos  : in std_logic_vector(6-1 downto 0); --64 posiciones de memoria
 	--Puertos de salida
	dato_tabla_atributos : out std_logic_vector(8-1 downto 0)
);
end component;

---- Declaracion de componentes de tabla_paletas-------------------------------------------------------------------------------
component tabla_paletas
port(
	--Puertos de entrada
	clk          	    : in std_logic;
	dir_tabla_paletas  : in std_logic_vector(5-1 downto 0); --32 posiciones de memoria
 	--Puertos de salida
	dato_tabla_paletas : out std_logic_vector(8-1 downto 0)
);
end component;

---- Declaracion de componentes de paletas-------------------------------------------------------------------------------
component paletas
port(
	--Puertos de entrada
	dir_paletas  : in std_logic_vector(6-1 downto 0); --64 posiciones de memoria
 	--Puertos de salida
	dato_paletas : out std_logic_vector(12-1 downto 0)
);
end component;

---- Declaracion de componentes de OAM-------------------------------------------------------------------------------
component OAM
port (
	--Puertos de entrada
	clk      			: in std_logic;
	dir_OAM  			: in std_logic_vector(8-1 downto 0);
	dir_entrada_OAM 	: in std_logic_vector(8-1 downto 0);
	dato_entrada_OAM 	: in std_logic_vector(8-1 downto 0);
	wea 					: in std_logic;
 	--Puertos de salida
	dato_OAM 			: out std_logic_vector(8-1 downto 0)
);
end component;

---- Declaracion de señaels intermedias ------------------------------------------------------------------------------
signal col_inter 				   	  : unsigned(9 downto 0);
signal fila_inter				   	  : unsigned(9 downto 0);
signal visible_inter 			     : std_logic;
signal dir_tabla_nombre_inter 	  : std_logic_vector(10-1 downto 0);
signal dato_tabla_nombre_inter	  : std_logic_vector(8-1 downto 0);
signal dir_tabla_patrones_inter    : std_logic_vector(13-1 downto 0);
signal dato_tabla_patrones_inter   : std_logic_vector(8-1 downto 0);
signal dir_tabla_atributos_inter   : std_logic_vector(6-1 downto 0);
signal dato_tabla_atributos_inter  : std_logic_vector(8-1 downto 0);
signal dir_tabla_paletas_inter     : std_logic_vector(5-1 downto 0);
signal dato_tabla_paletas_inter    : std_logic_vector(8-1 downto 0);
signal dir_paletas_inter           : std_logic_vector(6-1 downto 0);
signal dato_paletas_inter          : std_logic_vector(12-1 downto 0);
signal dir_OAM_inter	           	  : std_logic_vector(8-1 downto 0);
signal dato_OAM_inter	           : std_logic_vector(8-1 downto 0);
signal wea_inter 				   	  : std_logic;
signal dato_entrada_OAM_inter 	  : std_logic_vector(8-1 downto 0);
signal dir_entrada_OAM_inter       : std_logic_vector(8-1 downto 0);

begin

--- Referencia a componente sincro ----------------------------------------------------------------------------------------
Sincro_VGA : sincro
port map(
	rst		=> rst,
	clk		=> clk,
	col		=> col_inter,
	fila		=> fila_inter,
	visible	=> visible_inter,
	hsync		=> hsync,
	vsync		=> vsync
);

---- Referencia a componente de CPU --------------------------------------------------------------------------
VGA_CPU : CPU
port map(
	clk 				  		=> clk,
	rst 				  		=> rst,
	visible 			  		=> visible_inter,
	col 				  		=> col_inter,
	fila 			      	=> fila_inter,
	dato_tabla_nombre	  	=> dato_tabla_nombre_inter,
	dato_tabla_patrones  => dato_tabla_patrones_inter,
	dato_tabla_atributos => dato_tabla_atributos_inter,
	dato_tabla_paletas   => dato_tabla_paletas_inter,
	dato_paletas 		  	=> dato_paletas_inter,
	dato_OAM 			  	=> dato_OAM_inter,
	dir_tabla_nombre 	  	=> dir_tabla_nombre_inter,
	dir_tabla_patrones   => dir_tabla_patrones_inter,
	dir_tabla_atributos  => dir_tabla_atributos_inter,
	dir_tabla_paletas    => dir_tabla_paletas_inter,
	dir_paletas 		  	=> dir_paletas_inter,
	dir_OAM  			  	=> dir_OAM_inter,
   wea 				  		=> wea_inter,
	dato_entrada_OAM 		=> dato_entrada_OAM_inter,
	dir_entrada_OAM 		=> dir_entrada_OAM_inter,
	derecho 					=>	derecho,
	izquierdo 				=> izquierdo,
	arriba 					=> arriba,
	abajo 					=> abajo,
	comenzar 				=> comenzar,
	rojo 				  		=> rojo,
	verde 				  	=> verde,
	azul 				  		=> azul
);

---- Referencia a componentes de tabla_nombre -------------------------------------------------------------------------------
VGA_tabla_nombre : tabla_nombre
port map(
	clk 					=> clk,
	dir_tabla_nombre  => dir_tabla_nombre_inter,
	dato_tabla_nombre => dato_tabla_nombre_inter
);

---- Referencia a componentes de tabla_patrones -------------------------------------------------------------------------------
VGA_tabla_patrones : tabla_patrones
port map(
	clk 					  => clk,
	dir_tabla_patrones  => dir_tabla_patrones_inter,
	dato_tabla_patrones =>dato_tabla_patrones_inter
);

---- Referencia a componentes de tabla_atributos -------------------------------------------------------------------------------
VGA_tabla_atributos : tabla_atributos
port map(	
	clk 						=> clk,
	dir_tabla_atributos  => dir_tabla_atributos_inter,
	dato_tabla_atributos => dato_tabla_atributos_inter
);

---- Referencia a componentes de tabla_paletas -------------------------------------------------------------------------------
VGA_tabla_paletas : tabla_paletas
port map(
	clk 					 => clk,
	dir_tabla_paletas  => dir_tabla_paletas_inter,
	dato_tabla_paletas => dato_tabla_paletas_inter
);

---- Referencia a componentes de paletas -------------------------------------------------------------------------------
VGA_paletas : paletas
port map(
	dir_paletas  => dir_paletas_inter,
	dato_paletas => dato_paletas_inter
);

---- Referencia a componentes de OAM -------------------------------------------------------------------------------
VGA_OAM : OAM
port map(
    clk      		  => clk,
	dir_OAM  		  => dir_OAM_inter,
	dato_entrada_OAM => dato_entrada_OAM_inter,
	wea 				  => wea_inter,
	dato_OAM 		  => dato_OAM_inter,
	dir_entrada_OAM  => dir_entrada_OAM_inter
);
	
end estructural;

