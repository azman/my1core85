module sub8b ( iJ, iK, iB, oD, oB, oP);

parameter DATASIZE=8;
parameter USE_EXTB=0; // option to use external borrow

input[DATASIZE-1:0] iJ, iK, iB;
output[DATASIZE-1:0] oD, oB, oP;
wire[DATASIZE-1:0] oD, oB, oP;

wire[DATASIZE-1:0] tP, tB;

genvar index;

generate
if (USE_EXTB==0) begin : extb_block
	assign tB[0] = iB;
	for (index=1;index<DATASIZE;index=index+1) begin
		assign tB[index] = oB[index-1];
	end
end
else begin
	assign tB = iB;
end
endgenerate

generate
for (index=0;index<DATASIZE;index=index+1) begin : sub_block
	sub1b bit (iJ[index],iK[index],tB[index],oD[index],oB[index],oP[index]);
end
endgenerate

endmodule
