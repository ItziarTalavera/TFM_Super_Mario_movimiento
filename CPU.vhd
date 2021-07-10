----------------------------------------------------------------------------------
--                                   CPU                                        --
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library WORK;
use WORK.VGA_PKG.ALL;

entity CPU is
	Port (
	--Puertos de entrada
	clk 				 : in std_logic;
	rst 				 : in std_logic;
	visible 			 : in std_logic;
	col 				 : in unsigned(9 downto 0);
	fila 			     : in unsigned(9 downto 0);
	dato_tabla_nombre	 : in std_logic_vector(8-1 downto 0);
	dato_tabla_patrones  : in std_logic_vector(8-1 downto 0);
	dato_tabla_atributos : in std_logic_vector(8-1 downto 0);
	dato_tabla_paletas   : in std_logic_vector(8-1 downto 0);
	dato_paletas 		 : in std_logic_vector(12-1 downto 0);
	dato_OAM 			 : in std_logic_vector(8-1 downto 0);
	derecho 			 : in std_logic;
	izquierdo 			 : in std_logic;
	abajo 				 : in std_logic;
	arriba 				 : in std_logic;
	comenzar 			 : in std_logic;
	--Puertos de salida
	dir_tabla_nombre 	 : out std_logic_vector(10-1 downto 0);
	dir_tabla_patrones   : out std_logic_vector(13-1 downto 0);
	dir_tabla_atributos  : out std_logic_vector(6-1 downto 0);
	dir_tabla_paletas    : out std_logic_vector(5-1 downto 0);
	dir_paletas 		 : out std_logic_vector(6-1 downto 0);
	wea 				 : out std_logic;
	dir_OAM  			 : out std_logic_vector(8-1 downto 0);
	dato_entrada_OAM 	 : out std_logic_vector(8-1 downto 0);
	dir_entrada_OAM 	 : out std_logic_vector(8-1 downto 0);
	rojo 				 : out std_logic_vector(4-1 downto 0);
	verde 				 : out std_logic_vector(4-1 downto 0);
	azul 				 : out std_logic_vector(4-1 downto 0)
);
end CPU;

architecture behavioral of CPU is

--Señales para contar los 4 ciclos de reloj, 1 pixel
constant c_fin_cuenta : natural := 4;
signal conta1px  	  : unsigned(1 downto 0); --2 bits
signal nuevo_pxl 	  : std_logic; --Señal a '1' cuando se empieza un pixel (4 ciclos de reloj)

--Señales para contar 800 ms para comprobar el boton
constant c_fin_cuentaboton 	: natural := 8*10**6;
signal cuentaboton 		  	: unsigned(22 downto 0);
signal controlaboton 		: std_logic;

--Señales para mover el coche
signal posicion_col 		: unsigned(4 downto 0);
signal posicion_fila 		: unsigned(4 downto 0);
signal escribir_OAM 		: std_logic;
signal fin_mov_sprites 		: std_logic;
signal cuenta_mov_sprites 	: unsigned(3 downto 0);

--Sañales para acceder al mosaico actual
signal cuad_fila 	  : std_logic_vector(4 downto 0); --Fila de 8 a 4
signal in_fila 	 	  : std_logic_vector(2 downto 0); --Fila de 3 a 1
signal cuad_col  	  : std_logic_vector(4 downto 0); --Columna de 8 a 4
signal in_col 		  : unsigned(2 downto 0); --Columna de 3 a 1
signal in_col_vga 	  : unsigned(3 downto 0); --Columna de 3 a 0
signal fila_celda_act : unsigned(13 downto 0); --Fila actual

--Señales para acceder al mosaico iguiente
signal cuad_fila_sig  : std_logic_vector(4 downto 0); --Fila siguiene de 8 a 4
signal in_fila_sig 	  : std_logic_vector(2 downto 0); --Fila siguiene de 3 a 1
signal cuad_col_sig   : std_logic_vector(4 downto 0); --Columna siguiente de 8 a 4
signal fila_celda_sig : unsigned(13 downto 0); --Fila siguiente

--Señales para la maquina de estado 
type estados is (espera, t_byte_0, t_y_pos, t_byte_2, t_atributo_sprite, t_byte_3, t_x_pos, t_indice_sprite, t_pinta_sprite, t_nombre, t_atributo, t_patron_0, t_patron_1, t_paleta, t_paleta_guarda);
signal estado_actual, estado_siguiente : estados;

