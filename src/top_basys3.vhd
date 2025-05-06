--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;
 
architecture top_basys3_arch of top_basys3 is
 
    -- Component Declarations
    component ALU
        Port (
            i_A      : in STD_LOGIC_VECTOR(7 downto 0);
            i_B      : in STD_LOGIC_VECTOR(7 downto 0);
            i_op     : in STD_LOGIC_VECTOR(2 downto 0);
            o_result : out STD_LOGIC_VECTOR(7 downto 0);
            o_flags  : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
 
    component controller_fsm
        Port (
            i_reset : in STD_LOGIC;
            i_adv   : in STD_LOGIC;
            o_cycle : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
 
    component clock_divider
        generic (k_DIV : natural := 100000); -- slow clock (~10Hz for 100MHz input)
        Port (
            i_clk   : in STD_LOGIC;
            i_reset : in STD_LOGIC;
            o_clk   : out STD_LOGIC
        );
    end component;

component sevenseg_decoder is
    Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
           o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
end component sevenseg_decoder;
 
 
    component twos_comp
        Port (
            i_bin   : in STD_LOGIC_VECTOR(7 downto 0);
            o_sign  : out STD_LOGIC;
            o_hund  : out STD_LOGIC_VECTOR(3 downto 0);
            o_tens  : out STD_LOGIC_VECTOR(3 downto 0);
            o_ones  : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
 
    component TDM4
        generic (k_WIDTH : natural := 4);
        Port (
            i_clk   : in STD_LOGIC;
            i_reset : in STD_LOGIC;
            i_D3    : in STD_LOGIC_VECTOR(k_WIDTH-1 downto 0);
            i_D2    : in STD_LOGIC_VECTOR(k_WIDTH-1 downto 0);
            i_D1    : in STD_LOGIC_VECTOR(k_WIDTH-1 downto 0);
            i_D0    : in STD_LOGIC_VECTOR(k_WIDTH-1 downto 0);
            o_data  : out STD_LOGIC_VECTOR(k_WIDTH-1 downto 0);
            o_sel   : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;
 
    -- Signals
    signal slow_clk   : std_logic;
    signal o_cycle    : std_logic_vector(3 downto 0);
    signal op_code    : std_logic_vector(2 downto 0) := (others => '0');
    signal alu_output : std_logic_vector(7 downto 0);
    signal flags      : std_logic_vector(3 downto 0);
    signal d3, d2, d1, d0 : std_logic_vector(3 downto 0);
    signal w_seg : std_logic_vector(6 downto 0);
    signal w_sel : std_logic_vector(3 downto 0);
    signal w_data : std_logic_vector(3 downto 0);
    signal w_bin : std_logic_vector(7 downto 0);
    
    signal o_A : std_logic_vector(7 downto 0);
    signal o_B : std_logic_vector(7 downto 0);
 
begin
 
    -- FSM for instruction cycle
    fsm_inst : controller_fsm
        port map (
            i_reset => btnU,
            i_adv   => btnC,
            o_cycle => o_cycle
        );
        
        
     somth_inst : sevenseg_decoder
        port map (
            i_hex => w_data,
            o_seg_n => w_seg
     );
 
    -- Clock Divider to slow down the display
    clkdiv_inst : clock_divider
        generic map (k_DIV => 100000)  -- Adjust for ~10Hz from 100MHz
        port map (
            i_clk   => clk,
            i_reset => btnU,
            o_clk   => slow_clk
        );
 
    -- ALU instance
    alu_inst : ALU
        port map (
            i_A      => o_A,
            i_B      => o_B,
            i_op     => sw(2 downto 0),
            o_result => alu_output,
            o_flags  => flags
        );
 
    -- BCD converter
    bcd_inst : twos_comp
        port map (
            i_bin  => w_bin,
            o_sign => open,
            o_hund => d2,
            o_tens => d1,
            o_ones => d0
        );
 
    -- Time-Division Multiplexing for 7-seg display
    tdm_inst : TDM4
        generic map (k_WIDTH => 4)
        port map (
            i_clk   => slow_clk,
            i_reset => btnU,
            i_D3    => x"0",
            i_D2    => d2,
            i_D1    => d1,
            i_D0    => d0,
            o_data  => w_data,
            o_sel   => w_sel
        );

w_bin <= o_A when o_cycle = "0001" else
         o_B when o_cycle = "0010" else
         alu_output when o_cycle = "0100" else
         x"00";
         

seg <= w_seg when (w_sel = "1110" or w_sel = "1101" or w_sel = "1011") else
           "1111111" when flags(3) = '0' else  -- assumes 0 = positive
           "0111111";                        -- negative sign
           
 an <= w_sel;
 
    -- LED output (debugging)
    led(7 downto 0)   <= alu_output;
    led(11 downto 8)  <= "0000";
    led(15 downto 12) <= flags;
    
--first register
    reg_proc1 : process(slow_clk)
        begin
            if rising_edge(slow_clk) then
                if BtnU = '1' then
                    o_A <= (others => '0');
                elsif o_cycle = "0001" then 
                    o_A <= sw;
                end if;
            end if;
        end process reg_proc1;
    --second register
    reg_proc2 : process(slow_clk)
        begin
            if rising_edge(slow_clk) then
                if BtnU = '1' then
                    o_B <= (others => '0');
                    elsif o_cycle = "0010" then
                        o_B <= sw;
                    end if;
                end if;
        end process reg_proc2;
    



 
end top_basys3_arch;
	
