module core_control_tb();

parameter DATASIZE = 8;
parameter CLKPTIME = 10;
parameter IPIN_READY = 0;
parameter IPIN_HOLD = 1;
parameter IPIN_COUNT = 2;
parameter OPIN_COUNT = 8;

reg clk,rst;
reg[DATASIZE-1:0] code;
reg[IPIN_COUNT-1:0] ipin;
wire[OPIN_COUNT-1:0] opin;

	// reset block
	initial begin
		clk = 1'b0; rst = 1'b1; code = {DATASIZE{1'b0}};
		ipin = {IPIN_COUNT{1'b0}};
		ipin[IPIN_READY] = 1'b1; // memory always ready!
		$monitor("[%04g] STATE: %b {%b,%b,%b}",$time/CLKPTIME,dut.cstate,
			code,ipin,opin);
		#(CLKPTIME*3) rst = 1'b0;
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

	control dut (clk, rst, code, ipin, opin);

endmodule
