module decoder_tb ();

parameter MYSIZE = 3;
parameter OPSIZE=2**MYSIZE;

reg[MYSIZE-1:0] iS;
wire[OPSIZE-1:0] oY, oX;
reg[OPSIZE-1:0] oZ; // for checking

integer loop;
initial
begin
	// test 1-hot
	oZ = 1; // only LSB 1, the rest should be zero
	$display("[%3g] 1-HOT Encoding... %b",$time,oZ);
	$display("[%3g] Start test for %g-%g decoder...",$time, MYSIZE, OPSIZE);
	for (loop=0;loop<OPSIZE;loop=loop+1)
	begin
		iS = loop;
		#10;
		$write("[%3g] Input=%b, Output=%b => ",$time, iS, oY);
		if (oY != oZ) $display("[ERROR] Expected Output=%b",oZ);
		else $display("[OK]");
		oZ = oZ << 1;
	end
	$display("[%3g] End test.",$time);
	// test 1-cold
	oZ = 1; // only LSB 1, the rest should be zero
	$display("[%3g] 1-COLD Encoding... %b",$time,~oZ);
	$display("[%3g] Start test for %g-%g decoder...",$time, MYSIZE, OPSIZE);
	for (loop=0;loop<OPSIZE;loop=loop+1)
	begin
		iS = loop;
		#10;
		$write("[%3g] Input=%b, Output=%b => ",$time, iS, oX);
		if (oX != ~oZ) $display("[ERROR] Expected Output=%b",~oZ);
		else $display("[OK]");
		oZ = oZ << 1;
	end
	$display("[%3g] End test.",$time);
	$finish;
end

defparam dut.SEL_SIZE = MYSIZE;
decoder dut ( iS, oY);
defparam d2t.SEL_SIZE = MYSIZE;
defparam d2t.ONE_COLD = 1;
decoder d2t ( iS, oX);

endmodule
