module sub1b_tb ();

reg iJ, iK, iB;
wire oP, oB, oD;

integer loop, numA, numB, numC, test;
reg tC, tS;

initial begin
	$display("[%3g] Start test for 1-bit subtract...",$time);
	$display("[%3g] Input={B,J,K}, Output={B,D}",$time);
	for (loop=0;loop<8;loop=loop+1)
	begin
		{ iB,iJ,iK } = loop;
		#10;
		numA = iJ; numB = iK; numC = iB;
		$write("[%3g] Input={%b,%b,%b}, Output={%b,%b} => ",
			$time,iB,iJ,iK,oB,oD);
		test = numA - numB - numC;
		{ tC,tS } = test;
		if ((tC!==oB)||(tS!==oD))
			$display("[ERROR] Expected Output={%b,%b}",tC,tS);
		else
			$display("[OK]");
	end
	$display("[%3g] End test.",$time);
	$finish;
end

sub1b dut (iJ,iK,iB,oD,oB,oP);

endmodule
