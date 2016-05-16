module alu8b (inA,inB,inC,selOp,outF,outR);
input[7:0] inA,inB;
input[2:0] selOp; // selOp[2]=0(ARITH):1(LOGIC)
input inC; // from CY
output[7:0] outF,outR;

wire[7:0] tmpA,tmpL;
wire[1:0] tmpC; // AC & CY output from ARITH unit

addsub8b arith (inA,inB,inC,selOp,tmpC,tmpA);
logic8b logic (inA,inB,selOp,tmpL);
selacc8b select (tmpA,tmpL,tmpC,selOp,outF,outR);

endmodule