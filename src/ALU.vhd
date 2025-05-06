----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity ALU is
    port (
        i_A       : in  std_logic_vector(7 downto 0);
        i_B       : in  std_logic_vector(7 downto 0);
        i_op      : in  std_logic_vector(2 downto 0);
        o_result  : out std_logic_vector(7 downto 0);
        o_flags   : out std_logic_vector(3 downto 0)  -- ZNCV: Zero, Negative, Carry, Overflow
    );
end ALU;
architecture behavioral of ALU is
    component ripple_adder is 
    Port( A : in STD_LOGIC_VECTOR (3 downto 0);
          B : in STD_LOGIC_VECTOR (3 downto 0);
          Cin : in STD_LOGIC;
          S : out STD_LOGIC_VECTOR (3 downto 0);
          Cout : out STD_LOGIC
          );
    end component ripple_adder;
    signal A_low, A_high    :   std_logic_vector(3 downto 0);
    signal B_low, B_high    :   std_logic_vector(3 downto 0);
    signal B_mod            :   std_logic_vector(7 downto 0);
    signal sum_low, sum_high :  std_logic_vector(3 downto 0);
    signal carry_low : STD_LOGIC;
    signal carry_high : STD_LOGIC;
    signal alu_result : STD_LOGIC_VECTOR(7 downto 0);
    signal Cin       : STD_LOGIC;
    signal sum_final  : STD_LOGIC_VECTOR(7 downto 0);
    signal xnor_s     : std_logic;
    signal xor_s      : std_logic;
    signal alu_not    : std_logic;
    signal x_and      : std_logic;
begin 
    A_high <= i_A(7 downto 4);
    A_low  <= i_A(3 downto 0);
    B_mod <= i_B when i_op /= "001" else (not i_B);
    B_high <= B_mod(7 downto 4);
    B_low <= B_mod(3 downto 0);
    Cin <= '1' when i_op = "001" else '0';
    ripple_adder_1: ripple_adder
        port map(
            A => A_low,
            B => B_low,
            Cin => Cin,
            S => sum_low,
            Cout => carry_low
            );
     ripple_adder_2: ripple_adder
         port map(
            A => A_high,
            B => B_high,
            Cin => carry_low,
            S => sum_high,
            Cout => carry_high
            );
     sum_final(7 downto 4) <= sum_high;
     sum_final(3 downto 0) <= sum_low;
     with i_op select
     alu_result <= sum_final when "000",
                   sum_final when "001",
                   (B_mod and i_A) when "010",
                   (B_mod or i_A) when "011",
                   (others => '0') when others;
      o_result <= alu_result;
      o_flags(3) <= alu_result(7);
      o_flags(2) <= '1' when alu_result = "00000000" else '0';
      o_flags(1) <= carry_high and (not i_op(1));
      alu_not <= not i_op(1);
      xnor_s <= not (i_A(7) xor i_B(7) xor i_op(0));
      xor_s <= i_A(7) xor alu_result(7);
      x_and <= xnor_s and xor_s;
      o_flags(0) <= x_and and alu_not;
end behavioral;
