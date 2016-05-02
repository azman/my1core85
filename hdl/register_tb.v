module register_tb ();

parameter MYSIZE = 4; // must be multiple of 4 to allow proper auto-config
parameter MYCLKP = 10;
parameter MYSTEP = MYSIZE/4;

reg clk, rst, enb;
reg[MYSIZE-1:0] data_in;
wire[MYSIZE-1:0] data_out;

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
	#(1*MYCLKP); enb = 1'b0; data_in = {MYSTEP{4'ha}};
	#(1*MYCLKP); enb = 1'b1;
	#(1*MYCLKP); enb = 1'b0; data_in = {MYSTEP{4'h5}};
	#(1*MYCLKP); enb = 1'b1;
end

defparam dut.DATASIZE = MYSIZE;
register dut (clk, rst, enb, data_in, data_out);

endmodule
