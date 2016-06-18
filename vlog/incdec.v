module incdec (iS, iA, oS, oF);

parameter DATASIZE = 8;
parameter FLAGSIZE = 8;
parameter FLAG_S = 7;
parameter FLAG_Z = 6;
parameter FLAG_A = 4;
parameter FLAG_P = 2;
parameter FLAG_C = 0;

input iS;
input[DATASIZE-1:0] iA;
output[DATASIZE-1:0] oS;
output[FLAGSIZE-1:0] oF;
wire[DATASIZE-1:0] oS;
wire[FLAGSIZE-1:0] oF;

wire[DATASIZE-1:0] tS, tD;
wire[DATASIZE:0] tC, tB;

assign tC[0] = 1'b1; // add 1!
assign tC[DATASIZE:1] = iA[DATASIZE-1:0] & tC[DATASIZE-1:0];
assign tB[0] = 1'b1; // minus 1!
assign tB[DATASIZE:1] = ~iA[DATASIZE-1:0] & tB[DATASIZE-1:0];
assign tS = iA ^ tC;
assign tD = iA ^ tB;

assign oS = (iS==1) ? tD : tS;

assign oF[FLAG_S] = oS[FLAG_S];
assign oF[FLAG_Z] = ~|oS;
assign oF[FLAG_P] = ~^oS;
assign oF[FLAG_A] = (iS==1) ? tB[DATASIZE/2] : tC[DATASIZE/2];
assign oF[FLAG_C] = (iS==1) ? tB[DATASIZE] : tC[DATASIZE];

endmodule
