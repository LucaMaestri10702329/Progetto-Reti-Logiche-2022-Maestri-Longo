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
type state_type is (reset, 
                    start, 
                    idling,
                    convulution, 
                    store_data, 
                    read_word, 
                    store_word ,
                    write, 
                    compare ,
                    wait_confirm2,
                    store_result_convulution,
                    wait_confirm, 
                    state1, state2, 
                    state3, state4, 
                    shift_new_word, 
                    check_conter_convulution, 
                    store_new_word,
                    read_word_processing,
                    finalize);
                    
	signal current_state, next_state,current_state_mst,next_state_mst : state_type; --FSM states
	signal wz_bit                    : std_logic;                    --working zone bit
	signal offset                    : std_logic_vector(3 downto 0); --working zone offset
	signal data                      : std_logic_vector(7 downto 0); --data requested
	signal counter, next_counter     : integer range 0 to 2;         --address counters
	signal current_data              : std_logic_vector(6 downto 0); --data register
	
	
	signal wordBitCounter            : integer range 7 downto 0;
	signal input_address             : std_logic_vector(15 downto 0);
	signal reg                       : std_logic ;
	signal p1k                       : std_logic ;
	signal p2k                       : std_logic;
	signal word1: std_logic_vector(7 downto 0);
		signal word2: std_logic_vector(7 downto 0);
		signal word: std_logic_vector(7 downto 0);

	signal number_word               : std_logic_vector (7 downto 0);
	signal number_convulution        : integer range 7 downto 0;
	signal new_word                  : std_logic_vector(7 downto 0);
	signal counter_convulution       : integer range 8 downto 0;
	signal data_load                 : std_logic;
	signal number_word_read          : integer range 2 downto 0;
	begin
     

  process (i_clk, i_rst)
    begin
        if i_rst = '1' then
                    current_state <= reset;
                    current_state_mst <= state1;
         elsif rising_edge(i_clk) then
                case current_state is
                
                when reset =>
                                o_en         <= '1';
                                o_we         <= '0';
                                o_done       <= '0';
                                o_address    <= "0000000000000000";
                                o_data       <= "00000000";
                                number_word       <= "00000000";
                                input_address <="0000001111100111";
                                number_word_read<=00;
                                counter_convulution<=00000000;
                                current_state <= idling;
                                current_state_mst <= state1;
                when idling=>
                               current_state <= start;
              
                when start =>
                    IF i_start = '1' THEN
                              o_en       <= '1';
                              current_state <= read_word;
                    end if;
                              
                when read_word => 
                              number_word <= i_data;
                              current_state <= read_word_processing;
                              o_address<= "0000000000000001";
    
                when read_word_processing =>
                              current_state <= store_word;
                              
                when store_word =>
                             number_convulution <= 7;
                             current_state <= compare;
                             
                when compare =>
                               word <= i_data;
                               o_we         <= '1';
    
                             --if number_word = 0 then
                               -- next_state <= finalize;
                             --else 
                                current_state <= store_data;
                             --end if;
                                
                when store_data =>
                              current_state   <= convulution;
                              
                when convulution =>
                              --reg <= word(7) ;
                              word <= std_logic_vector(unsigned(word) sll 1);                          
                              
                             case current_state_mst is
                                when state1 => 
                                    if word(7)= '1' then
                                        current_state_mst <= state2;
                                        p1k <= '1';
                                        p2k <= '1';
                                    else 
                                        current_state_mst <= state1;
                                        p1k <= '0';
                                        p2k <= '0';
                                    end if;
                                    when state2 => 
                                        if word(7)= '1' then
                                            current_state_mst <= state3;
                                            p1k <= '1';
                                            p2k <= '0';
                                        else 
                                            current_state_mst <= state4;
                                            p1k <= '0';
                                            p2k <= '1';
                                        end if;
                                    when state3 => 
                                        if word(7)= '1' then
                                            current_state_mst <= state3;
                                            p1k <= '0';
                                            p2k <= '1';
                                        else 
                                            current_state_mst <= state4;
                                            p1k <= '1';
                                            p2k <= '0';
                                        end if;
                                   when state4 => 
                                        if word(7)= '1' then
                                            current_state_mst <= state2;
                                            p1k <= '0';
                                            p2k <= '0';
                                    else 
                                            current_state_mst <= state1;
                                            p1k <= '1';
                                            p2k <= '1';
                                    end if;
                                when others =>
                                end case;
                                counter_convulution <= counter_convulution +1;
                                current_state <= store_result_convulution;
                                
                when store_result_convulution =>
                            case counter_convulution is
                                 when 1 => 
                                        word1(7) <= p1k;
                                        word1(6)<= p2k; 
                                        current_state <= convulution ;
                                 when 2 => 
                                        word1(5) <= p1k;
                                        word1(4)<=p2k; 
                                        current_state <= convulution ;
                                 when 3 => 
                                        word1(3) <= p1k;
                                        word1(2)<=p2k;
                                        current_state <= convulution ;
                                 when 4 => 
                                         word1(1) <= p1k;
                                         word1(0)<=p2k;  
                                         current_state <= convulution ;
                                 when 5 => 
                                        word2(0)<=p1k;  
                                        word2(1)<=p2k;
                                        current_state <= convulution ;
                                 when 6 => 
                                        word2(2) <= p1k;
                                        word2(3)<=p2k;
                                        current_state <= convulution ;
                                 when 7=>
                                        word2(4) <= p1k;
                                        word2(5) <= p2k;
                                        current_state <= convulution ;
                                 when 8=>
                                        word2(6) <= p1k;
                                        word2(7) <= p2k;   
                                        current_state <= store_new_word ;
                                 when others=>
                                    
                             end case;
                                
                            
                        when store_new_word =>
                            o_data <= std_logic_vector(RESIZE(unsigned(word1), 8));      
                            o_address <= std_logic_vector(to_unsigned(to_integer(unsigned(input_address))+1,16));
                            current_state <= wait_confirm;
                        when wait_confirm =>  
                            current_state <= wait_confirm2;
                        when  wait_confirm2=>
                            current_state <= finalize;
                        when write=>
                                o_data <= std_logic_vector(RESIZE(unsigned(word2), 8));      
                                o_address <= std_logic_vector(to_unsigned(to_integer(unsigned(input_address))+1,16));
                        when finalize =>
                            if(i_start = '1')
                                then
                                  o_done <= '1';
                                else
                                  o_done <= '0';
                                  current_state <= reset;
                                end if;
                            
                            
                when others =>
                        current_state <= current_state;
                    
                end case;
            end if;
    end process;

end Behavioral;
