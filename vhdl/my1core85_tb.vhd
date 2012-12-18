library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my1core85_pack.all;
use work.my1core85_sim.all;

entity my1core85_tb is
end my1core85_tb;

architecture behavior of my1core85_tb is 

	constant HEX_FILENAME : string := "test.hex";
	constant CLK_PERIOD_NS : time := 10 ns;

	signal sys_clk : std_logic := '1';
	signal sys_rst : std_logic := '1';
	signal clk_out, rst_out: std_logic;
	signal AD: std_logic_vector(DATASIZE-1 downto 0);
	signal A: std_logic_vector(ADDRSIZE-1 downto DATASIZE);
	signal ALE, S1, S0: std_logic;
	signal IOMB, RD_B, WR_B: std_logic;
	signal READY: std_logic;
	signal INTR, HOLD, SID: std_logic;
	signal INTA_B, HLDA, SOD: std_logic;
	signal TRAP, RST75, RST65, RST55: std_logic;

	signal prev_status: std_logic_vector(STATSIZE-1 downto 0) := "000";
	signal mem_data: std_logic_vector(DATASIZE-1 downto 0);
	signal A_latch: std_logic_vector(DATASIZE-1 downto 0);

begin

	-- instantiate the unit under test (UUT)
	core_unit : entity my1core85(structural)
	port map
	(
		CLK => sys_clk,
		RST_IN_B => sys_rst,
		CLK_OUT => clk_out,
		RST_OUT =>rst_out,
		AD => AD,
		A => A,
		ALE => ALE,
		S1 => S1,
		S0 => S0,
		IOMB => IOMB,
		RD_B => RD_B,
		WR_B => WR_B,
		READY => READY,
		INTR => INTR,
		HOLD => HOLD,
		SID => SID,
		INTA_B => INTA_B,
		HLDA => HLDA,
		SOD => SOD,
		TRAP => TRAP,
		RST75 => RST75,
		RST65 => RST65,
		RST55 => RST55
	);

	-- generate clk and rst signals
	sys_clk <= not sys_clk after CLK_PERIOD_NS/2;
	sys_rst <= '0' after CLK_PERIOD_NS,
				'1' after 2*CLK_PERIOD_NS,
				'0' after 4*CLK_PERIOD_NS;

	-- simulate external address latch
	addr_latch : process(sys_clk)
			variable t_A_latch : std_logic_vector(DATASIZE-1 downto 0);
	begin
		if rising_edge(sys_clk) then
			t_A_latch := A_latch;
			if ALE = '1' then
				t_A_latch <= AD;
			end if;
			A_latch <= t_A_latch;
		end if;
	end process addr_latch;

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
