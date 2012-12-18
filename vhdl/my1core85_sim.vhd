library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

use work.my1core85_pack.all;

package my1core85_sim is

	constant DataBits : integer := DATABITS;
	constant AddrBits : integer := ADDRBITS;
	constant FullSize : integer := 2**ADDRBITS;

	type Nibble is array (DataBits/2-1 downto 0) of std_logic;
	type ByteData is array (DataBits-1 downto 0) of std_logic;
	type WordData is array (DataBits*2-1 downto 0) of std_logic;
	type MemLoc is record
		Data: ByteData;
		Flag: std_logic;
	end record;
	type Memory is array (0 to FullSize-1) of MemLoc;
	procedure init_memory ( CodeMemory: out Memory );
	procedure insert_memory ( StartAddr: in WordData; 
		MemSize: in integer; CodeMemory: out Memory );
	procedure read_file_hex ( HexFile: in string; CodeMemory: out Memory );

end package;

package body my1core85_sim is

	function hexchar2nibble ( hexchar : character ) return Nibble is 
		variable retval: Nibble;
	begin
		case hexchar is
			when '0' => retval := x"0";
			when '1' => retval := x"1";
			when '2' => retval := x"2";
			when '3' => retval := x"3";
			when '4' => retval := x"4";
			when '5' => retval := x"5";
			when '6' => retval := x"6";
			when '7' => retval := x"7";
			when '8' => retval := x"8";
			when '9' => retval := x"9";
			when 'A' | 'a' => retval := x"A";
			when 'B' | 'b' => retval := x"B";
			when 'C' | 'c' => retval := x"C";
			when 'D' | 'd' => retval := x"D";
			when 'E' | 'e' => retval := x"E";
			when 'F' | 'f' => retval := x"F";
			when others =>
				assert false report "Not a hex char?" severity failure;
		end case;
		return retval;
	end hexchar2nibble;

	procedure init_memory ( CodeMemory: out Memory ) is
	begin
		for index in 0 to FullSize-1 loop
			CodeMemory(index).Flag := '0';
			CodeMemory(index).Data := x"00";
		end loop;
	end init_memory;

	procedure insert_memory ( StartAddr: in WordData; 
		MemSize: in integer; CodeMemory: out Memory ) is
		variable CheckBeg, CheckEnd: integer;
	begin
		CheckBeg := to_integer(StartAddr);
		CheckEnd := (CheckBeg + MemSize) - 1;
		assert cCheckBeg < FullSize and CheckEnd < FullSize
			report "Memory Out of Valid Range (" &
				CheckBeg & "-" & CheckEnd & ")!"
			severity failure;
		for index in cCheckBeg to cCheckEnd loop
			CodeMemory(index).Flag := '1';
		end loop;
	end check_memory;

	procedure read_file_hex ( filename: in string; CodeMemory: out Memory ) is
		variable checkline: line;
		variable testchar: character;
		variable read_ok, file_ok: boolean;
		variable checksum, checkval: ByteData;
		variable byte_count, byte_rectype: ByteData;
		variable byte_addr: WordData;
		variable temp_count, code_addr: integer;
		FILE hexfile: TEXT IS IN filename;
	begin
		file_ok := false;
		while not endfile(hexfile) loop
			readline(hexfile,checkline);
			checksum := x"00";
			-- get start code ':'
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			assert testchar = ':'
				report filename & ": Not in Intel HEX format?"
				severity failure; -- stop sim?
			-- get byte count (usu. 0x10 or 0x20)
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			byte_count(3 downto 0) := hexchar2nibble(testchar);
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			byte_count(7 downto 4) := hexchar2nibble(testchar);
			temp_count := to_integer(unsigned(byte_count));
			checkval := byte_count;
			checksum := std_logic_vector(
				unsigned(checksum) + unsigned(checkval) );
			-- get address
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			byte_addr(3 downto 0) := hexchar2nibble(testchar);
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			byte_addr(7 downto 4) := hexchar2nibble(testchar);
			checkval := byte_addr(7 downto 0);
			checksum := std_logic_vector(
				unsigned(checksum) + unsigned(checkval) );
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			byte_addr(11 downto 8) := hexchar2nibble(testchar);
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			byte_addr(15 downto 12) := hexchar2nibble(testchar);
			code_addr := to_integer(unsigned(byte_addr));
			checkval := byte_addr(15 downto 8);
			checksum := std_logic_vector(
				unsigned(checksum) + unsigned(checkval) );
			-- get record type
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			checkval(3 downto 0) := hexchar2nibble(testchar);
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			checkval(7 downto 4) := hexchar2nibble(testchar);
			byte_rectype := checkval;
			checksum := std_logic_vector(
				unsigned(checksum) + unsigned(checkval) );
			assert checkval = x"00" or checkval = x"01"
				-- must be either data or end-of-file record
				report "Record Type: Not supported type!"
				severity error;
			-- get byte_count data
			for index in 0 to temp_count-1 loop
				read(checkline,testchar,read_ok);
				assert read_ok report "Read Failed!" severity failure;
				checkval(3 downto 0) := hexchar2nibble(testchar);
				read(checkline,testchar,read_ok);
				assert read_ok report "Read Failed!" severity failure;
				checkval(7 downto 4) := hexchar2nibble(testchar);
				checksum := std_logic_vector(
					unsigned(checksum) + unsigned(checkval) );
				assert CodeMemory(code_addr).Flag = '1'
					report "Invalid Memory Location!"
					severity failure;
				CodeMemory(code_addr).Data := checkval;
				code_addr := code_addr + 1;
			end loop;
			-- do checksum
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			checkval(3 downto 0) := hexchar2nibble(testchar);
			read(checkline,testchar,read_ok);
			assert read_ok report "Read Failed!" severity failure;
			checkval(7 downto 4) := hexchar2nibble(testchar);
			assert checkval = checksum
				report "Invalid Checksum Value!"
				severity error;
			if byte_rectype = x"01" then
				file_ok := true;
			end if;
		end loop;
		assert file_ok report "Invalid Intel HEX format?!!" severity error;
	end read_file_hex;

end my1core85_sim;
