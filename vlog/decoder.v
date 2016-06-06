module decoder ( iS, oY );

parameter SEL_SIZE = 3;
parameter OUT_SIZE = 2**SEL_SIZE;
parameter CHK_SIZE = OUT_SIZE*SEL_SIZE;
parameter ONE_COLD = 0;

input[SEL_SIZE-1:0] iS;
output[OUT_SIZE-1:0] oY;

wire[OUT_SIZE-1:0] oY;
wire[CHK_SIZE-1:0] tS;

genvar index,check,istep;

generate
for (check=0;check<SEL_SIZE;check=check+1) begin
	localparam count = 2**check;
	localparam steps = 2**(check+1);
	// for inverts
	for (index=0;index<OUT_SIZE;index=index+steps) begin
		for (istep=0;istep<count;istep=istep+1) begin
			assign tS[((index+istep)*SEL_SIZE)+check] = ~iS[check];
		end
	end
	// for directs
	for (index=0;index<OUT_SIZE;index=index+steps) begin
		for (istep=0;istep<count;istep=istep+1) begin
			assign tS[((index+istep+count)*SEL_SIZE)+check] = iS[check];
		end
	end
end
endgenerate

generate
for (index=0;index<OUT_SIZE;index=index+1)
begin
	if (ONE_COLD)
		assign oY[index] = ~&tS[index*SEL_SIZE+(SEL_SIZE-1):index*SEL_SIZE];
	else
		assign oY[index] = &tS[index*SEL_SIZE+(SEL_SIZE-1):index*SEL_SIZE];
end
endgenerate

endmodule
