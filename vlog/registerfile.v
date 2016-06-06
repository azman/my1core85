module registerfile ( clk, rst, wrenb, flenb, r1enb, r2enb,
	waddr, r1add, r2add, wdata, ifdat, r1dat, r2dat, ofdat );

// general purpose register block
// - with two read ports and one write port
// - special interface for a flag register (8085-specific)

parameter DATASIZE = 8;
parameter ADDRSIZE = 3;
parameter REGCOUNT = 2**ADDRSIZE;
parameter REG_FLAG = REGCOUNT-2; // this is 8085-specific

input clk, rst, wrenb, flenb, r1enb, r2enb; // flenb = 8085 specific
input[ADDRSIZE-1:0] waddr, r1add, r2add;
input[DATASIZE-1:0] wdata, ifdat; // ifdat = 8085 specific
output[DATASIZE-1:0] r1dat, r2dat, ofdat; // ofdat = 8085 specific
wire[DATASIZE-1:0] r1dat, r2dat, ofdat;

wire[DATASIZE-1:0] tdata[REGCOUNT-1:0],ddata[REGCOUNT-1:0];
wire[REGCOUNT-1:0] tWR, tR1, tR2, tYW, tY1, tY2;

assign tR1 = tY1 & {REGCOUNT{r1enb}};
assign tR2 = tY2 & {REGCOUNT{r2enb}};

genvar index;
generate
for (index=0;index<REGCOUNT;index=index+1) begin : reg_block
	if (index==REG_FLAG) begin
		assign tWR[index] = flenb;
		assign ddata[index] = ifdat;
		assign ofdat = tdata[index];
	end
	else begin
		assign tWR[index] = tYW[index] & wrenb;
		assign ddata[index] = wdata;
	end
	defparam regs.DATASIZE = DATASIZE;
	register regs (clk, rst, tWR[index], ddata[index], tdata[index]);
	defparam buf1.DATASIZE = DATASIZE;
	zbuffer buf1 (tR1[index], tdata[index], r1dat);
	defparam buf2.DATASIZE = DATASIZE;
	zbuffer buf2 (tR2[index], tdata[index], r2dat);
end
endgenerate

defparam wadd1.SEL_SIZE = ADDRSIZE;
decoder wadd1 ( waddr, tYW);
defparam radd1.SEL_SIZE = ADDRSIZE;
decoder radd1 ( r1add, tY1);
defparam radd2.SEL_SIZE = ADDRSIZE;
decoder radd2 ( r2add, tY2);

endmodule
