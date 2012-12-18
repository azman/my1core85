-----------------------------------------------------------------------------
-- Filename: my1core85inst.vhd
-- Function: Instruction Decoder
-- Comment:
-- == instruction register and decoder
-- == machine encoding as well...
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
use work.my1core85_pack.all; 

entity my1core85inst is
	port
	(
		port_in: in my1core85inst_input;
		port_out: out my1core85inst_output
	);
end my1core85inst;

architecture behavioral of my1core85inst is

	signal inst_reg: std_logic_vector(DATASIZE-1 downto 0);
	signal inst_cat: std_logic_vector(1 downto 0);
	signal inst_tgt: std_logic_vector(5 downto 0);
	signal inst_src, inst_dst: std_logic_vector(2 downto 0);
	signal temp_out: my1core85inst_output;

begin

	-- assign output
	port_out <= temp_out;

	-- internal link
	inst_cat <= inst_reg(7 downto 6);
	inst_tgt <= inst_reg(5 downto 0);
	inst_dst <= inst_reg(5 downto 3);
	inst_src <= inst_reg(2 downto 0);

	do_decode : process ( inst_reg ) is -- combinational logic!
	begin
		--assign default
		temp_out.go_read <= '0';
		temp_out.go_write <= '0';
		temp_out.go_halt <= '0';
		temp_out.go_extd <= '0';
		temp_out.do_arg <= (others=>'0');
		temp_out.do_data <= (others=>'0');
		temp_out.tgt_dst <= inst_dst;
		temp_out.tgt_src <= inst_src;
		case inst_cat is
		when "01" =>
			case inst_tgt is
			when "110110" => -- HLT instruction!
				temp_out.go_halt <= '1';
			when others =>
				if inst_src = "110" then
					temp_out.go_read <= '1';
					temp_out.do_data <= "01";
				elsif inst_dst = "110" then
					temp_out.go_write <= '1';
					temp_out.do_data <= "01";
				end if;
			end case;
		when others =>
			-- do nothing for now
		end case;
	end process do_decode;

	reg_write : process ( port_in.reg_clk ) is
		variable t_inst_reg: std_logic_vector(DATASIZE-1 downto 0);
	begin
		if rising_edge( port_in.reg_clk ) then
			-- reset circuit NOT required
			t_inst_reg := inst_reg;
			if ( port_in.reg_enb = '1' ) then
				t_inst_reg := port_in.reg_data;
			end if;
			inst_reg <= t_inst_reg;
		end if;
	end process reg_write;

end behavioral;
