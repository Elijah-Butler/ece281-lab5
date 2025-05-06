library ieee;
use ieee.std_logic_1164.all;
 
entity ripple_adder is
    Port (
        A    : in  STD_LOGIC_VECTOR (3 downto 0);
        B    : in  STD_LOGIC_VECTOR (3 downto 0);
        Cin  : in  STD_LOGIC;
        S    : out STD_LOGIC_VECTOR (3 downto 0);
        Cout : out STD_LOGIC
    );
end ripple_adder;
 
architecture behavioral of ripple_adder is
    signal carry : STD_LOGIC_VECTOR (4 downto 0);
begin
    carry(0) <= Cin;
    adders: for i in 0 to 3 generate
        S(i) <= A(i) xor B(i) xor carry(i);
        carry(i+1) <= (A(i) and B(i)) or (A(i) and carry(i)) or (B(i) and carry(i));
    end generate;
    Cout <= carry(4);
end behavioral;
