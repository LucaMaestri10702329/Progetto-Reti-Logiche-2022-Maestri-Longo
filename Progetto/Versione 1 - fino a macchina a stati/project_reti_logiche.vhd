----------------------------------------------------------------------------------
-- company: Polimi
-- engineer: Luca Maestri - Virginia Longo
-- 
-- create date: 05/05/2022 05:05:22 pm
-- design name: RTL Project
-- module name: 10702329 - behavioral
-- project name: RTL Project
-- target devices: FF, LUT
-- tool versions: 2016.4
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
port (
		i_clk     : in std_logic;                      --clock synchronizing fsm
		i_start   : in std_logic;                      --signal to start read ram process
		i_rst     : in std_logic;                      --signal resetting fsm
		i_data    : in std_logic_vector(7 downto 0);   --signal from ram with value requested
		o_address : out std_logic_vector(15 downto 0); --signal from fsm to ram requesting address
		o_done    : out std_logic;                     --signal identifying session terminated
		o_en      : out std_logic;                     --signal to access ram
		o_we      : out std_logic;                     --signal to write on ram
		o_data    : out std_logic_vector(7 downto 0)   --signal containing data to write
	);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
type state_type is (reset, start, store_data, convulution, save_data, read_word, wait_confirm, state1, state2, state3, state4);
	signal current_state, next_state,current_state_mst : state_type; --FSM states
	signal wz_bit                    : std_logic;                    --working zone bit
	signal offset                    : std_logic_vector(3 downto 0); --working zone offset
	signal data                      : std_logic_vector(8 downto 0); --data requested
	signal counter, next_counter     : integer range 0 to 2;         --address counters
	signal current_data              : std_logic_vector(6 downto 0); --data register
	
	
	signal wordBitCounter            : integer range 7 downto 0;
	signal input_address             : std_logic_vector(15 downto 0);
	signal reg                      : std_logic ;
	signal p1k                       : std_logic ;
	signal p2k                       : std_logic;
	signal number_word              : integer range 255 downto 0;
	begin
        process (i_clk, i_rst)
        begin
            if i_rst = '1' then
                current_state <= reset;
                current_state_mst <= state1;
            elsif rising_edge(i_clk) then
                counter       <= next_counter;
                current_state <= next_state;
            end if;
        end process; 
    process (current_state, i_start, i_data, data, offset, wz_bit, counter, current_data)
    begin
            next_counter <= counter;
            o_en         <= '0';
            o_we         <= '0';
            o_done       <= '0';
            o_address    <= "0000000000000000";
            o_data       <= "00000000";
            offset       <= "0000";
            
            case current_state is
                        when reset =>
                            if i_start = '0' then
                                next_state <= reset;
                            elsif i_start = '1' then
                                next_state <= start;
                            end if;
            when start =>
                          o_address  <= "0000000000000000";
                          o_we       <= '0';
                          o_en       <= '1';
                          wz_bit     <= '0';
                          offset     <= "0000";
                          next_state <= store_data;
            when read_word => 
                          data <= i_data(7 downto 0);
                          o_address <= input_address;
                          o_en <= '1';
                          next_state <= convulution;
                          next_counter <= 0;
            when store_data =>
                          data         <= i_data(7 downto 0);
                          o_address    <= std_logic_vector(to_unsigned(to_integer(unsigned(input_address))+1,16));
                          o_en         <= '1';
                          next_state   <= convulution;
                          next_counter <= 0;
            when convulution =>
                          reg <= data(7) ;
                          wordBitCounter <= wordBitCounter-1;
                          data <= std_logic_vector(unsigned(data) sll 1);
                    case current_state_mst is
                        when state1 => 
                            if reg= '1' then
                                current_state_mst <= state2;
                                p1k <= '1';
                                p2k <= '1';
                            else 
                                current_state_mst <= state1;
                                p1k <= '0';
                                p2k <= '0';
                            end if;
                       when state2 => 
                            if reg= '1' then
                                current_state_mst <= state3;
                                p1k <= '1';
                                p2k <= '0';
                            else 
                                current_state_mst <= state4;
                                p1k <= '0';
                                p2k <= '1';
                            end if;
                      when state3 => 
                            if reg= '1' then
                                current_state_mst <= state3;
                                p1k <= '0';
                                p2k <= '1';
                            else 
                                current_state_mst <= state4;
                                p1k <= '1';
                                p2k <= '0';
                            end if;
                      when state4 => 
                            if reg= '1' then
                                current_state_mst <= state2;
                                p1k <= '0';
                                p2k <= '0';
                            else 
                                current_state_mst <= state1;
                                p1k <= '1';
                                p2k <= '1';
                            end if;
                  end case;
            end case;
    end process;


end architecture;