signal fin_celda 	  : std_logic; --Señal de final de la celda
signal pide_color_num : unsigned(1 downto 0); --Señal para pedir los 4 colores de la paleta
signal nuevo_color 	  : std_logic; --Señal de final de la celda
signal pide_color	  : std_logic;

signal dato_nombre			: std_logic_vector(7 downto 0); --Señal para guardar el valor de la tabla de nombre 
signal dato_atributos		: std_logic_vector(7 downto 0); --Señal para guardar el valor de la tabla de atributos
signal dato_patron_0		: std_logic_vector(7 downto 0); --Señal para guardar el valor de la tabla de patrones del plano 0
signal dato_patron_1		: std_logic_vector(7 downto 0); --Señal para guardar el valor de la tabla de patrones del plano 1
signal selec_paleta			: std_logic_vector(1 downto 0); --Señal que seleeciona la paleta dependiendo de la tabla de atributos
signal dato_paleta_0		: std_logic_vector(5 downto 0); --Señal que guarda el valor del color 0 de la tabla de paletas
signal dato_paleta_1		: std_logic_vector(5 downto 0); --Señal que guarda el valor del color 1 de la tabla de paletas
signal dato_paleta_2		: std_logic_vector(5 downto 0); --Señal que guarda el valor del color 2 de la tabla de paletas
signal dato_paleta_3 		: std_logic_vector(5 downto 0); --Señal que guarda el valor del color 3 de la tabla de paletas
signal y_pos 				: std_logic_vector(7 downto 0); --Señal que guarda el valor y (fila) del sprite
signal atributo_sprite 		: std_logic_vector(7 downto 0); --Señal que guarda el valor del atributo del sprite
signal x_pos 				: std_logic_vector(7 downto 0); --Señal que guarda el valor x (columna) del sprite
signal indice_sprite		: std_logic_vector(7 downto 0); --Señal que guarda el valor del incice del sprite
signal pinta_sprite 		: std_logic;
signal cuenta_sprite 		: unsigned(3 downto 0);
signal volteo_horizontal 	: std_logic;
signal dato_patron_0_def	: std_logic_vector(7 downto 0); --Señal para guardar el valor de la tabla de patrones del plano 0
signal dato_patron_1_def	: std_logic_vector(7 downto 0); --Señal para guardar el valor de la tabla de patrones del plano 1
signal indice_sprite_volteo	: unsigned(7 downto 0); --Señal que guarda el valor del incice del sprite
signal volteo_vertical 		: std_logic;

--Señales para elegir el color final
signal selec_color 		  : std_logic_vector(1 downto 0); --Señal que selecciona el color dependiendo de las tablas de patrones
signal dato_patron_0_act  : std_logic_vector(7 downto 0); --Señal para guardar el valor de la tabla de patrones del plano 0
signal dato_patron_1_act  : std_logic_vector(7 downto 0); --Señal para guardar el valor de la tabla de patrones del plano 1
signal dato_paleta_0_act  : std_logic_vector(5 downto 0); --Señal que guarda el valor del color 0 de la tabla de paletas
signal dato_paleta_1_act  : std_logic_vector(5 downto 0); --Señal que guarda el valor del color 1 de la tabla de paletas
signal dato_paleta_2_act  : std_logic_vector(5 downto 0); --Señal que guarda el valor del color 2 de la tabla de paletas
signal dato_paleta_3_act  : std_logic_vector(5 downto 0); --Señal que guarda el valor del color 3 de la tabla de paletas

--Señales para inicializar la OAM
signal fin_OAM : std_logic;
signal cuenta_OAM : unsigned(7 downto 0); 
type img_OAM is array (natural range<>) of std_logic_vector(8-1 downto 0);
constant title : img_OAM := (
	"00010110",
	"00000000",
	"00000000",
	"00001000",
	"00010110",
	"00000001",
	"00000000",
	"00001001",
	"00010111",
	"00000010",
	"00000000",
	"00001000",
	"00010111",
	"00000011",
	"00000000",
	"00001001",
	"00011000",
	"00000100",
	"00000000",
	"00001000",
	"00011000",
	"00000101",
	"00000000",
	"00001001",
	"00011001",
	"00000110",
	"00000000",
	"00001000",
	"00011001",
	"00000111",
	"00000000",
	"00001001",
	"00010000",
	"01110000",
	"00000001",
	"00010110",
	"00010000",
	"01110001",
	"00000001",
	"00010111",
	"00010001",
	"01110010",
	"00000001",
	"00010110",
	"00010001",
	"01110011",
	"00000001",
	"00010111",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000",
	"00000000",
	"00000000",
	"00100000",
	"00000000"
);

