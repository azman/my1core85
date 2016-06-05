module alu_tb ();

parameter MYSIZE=8;
parameter FLAG_S=7;
parameter FLAG_Z=6;
parameter FLAG_A=4;
parameter FLAG_P=2;
parameter FLAG_C=0;

reg[2:0] iS;
reg[MYSIZE-1:0] iA, iB, iF, tY;
wire[MYSIZE-1:0] oY, oF;
reg tX;

integer numA, numB, numC, test, rest, ecnt;

initial begin
	$display("[%3g] Start test for %g-bit ALU...",$time,MYSIZE);
	ecnt = 0;
	for (numC=0;numC<8;numC=numC+1) begin
		iS = numC;
		for (numA=0;numA<2**MYSIZE;numA=numA+1) begin
			iA = numA;
			for (numB=0;numB<2**MYSIZE;numB=numB+1) begin
				iB = numB;
				iF = {MYSIZE{1'b0}}; // clear flags
				iF[FLAG_C] = 1'b1;
				#10;
				rest = {oF[FLAG_C],oY};
				case (iS)
					3'b000: begin // ADD
						test = numA + numB;
						{tX,tY} = test;
						if (tY!==oY||tX!==oF[FLAG_C]) begin
							$display("[ERROR] {%0d+%0d}={%0d}, got {%0d} %b",
								iA,iB,test,rest,dut.sC[FLAG_C]);
							ecnt = ecnt + 1;
						end
					end
					3'b001: begin // ADD with carry
						test = numA + numB + 1;
						{tX,tY} = test;
						if (tY!==oY||tX!==oF[FLAG_C]) begin
							$display("[ERROR] {%0d+%0d+%b}={%0d}, got {%0d} %b",
								iA,iB,iF[FLAG_C],test,rest,dut.sC[FLAG_C]);
							ecnt = ecnt + 1;
						end
					end
					3'b010: begin // SUB
						test = numA - numB;
						{tX,tY} = test;
						if (tY!==oY||tX!==oF[FLAG_C]) begin
							$display("[ERROR] {%0d-%0d}={%0d}, got {%0d} %b",
								iA,iB,test,rest,dut.sC[FLAG_C]);
							ecnt = ecnt + 1;
						end
					end
					3'b011: begin // SUB with borrow
						test = numA - numB - 1;
						{tX,tY} = test;
						if (tY!==oY||tX!==oF[FLAG_C]) begin
							$display("[ERROR] {%0d-%0d-%b}={%0d}, got {%0d} %b",
								iA,iB,iF[FLAG_C],test,rest,dut.sC[FLAG_C]);
							ecnt = ecnt + 1;
						end
					end
					3'b100: begin // AND
						tY = iA & iB;
						if (tY!==oY) begin
							$display("[ERROR] {%b&%b}={%b}, got {%b}",
								iA,iB,tY,oY);
							ecnt = ecnt + 1;
						end
					end
					3'b101: begin // XOR
						tY = iA ^ iB;
						if (tY!==oY) begin
							$display("[ERROR] {%b^%b}={%b}, got {%b}",
								iA,iB,tY,oY);
							ecnt = ecnt + 1;
						end
					end
					3'b110: begin // OR
						tY = iA | iB;
						if (tY!==oY) begin
							$display("[ERROR] {%b|%b}={%b}, got {%b}",
								iA,iB,tY,oY);
							ecnt = ecnt + 1;
						end
					end
					3'b111: begin // PASS (with SUB flag results)
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
alu dut (iS,iA,iB,iF,oY,oF);

endmodule
