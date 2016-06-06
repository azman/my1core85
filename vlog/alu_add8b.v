module add8b ( iA, iB, iC, oS, oC, oP);

parameter DATASIZE=8;
parameter USE_EXTC=0; // option to use external carry

input[DATASIZE-1:0] iA, iB, iC;
output[DATASIZE-1:0] oS, oC, oP;
wire[DATASIZE-1:0] oS, oC, oP;

wire[DATASIZE-1:0] tP, tC;

genvar index;

generate
if (USE_EXTC==0) begin : extc_block
	assign tC[0] = iC;
	for (index=1;index<DATASIZE;index=index+1) begin
		assign tC[index] = oC[index-1];
	end
end
else begin
	assign tC = iC;
end
endgenerate

generate
for (index=0;index<DATASIZE;index=index+1) begin : add_block
	add1b bit (iA[index],iB[index],tC[index],oS[index],oC[index],oP[index]);
end
endgenerate

endmodule