begin

--COLUMNAS Y FILAS ACTUALES--

--Señales actuales
cuad_fila <= std_logic_vector(fila(8 downto 4)); --Fila de la cuadricula en la que se dividen la tabla de nombre (30)
in_fila <= std_logic_vector(fila(3 downto 1)); --Fila dentro de cada cuadricula de la tabla de nombre, fila de los mosaicos (8)
cuad_col <= std_logic_vector(col(8 downto 4)); --Columna de la cuadricula en la que se dividen la tabla de nombre (32)
in_col <= unsigned(col(3 downto 1)); --Columna dentro de cada cuadricula de la tabla de nombre, columna de los mosaicos (8)
in_col_vga <= col(3 downto 0); --Columna de la vga (16)
fila_celda_act(4 downto 0) <= unsigned(cuad_col); --Fila celda actual
fila_celda_act(5) <= fila(0); --Fila celda actual
fila_celda_act(8 downto 6) <= unsigned(in_fila); --Fila celda actual
fila_celda_act(13 downto 9) <= unsigned(cuad_fila); --Fila celda actual

--COLUMNAS Y FILAS SIGUIENTES--

P_fila_sig: Process(fila_celda_act, visible)
begin
	if visible = '1' then
		fila_celda_sig <= fila_celda_act + 1;
	else
		fila_celda_sig <= (others => '0');
	end if;
end process;

cuad_col_sig <= std_logic_vector(fila_celda_sig(4 downto 0)); --Columna siguiente de la cuadricula de la tabla de nombre

--CONTADOR NUEVO PIXEL

--Proceso que cuenta 4 ciclos de reloj, 1 pixel
P_cont_clk: Process (rst, clk)
begin
	if rst = '1' then
		conta1px <= (others => '0');
	elsif clk'event and clk = '1' then
		if nuevo_pxl = '1' then
			conta1px <= (others => '0');
		else
			conta1px <= conta1px + 1;
		end if;
	end if;
end process;

--Sentencia concurrente de fin de cuenta
nuevo_pxl <= '1' when conta1px = c_fin_cuenta - 1 else '0';

--Señal de fin de la celda
fin_celda <= '1' when nuevo_pxl = '1' and in_col_vga = 15 else '0';

P_cont_paletas: Process (rst, clk)
begin
	if rst = '1' then
		pide_color_num <= (others => '0');
	elsif clk'event and clk = '1' then
		if pide_color = '1' then
			if nuevo_color = '1' then
				pide_color_num <= (others => '0');
			else
				pide_color_num <= pide_color_num + 1;
			end if;
		end if;
	end if;
end process;

nuevo_color <= '1' when pide_color_num = c_fin_cuenta - 1 else '0';

--POSICIÓN MARIO--
--Proceso que genera la señal periódica de 800 ms para comprobar el boton
P_contador: Process (rst, clk)
begin
	if rst = '1' then
		cuentaboton <= (others => '0');
	elsif clk'event and clk = '1' then
		if controlaboton = '1' then
			cuentaboton <= (others => '0');
		else
			cuentaboton <= cuentaboton + 1;
		end if;
	end if;
end process;

--Sentencia concurrente de fin de cuenta
controlaboton <= '1' when cuentaboton = c_fin_cuentaboton -1 else '0';

