-----------------------------------------------------------------------------
-- Filename: my1core85ctrl_tb.vhd
-- Function: Test Bench for 8085 Timing & Control Unit
-- Comment:
-- == test this?
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my1core85pack.all;
use work.my1core85sim.all;
use work.all;

entity my1core85ctrl_tb is
end my1core85ctrl_tb;

architecture behavior of my1core85ctrl_tb is

	constant CLK_PERIOD_NS : time := 10 ns;

	signal sys_clk : std_logic := '1';
	signal sys_rst : std_logic := '1';

begin

	-- instantiate the unit under test (UUT)
	ctrl_inst : entity my1core85ctrl(structural)
	port map
	(
		port_in: in my1core85ctrl_input;
		port_out: out my1core85ctrl_output
	);

	-- generate clk and rst signals
	sys_clk <= not sys_clk after CLK_PERIOD_NS/2;
	sys_rst <= '0' after CLK_PERIOD_NS,
				'1' after 2*CLK_PERIOD_NS,
				'0' after 4*CLK_PERIOD_NS;

	-- stimuli, feed processor core with instruction? memory_access
	code_stimuli : process
		variable code_mem: Memory;
		variable code_add: integer;
	begin
		report "Initializing Memory!";
		init_memory(code_mem);
		report "Inserting 8K Memory @ 0000H!";
		insert_memory(x"0000",2**13,code_mem);
		report "Inserting 8K Memory @ 2000H!";
		insert_memory(x"2000",2**13,code_mem);
		report "Start HEX file!";
		read_file_hex(HEX_FILENAME,code_mem);
		report "Memory Ready!";
		while 1 loop
			mem_data <= (others => 'Z');
			wait until rising_edge(sys_clk);
			if RD_B = '0' then
				code_add := to_integer(A&A_latch);
				if code_mem(code_add).Flag = '1' then
					mem_data <= code_mem(code_add).Data;
				end if;
			elsif WR_B = '0' then
				code_add := to_integer(A&A_latch);
				if code_mem(code_add).Flag = '1' then
					code_mem(code_add).Data <= AD;
				end if;
			end if;
		end loop;
		wait;
	end process code_stimuli;

	-- core status
	stat_response : process
		constant response_type: string := "CORE8085: ";
		variable cycle_type: string;
		variable core_status: std_logic_vector(2 downto 0);
	begin
		wait until falling_edge(sys_clk);
		core_status := IOMB & S1 & S0;
		if core_status /= prev_status then
			case core_status is
			when "011" => cycle_type := "OPCODE FETCH";
			when "010" => cycle_type := "MEMORY READ";
			when "001" => cycle_type := "MEMORY WRITE";
			when "000" => cycle_type := "BUS IDLE (HALT)";
			when "100" => cycle_type := "BUS IDLE (HALT)";
			when "110" => cycle_type := "I/O READ";
			when "101" => cycle_type := "I/O WRITE";
			when "111" => cycle_type := "INTERRUPT ACK.";
			when others => cycle_type := "<unknown>";
			end case;
			report response_type & cycle_type;
		end if;
		prev_status <= core_status;
	end process stat_response;

end behavior;
