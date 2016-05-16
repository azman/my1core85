module decode4b (inD,outT);
input[3:0] inD; // 4-16 bit decoder
output[15:0] outT; // active high output

wire[7:0] tmpD8;

assign tmpD8[0] = ~inD[1] & ~inD[0];
assign tmpD8[1] = ~inD[1] & inD[0];
assign tmpD8[2] = inD[1] & ~inD[0];
assign tmpD8[3] = inD[1] & inD[0];

assign tmpD8[4] = ~inD[3] & ~inD[2];
assign tmpD8[5] = ~inD[3] & inD[2];
assign tmpD8[6] = inD[3] & ~inD[2];
assign tmpD8[7] = inD[3] & inD[2];

assign outT[0] = tmpD8[0] & tmpD8[4];
assign outT[1] = tmpD8[1] & tmpD8[4];
assign outT[2] = tmpD8[2] & tmpD8[4];
assign outT[3] = tmpD8[3] & tmpD8[4];

assign outT[4] = tmpD8[0] & tmpD8[5];
assign outT[5] = tmpD8[1] & tmpD8[5];
assign outT[6] = tmpD8[2] & tmpD8[5];
assign outT[7] = tmpD8[3] & tmpD8[5];

assign outT[8] = tmpD8[8] & tmpD8[6];
assign outT[9] = tmpD8[9] & tmpD8[6];
assign outT[10] = tmpD8[10] & tmpD8[6];
assign outT[11] = tmpD8[11] & tmpD8[6];

assign outT[12] = tmpD8[12] & tmpD8[7];
assign outT[13] = tmpD8[13] & tmpD8[7];
assign outT[14] = tmpD8[14] & tmpD8[7];
assign outT[15] = tmpD8[15] & tmpD8[7];

endmodule