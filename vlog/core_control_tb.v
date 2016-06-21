module core_control_tb();

parameter CLKPTIME = 10;
parameter INSTSIZE = dut.INSTSIZE;
parameter IPIN_READY = dut.IPIN_READY;
parameter IPIN_HOLD = dut.IPIN_HOLD;
parameter IPIN_COUNT = dut.IPIN_COUNT;
parameter OENB_COUNT = dut.OENB_COUNT;
parameter OPIN_COUNT = dut.OPIN_COUNT;

reg clk,rst;
reg[INSTSIZE-1:0] inst; // decoded instruction info
reg[IPIN_COUNT-1:0] ipin;
wire[OENB_COUNT-1:0] oenb;
wire[OPIN_COUNT-1:0] opin;

// reset block
initial begin
	clk = 1'b1; rst = 1'b0; inst = {INSTSIZE{1'b0}};
	ipin = {IPIN_COUNT{1'b0}};
	ipin[IPIN_READY] = 1'b1; // memory always ready!
	$monitor("[%04g] STATE: %b {%b,%b}",$time/CLKPTIME,dut.cstate,oenb,opin);
	#(CLKPTIME*3) rst = 1'b1;
end

// generate clock
always begin
	#(CLKPTIME/2) clk = !clk;
end

//parameter INST_GO6 = 0;
//parameter INST_DAD = 1;
//parameter INST_HLT = 2;
//parameter INST_DIO = 3;
//parameter INFO_CYC = 4; // 4-bits cycle info
//parameter INST_CYL = 4;
//parameter INST_CYH = 7;
//parameter INST_RWL = 8;
//parameter INST_RWH = 11;
//parameter INST_CDL = 12;
//parameter INST_CDH = 15;
//parameter INST_CCC = 16;
//parameter INSTSIZE = 17;

parameter INST_FXXXX = 17'b0_0000_0000_0000_0_0_0_0;
parameter INST_SXXXX = 17'b0_0000_0000_0000_0_0_0_1;
parameter INST_FRXXX = 17'b0_0000_0000_0001_0_0_0_0;
parameter INST_FWXXX = 17'b0_0000_0001_0001_0_0_0_0;
parameter INST_FRRRX = 17'b0_0100_0000_0111_0_0_0_0;
parameter INST_FRRWX = 17'b0_0100_0100_0111_0_0_0_0;

task do_inst;
	input[INSTSIZE-1:0] l_inst;
	begin
		// wait until state T2 to assign new inst
		while (dut.cstate[2]!==1'b1) #1;
		inst = l_inst;
		while (dut.cstate[4]!==1'b1) #1;
		if (l_inst[dut.INST_GO6])
			while (dut.cstate[6]!==1'b1) #1;
		if (dut.dofirst!=1'b1) begin
			while (dut.do_last!==1'b1) #1;
			// if this is halt instruction, wait for halt state
			while (dut.cstate[1]!==1'b1) #1;
			while (dut.cstate[3]!==1'b1) #1;
		end
		//#(CLKPTIME);
	end
endtask

//generate stimuli
always begin
	// wait reset to finish
	while (~rst) #1;
	$display("[DEBUG] single 4-state instruction!");
	do_inst(INST_FXXXX);
	$display("[DEBUG] single 6-state instruction!");
	do_inst(INST_SXXXX); // assign 6-state instruction?
	$display("[DEBUG] 2-cycle FR 7-state instruction!");
	do_inst(INST_FRXXX); // assign 7-state FR instruction?
	$display("[DEBUG] 2-cycle FW 7-state instruction!");
	do_inst(INST_FWXXX); // assign 7-state FW instruction?
	$display("[DEBUG] lda instruction! - 4th cycle is data!");
	do_inst(INST_FRRRX); // assign lda instruction?
	$display("[DEBUG] sta instruction! - 4th cycle is data!");
	do_inst(INST_FRRWX); // assign sta instruction?
	$finish;
end

control dut (~clk, ~rst, inst, ipin, oenb, opin);

endmodule
