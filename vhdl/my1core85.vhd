-----------------------------------------------------------------------------
-- Filename: my1core85.vhd
-- Function: Top Level 8085 Core
-- Comment:
-- == modified clock interface
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.my1core85_pack.all; 

entity my1core85 is
	port
	(
		--X1, X2: in std_logic; -- cystal input
		--VCC, VSS: in std_logic; -- power lines
		CLK, RST_IN_B: in std_logic;
		CLK_OUT, RST_OUT: out std_logic;
		AD: inout std_logic_vector(DATASIZE-1 downto 0);
		A: out std_logic_vector(ADDRSIZE-1 downto DATASIZE);
		ALE, S1, S0: out std_logic;
		IOMB, RD_B, WR_B: out std_logic;
		READY: in std_logic;
		INTR, HOLD, SID: in std_logic;
		INTA_B, HLDA, SOD: out std_logic;
		TRAP, RST75, RST65, RST55: in std_logic
	);
end my1core85;

architecture structural of my1core85 is

	signal data_in, data_out: std_logic_vector(DATASIZE-1 downto 0);
	signal sys_clk, reg_clk: std_logic;
	signal inst_in: my1core85inst_input;
	signal inst_out: my1core85inst_output;
	signal ctrl_in: my1core85ctrl_input;
	signal ctrl_out: my1core85ctrl_output;

begin

	-- assign module pins
	ALE <= ctrl_out.pin_ale;
	S1 <= ctrl_out.pin_stat1;
	S0 <= ctrl_out.pin_stat0;
	IOMB <= ctrl_out.pin_iomb;
	RD_B <= ctrl_out.pin_rdb;
	WR_B <= ctrl_out.pin_wrb;
	HLDA <= ctrl_out.pin_hlda;
	RST_OUT <= ctrl_out.pin_rst_out;

	data_in <= AD when ctrl_out.pin_rdb = '0' else (others=>'0');
	AD <= data_out when ctrl_out.pin_wrb = '0' else (others=>'Z');

	-- internal assignment
	-- should use proper clock generator for this
	sys_clk <= CLK;
	reg_clk <= not CLK;

	ctrl_in <= (
		sys_clk => sys_clk,
		pin_rdy => READY,
		pin_hld => HOLD,
		pin_rst => RST_IN_B,
		get_inst => inst_out
		);

	inst_in <= (
		reg_clk => reg_clk,
		reg_enb => ctrl_out.enb_ireg,
		reg_data => data_in
		);

	inst_unit : entity my1core85inst(behavioral)
	port map
	(
		port_in => inst_in,
		port_out => inst_out
	);

	ctrl_unit : entity my1core85ctrl(behavioral)
	port map
	(
		port_in => ctrl_in,
		port_out => ctrl_out
	);

end structural;
