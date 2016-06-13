module alu (iS, iA, iB, iF, oY, oF);

parameter DATASIZE = 8;
parameter FLAG_S = 7;
parameter FLAG_Z = 6;
parameter FLAG_A = 4;
parameter FLAG_P = 2;
parameter FLAG_C = 0;

input[2:0] iS;
input[DATASIZE-1:0] iA, iB, iF;
output[DATASIZE-1:0] oY, oF;

wire[DATASIZE-1:0] tA,tL,tADD,tSUB,tC,tB,sC;
wire[DATASIZE-1:0] dA,dS; // propagate (unused) dummy signals
wire tACL,tCYL,tACA,tCYA;

// option to use carry in!
assign sC[0] = iS[0] & iF[FLAG_C];
assign sC[DATASIZE-1:1] = {(DATASIZE-2){1'b0}};
// select arithmetic op
assign tA = iS[1] ? tSUB : tADD;
// select alu op
assign oY = iS[2] ? tL : tA;

// these always updates accordingly
assign oF[FLAG_S] = oY[FLAG_S]; // sign flag
assign oF[FLAG_Z] = ~|oY; // zero flag
assign oF[FLAG_P] = ~^oY; // odd-parity flag
// these depends on operations
assign oF[FLAG_A] = iS[2] ? tACL : tACA; // auxiliary carry flag
assign oF[FLAG_C] = iS[2] ? tCYL : tCYA; // carry flag
// AND sets, XOR/OR clears, CMP takes SUB results
assign tACL = (~(iS[1]|iS[0]))|(iS[1]&iS[0]&tB[3]);
// AND/XOR/OR always clears, CMP takes SUB results
assign tCYL = (iS[1]&iS[0]&tB[7]);
// arithmetic flag assignments
assign tACA = iS[1] ? tB[3] : tC[3];
assign tCYA = iS[1] ? tB[7] : tC[7];

// adder circuit
add8b doadd (iA,iB,sC,tADD,tC,dA);
// subtract circuit
sub8b dosub (iA,iB,sC,tSUB,tB,dS);
// logic circuit
logic dolog (iS[1:0],iA,iB,tL);

endmodule
