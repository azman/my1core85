module incdec_tb ();

parameter DATASIZE = 16;

reg iS;
reg[DATASIZE-1:0] iA;
wire[DATASIZE-1:0] oS,oF;

integer numA, numS, test, ecnt;
reg[DATASIZE-1:0] tS;
reg tC;
reg[8*2-1:0] ops;

initial begin
	$display("[%3g] Start test for %g-bit increment/decrement...",
		$time,DATASIZE);
	ecnt = 0;
	for (numS=0;numS<2;numS=numS+1) begin
		iS = numS;
		for (numA=0;numA<2**DATASIZE;numA=numA+1) begin
			iA = numA;
			#10;
			if (iS) begin
				test = numA - 1;
				{ tC,tS } = test;
				ops = "--";
			end else begin
				test = numA + 1;
				{ tC,tS } = test;
				ops = "++";
			end
			//$write("[%3g] {%g+%g+%b}={%g} => ",
			//	$time,iA,iB,iC[0],{oC[DATASIZE-1],oS});
			if ((tC!==oF[0])||(tS!==oS)) begin
				$display("[ERROR] {%g%s}={%g:%b,%g}, got {%g:%b,%g}",
					iA,ops,{tC,tS},tC,tS,{oF[0],oS},oF[0],oS);
				ecnt = ecnt + 1;
			end
			//else begin
			//	$display("[OK]");
			//end
		end
	end
	$display("[%3g] End test {ErrorCount=%g}",$time,ecnt);
	$finish;
end

incdec #(.DATASIZE(DATASIZE)) dut (iS,iA,oS,oF);

endmodule
