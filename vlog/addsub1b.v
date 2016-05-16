module addsub1b (inA,inB,inC,sel,outP,outC,outS);
input inA,inB,inC,sel; // sel=0(ADD):1(SUB)
output outP,outC,outS;

wire tmpP,tmpC,tmpR; // propagate, carry, borrow

assign tmpP = inA ^ inB;
assign outS = tmpP ^ inC;
assign tmpC = (inA & inB) | (tmpP & inC);
assign tmpR = (~inA & inB) | (~tmpP & inC);
assign outP = sel ? ~tmpP : tmpP;
assign outC = sel ? tmpR : tmpC);

endmodule