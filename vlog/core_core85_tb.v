module core85_tb();

parameter CLKPTIME = 10;
parameter DATASIZE = dut.DATASIZE;
parameter ADDRSIZE = dut.ADDRSIZE;

// get tasks and functions from common_tb
`include "common_tb.v"

// reset block
initial begin
	clk = 1'b0; rst = 1'b1; // power-on reset
	ready = 1'b0; hold = 1'b0; sid =  1'b0; // not implemented for now
	intr =  1'b0; trap =  1'b0; // no interrupts for now
	rst75 =  1'b0; rst65 =  1'b0; rst55 =  1'b0;
	#(CLKPTIME*3) rst = 1'b0; // 3-clock cycle reset
	//$monitor("[%05g] STATE: %b {%b}[%h][%h]",$time,
	//	dut.ctrl.cstate,dut.oenb,addr,addrdata);
end

// generate clock
always begin
	#(CLKPTIME/2) clk = !clk;
end

// detect register change
always @(dut.proc.qdata or dut.proc.rtemp or dut.proc.int_q
		or dut.proc.spout or dut.proc.tpout) begin // or dut.proc.pcout
	$write("[%05g] REGS: ", $time);
	$write("[B:%h] [C:%h] ", dut.proc.qdata[0], dut.proc.qdata[1]);
	$write("[D:%h] [E:%h] ", dut.proc.qdata[2], dut.proc.qdata[3]);
	$write("[H:%h] [L:%h] ", dut.proc.qdata[4], dut.proc.qdata[5]);
	$write("[F:%h] [A:%h]\n", dut.proc.qdata[6], dut.proc.qdata[7]);
	$write("[%05g] REGS: ", $time);
	$write("[T:%h] [S:%h] ", dut.proc.rtemp, dut.proc.int_q);
	$write("[PC:%h] [SP:%h] ", dut.proc.pcout, dut.proc.spout);
	$write("[TP:%h]\n", dut.proc.tpout);
end

// detect new instruction
always @(dut.proc.rinst) begin
	$write("[%05g] CODE: [I:%h] ", $time, dut.proc.rinst);
	deassemble(dut.proc.rinst);
end

// more than 1 cycle?
always @(dut.proc.cycgo) begin
	$write("[EXTRA] [M:%b][W:%b][D:%b]\n", dut.proc.cycgo,
		dut.proc.cycrw, dut.proc.cyccd);
end

// detect stop condition
always begin
	while (dut.proc.rinst!==8'h76) #1; // wait for halt instruction
	while (dut.ctrl.cstate[9]!==1'b1) #1; // wait for halt state
	$finish;
end

// fail-safe stop condition
always begin
	#2500 $finish;
end

core85 dut (clk, ~rst, ready, hold, sid, intr, trap, rst75, rst65, rst55,
	addrdata, addr, clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_,
	ale, hlda, sod);

endmodule
