module sub1b ( iJ, iK, iB, oD, oB, oP);

input iJ, iK, iB;
output oP, oB, oD;
wire oP, oB, oD;
wire tP, tG, tB;

assign tP = iJ ^ iK;
assign tG = ~iJ & iK;
assign tB = ~tP & iB;
assign oD = tP ^ iB;
assign oB = tG | tB;
assign oP = tP; // for CLA circuit?

endmodule
