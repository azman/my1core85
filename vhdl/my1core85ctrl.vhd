-----------------------------------------------------------------------------
-- Filename: my1core85ctrl.vhd
-- Function: Timing and Control Unit
-- Comment:
-- == state machine in here...
-- == based on the timing diagram, states change on falling edge!
-- == make the registers clock on rising edge!
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my1core85_pack.all; 

entity my1core85ctrl is
	port
	(
		port_in: in my1core85ctrl_input;
		port_out: out my1core85ctrl_output
	);
end my1core85ctrl;

architecture behavioral of my1core85ctrl is

	signal curr_state, next_state: proc_state_type := init_state;
	type ctrl_data_type is record
		this_cycle: mach_cycle_type;
		chk_inst: my1core85inst_output;
		get_inst: std_logic;
		out_stat: std_logic_vector(STATSIZE-1 downto 0);
		out_wrb, out_rdb: std_logic;
		out_ale, out_hlda, out_rst_out: std_logic;
	end record;
	constant init_data: ctrl_data_type := ( init_cycle, zero_inst, '0',
		"011", -- status bits
		'1', '1', -- rd/wr active low, 
		'0','0', '0' ); -- ale high pulse!
	signal curr_data, next_data: ctrl_data_type := init_data;
	signal chk_last, go_write, go_iochk: std_logic;

begin

	-- output port assignment(s)
	port_out.pin_stat1 <= curr_data.out_stat(IDX_STAT1);
	port_out.pin_stat0 <= curr_data.out_stat(IDX_STAT0);
	port_out.pin_iomb <= curr_data.out_stat(IDX_IO_MB);
	port_out.pin_wrb <= curr_data.out_wrb;
	port_out.pin_rdb <= curr_data.out_rdb;
	port_out.pin_ale <= '1' when curr_data.out_ale = '1' and
		port_in.sys_clk = '1' else '0'; -- because ALE needs half period
	port_out.pin_hlda <= curr_data.out_hlda;
	port_out.pin_rst_out <= curr_data.out_rst_out;
	port_out.enb_ireg <= curr_data.get_inst;

	-- internal 'wiring'
	chk_last <= '1' when curr_data.chk_inst.do_arg = "00" and
		curr_data.chk_inst.do_data = "00" else '0';
	go_write <= '1' when curr_data.chk_inst.do_data /= "00" and
		curr_data.chk_inst.go_write = '1' else '0';
	go_iochk <= '1' when curr_data.chk_inst.do_data /= "00" and
		curr_data.chk_inst.go_io = '1' else '0';

	comb_proc : process( curr_state, port_in ) is -- combinational
		variable temp_state: proc_state_type;
		variable temp_data: ctrl_data_type;
	begin
		temp_state := curr_state; -- next_state defaults to curr_state
		temp_data := curr_data;
		temp_data.get_inst := '0'; -- always reset this (1 state period)
		temp_data.out_ale := '1';
		case curr_state is
		when STATE_R =>
			temp_data := init_data;
			temp_state := STATE_1;
		when STATE_1 =>
			if temp_data.chk_inst.go_halt = '1' then
				temp_state := STATE_X;
			else
				temp_state := STATE_2;
			end if;
		when STATE_2 =>
			if port_in.pin_rdy = '1' or temp_data.this_cycle = BUS_IDLE then
				temp_state := STATE_3;
			else
				temp_state := STATE_W;
			end if;
		when STATE_3 =>
			if temp_data.this_cycle = OPCODE_FETCH then
				temp_state := STATE_4;
			else
				temp_state := STATE_1;
			end if;
		when STATE_4 =>
			temp_data.chk_inst := port_in.get_inst; -- from inst decoder!
			if temp_data.chk_inst.go_extd = '1' then
				temp_state := STATE_5;
			else
				temp_state := STATE_1;
			end if;
		when STATE_5 =>
			temp_state := STATE_6;
		when STATE_6 =>
			temp_state := STATE_1;
		when STATE_H =>
			if port_in.pin_hld = '0' then
				temp_data.out_hlda := '0';
				if temp_data.chk_inst.go_halt = '1' then
					temp_state := STATE_X;
				else
					temp_state := STATE_1;
				end if;
			end if;
		when STATE_X =>
			if port_in.pin_hld = '1' then
				temp_data.out_hlda := '1';
				temp_state := STATE_H;
			--elsif valid interrupt then
			--	temp_state := STATE_1;
			end if;
		when STATE_W =>
			if port_in.pin_rdy = '1' then
				temp_state := STATE_3;
			end if;
		end case;
		-- check exit state
		case temp_state is
		when STATE_1 =>
			if temp_data.out_hlda = '1' then
				temp_state := STATE_H;
			else
				-- except for a few inst?
				temp_data.out_ale := '0';
				-- check instruction sequence
				temp_data.out_stat(IDX_IO_MB) := go_iochk;
				temp_data.out_stat(IDX_STAT1) :=
					not temp_data.chk_inst.go_halt and ( not
					go_write or chk_last );
				temp_data.out_stat(IDX_STAT0) :=
					not temp_data.chk_inst.go_halt and (
					go_write or chk_last );
				-- check instruction sequence
				case temp_data.out_stat is
				when "011" =>
					temp_data.this_cycle := OPCODE_FETCH;
				when "010" =>
					temp_data.this_cycle := MEMORY_READ;
				when "001" =>
					temp_data.this_cycle := MEMORY_WRITE;
				when "000" =>
					temp_data.this_cycle := BUS_IDLE; -- HALT is BUS_IDLE
				when "100" =>
					temp_data.this_cycle := BUS_IDLE; -- HALT is BUS_IDLE
				when "110" =>
					temp_data.this_cycle := IO_READ;
				when "101" =>
					temp_data.this_cycle := IO_WRITE;
				when "111" =>
					temp_data.this_cycle := INTR_ACK;
				when others => -- default? shouldn't get here!
					temp_data.this_cycle := OPCODE_FETCH;
				end case;
				-- check machine cycle sequence
				if chk_last = '1' then
					--temp_data.chk_intr := '1';
				end if;
			end if;
		when STATE_2 =>
			temp_data.out_wrb := temp_data.out_stat(IDX_STAT1);
			temp_data.out_rdb := temp_data.out_stat(IDX_STAT0);
		when STATE_3 =>
			temp_data.out_wrb := '1';
			temp_data.out_rdb := '1';
			if curr_data.this_cycle = OPCODE_FETCH then
				temp_data.get_inst := '1';
			end if;
			if port_in.pin_hld = '1' then
				temp_data.out_hlda := '1';
			end if;
		when STATE_5 =>
			if port_in.pin_hld = '1' then
				temp_data.out_hlda := '1';
			end if;
		when others =>
			-- do nothing???
		end case;
		-- reset overrides all!
		if port_in.pin_rst = '0' then -- active low??
			temp_state := STATE_R;
		end if;
		next_state <= temp_state;
		next_data <= temp_data;
	end process comb_proc;

	sequ_proc : process ( port_in.sys_clk ) is -- sequential
	begin
		if port_in.pin_rst = '0' then -- async reset, active low
			-- should remain low for 10ms after min vcc
			-- 3 clock cycles for correct reset operation?
			curr_state <= init_state;
			curr_data <= init_data;
		elsif falling_edge(port_in.sys_clk) then -- state change on -ve edge!
			curr_state <= next_state;
			curr_data <= next_data;
		end if;
	end process sequ_proc;

end behavioral;
