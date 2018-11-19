module io8255 ( RST, WR_, RD_, CS_, ADDR, DATA, PORTA, PORTB, PORTC );

parameter DATASIZE = 8;
parameter ADDRSIZE = 2;
parameter REGCOUNT = 2**ADDRSIZE;

// port definitions (i/o)
input RST, WR_, RD_, CS_;
input[ADDRSIZE-1:0] ADDR;
inout[DATASIZE-1:0] DATA, PORTA, PORTB, PORTC;

// output ports as wires
wire[DATASIZE-1:0] DATA, PORTA, PORTB, PORTC;

// alias for inout as input signals
wire[DATASIZE-1:0] inpD, inpA, inpB, inpC;
assign inpD = DATA;
assign inpA = PORTA;
assign inpB = PORTB;
assign inpC = PORTC;

// alias for output signals (driver)
wire[DATASIZE-1:0] outA, outB, outC, outS, outD;
assign PORTA = (dirA==1) ? {DATASIZE{1'bZ}} : outA;
assign PORTB = (dirB==1) ? {DATASIZE{1'bZ}} : outB;
assign PORTC[7:4] = (diCU==1) ? {4{1'bZ}} : outC[7:4];
assign PORTC[3:0] = (diCL==1) ? {4{1'bZ}} : outC[3:0];
assign DATA = (RD_==0&&CS_==0) ? outD : {DATASIZE{1'bZ}};

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

// port addressing
wire[REGCOUNT-1:0] selr;
decoder #(ADDRSIZE) rsel (ADDR,selr);

// latch write enable
wire dowr, wr_A, wr_B, wr_C, wr_S;
assign dowr = ~WR_ & ~CS_;
assign wr_A = dowr & selr[0];
assign wr_B = dowr & selr[1];
assign wr_C = dowr & selr[2];
assign wr_S = dowr & selr[3];

// the four horsemen... errr, latches
latch pio0 (RST,wr_A,inpD,outA);
latch pio1 (RST,wr_B,inpD,outB);
latch pio2 (RST,wr_C,inpD,outC);
latch pio3 (RST,wr_S,inpD,outS);

// port read enable
wire dord, rd_A, rd_B, rd_C, rd_S;
assign dord = ~RD_ & ~CS_;
assign rd_A = dord & selr[0];
assign rd_B = dord & selr[1];
assign rd_C = dord & selr[2];
assign rd_S = dord & selr[3];

// drive DATA port
zbuffer buf0 (rd_A,inpA,outD);
zbuffer buf1 (rd_B,inpB,outD);
zbuffer buf2 (rd_C,inpC,outD);
zbuffer buf3 (rd_S,outS,outD);

endmodule
