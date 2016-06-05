module alureg ( clk, iC );

parameter DATASIZE=8;
parameter FLAG_S=7;
parameter FLAG_Z=6;
parameter FLAG_A=4;
parameter FLAG_P=2;
parameter FLAG_C=0;

defparam alu_block.DATASIZE=MYSIZE;
alu alu_block (iS,iA,iB,iF,oY,oF);
defparam reg_block.DATASIZE=MYSIZE;
registerfile reg_block (clk,rst,wrenb,flenb,r1enb,r2enb,
	waddr,r1add,r2add,wdata,ifdat,r1dat,r2dat,ofdat);

// top 2-bits instruction decoding
// 00 - transfer + arithmetic // ta
// 01 - register move + halt // mv
// 10 - basic alu (ad,as,&,|,^,cmp) // al
// 11 - stack, i/o & control // sc

endmodule