--Inicialización de la OAM
P_iniciarliar: Process (rst, clk)
begin
	if rst = '1' then
		cuenta_OAM <= (others => '0');
		cuenta_mov_sprites <= (others => '0');
		dir_entrada_OAM <= (others => '0');
		dato_entrada_OAM <= (others => '0');
		posicion_col <= "01000"; --8
		posicion_fila <= "10110"; --22
		escribir_OAM <='0';
	elsif clk'event and clk = '1' then
		if comenzar = '1' then
			if fin_OAM = '1' then
				cuenta_OAM <= (others => '0');
			else
				cuenta_OAM <= cuenta_OAM + 1;
			end if;
			escribir_OAM <= '1';
			dir_entrada_OAM <= std_logic_vector(cuenta_OAM);
			dato_entrada_OAM <= title(to_integer(unsigned(cuenta_OAM)));
			posicion_col <= "01000"; --8
			posicion_fila <= "10110"; --22
		else
			if controlaboton = '1' then
				if derecho = '1' then
					if posicion_col = "11111" then
						posicion_col <= "00000";
					else
						posicion_col <= posicion_col + 1;
					end if;
					escribir_OAM <='1';
				elsif izquierdo = '1' then
					if posicion_col = "00000" then
						posicion_col <= "11111";
					else
						posicion_col <= posicion_col - 1;
					end if;
					escribir_OAM <='1';
				elsif arriba = '1' then
					if posicion_fila = "00000" then
						posicion_fila <= "11101";
					else
						posicion_fila <= posicion_fila - 1;
					end if;
					escribir_OAM <='1';				
				elsif abajo = '1' then
					if posicion_fila = "11101" then
						posicion_fila <= "00000";
					else
						posicion_fila <= posicion_fila + 1;
					end if;
					escribir_OAM <='1';				
				end if;
			end if;
			if fin_mov_sprites = '1' then
				cuenta_mov_sprites <= (others => '0');
			else
				cuenta_mov_sprites <= cuenta_mov_sprites + 1;
			end if;
			dir_entrada_OAM(7 downto 5) <= (others => '0');
			--dir_entrada_OAM(4 downto 2) <= "111";
			dir_entrada_OAM(4 downto 2) <= std_logic_vector(cuenta_mov_sprites(3 downto 1));
			if std_logic(cuenta_mov_sprites(0)) = '0' then
				dir_entrada_OAM(1 downto 0) <= "00";
			else
				dir_entrada_OAM(1 downto 0) <= "11";
			end if;
			dato_entrada_OAM(7 downto 5) <= (others => '0');
			case cuenta_mov_sprites is 
				when "0000" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_fila);
				when "0001" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_col);
				when "0010" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_fila);
				when "0011" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_col + 1);
				when "0100" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_fila + 1);
				when "0101" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_col);
				when "0110" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_fila + 1);
				when "0111" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_col + 1);
				when "1000" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_fila + 2);
				when "1001" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_col);
				when "1010" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_fila + 2);
				when "1011" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_col + 1);
				when "1100" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_fila + 3);
				when "1101" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_col);
				when "1110" =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_fila + 3);
				when others =>
					dato_entrada_OAM(4 downto 0) <= std_logic_vector(posicion_col + 1);
			end case;
		end if;
	end if;
end process;

fin_OAM <= '1' when cuenta_OAM = 255 else '0';
fin_mov_sprites <= '1' when  cuenta_mov_sprites = 15 else '0';

--Proceso que indica cuando escribir en la OAM, cuando comenzamos para inicializar la OAM y cuando pulsamos los botones para mover el coche
P_escribir_OAM: Process (escribir_OAM)
begin
	if escribir_OAM = '1' then
		wea <= '1';
	else
		wea <= '0';
	end if;
end process;

--MAQUINA DE ESTADO--

--Registro de estados
P_estado_0: Process(clk, rst)
begin
	if rst = '1' then
		estado_actual <= espera;
	elsif clk'event and clk = '1' then
		estado_actual <= estado_siguiente;
	end if;
end process;

