module logic ( iS, iA, iB, oY);

parameter DATASIZE=8;

input[1:0] iS; // 00=AND, 01=XOR, 10=OR, 11=PASS
input[DATASIZE-1:0] iA, iB;
output[DATASIZE-1:0] oY;
wire[DATASIZE-1:0] oY;

wire[DATASIZE-1:0] tA,tX,tO,tC,tD;

assign tA = iA & iB; // AND
assign tX = iA ^ iB; // XOR
assign tO = iA | iB; // OR

assign tC = iS[0] ? tX : tA;
assign tD = iS[0] ? iA : tO;

assign oY = iS[1] ? tD : tC;

endmodule
