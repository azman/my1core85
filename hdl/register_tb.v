module register_tb ();

parameter MYSIZE = 4; // must be multiple of 4 to allow proper auto-config
parameter MYCLKP = 10;
parameter MYSTEP = MYSIZE/4;

reg clk, rst, enb;
reg[MYSIZE-1:0] data_in;
wire[MYSIZE-1:0] data_out;

task reg_data;
	input[MYSIZE-1:0] data;
	integer loop;
	begin
		$display("[%04g] Register data {%h}", $time,data);
		data_in = data;
		#(1*MYCLKP); enb = 1'b1;
		#(1*MYCLKP); enb = 1'b0;
		$write("[%04g] Checking data {%h} => ", $time,data_out);
		if (data_out==data) $display("[OK]");
		else $display("[ERROR!]");
	end
endtask

// reset stuffs
initial begin
	clk = 1'b0; rst = 1'b0;
	enb = 1'b0; data_in = {MYSTEP{4'h0}};
	#(1*MYCLKP) rst = 1'b0;
	#(5*MYCLKP) rst = 1'b1;
	#(5*MYCLKP) rst = 1'b0;
end

// generate clock
always #(MYCLKP/2) clk = !clk;

//generate stimuli
always begin
	reg_data({MYSTEP{4'ha}});
	reg_data({MYSTEP{4'h5}});
	$finish;
end

defparam dut.DATASIZE = MYSIZE;
register dut (clk, rst, enb, data_in, data_out);

endmodule
