module sub8b_tb ();

parameter DATASIZE = 8;

reg[DATASIZE-1:0] iJ, iK, iB;
wire[DATASIZE-1:0] oD, oB, oP;

integer numA, numB, numC, test, ecnt, what;
reg[DATASIZE-1:0] tD;
reg tB;

initial begin
	$display("[%3g] Start test for %g-bit subtract...",$time,DATASIZE);
	ecnt = 0;
	for (numC=0;numC<2;numC=numC+1) begin
		iB = numC;
		for (numA=0;numA<2**DATASIZE;numA=numA+1) begin
			iJ = numA;
			for (numB=0;numB<2**DATASIZE;numB=numB+1) begin
				iK = numB;
				#10;
				test = numA - numB - numC;
				{ tB,tD } = test;
				what = oD;
				if (oB[DATASIZE-1]) what = what - 2**(DATASIZE);
				//$write("[%3g] {%g-%g-%b}={%0d}{%0d} => ",
				//	$time,iJ,iK,iB[0],what,test);
				if ((tB!==oB[DATASIZE-1])||(tD!==oD)) begin
					$display("[ERROR] {%g-%g-%b}={%0d:%b,%g}, got {%0d:%b,%g}",
						iJ,iK,iB[0],test,tB,tD,what,oB[DATASIZE-1],oD);
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

sub8b #(DATASIZE) dut (iJ,iK,iB,oD,oB,oP);

endmodule