--Lógica de estado siguiente 
P_estado_1: Process (estado_actual, fin_celda, pide_color_num, cuad_col_sig, cuad_fila, in_fila, dato_nombre, selec_paleta, dato_atributos, cuenta_sprite, volteo_vertical, volteo_horizontal, y_pos, atributo_sprite, x_pos, pinta_sprite, indice_sprite,indice_sprite_volteo)
begin
    estado_siguiente <= estado_actual;
    dir_tabla_nombre <= (others => '0');
    dir_tabla_atributos <= (others => '0');
    dir_tabla_patrones <= (others => '0');
	 selec_paleta(0) <= cuad_col_sig(1); --Seleccion de la paleta por la columna 
	 selec_paleta(1) <= cuad_fila(1); --Seleccion de la paleta por la fila
    dir_tabla_paletas <= (others => '0');
	 dir_OAM <= (others => '0');
	 indice_sprite_volteo <= (others => '0');
    case estado_actual is 
	    when espera =>
	        if fin_celda = '1' then
	            estado_siguiente <= t_byte_0; 
	        end if;
		when t_byte_0 =>
			dir_OAM(7 downto 6) <= (others => '0');
			dir_OAM(5 downto 2) <= std_logic_vector(cuenta_sprite);
			dir_OAM(1 downto 0) <= "00";
			estado_siguiente <= t_y_pos;
		when t_y_pos =>
			estado_siguiente <= t_byte_2;
		when t_byte_2 =>	
			if unsigned(y_pos) = unsigned(cuad_fila) then
				estado_siguiente <= t_atributo_sprite;
				dir_OAM(7 downto 6) <= (others => '0');
				dir_OAM(5 downto 2) <= std_logic_vector(cuenta_sprite);
				dir_OAM(1 downto 0) <= "10";
			elsif cuenta_sprite < 11 then
				estado_siguiente <= t_byte_0;
			else
				estado_siguiente <= t_nombre;
			end if;
		when t_atributo_sprite =>
			estado_siguiente <= t_byte_3;
		when t_byte_3 =>
			if atributo_sprite(5) = '0' then --En frente del fondo
				estado_siguiente <= t_x_pos;
				dir_OAM(7 downto 6) <= (others => '0');
				dir_OAM(5 downto 2) <= std_logic_vector(cuenta_sprite);
				dir_OAM(1 downto 0) <= "11";
			elsif cuenta_sprite < 11 then
				estado_siguiente <= t_byte_0;
			else	
				estado_siguiente <= t_nombre;
			end if;
		when t_x_pos =>
			estado_siguiente <= t_indice_sprite;
		when t_indice_sprite =>
			if unsigned(x_pos) = unsigned(cuad_col_sig) then
				estado_siguiente <= t_pinta_sprite;
				dir_OAM(7 downto 6) <= (others => '0');
				dir_OAM(5 downto 2) <= std_logic_vector(cuenta_sprite);
				dir_OAM(1 downto 0) <= "01";
			elsif cuenta_sprite < 11 then
				estado_siguiente <= t_byte_0;
			else	
				estado_siguiente <= t_nombre;
			end if;	
		when t_pinta_sprite =>
			estado_siguiente <= t_patron_0;
	    when t_nombre =>
	    	estado_siguiente <= t_atributo;
	    	dir_tabla_nombre(4 downto 0) <= cuad_col_sig;
			if cuad_fila = "11110" or cuad_fila = "11111" then 
				dir_tabla_nombre(9 downto 5) <= "00000";
			else
				dir_tabla_nombre(9 downto 5) <= cuad_fila;
			end if;
	    when t_atributo =>
	    	estado_siguiente <= t_patron_0;
			dir_tabla_atributos(2 downto 0) <= cuad_col_sig(4 downto 2);
			dir_tabla_atributos(5 downto 3) <= cuad_fila(4 downto 2);
	    when t_patron_0 =>
	    	estado_siguiente <= t_patron_1;
			if volteo_vertical = '1' then
				case in_fila is
					when "000" =>
						dir_tabla_patrones(2 downto 0) <= "111";
					when "001" =>
						dir_tabla_patrones(2 downto 0) <= "110";
					when "010" =>
						dir_tabla_patrones(2 downto 0) <= "101";
					when "011" =>
						dir_tabla_patrones(2 downto 0) <= "100";
					when "100" =>
						dir_tabla_patrones(2 downto 0) <= "011";
					when "101" =>
						dir_tabla_patrones(2 downto 0) <= "010";
					when "110" =>
						dir_tabla_patrones(2 downto 0) <= "001";
					when others =>
						dir_tabla_patrones(2 downto 0) <= "000";
				end case;
			else
				dir_tabla_patrones(2 downto 0) <= in_fila;
			end if;
			dir_tabla_patrones(3) <= '0';
			if pinta_sprite = '1' then
				if volteo_horizontal = '1' and volteo_vertical = '0' then
					if indice_sprite(0) = '0' then
						indice_sprite_volteo <= unsigned(indice_sprite) + 1;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					else	
						indice_sprite_volteo <= unsigned(indice_sprite) - 1;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					end if;
				elsif volteo_horizontal = '0' and volteo_vertical = '1' then
					if indice_sprite(1 downto 0) = "00" or indice_sprite(1 downto 0) = "01" then
						indice_sprite_volteo <= unsigned(indice_sprite) + 2;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					else	
						indice_sprite_volteo <= unsigned(indice_sprite) - 2;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					end if;
				elsif volteo_horizontal = '1' and volteo_vertical = '1' then
					if indice_sprite(1 downto 0) = "00" then
						indice_sprite_volteo <= unsigned(indice_sprite) + 3;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo);
					elsif indice_sprite(1 downto 0) = "01" then
						indice_sprite_volteo <= unsigned(indice_sprite) + 1;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo);
					elsif indice_sprite(1 downto 0) = "10" then
						indice_sprite_volteo <= unsigned(indice_sprite) - 1;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo);
					else	
						indice_sprite_volteo <= unsigned(indice_sprite) - 3;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					end if;
				else
					dir_tabla_patrones(11 downto 4) <= indice_sprite; 
				end if;
				dir_tabla_patrones(12) <= '1';
			else
				dir_tabla_patrones(11 downto 4) <= dato_nombre; 
				dir_tabla_patrones(12) <= '0';
			end if;
	    when t_patron_1 =>
	    	estado_siguiente <= t_paleta;
			if volteo_vertical = '1' then
				case in_fila is
					when "000" =>
						dir_tabla_patrones(2 downto 0) <= "111";
					when "001" =>
						dir_tabla_patrones(2 downto 0) <= "110";
					when "010" =>
						dir_tabla_patrones(2 downto 0) <= "101";
					when "011" =>
						dir_tabla_patrones(2 downto 0) <= "100";
					when "100" =>
						dir_tabla_patrones(2 downto 0) <= "011";
					when "101" =>
						dir_tabla_patrones(2 downto 0) <= "010";
					when "110" =>
						dir_tabla_patrones(2 downto 0) <= "001";
					when others =>
						dir_tabla_patrones(2 downto 0) <= "000";
				end case;
			else
				dir_tabla_patrones(2 downto 0) <= in_fila;
			end if;
			dir_tabla_patrones(3) <= '1';
			if pinta_sprite = '1' then
				if volteo_horizontal = '1' and volteo_vertical = '0' then
					if indice_sprite(0) = '0' then
						indice_sprite_volteo <= unsigned(indice_sprite) + 1;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					else	
						indice_sprite_volteo <= unsigned(indice_sprite) - 1;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					end if;
				elsif volteo_horizontal = '0' and volteo_vertical = '1' then
					if indice_sprite(1 downto 0) = "00" or indice_sprite(1 downto 0) = "01" then
						indice_sprite_volteo <= unsigned(indice_sprite) + 2;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					else	
						indice_sprite_volteo <= unsigned(indice_sprite) - 2;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					end if;
				elsif volteo_horizontal = '1' and volteo_vertical = '1' then
					if indice_sprite(1 downto 0) = "00" then
						indice_sprite_volteo <= unsigned(indice_sprite) + 3;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo);
					elsif indice_sprite(1 downto 0) = "01" then
						indice_sprite_volteo <= unsigned(indice_sprite) + 1;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo);
					elsif indice_sprite(1 downto 0) = "10" then
						indice_sprite_volteo <= unsigned(indice_sprite) - 1;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo);
					else	
						indice_sprite_volteo <= unsigned(indice_sprite) - 3;
						dir_tabla_patrones(11 downto 4) <= std_logic_vector(indice_sprite_volteo); 
					end if;
				else
					dir_tabla_patrones(11 downto 4) <= indice_sprite; 
				end if;
				dir_tabla_patrones(12) <= '1';
			else
				dir_tabla_patrones(11 downto 4) <= dato_nombre; 
				dir_tabla_patrones(12) <= '0';
			end if;
	    when t_paleta =>
			if pinta_sprite = '1' then
				dir_tabla_paletas(3 downto 2) <= atributo_sprite(1 downto 0);
				dir_tabla_paletas(4) <= '1';
			else
				if selec_paleta = "00" then
					dir_tabla_paletas(3 downto 2) <= dato_atributos(1 downto 0);
				elsif selec_paleta = "01" then
					dir_tabla_paletas(3 downto 2) <= dato_atributos(3 downto 2);
				elsif selec_paleta = "10" then
					dir_tabla_paletas(3 downto 2) <= dato_atributos(5 downto 4);
				else
					dir_tabla_paletas(3 downto 2) <= dato_atributos(7 downto 6);
				end if;
				dir_tabla_paletas(4) <= '0';
			end if;
			if pide_color_num = "00" then
				estado_siguiente <= t_paleta;
				dir_tabla_paletas(1 downto 0) <= "00";
			elsif pide_color_num = "01" then
				estado_siguiente <= t_paleta;
				dir_tabla_paletas(1 downto 0) <= "01";
			elsif pide_color_num = "10" then
				estado_siguiente <= t_paleta;
				dir_tabla_paletas(1 downto 0) <= "10";
			else
				estado_siguiente <= t_paleta_guarda;
				dir_tabla_paletas(1 downto 0) <= "11";
			end if;
	    when others =>
	    	estado_siguiente <= espera;
    end case;
