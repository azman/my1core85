module core85_tb();

parameter CLKPTIME = 10;

reg clk, rst, ready, hold, sid, intr, trap, rst75, rst65, rst55;
reg[dut.DATASIZE-1:0] addrdata;
wire[dut.ADDRSIZE-1:dut.DATASIZE] addr;
wire clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_, ale, hlda, sod;

// reset block
initial begin
	clk = 1'b0; rst = 1'b1; // power-on reset
	#(CLKPTIME*3) rst = 1'b0; // 3-clock cycle reset
	$monitor("[%04g] {%b}",$time/CLKPTIME,dut.ctrl.cstate);
end

// generate clock
always begin
	#(CLKPTIME/2) clk = !clk;
end

//generate stimuli
always begin
	#(CLKPTIME*2); $finish;
end

core85 dut (clk, ~rst, ready, hold, sid, intr, trap, rst75, rst65, rst55,
	addrdata, addr, clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_,
	ale, hlda, sod);

endmodule
