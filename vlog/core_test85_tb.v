module test85_tb();

parameter CLKPTIME = 10;
parameter DATASIZE = 8;
parameter ADDRSIZE = 16;

// get tasks and functions from common_tb
`include "common_tb.v"

// reset block
initial begin
	clk = 1'b0; rst = 1'b1; // power-on reset
	ready = 1'b1; hold = 1'b0; sid =  1'b0; // not implemented for now
	intr =  1'b0; trap =  1'b0; // no interrupts for now
	rst75 =  1'b0; rst65 =  1'b0; rst55 =  1'b0;
	#(CLKPTIME*3) rst = 1'b0; // 3-clock cycle reset
	//$monitor("[%05g] STATE: %b {%b}[%h][%h]",$time,
	//	dut.cstate, dut.stactl,addr,addrdata);
end

// generate clock
always begin
	#(CLKPTIME/2) clk = !clk;
end

// detect register change //or dut.pcpc_q
always @(dut.rgq or dut.temp_q or dut.intr_q or dut.sptr_q or dut.tptr_q) begin
	$write("[%05g] REGS: ", $time);
	$write("[B:%h] [C:%h] ", dut.rgq[0], dut.rgq[1]);
	$write("[D:%h] [E:%h] ", dut.rgq[2], dut.rgq[3]);
	$write("[H:%h] [L:%h] ", dut.rgq[4], dut.rgq[5]);
	$write("[F:%h] [A:%h]\n", dut.rgq[6], dut.rgq[7]);
	$write("[%05g] REGS: ", $time);
	$write("[T:%h] [I:%h] ", dut.temp_q, dut.intr_q);
	$write("[PC:%h] [SP:%h] [TP:%h]\n", dut.pcpc_q, dut.sptr_q, dut.tptr_q);
end

// detect new state (alternative to using monitor)
always @(dut.cstate) begin
//	$strobe("[%05g] STATE: %b {%b}[%h][%h][%h][%h]",$time,
//		dut.cstate, dut.stactl,addr,addrdata,dut.busd_d,dut.busd_q);
end

// detect new instruction
always @(dut.ireg_q) begin
	$write("[%05g] CODE: [I:%h] ", $time, dut.ireg_q);
	deassemble(dut.ireg_q);
end

// more than 1 cycle?
always @(dut.cycgo) begin
	if(dut.cycgo!=={4{1'b0}}) begin
		$write("[EXTRA] [M:%b][W:%b][D:%b]\n", dut.cycgo,
			dut.cycrw, dut.cyccd);
	end
end

// detect stop condition
always begin
	while (dut.ireg_q!==8'h76) #1; // wait for halt instruction
	while (dut.cstate[9]!==1'b1) #1; // wait for halt state
	$finish;
end

// fail-safe stop condition
always begin
	#2200 $finish;
end

always @(negedge clk) begin
	//$strobe("[%05g] {chk_adh:%b}{chk_adhl:%b}{chk_dat:%b}\n",
	//	$time,dut.chk_adh, dut.chk_adl, dut.chk_dat);
	//$strobe("[%05g] {chk_rgr:%b}{chk_rgw:%b}{chk_irw:%b}{chk_pcw:%b}\n",
	//	$time,dut.chk_rgr, dut.chk_rgw, dut.chk_irw, dut.chk_pcw);
	//$strobe("[%05g] {rgr:%b}{rgw:%b}{accu_d:%b}{accu_w:%b}\n",
	//	$time,dut.rgr, dut.rgw, dut.accu_d, dut.accu_w);
	//$strobe("[%05g] {rgr:%b}{rgw:%b}{opr1_d:%b}{opr2_d:%b}\n",
	//	$time,dut.rgr, dut.rgw, dut.opr1_d, dut.opr2_d);
	//$strobe("[%05g] {upc:%b}{umm:%b}{um0:%b}{um1:%b}{ums:%b}{umt:%b}\n",
	//	$time,dut.usepc,dut.usemm,dut.usem0,dut.usem1,dut.usems,dut.usemt);
end

test85 dut (clk, ~rst, ready, hold, sid, intr, trap, rst75, rst65, rst55,
	addrdata, addr, clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_,
	ale, hlda, sod);

endmodule