end process;

P_estado_3: Process(rst, clk)
begin
	if rst = '1' then
		dato_nombre <= (others => '0');
		dato_atributos <= (others => '0');
		dato_patron_0 <= (others => '0');
		dato_patron_1 <= (others => '0');
		dato_paleta_0 <= (others => '0');
		dato_paleta_1 <= (others => '0');
		dato_paleta_2 <= (others => '0');
		dato_paleta_3 <= (others => '0');
		y_pos <= (others => '0');
		atributo_sprite <= (others => '0');
		x_pos <= (others => '0');
		indice_sprite <= (others => '0');
		pinta_sprite <= '0';
		pide_color <= '0';
		cuenta_sprite <= (others => '0');
		volteo_horizontal <= '0';
		volteo_vertical <= '0';
	elsif clk'event and clk = '1' then
		case estado_actual is
			when t_y_pos =>
				y_pos <= dato_OAM;
			when t_byte_2 =>	
				if unsigned(y_pos) = unsigned(cuad_fila) then
					cuenta_sprite <= cuenta_sprite;
				elsif cuenta_sprite = 11 then
					cuenta_sprite <= (others => '0');
				else
					cuenta_sprite <= cuenta_sprite + 1;
				end if;
			when t_atributo_sprite =>
				atributo_sprite <= dato_OAM;
			when t_byte_3 =>
				if atributo_sprite(5) = '0' then --En frente del fondo
					cuenta_sprite <= cuenta_sprite;
				elsif cuenta_sprite = 11 then
					cuenta_sprite <= (others => '0');
				else	
					cuenta_sprite <= cuenta_sprite + 1;
				end if;
			when t_x_pos =>
				x_pos <= dato_OAM;
			when t_indice_sprite =>
				if unsigned(x_pos) = unsigned(cuad_col_sig) then
					cuenta_sprite <= cuenta_sprite;
				elsif cuenta_sprite = 11 then
					cuenta_sprite <= (others => '0');
				else	
					cuenta_sprite <= cuenta_sprite + 1;
				end if;	
			when t_pinta_sprite =>
				indice_sprite <= dato_OAM;
				pinta_sprite <= '1';
				if atributo_sprite(6) = '1' and atributo_sprite(7) = '0' then
					volteo_horizontal <= '1';
					volteo_vertical <= '0';
				elsif atributo_sprite(6) = '0' and atributo_sprite(7) = '1' then
					volteo_horizontal <= '0';
					volteo_vertical <= '1';
				elsif atributo_sprite(6) = '1' and atributo_sprite(7) = '1' then
					volteo_horizontal <= '1';
					volteo_vertical <= '1';
				else
					volteo_horizontal <= '0';
					volteo_vertical <= '0';
				end if;
				if cuenta_sprite = 11 then
					cuenta_sprite <= (others => '0');
				else
					cuenta_sprite <= cuenta_sprite + 1;
				end if;
			when t_atributo =>
				volteo_horizontal <= '0';
				volteo_vertical <= '0';
				dato_nombre <= dato_tabla_nombre; --Se guarda el dato con el nombre del mosaico
				pinta_sprite <= '0';
			when t_patron_0 =>
				dato_atributos <= dato_tabla_atributos; --Se guarda el dato con el atributo del mosaico
			when t_patron_1 =>
				dato_patron_0 <= dato_tabla_patrones; --Se guarda el dato con el patron del plano 0 del mosaico
				pide_color <= '1';
			when t_paleta =>
				if pide_color_num = "00" then
					pide_color <= '1';
					if volteo_horizontal = '1' then
						dato_patron_0_def(7) <= dato_patron_0(0);
						dato_patron_0_def(6) <= dato_patron_0(1);
						dato_patron_0_def(5) <= dato_patron_0(2);
						dato_patron_0_def(4) <= dato_patron_0(3);
						dato_patron_0_def(3) <= dato_patron_0(4);
						dato_patron_0_def(2) <= dato_patron_0(5);
						dato_patron_0_def(1) <= dato_patron_0(6);
						dato_patron_0_def(0) <= dato_patron_0(7);
					else
						dato_patron_0_def <= dato_patron_0;
					end if;
					dato_patron_1 <= dato_tabla_patrones; --Se guarda el dato con el patron del plano 1 del mosaico
				elsif pide_color_num = "01" then
					pide_color <= '1';
					if volteo_horizontal = '1' then
						dato_patron_1_def(7) <= dato_patron_1(0);
						dato_patron_1_def(6) <= dato_patron_1(1);
						dato_patron_1_def(5) <= dato_patron_1(2);
						dato_patron_1_def(4) <= dato_patron_1(3);
						dato_patron_1_def(3) <= dato_patron_1(4);
						dato_patron_1_def(2) <= dato_patron_1(5);
						dato_patron_1_def(1) <= dato_patron_1(6);
						dato_patron_1_def(0) <= dato_patron_1(7);
					else
						dato_patron_1_def <= dato_patron_1;
					end if;
					dato_paleta_0 <= dato_tabla_paletas(5 downto 0); --Se guarda el dato con el color 0 de la paleta
				elsif pide_color_num = "10" then
					pide_color <= '1';
					dato_paleta_1 <= dato_tabla_paletas(5 downto 0); --Se guarda el dato con el color 1 de la paleta
				else
					pide_color <= '0';
					dato_paleta_2 <= dato_tabla_paletas(5 downto 0); --Se guarda el dato con el color 2 de la paleta
				end if;
			when t_paleta_guarda =>
				dato_paleta_3 <= dato_tabla_paletas(5 downto 0); --Se guarda el dato con el color 3 de la paleta
			when others =>
				pide_color <= '0';
		end case;
	end if;
