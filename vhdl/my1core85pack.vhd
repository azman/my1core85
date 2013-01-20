-----------------------------------------------------------------------------
-- Filename: my1core85pack.vhd
-- Function: Package for 8085 Core
-- Comment:
-- == package for constants and custom types
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package my1core85pack is

	constant ADDRSIZE: integer := 16;
	constant DATASIZE: integer := 8;
	constant STATSIZE: integer := 3;
	constant IDX_IO_MB: integer := 2;
	constant IDX_STAT1: integer := 1;
	constant IDX_STAT0: integer := 0;

	type proc_state_type is ( STATE_1, STATE_2, STATE_3,
		STATE_4, STATE_5, STATE_6, STATE_R, STATE_W,
		STATE_H, STATE_X ); -- hold and halt states!
	type mach_cycle_type is ( OPCODE_FETCH, MEMORY_READ,
		MEMORY_WRITE, IO_READ, IO_WRITE, INTR_ACK,
		BUS_IDLE );

	constant INIT_STATE: proc_state_type := STATE_R; -- reset state
	constant INIT_CYCLE: mach_cycle_type := OPCODE_FETCH;

	type my1core85inst_input is record
		reg_clk: std_logic;
		reg_enb: std_logic;
		reg_data: std_logic_vector(DATASIZE-1 downto 0);
	end record;

	type my1core85inst_output is record
		go_read, go_write, go_io: std_logic;
		go_halt, go_extd: std_logic;
		do_arg: std_logic_vector(1 downto 0);
		do_data: std_logic_vector(1 downto 0);
		tgt_src, tgt_dst: std_logic_vector(2 downto 0);
	end record;

	type my1core85ctrl_input is record
		sys_clk: std_logic;
		pin_rdy, pin_hld, pin_rst: std_logic;
		get_inst: my1core85inst_output;
	end record;

	type my1core85ctrl_output is record
		pin_stat1, pin_stat0, pin_iomb: std_logic;
		pin_wrb, pin_rdb, pin_ale: std_logic;
		pin_hlda, pin_rst_out: std_logic;
		enb_ireg: std_logic;
	end record;

	constant ZERO_INST: my1core85inst_output := ( '0', '0', '0', '0', '0',
		"00", "00", "111", "111" );

end package;
