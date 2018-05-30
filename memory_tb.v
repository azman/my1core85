module memory_tb();

parameter DATASIZE = 8;
parameter ADDRSIZE = 16;
parameter MEM_SIZE = (2**ADDRSIZE);

reg[DATASIZE-1:0] memory[0:MEM_SIZE-1];
reg[ADDRSIZE-1:0] addr;
integer loop;

initial begin
	$readmemh("memory.txt",memory);//,0,MEM_SIZE-1);
	for (loop=0;loop<MEM_SIZE;loop=loop+1)
	begin
		addr = loop;
		if (memory[loop]!==8'hXX)
			$display("[%04x] Value=%02x (%b)",addr,memory[loop],memory[loop]);
	end
end

endmodule
