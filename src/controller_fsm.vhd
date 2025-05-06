----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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
 
 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
 
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
 
entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;
 
architecture FSM of controller_fsm is
    type state_t is (S0, S1, S2, S3);
    signal state, n_state: state_t;
begin
    process(i_adv, i_reset)
    begin
        if i_reset = '1' then
            state <= S0;
        elsif rising_edge(i_adv) then
            state <= n_state;
        end if;
    end process;
  process(state)
    begin
        case state is
        when S0 =>
            n_state <= S1;
        when S1 =>
            n_state <= S2;
        when S2 => 
            n_state <= S3;
        when S3 =>
            n_state <= S0;
        end case;
    end process;
  process(state)
    begin
        case state is 
        when S0 => 
            o_cycle<="0001";
        when S1 =>
            o_cycle <= "0010";
        when S2 =>
            o_cycle <= "0100";
        when S3 =>
            o_cycle <= "1000";
    end case;
  end process;
 
 
end FSM;
