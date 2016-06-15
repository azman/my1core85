module core_control_tb();

parameter CLKPTIME = 10;
parameter IPIN_READY = 0;
parameter IPIN_HOLD = 1;
parameter IPIN_COUNT = dut.IPIN_COUNT;
parameter OENB_COUNT = dut.OENB_COUNT;
parameter OPIN_COUNT = dut.OPIN_COUNT;

reg clk,rst;
reg[dut.INSTSIZE-1:0] inst; // decoded instruction info
reg[IPIN_COUNT-1:0] ipin;
wire[OENB_COUNT-1:0] oenb;
wire[OPIN_COUNT-1:0] opin;

// reset block
initial begin
	clk = 1'b1; rst = 1'b0; inst = {dut.INSTSIZE{1'b0}};
	ipin = {IPIN_COUNT{1'b0}};
	ipin[IPIN_READY] = 1'b1; // memory always ready!
	$monitor("[%04g] STATE: %b {%b,%b,%b,%b}",$time/CLKPTIME,
		dut.cstate,inst,ipin,oenb,opin);
	#(CLKPTIME*3) rst = 1'b1;
end

// generate clock
always begin
	#(CLKPTIME/2) clk = !clk;
end

//generate stimuli
always begin
	// just monitoring state - not feeding anything
	#(CLKPTIME*50); $finish;
end

control dut (~clk, ~rst, inst, ipin, oenb, opin);

endmodule
