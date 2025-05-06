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
        generic (k_DIV : natural := 5000000); -- slow clock (~10Hz for 100MHz input)
        Port (
            i_clk   : in STD_LOGIC;
            i_reset : in STD_LOGIC;
            o_clk   : out STD_LOGIC
        );
    end component;
 
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
    signal opp_1      : std_logic_vector(7 downto 0) := (others => '0');
    signal opp_2      : std_logic_vector(7 downto 0) := (others => '0');
    signal op_code    : std_logic_vector(2 downto 0) := (others => '0');
    signal alu_output : std_logic_vector(7 downto 0);
    signal flags      : std_logic_vector(3 downto 0);
    signal d3, d2, d1, d0 : std_logic_vector(3 downto 0);
    signal seg_data   : std_logic_vector(3 downto 0);
 
begin
 
    -- FSM for instruction cycle
    fsm_inst : controller_fsm
        port map (
            i_reset => btnU,
            i_adv   => btnC,
            o_cycle => o_cycle
        );
 
    -- Clock Divider to slow down the display
    clkdiv_inst : clock_divider
        generic map (k_DIV => 5000000)  -- Adjust for ~10Hz from 100MHz
        port map (
            i_clk   => clk,
            i_reset => btnU,
            o_clk   => slow_clk
        );
 
    -- ALU instance
    alu_inst : ALU
        port map (
            i_A      => opp_1,
            i_B      => opp_2,
            i_op     => op_code,
            o_result => alu_output,
            o_flags  => flags
        );
 
    -- BCD converter
    bcd_inst : twos_comp
        port map (
            i_bin  => alu_output,
            o_sign => open,
            o_hund => d3,
            o_tens => d2,
            o_ones => d1
        );
 
    -- Time-Division Multiplexing for 7-seg display
    tdm_inst : TDM4
        generic map (k_WIDTH => 4)
        port map (
            i_clk   => slow_clk,
            i_reset => btnU,
            i_D3    => d3,
            i_D2    => d2,
            i_D1    => d1,
            i_D0    => flags,
            o_data  => seg_data,
            o_sel   => an
        );
 
    -- 7-segment decoder
    process(seg_data)
        variable seg_temp : std_logic_vector(6 downto 0);
    begin
        case seg_data is
            when "0000" => seg_temp := "1000000"; -- 0
            when "0001" => seg_temp := "1111001"; -- 1
            when "0010" => seg_temp := "0100100"; -- 2
            when "0011" => seg_temp := "0110000"; -- 3
            when "0100" => seg_temp := "0011001"; -- 4
            when "0101" => seg_temp := "0010010"; -- 5
            when "0110" => seg_temp := "0000010"; -- 6
            when "0111" => seg_temp := "1111000"; -- 7
            when "1000" => seg_temp := "0000000"; -- 8
            when "1001" => seg_temp := "0010000"; -- 9
            when others => seg_temp := "1111111"; -- blank
        end case;
        seg <= seg_temp;
    end process;
 
    -- FSM data handling based on o_cycle
    process(clk)
    begin
        if rising_edge(clk) then
            case o_cycle is
                when "0001" =>
                    opp_1 <= sw;
                when "0010" =>
                    opp_2 <= sw;
                when "0011" =>
                    op_code <= sw(2 downto 0);
                when others =>
                    null;
            end case;
        end if;
    end process;
 
    -- LED output (debugging)
    led(7 downto 0)   <= alu_output;
    led(11 downto 8)  <= flags;
    led(15 downto 12) <= "0000";
 
end top_basys3_arch;
	
