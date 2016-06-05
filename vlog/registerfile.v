module registerfile ( clk, rst, wrenb, r1enb, r2enb,
	waddr, r1add, r2add, wdata, r1dat, r2dat );

parameter DATASIZE=8;
parameter ADDRSIZE=3;
parameter REGCOUNT=2**ADDRSIZE;

input clk, rst, wrenb, r1enb, r2enb;
input[ADDRSIZE-1:0] waddr, r1add, r2add;
input[DATASIZE-1:0] wdata;
output[DATASIZE-1:0] r1dat, r2dat;
wire[DATASIZE-1:0] r1dat, r2dat;

wire[DATASIZE-1:0] tdata[REGCOUNT-1:0];
wire[REGCOUNT-1:0] tWR, tR1, tR2, tYW, tY1, tY2;

assign tWR = tYW & {REGCOUNT{wrenb}};
assign tR1 = tY1 & {REGCOUNT{r1enb}};
assign tR2 = tY2 & {REGCOUNT{r2enb}};

genvar index;
generate
for (index=0;index<REGCOUNT;index=index+1) begin : reg_block
	defparam regs.DATASIZE = DATASIZE;
	register regs (clk, rst, tWR[index], wdata, tdata[index]);
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
