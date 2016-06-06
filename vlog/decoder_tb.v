module decoder_tb ();

parameter DATASIZE = 3;
parameter OUTPSIZE = 2**DATASIZE;

reg[DATASIZE-1:0] iS;
wire[OUTPSIZE-1:0] oY, oX;
reg[OUTPSIZE-1:0] oZ; // for checking

integer loop;
initial
begin
	// test 1-hot
	oZ = 1; // only LSB 1, the rest should be zero
	$display("[%3g] 1-HOT Encoding... %b",$time,oZ);
	$display("[%3g] Start test for %g-%g decoder...",$time, DATASIZE, OUTPSIZE);
	for (loop=0;loop<OUTPSIZE;loop=loop+1)
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
	$display("[%3g] Start test for %g-%g decoder...",$time, DATASIZE, OUTPSIZE);
	for (loop=0;loop<OUTPSIZE;loop=loop+1)
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

defparam dut.SEL_SIZE = DATASIZE;
decoder dut ( iS, oY);
defparam d2t.SEL_SIZE = DATASIZE;
defparam d2t.ONE_COLD = 1;
decoder d2t ( iS, oX);

endmodule
