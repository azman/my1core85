module core85_tb();

parameter CLKPTIME = 10; // time unit per clock cycle
parameter REG_UNIC = 1; // detect unique register change
parameter SHOW_PC_ = 0; // show program counter when REG_UNIC=1
parameter SHOWMORE = 0; // show machine cycle decoding
parameter SHOW_HH_ = 1; // show hold & interrupt registers
parameter SHOW_TS_ = 0; // show state register
parameter SHOW_BUS = 0; // show data/address bus

// get tasks and functions from common_tb
`include "common_tb.v"

// reset block
initial begin
	clk = 1'b0; rst = 1'b1; // power-on reset
	$display("[%05g] RESET ASSERTED!",$time);
	ready = 1'b1; hold = 1'b0; sid =  1'b0; // not implemented for now
	intr =  1'b0; trap =  1'b0; // no interrupts for now
	rst75 =  1'b0; rst65 =  1'b0; rst55 =  1'b0;
	#(CLKPTIME*7/2) rst = 1'b0; // 3.5-clock cycle reset
	$display("[%05g] RESET DE-ASSERTED!",$time);
end

// generate interrupt
initial begin
	#(CLKPTIME*10) rst75 = 1'b1;
	$display("[%05g] [INTERRUPT] RST7.5!",$time);
	#(CLKPTIME*1) rst75 = 1'b0;
	#(CLKPTIME*550) rst75 = 1'b1;
	$display("[%05g] [INTERRUPT] RST7.5!",$time);
	#(CLKPTIME*1) rst75 = 1'b0;
	#(CLKPTIME*10) rst55 = 1'b1;
	$display("[%05g] [INTERRUPT] RST5.5!",$time);
	#(CLKPTIME*1) rst55 = 1'b0;
	#(CLKPTIME*10) rst75 = 1'b1;
	$display("[%05g] [INTERRUPT] RST7.5!",$time);
	#(CLKPTIME*1) rst75 = 1'b0;
end

// generate hold (dma controller?)
initial begin
	#(CLKPTIME*100) hold = 1'b1;
	$display("[%05g] [HOLD] FREEZE!",$time);
	#(CLKPTIME*10) hold = 1'b0;
	$display("[%05g] [HOLD] UNFREEZE!",$time);
end

// generate clock
always begin
	#(CLKPTIME/2) clk = !clk;
end

// detect new state (alternative to using monitor)
generate
if (SHOW_TS_) begin
	always @(dut.cstate) begin
		$write("[%05g] STATE: %b {%b}\n",$time,dut.cstate,dut.stactl);
		// also some important internal status/control bits
		//$write("[%05g] {chk_adh:%b}{chk_adhl:%b}{chk_dat:%b}\n",
		//	$time,dut.chk_adh, dut.chk_adl, dut.chk_dat);
		//$write("[%05g] {chk_rgr:%b}{chk_rgw:%b}{chk_pci:%b}{chk_tpi:%b}\n",
		//	$time,dut.chk_rgr, dut.chk_rgw, dut.chk_pci, dut.chk_tpi);
		//$write("[%05g] {pcpc_d:%h}{pcpc_w:%b}{pctr_q:%h}{pctr_w:%b}\n",
		//	$time,dut.pcpc_d, dut.pcpc_w, dut.pctr_q, dut.pctr_w);
		//$write("[%05g] {upc:%b}{umm:%b}{um0:%b}{um1:%b}{ums:%b}{umt:%b}\n",
		//	$time,dut.usepc,dut.usemm,dut.usem0,dut.usem1,dut.usems,dut.usemt);
	end
end
endgenerate

// detect machine cycle
always @(dut.cstate) begin
	if (dut.cstate[1]===1'b1) begin
		decode_cycle();
	end else if (dut.cstate[4]===1'b1) begin
		// detect extra instruction cycles
		if (SHOWMORE) begin
			$write("[%05g] DECODE [M:%b][W:%b][D:%b][S:%b]\n",$time,
				dut.cycgo,dut.cycrw,dut.cyccd,dut.i_go6);
		end
	end
end

// detect change in status/control signals
//always @(iom_ or s1 or s0 or inta_ or wr_ or rd_) begin
	//$write("[%05g] IO/M:%b,S1:%b,S0:%b,INTA:%b,WR:%b,RD:%b\n",
	//	$time,iom_,s1,s0,inta_,wr_,rd_);
//end

// detect changes on data/addr bus
generate
	if (SHOW_BUS) begin
		always @(addrdata or addrhigh) begin
			// strobe will execute last in time unit
			$strobe("[%05g] ADDH:[%h],DATA:[%h]",$time,addrhigh,addrdata);
		end
	end
endgenerate

generate
if (!REG_UNIC) begin
	// detect register change
	always @(dut.rgq or dut.temp_q or dut.intr_q or
			dut.sptr_q or dut.tptr_q) begin // or dut.pcpc_q
		$write("[%05g] REGS: ", $time);
		$write("[B:%h] [C:%h] ", dut.rgq[0], dut.rgq[1]);
		$write("[D:%h] [E:%h] ", dut.rgq[2], dut.rgq[3]);
		$write("[H:%h] [L:%h] ", dut.rgq[4], dut.rgq[5]);
		$write("[F:%h] [A:%h]\n", dut.rgq[6], dut.rgq[7]);
		$write("[%05g] REGS: ", $time);
		$write("[IR:%h] [PC:%h] ", dut.ireg_q, dut.pcpc_q);
		$write("[T:%h] [M:%h] [S:%h] ", dut.temp_q, dut.intr_q, dut.ints_q);
		$write("[SP:%h] [TP:%h]\n", dut.sptr_q, dut.tptr_q);
	end
end
endgenerate

// detect change in main register
genvar i;
generate
if (REG_UNIC) begin
	for(i=0;i<8;i=i+1) begin
		always @(dut.rgq[i]) begin
			$write("[%05g] REGS: [%s:%h]\n",$time,reg8_name(i),dut.rgq[i]);
		end
	end
end
endgenerate

// detect change in temp register
generate
if (REG_UNIC) begin
	always @(dut.temp_q) begin
		$write("[%05g] REGS: [T:%h]\n",$time,dut.temp_q);
	end
end
endgenerate

// detect change in other registers
generate
if (REG_UNIC) begin
	always @(dut.ints_q) begin
		$write("[%05g] REGS: [INTP:%b][INTE:%b][INTM:%b]\n",
			$time,dut.ints_q[6:4],dut.ints_q[3],dut.ints_q[2:0]);
	end
end
endgenerate

// detect change in program counter
generate
if (REG_UNIC&&SHOW_PC_) begin
	always @(dut.pcpc_q) begin
		$write("[%05g] REGS: [PC:%h]\n", $time,dut.pcpc_q);
	end
end
endgenerate

// detect change in stack pointer
generate
if (REG_UNIC) begin
	always @(dut.sptr_q) begin
		$write("[%05g] REGS: [SP:%h]\n", $time,dut.sptr_q);
	end
end
endgenerate

// detect change in temporary pointer
generate
if (REG_UNIC) begin
	always @(dut.tptr_q) begin
		$write("[%05g] REGS: [TP:%h]\n", $time,dut.tptr_q);
	end
end
endgenerate

// detect change in interrupt flip-flop
generate
if (SHOW_HH_) begin
	always @(dut.vint_q) begin
		$write("[%05g] REGS: [VINT:%b]\n", $time,dut.vint_q);
	end
end
endgenerate

// detect change in internal interrupt acknowledge flip-flop
generate
if (SHOW_HH_) begin
	always @(dut.inta_q) begin
		$write("[%05g] REGS: [INTA:%b]\n", $time,dut.inta_q);
	end
end
endgenerate

// detect change in hold sampling flip-flop
generate
if (SHOW_HH_) begin
	always @(dut.hold_q) begin
		$write("[%05g] REGS: [HOLD:%b]\n", $time,dut.hold_q);
	end
end
endgenerate

// detect change in hold acknowledge flip-flop
generate
if (SHOW_HH_) begin
	always @(dut.hlda_q) begin
		$write("[%05g] REGS: [HLDA:%b]\n", $time,dut.hlda_q);
	end
end
endgenerate

// detect change in sod flip-flop
generate
if (REG_UNIC) begin
	always @(dut.psdo_q) begin
		$write("[%05g] REGS: [PSDO:%b]\n", $time,dut.psdo_q);
	end
end
endgenerate

// detect new instruction
always @(dut.ireg_q) begin
	$write("[%05g] CODE: [I:%h] ", $time, dut.ireg_q);
	deassemble(dut.ireg_q);
end

// detect stop condition
always begin
	while (dut.ireg_q!==8'h76) #1; // wait for halt instruction
	while (dut.cstate[9]!==1'b1) #1; // wait for halt state
	$finish;
end

// fail-safe stop condition (1000 clock cycles)
always begin
	#(CLKPTIME*1000) $finish;
end

core85 dut (clk, ~rst, ready, hold, sid, intr, trap, rst75, rst65, rst55,
	addrdata, addrhigh, clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_,
	ale, hlda, sod);

endmodule
