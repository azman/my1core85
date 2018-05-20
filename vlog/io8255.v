module io8255 ( RST, WR_, RD_, CS_, ADDR, PORTA, PORTB, PORTC, PDATA );

parameter DATASIZE = 8;
parameter ADDRSIZE = 2;
parameter REGCOUNT = 2**ADDRSIZE;

// port definitions (i/o)
input RST, WR_, RD_, CS_;
input[ADDRSIZE-1:0] A;
inout[DATASIZE-1:0] PORTA, PORTB, PORTC, PDATA;

// output ports as wires
wire[DATASIZE-1:0] PORTA, PORTB, PORTC, PDATA;

// alias for input signals
wire rst_, wrn_, rdn_, csn_;
wire[ADDRSIZE-1:0] addr;
wire[DATASIZE-1:0] inpA, inpB, inpC, iDAT;
assign rst_ = RST;
assign wrn_ = WR_;
assign rdn_ = RD_;
assign csn_ = CS_;
assign addr = A;
assign inpA = PORTA;
assign inpB = PORTB;
assign inpC = PORTC;
assign iDAT = PDATA;

// port addressing
wire[REGCOUNT-1:0] selr;
decoder #(ADDRSIZE) rsel (addr,selr);

// alias for output signals (driver)
wire[DATASIZE-1:0] outA, outB, outC, outS, oDAT;

// assign output pins
assign PORTA = (dirA==1) ? {DATASIZE{1'bZ}} : outA;
assign PORTB = (dirB==1) ? {DATASIZE{1'bZ}} : outB;
assign PORTC = (dirC==1) ? {DATASIZE{1'bZ}} : outC;
assign PDATA = (wrn_==0) ? {DATASIZE{1'bZ}} : oDAT;

// configurations
wire[1:0] modU;
wire sCFG, modL, dirA, dirB, diCU, diCL;
assign sCFG = outS[7]; // assume 1! (BSR NOT SUPPORTED!)
assign modU = outS[6:5]; // assume 00!
assign dirA = outS[4];
assign diCU = outS[3];
assign modL = outS[2]; // assume 0!
assign dirB = outS[1];
assign diCL = outS[0];

// latch write enable
wire dowr, wr_A, wr_B, wr_C, wr_S;
assign dowr = ~wrn_ & ~csn_;
assign wr_A = dowr & selr[0];
assign wr_B = dowr & selr[1];
assign wr_C = dowr & selr[2];
assign wr_S = dowr & selr[3];

// the four horsemen... errr, latches
latch pio0 (1'b0,wr_A,iDAT,outA);
latch pio1 (1'b0,wr_B,iDAT,outB);
latch pio2 (1'b0,wr_C,iDAT,outC);
latch pio3 (1'b0,wr_S,iDAT,outS);

// port read enable
wire dord, rd_A, rd_B, rd_C, rd_S;
assign dord = ~rdn_ & ~csn_;
assign rd_A = dord & selr[0];
assign rd_B = dord & selr[1];
assign rd_C = dord & selr[2];
assign rd_S = dord & selr[3];

// drive DATA port
zbuffer buf0 (rd_A,inpA,oDAT);
zbuffer buf1 (rd_B,inpB,oDAT);
zbuffer buf2 (rd_C,inpC,oDAT);
zbuffer buf3 (rd_S,outS,oDAT);

endmodule
