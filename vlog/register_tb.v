module register_tb ();

parameter DATASIZE = 4; // must be multiple of 4 to allow proper auto-config
parameter CLKPTIME = 10;
parameter STEPSIZE = DATASIZE/4;

reg clk, rst, enb;
reg[DATASIZE-1:0] data_in;
wire[DATASIZE-1:0] data_out;

task reg_data;
	input[DATASIZE-1:0] data;
	begin
		$display("[%04g] Register data {%h}", $time,data);
		data_in = data;
		#(1*CLKPTIME); enb = 1'b1;
		#(1*CLKPTIME); enb = 1'b0;
		$write("[%04g] Checking data {%h} => ", $time,data_out);
		if (data_out==data) $display("[OK]");
		else $display("[ERROR!]");
	end
endtask

// reset stuffs
initial begin
	clk = 1'b0; rst = 1'b0;
	enb = 1'b0; data_in = {STEPSIZE{4'h0}};
	#(1*CLKPTIME) rst = 1'b0;
	#(5*CLKPTIME) rst = 1'b1;
	#(5*CLKPTIME) rst = 1'b0;
end

// generate clock
always #(CLKPTIME/2) clk = !clk;

//generate stimuli
always begin
	$display("[%04g] Testing register module...", $time);
	reg_data({STEPSIZE{4'ha}});
	reg_data({STEPSIZE{4'h5}});
	$finish;
end

defparam dut.DATASIZE = DATASIZE;
register dut (clk, rst, enb, data_in, data_out);

endmodule
