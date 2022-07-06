----------------------------------------------------------------------------------
-- company: Polimi
-- engineer: Luca Maestri (10702329 / 937019) // Virginia Longo (10685389 / 937860)
-- Instuctor/Supervisor: Prof. Fabio Salice
-- create date: 05/05/2022 05:05:22 pm
-
-- project name: Prova Finale - Progetto di Reti Logiche
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
                    read_number_word,
                    check_number_word_zero,
                    set_number_convulution,
                    read_data,
                    wait_read,
                    read_data_processing,
                    store_result_convulution,
                    state1, state2, 
                    state3, state4, 
                    store_new_word1,
                    store_new_word2,
                    read_again_word,
                    finalize);
                    
	signal current_state, next_state,current_state_mst,next_state_mst : state_type; --FSM states
	signal wz_bit                    : std_logic;                    --working zone bit
	signal offset                    : std_logic_vector(3 downto 0); --working zone offset
	signal data                      : std_logic_vector(7 downto 0); --data requested
	signal counter, next_counter     : integer range 0 to 2;         --address counters
	signal current_data              : std_logic_vector(6 downto 0); --data register
	
	
	signal output_address            : std_logic_vector(15 downto 0);
	signal input_address             : std_logic_vector(15 downto 0);
	signal p1k                       : std_logic ;
	signal p2k                       : std_logic;
	signal word1                     : std_logic_vector(7 downto 0);
	signal word2                     : std_logic_vector(7 downto 0);
	signal word                      : std_logic_vector(7 downto 0);

	signal number_word               : std_logic_vector (7 downto 0);
	signal number_convulution        : integer range 7 downto 0;
	signal counter_convulution       : integer range 8 downto 0;
	signal number_word_read          : integer range 2 downto 0;
	begin
     

  process (i_clk, i_rst)
    begin
        if i_rst = '1' then
                    current_state <= reset;
                    current_state_mst <= state1;
         elsif rising_edge(i_clk) then
                case current_state is
				--Reset resets every signal for starting the algorithm.
                when reset =>
                                o_en         <= '1';
                                o_we         <= '0';
                                o_done       <= '0';
                                o_address    <= "0000000000000000";
                                o_data       <= "00000000";
                                number_word       <= "00000000";
                                output_address <="0000001111100111";
                                input_address <= "0000000000000001";
                                number_word_read <= 00;
                                counter_convulution <= 00000000;
                                current_state <= idling;
                                current_state_mst <= state1;
				--idling goes to start 				
                when idling=>
                               current_state <= start;
				
				--start prepares the memory is i_start is up 
                when start =>
                    IF i_start = '1' THEN
                              o_en <= '1';
                              current_state <= read_number_word;
                    end if;
                              
							  
				--read_number_word reads the number of words we have to process	 		  
                when read_number_word => 
                              number_word <= i_data;
                              o_address <= input_address;
                              current_state <= check_number_word_zero;
							  
                --check_number_word_zero checks if there is a word to read, if not we go to finalize.
                when check_number_word_zero =>
                               if(to_integer(unsigned(number_word))  = 0) then
                                  current_state <= finalize;
                               else
                                  current_state <= set_number_convulution;
                               end if;
				--set_number_convulution sets the number_convulution for knowing how many times doing a convulution.
                when set_number_convulution =>
                             number_convulution <= 0;
                             current_state <= read_data;
                --read_again_word prepares the memory setting and some signal for read another word.
                when read_again_word =>
                                   o_en         <= '1';
                                   o_we         <= '0';
                                   o_done       <= '0';
                                   counter_convulution <= 00000000;
                                   current_state <= set_number_convulution;
                                   o_address <= input_address;
                                 
                --read_data read the word to process, update the input address also
                when read_data =>
                               word <= i_data;
                               current_state <= read_data_processing;
                               o_we <= '0';
                               input_address <= std_logic_vector(to_unsigned(to_integer(unsigned(input_address))+1,16));
                               
                -- read_data_processing is needed because there are some delay, this state let us to have a correct complete read.               
                when read_data_processing =>
                               current_state <= convulution;
                
			
				
				--convulution rapresents the FSM of the convulution itself, prepares also the bit for the next convulution
                when convulution =>
                             word <= std_logic_vector(unsigned(word) sll 1);                          
                              
                             case current_state_mst is
                                when state1 => 
                                    if word(7) = '1' then
                                        current_state_mst <= state2;
                                        p1k <= '1';
                                        p2k <= '1';
                                    else 
                                        current_state_mst <= state1;
                                        p1k <= '0';
                                        p2k <= '0';
                                    end if;
                                    when state2 => 
                                        if word(7) = '1' then
                                            current_state_mst <= state3;
                                            p1k <= '1';
                                            p2k <= '0';
                                        else 
                                            current_state_mst <= state4;
                                            p1k <= '0';
                                            p2k <= '1';
                                        end if;
                                    when state3 => 
                                        if word(7) = '1' then
                                            current_state_mst <= state3;
                                            p1k <= '0';
                                            p2k <= '1';
                                        else 
                                            current_state_mst <= state4;
                                            p1k <= '1';
                                            p2k <= '0';
                                        end if;
                                   when state4 => 
                                        if word(7) = '1' then
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
                --store_result_convulution save the p1k and the p2k value in the right position for word1 and word2.
                when store_result_convulution =>
                            case counter_convulution is
                                 when 1 => 
                                        word1(7) <= p1k;
                                        word1(6) <= p2k; 
                                        current_state <= convulution ;
                                 when 2 => 
                                        word1(5) <= p1k;
                                        word1(4) <= p2k; 
                                        current_state <= convulution ;
                                 when 3 => 
                                        word1(3) <= p1k;
                                        word1(2) <= p2k;
                                        current_state <= convulution ;
                                 when 4 => 
                                         word1(1) <= p1k;
                                         word1(0) <= p2k;  
                                         current_state <= convulution ;
                                 when 5 => 
                                        word2(7) <= p1k;  
                                        word2(6) <= p2k;
                                        current_state <= convulution ;
                                 when 6 => 
                                        word2(5) <= p1k;
                                        word2(4) <= p2k;
                                        current_state <= convulution ;
                                 when 7=>
                                        word2(3) <= p1k;
                                        word2(2) <= p2k;
                                        current_state <= convulution ;
                                 when 8=>
                                        word2(1) <= p1k;
                                        word2(0) <= p2k;   
                                        o_we <= '1';
										o_address <= output_address;
                                        current_state <= store_new_word1 ;
                                 when others=>
                                    
                             end case;
                        
                --store_new_word1 print on the ram the first word obtained       
                when store_new_word1 =>
                        o_data <= std_logic_vector(RESIZE(unsigned(word1), 8));      
                        o_address <= std_logic_vector(to_unsigned(to_integer(unsigned(output_address))+1,16));
                        output_address <= std_logic_vector(to_unsigned(to_integer(unsigned(output_address))+1,16));
                        current_state <= store_new_word2;
						
                --store_new_word2 print on the ram the second word obtained
                when store_new_word2 =>
                        o_data <= std_logic_vector(RESIZE(unsigned(word2), 8));      
                        o_address <= std_logic_vector(to_unsigned(to_integer(unsigned(output_address))+1,16));
                        output_address <= std_logic_vector(to_unsigned(to_integer(unsigned(output_address))+1,16));
                        number_word <= std_logic_vector(to_unsigned(to_integer(unsigned(number_word))-1,8));
                        current_state <= wait_read;
                        
                       
                --Wait read check the number of word: if there are zero words to read, we go to finalize else we go to read again    
                when wait_read=>
                         o_we <= '0';
                         current_state <= read_data;
                          if(to_integer(unsigned(number_word)) >0) then
                                                    current_state <= read_again_word;
                                                else
                                                  current_state <= finalize;
                                                end if;
                --Finalize prepares the o_done signal to up if i_start is already up else it goes to reset     
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
