module logic_tb ();

parameter MYSIZE=8;

reg[1:0] iS; // 00=AND, 01=XOR, 10=OR, 11=PASS
reg[MYSIZE-1:0] iA, iB, tY;
wire[MYSIZE-1:0] oY;

integer numA, numB, numC, ecnt;

initial begin
	$display("[%3g] Start test for %g-bit logic...",$time,MYSIZE);
	ecnt = 0;
	for (numC=0;numC<4;numC=numC+1) begin
		iS = numC;
		for (numA=0;numA<2**MYSIZE;numA=numA+1) begin
			iA = numA;
			for (numB=0;numB<2**MYSIZE;numB=numB+1) begin
				iB = numB;
				#10;
				case (iS)
					2'b00: begin // AND
						tY = iA & iB;
						if (tY!==oY) begin
							$display("[ERROR] {%b&%b}={%b}, got {%b}",
								iA,iB,tY,oY);
							ecnt = ecnt + 1;
						end
					end
					2'b01: begin // XOR
						tY = iA ^ iB;
						if (tY!==oY) begin
							$display("[ERROR] {%b^%b}={%b}, got {%b}",
								iA,iB,tY,oY);
							ecnt = ecnt + 1;
						end
					end
					2'b10: begin // OR
						tY = iA | iB;
						if (tY!==oY) begin
							$display("[ERROR] {%b|%b}={%b}, got {%b}",
								iA,iB,tY,oY);
							ecnt = ecnt + 1;
						end
					end
					2'b11: begin // PASS
						tY = iA;
						if (tY!==oY) begin
							$display("[ERROR] {%b}={%b}, got {%b}",
								iA,tY,oY);
							ecnt = ecnt + 1;
						end
					end
				endcase
			end
		end
	end
	$display("[%3g] End test {ErrorCount=%g}",$time,ecnt);
	$finish;
end

defparam dut.DATASIZE=MYSIZE;
logic dut (iS,iA,iB,oY);

endmodule
