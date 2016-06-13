module register_tb ();

parameter DATASIZE = 4; // must be multiple of 4 to allow 'auto-config'
parameter CLKPTIME = 10;
parameter STEPSIZE = DATASIZE/4;

reg clk, rst, enb;
reg[DATASIZE-1:0] idata;
wire[DATASIZE-1:0] odata;

task reg_data;
	input[DATASIZE-1:0] data;
	begin
		$display("[%04g] Register data {%h}", $time,data);
		idata = data;
		#(1*CLKPTIME); enb = 1'b1;
		#(1*CLKPTIME); enb = 1'b0;
		$write("[%04g] Checking data {%h} => ", $time,odata);
		if (odata==data) $display("[OK]");
		else $display("[ERROR!]");
	end
endtask

// reset stuffs
initial begin
	clk = 1'b0; rst = 1'b0;
	enb = 1'b0; idata = {STEPSIZE{4'h0}};
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

register #(DATASIZE) dut (clk, rst, enb, idata, odata);

endmodule
