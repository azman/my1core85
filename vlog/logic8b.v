module logic8b (inA,inB,selOp,outC);
input[7:0] inA,inB;
input[2:0] selOp; // x00=AND, x01=XOR, x10=OR, x11=PASS
output[7:0] outC;

logic1b logic0 (inA[0],inB[0],selOp,outC[0]);
logic1b logic1 (inA[1],inB[1],selOp,outC[1]);
logic1b logic2 (inA[2],inB[2],selOp,outC[2]);
logic1b logic3 (inA[3],inB[3],selOp,outC[3]);
logic1b logic4 (inA[4],inB[4],selOp,outC[4]);
logic1b logic5 (inA[5],inB[5],selOp,outC[5]);
logic1b logic6 (inA[6],inB[6],selOp,outC[6]);
logic1b logic7 (inA[7],inB[7],selOp,outC[7]);

endmodule