module selacc8b (inA,inB,inC,selOp,outF,outC);
input[7:0] inA,inB;
input[1:0] inC;
input[2:0] selOp;
output[7:0] outF,outC;

wire[7:0] tmpF;
wire tmpCY,tmpAC;
wire test1,test2;

assign test1 = selOp[1] & selOp[0];
assign test2 = test1 & selOp[2];

mux8b selALU (inA,inB,selOp[2],outC); // selOp[2]=0(ARITH):1(LOGIC)
mux8b selFLG (outC,inA,test2,tmpF); // prepare to resolve flag

assign outF[7] = tmpF[7]; // Sign flag
assign outF[6] = ~(tmpF[0] | tmpF[1] | tmpF[2] | tmpF[3] | tmpF[4] | tmpF[5] | tmpF[6] | tmpF[7]); // Zero flag
assign outF[2] = ~(tmpF[0] ^ tmpF[1] ^ tmpF[2] ^ tmpF[3] ^ tmpF[4] ^ tmpF[5] ^ tmpF[6] ^ tmpF[7]); // Parity flag

// AND sets, XOR/OR clears, CMP takes SUB results
assign tmpAC = ~(selOp[1] | selOp[0]) + (test1 & inC[1]);
// AND/XOR/OR always clears, CMP takes SUB results
assign tmpCY = (test1 & inC[0]);

mux1b muxA (inC[1],tmpAC,selOp[2],outF[4]); // AC flag
mux1b muxC (inC[0],tmpCY,selOp[2],outF[0]); // CY flag

endmodule