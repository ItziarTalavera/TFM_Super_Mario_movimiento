-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  use WORK.VGA_PKG.ALL; 
  
  ENTITY PPU_tb IS
  END PPU_tb;

  ARCHITECTURE behavior OF PPU_tb IS 

  -- Component Declaration
          COMPONENT PPU
          PORT(
				-- Puertos de entrada
				rst	: in  std_logic;
				clk   : in  std_logic;
				-- Puertos de salida
				rojo  : out std_logic_vector(4-1 downto 0);
				verde : out std_logic_vector(4-1 downto 0);
				azul  : out std_logic_vector(4-1 downto 0);
				hsync : out std_logic;
				vsync : out std_logic
				);
          END COMPONENT;

			--Inputs
			  SIGNAL rst :  std_logic;
			  SIGNAL clk :  std_logic;
			 
			 --Outputs
			 signal rojo : std_logic_vector(3 downto 0);
			 signal verde : std_logic_vector(3 downto 0);
			 signal azul : std_logic_vector(3 downto 0);
			 SIGNAL hsync :  std_logic;
          SIGNAL vsync :  std_logic;       

  BEGIN
  
	uut: PPU PORT MAP (
			rst => rst,
			clk => clk,
			rojo => rojo,
			verde => verde,
			azul => azul,
			hsync => hsync,
			vsync => vsync
		);
		
	Estimulos_clk: Process
	begin
		clk <= '1';
		wait for 5 ns;
		clk <= '0';
		wait for 5 ns;
	end process;
	
	Estimulos_rst: Process
	begin
		rst <= '1';
		wait for 100 ns;
		rst <= '0';
		wait for 10 ns;
		wait;
	end process;

  END;
