module adder (iA, iB, iC, oS, oC, oP);

parameter DATASIZE = 8;
parameter USE_EXTC = 0; // option to use external carry

input[DATASIZE-1:0] iA, iB, iC;
output[DATASIZE-1:0] oS, oC, oP;
wire[DATASIZE-1:0] oS, oC, oP;

wire[DATASIZE-1:0] tP, tG, tC, tD;

genvar index; // generate is only available in verilog2001

assign tC[0] = iC[0]; // always external carry in
generate
for (index=1;index<DATASIZE;index=index+1) begin : cry_block
	if (USE_EXTC==0) begin
		assign tC[index] = oC[index-1];
	end else begin
		assign tC[index] = iC[index];
	end
end
endgenerate

generate
for (index=0;index<DATASIZE;index=index+1) begin : add_block
	assign tP[index] = iA[index] ^ iB[index];
	assign tG[index] = iA[index] & iB[index];
	assign tD[index] = tP[index] & tC[index];
	assign oS[index] = tP[index] ^ tC[index];
	assign oC[index] = tG[index] | tD[index];
	assign oP[index] = tP[index]; // for CLA circuit?
end
endgenerate

endmodule
