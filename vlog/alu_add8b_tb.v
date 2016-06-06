module add8b_tb ();

parameter DATASIZE = 8;

reg[DATASIZE-1:0] iA, iB, iC;
wire[DATASIZE-1:0] oS, oC, oP;

integer numA, numB, numC, test, ecnt;
reg[DATASIZE-1:0] tS;
reg tC;

initial begin
	$display("[%3g] Start test for %g-bit adder...",$time,DATASIZE);
	ecnt = 0;
	for (numC=0;numC<2;numC=numC+1) begin
		iC = numC;
		for (numA=0;numA<2**DATASIZE;numA=numA+1) begin
			iA = numA;
			for (numB=0;numB<2**DATASIZE;numB=numB+1) begin
				iB = numB;
				#10;
				test = numA + numB + numC;
				{ tC,tS } = test;
				//$write("[%3g] {%g+%g+%b}={%g} => ",
				//	$time,iA,iB,iC[0],{oC[DATASIZE-1],oS});
				if ((tC!==oC[DATASIZE-1])||(tS!==oS)) begin
					$display("[ERROR] {%g+%g+%b}={%g:%b,%g}, got {%g:%b,%g}",
						iA,iB,iC[0],{tC,tS},tC,tS,
						{oC[DATASIZE-1],oS},oC[DATASIZE-1],oS);
					ecnt = ecnt + 1;
				end
				//else begin
				//	$display("[OK]");
				//end
			end
		end
	end
	$display("[%3g] End test {ErrorCount=%g}",$time,ecnt);
	$finish;
end

defparam dut.DATASIZE = DATASIZE;
add8b dut (iA,iB,iC,oS,oC,oP);

endmodule