end process;

--PALETA--

--Proceso para el color actualizado para pintar en la celda actual
P_color_act: Process (rst, clk)
begin
	if rst = '1' then
		dato_patron_0_act <= (others => '0');
		dato_patron_1_act <= (others => '0');
		dato_paleta_0_act <= (others => '0');
		dato_paleta_1_act <= (others => '0');
		dato_paleta_2_act <= (others => '0');
		dato_paleta_3_act <= (others => '0');
	elsif clk'event and clk = '1' then
		if fin_celda = '1' then
			dato_patron_0_act <= dato_patron_0_def;
			dato_patron_1_act <= dato_patron_1_def;
			dato_paleta_0_act <= dato_paleta_0;
			dato_paleta_1_act <= dato_paleta_1;
			dato_paleta_2_act <= dato_paleta_2;
			dato_paleta_3_act <= dato_paleta_3;		
		end if;
	end if;
end process;

selec_color(0) <= dato_patron_0_act(to_integer(in_col)); --Seleccion color por la tabla de patrones del plano 0
selec_color(1) <= dato_patron_1_act(to_integer(in_col)); --Seleccion color por la tabla de patrones del plano 1

dir_paletas <= dato_paleta_0_act when selec_color = "00" else --Direccion de la paleta de colores, color 0
			   dato_paleta_1_act when selec_color = "01" else --Direccion de la paleta de colores, color 1
			   dato_paleta_2_act when selec_color = "10" else --Direccion de la paleta de colores, color 2
			   dato_paleta_3_act; --Direccion de la paleta de colores, color 3

--PINTAR LA PANTALLA--

P_pinta: Process (visible, dato_paletas)
begin
		if visible = '1' then
			rojo   <= dato_paletas(11 downto 8);
			verde  <= dato_paletas(7 downto 4);
			azul   <= dato_paletas(3 downto 0);
		else
			rojo   <= (others => '0');
			verde  <= (others => '0');
			azul   <= (others => '0');
		end if;
end process;

end behavioral;
