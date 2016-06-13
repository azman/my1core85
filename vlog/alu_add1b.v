module add1b (iA, iB, iC, oS, oC, oP);

input iA, iB, iC;
output oP, oC, oS;
wire oP, oC, oS;
wire tP, tG, tC;

assign tP = iA ^ iB;
assign tG = iA & iB;
assign tC = tP & iC;
assign oS = tP ^ iC;
assign oC = tG | tC;
assign oP = tP; // for CLA circuit?

endmodule
