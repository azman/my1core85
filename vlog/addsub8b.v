module addsub8b (inA,inB,inC,selOp,outC,outS);
input[7:0] inA,inB;
input[2:0] selOp; // selOp[2]=N/A, selOp[1]=0(ADD):1(SUB), selOp[0]=selCY
input inC;
output[7:0] outS;
output[1:0] outC; // outC[1]=AC, outC[0]=CY

wire[7:0] tmpP,tmpC; // tmpP for CLA if needed later

// Input CY to AU dependes on selOp on ARITH op
assign tmpC[0] = ~selOp[2] & selOp[0] & inC;

addsub1b adsb0 (inA[0],inB[0],tmpC[0],selOp[1],tmpP[0],tmpC[1],outS[0]);
addsub1b adsb1 (inA[1],inB[1],tmpC[1],selOp[1],tmpP[1],tmpC[2],outS[1]);
addsub1b adsb2 (inA[2],inB[2],tmpC[2],selOp[1],tmpP[2],tmpC[3],outS[2]);
addsub1b adsb3 (inA[3],inB[3],tmpC[3],selOp[1],tmpP[3],outC[1],outS[3]);
addsub1b adsb4 (inA[4],inB[4],outC[1],selOp[1],tmpP[4],tmpC[4],outS[4]);
addsub1b adsb5 (inA[5],inB[5],tmpC[4],selOp[1],tmpP[5],tmpC[5],outS[5]);
addsub1b adsb6 (inA[6],inB[6],tmpC[5],selOp[1],tmpP[6],tmpC[6],outS[6]);
addsub1b adsb7 (inA[7],inB[7],tmpC[6],selOp[1],tmpP[7],outC[0],outS[7]);

endmodule