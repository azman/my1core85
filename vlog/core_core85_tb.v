module core85_tb();

parameter CLKPTIME = 10;
parameter DATASIZE = dut.DATASIZE;
parameter ADDRSIZE = dut.ADDRSIZE;

reg clk, rst, ready, hold, sid, intr, trap, rst75, rst65, rst55;
wire[DATASIZE-1:0] addrdata;
wire[ADDRSIZE-1:DATASIZE] addr;
wire clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_, ale, hlda, sod;

// system memory
reg[DATASIZE-1:0] memory[(2**ADDRSIZE)-1:0];
//integer loop;
reg[ADDRSIZE-1:0] mem_addr;

// reset block
initial begin
	$readmemh("memory.txt",memory);
	//$display("[DEBUG] MEMORY LOADED");
	//for (loop=0;loop<8;loop=loop+1) begin
	//	$display("[DEBUG] %d:%h",loop,memory[loop]);
	//end
	clk = 1'b0; rst = 1'b1; // power-on reset
	#(CLKPTIME*3) rst = 1'b0; // 3-clock cycle reset
	$monitor("[%04g] STATE: %b {%b,%b}",$time/CLKPTIME,
		dut.ctrl.cstate,dut.oenb,dut.opin);
end

// generate clock
always begin
	#(CLKPTIME/2) clk = !clk;
end

// memory address latch
always @(ale) begin
	if (ale) begin
		mem_addr =  { addr, addrdata };
	end
end

//generate stimuli
always begin
	#(CLKPTIME*20); $finish;
end

core85 dut (clk, ~rst, ready, hold, sid, intr, trap, rst75, rst65, rst55,
	addrdata, addr, clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_,
	ale, hlda, sod);

endmodule
