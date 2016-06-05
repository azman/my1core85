module zbuffer_tb ();

parameter MYSIZE = 4;
parameter MYCLKP = 10;

reg enable;
reg[MYSIZE-1:0] data_in;
wire[MYSIZE-1:0] data_out;

task chk_state;
	begin
		#(1*MYCLKP); // let everything settle down
		$write("[%04g] Idata={%b}, Odata={%b}, enable={%b} => ",
			$time,data_in,data_out,enable);
		if (enable==1) begin
			if (data_out!==data_in) $display("[ERROR]");
			else $display("[OK!]");
		end
		else begin
			if (data_out!=={MYSIZE{1'bz}}) $display("[ERROR]");
			else $display("[OK!]");
		end
	end
endtask

// reset stuffs
initial begin
	enable = 1'b0; data_in = 1'b0;
end

//generate stimuli
always begin
	data_in = {MYSIZE{1'b1}};
	chk_state;
	enable = 1'b1;
	chk_state;
	data_in = {MYSIZE{1'b0}};
	chk_state;
	enable = 1'b0;
	chk_state;
	$finish;
end

defparam dut.DATASIZE = MYSIZE;
zbuffer dut (enable, data_in, data_out);

endmodule
