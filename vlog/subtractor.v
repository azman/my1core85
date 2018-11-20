module subtractor (iJ, iK, iB, oD, oB, oP);

parameter DATASIZE = 8;
parameter USE_EXTB = 0; // option to use external borrow

input[DATASIZE-1:0] iJ, iK, iB;
output[DATASIZE-1:0] oD, oB, oP;
wire[DATASIZE-1:0] oD, oB, oP;

wire[DATASIZE-1:0] tP, tG, tB, tC;

genvar index;

assign tB[0] = iB[0];
generate
for (index=1;index<DATASIZE;index=index+1) begin : brw_block
	if (USE_EXTB==0) begin
		assign tB[index] = oB[index-1];
	end else begin
		assign tB[index] = iB[index];
	end
end
endgenerate

generate
for (index=0;index<DATASIZE;index=index+1) begin : sub_block
	assign tP[index] = iJ[index] ^ iK[index];
	assign tG[index] = ~iJ[index] & iK[index];
	assign tC[index] = ~tP[index] & tB[index];
	assign oD[index] = tP[index] ^ tB[index];
	assign oB[index] = tG[index] | tC[index];
	assign oP[index] = tP[index]; // for CLA circuit?
end
endgenerate

endmodule
