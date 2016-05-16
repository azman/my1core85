module mux8b (inA,inB,sel,outC);
input[7:0] inA,inB;
input sel;
output[7:0] outC;

assign outC[0] = sel ? inB[0] : inA[0];
assign outC[1] = sel ? inB[1] : inA[1];
assign outC[2] = sel ? inB[2] : inA[2];
assign outC[3] = sel ? inB[3] : inA[3];
assign outC[4] = sel ? inB[4] : inA[4];
assign outC[5] = sel ? inB[5] : inA[5];
assign outC[6] = sel ? inB[6] : inA[6];
assign outC[7] = sel ? inB[7] : inA[7];

endmodule