module sub1b_tb ();

reg iA, iB, iC;
wire oP, oC, oS;

integer loop, numA, numB, numC, test;
reg tC, tS;

initial begin
	$display("[%3g] Start test for 1-bit subtract...",$time);
	$display("[%3g] Input={B,J,K}, Output={B,D}",$time);
	for (loop=0;loop<8;loop=loop+1)
	begin
		{ iC,iA,iB } = loop;
		#10;
		numA = iA; numB = iB; numC = iC;
		$write("[%3g] Input={%b,%b,%b}, Output={%b,%b} => ",
			$time,iC,iA,iB,oC,oS);
		test = numA - numB - numC;
		{ tC,tS } = test;
		if ((tC!==oC)||(tS!==oS))
			$display("[ERROR] Expected Output={%b,%b}",tC,tS);
		else
			$display("[OK]");
	end
	$display("[%3g] End test.",$time);
	$finish;
end

sub1b dut (iA,iB,iC,oS,oC,oP);

endmodule
