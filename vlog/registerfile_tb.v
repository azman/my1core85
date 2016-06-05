module registerfile_tb ();

parameter MYSIZE = 8;
parameter MYCLKP = 10;
parameter REGBIT = 3;
parameter RCOUNT = 2**REGBIT;
parameter MYSTEP = MYSIZE/4;

reg clk, rst, wrenb, r1enb, r2enb;
reg[REGBIT-1:0] waddr, r1add, r2add;
reg[MYSIZE-1:0] wdata;
wire[MYSIZE-1:0] r1dat, r2dat;

task reg_write;
	input[REGBIT-1:0] addr;
	input[MYSIZE-1:0] data;
	begin
		$display("[%04g] Writing data {%h} to {%h}", $time,data,addr);
		wdata = data; waddr = addr; r1add = addr;
		#(1*MYCLKP); wrenb = 1'b1; r1enb = 1'b1;
		#(1*MYCLKP); wrenb = 1'b0;
		$write("[%04g] Checking data @{%h} : {%h} => ", $time,r1add,r1dat);
		if (r1dat===data) $display("[OK]");
		else $display("[ERROR!]");
		#(1*MYCLKP); r1enb = 1'b0;
	end
endtask

task reg_print;
	begin
		$display("[%04g] Register content...", $time);
		$display("[%04g]    Register 0: %h", $time,
			dut.reg_block[0].regs.data_out);
		$display("[%04g]    Register 1: %h", $time,
			dut.reg_block[1].regs.data_out);
		$display("[%04g]    Register 2: %h", $time,
			dut.reg_block[2].regs.data_out);
		$display("[%04g]    Register 3: %h", $time,
			dut.reg_block[3].regs.data_out);
		$display("[%04g]    Register 4: %h", $time,
			dut.reg_block[4].regs.data_out);
		$display("[%04g]    Register 5: %h", $time,
			dut.reg_block[5].regs.data_out);
		$display("[%04g]    Register 6: %h", $time,
			dut.reg_block[6].regs.data_out);
		$display("[%04g]    Register 7: %h", $time,
			dut.reg_block[7].regs.data_out);
	end
endtask

// reset stuffs
initial begin
	clk = 1'b0; rst = 1'b0;
	#(5*MYCLKP) rst = 1'b1;
	#(5*MYCLKP) rst = 1'b0;
end

// generate clock
always #(MYCLKP/2) clk = !clk;

//generate stimuli
always begin
	$display("[%04g] Testing registerfile module...", $time);
	#(10*MYCLKP)
	reg_print;
	reg_write(3'b000,{MYSTEP{4'ha}});
	reg_print;
	reg_write(3'b000,{MYSTEP{4'h5}});
	reg_print;
	reg_write(3'b001,{MYSTEP{4'ha}});
	reg_print;
	reg_write(3'b001,{MYSTEP{4'h5}});
	reg_print;
	$finish;
end

defparam dut.DATASIZE = MYSIZE;
registerfile dut (clk, rst, wrenb, r1enb, r2enb,
	waddr, r1add, r2add, wdata, r1dat, r2dat);

endmodule
