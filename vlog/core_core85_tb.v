module core85_tb();

parameter CLKPTIME = 10;
parameter DATASIZE = dut.DATASIZE;
parameter ADDRSIZE = dut.ADDRSIZE;

reg clk, rst, ready, hold, sid, intr, trap, rst75, rst65, rst55;
wire[DATASIZE-1:0] addrdata;
wire[ADDRSIZE-1:DATASIZE] addr;
wire clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_, ale, hlda, sod;

// get tasks and functions from common_tb
`include "common_tb.v"

// system memory
reg[DATASIZE-1:0] memory[(2**ADDRSIZE)-1:0];
reg[ADDRSIZE-1:0] mem_addr;
//integer loop;

// memory read
assign addrdata = (rd_===1'b0&&iom_===1'b0) ?
	memory[mem_addr] : {DATASIZE{1'bz}};

// reset block
initial begin
	$readmemh("memory.txt",memory);
	//$display("[DEBUG] MEMORY LOADED");
	//for (loop=0;loop<8;loop=loop+1) begin
	//	$display("[DEBUG] %d:%h",loop,memory[loop]);
	//end
	clk = 1'b0; rst = 1'b1; // power-on reset
	ready = 1'b0; hold = 1'b0; sid =  1'b0; // not implemented for now
	intr =  1'b0; trap =  1'b0; // no interrupts for now
	rst75 =  1'b0; rst65 =  1'b0; rst55 =  1'b0;
	#(CLKPTIME*3) rst = 1'b0; // 3-clock cycle reset
	$monitor("[%04g] STATE: %b {%b}[%h][%h]",$time/CLKPTIME,
		dut.ctrl.cstate,dut.oenb,addr,addrdata);
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

// detect memory writes
always @(posedge wr_) begin
	if (iom_===1'b0) begin
		$write("[%04g] WR MEM@%h: %h => ", $time/CLKPTIME,
			mem_addr, memory[mem_addr]);
		memory[mem_addr] = addrdata;
		$write("%h\n", memory[mem_addr]);
	end
end

// detect memory reads
always @(posedge rd_) begin
	if (iom_===1'b0) begin // &&s0===1'b0
		$write("[%04g] RD MEM@%h: %h\n", $time/CLKPTIME,
			mem_addr, memory[mem_addr]);
	end
end

// detect register change
always @(dut.proc.qdata or dut.proc.rtemp or dut.proc.int_q
		or dut.proc.spout or dut.proc.tpout) begin // or dut.proc.pcout
	$write("[%04g] REGS: ", $time/CLKPTIME);
	$write("[B:%h] [C:%h] ", dut.proc.qdata[0], dut.proc.qdata[1]);
	$write("[D:%h] [E:%h] ", dut.proc.qdata[2], dut.proc.qdata[3]);
	$write("[H:%h] [L:%h] ", dut.proc.qdata[4], dut.proc.qdata[5]);
	$write("[F:%h] [A:%h]\n", dut.proc.qdata[6], dut.proc.qdata[7]);
	$write("[%04g] REGS: ", $time/CLKPTIME);
	$write("[T:%h] [S:%h] ", dut.proc.rtemp, dut.proc.int_q);
	$write("[PC:%h] [SP:%h] ", dut.proc.pcout, dut.proc.spout);
	$write("[TP:%h]\n", dut.proc.tpout);
end

// detect new instruction
always @(dut.proc.rinst) begin
	$write("[%04g] CODE: [I:%h] ", $time/CLKPTIME, dut.proc.rinst);
	deassemble(dut.proc.rinst);
end

// more than 1 cycle?
always @(dut.proc.cycgo) begin
	$write("[MORE] [M:%b][W:%b][D:%b]\n", dut.proc.cycgo,
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
