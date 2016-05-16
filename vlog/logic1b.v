module logic1b (inA,inB,sel,outC);
input inA,inB;
input[2:0] sel; // x00=AND, x01=XOR, x10=OR, x11=PASS
output outC;

wire tmpA,tmpX,tmpO,tmpC,tmpD;

assign tmpA = inA & inB; // AND
assign tmpX = inA ^ inB; // XOR
assign tmpO = inA | inB; // OR

assign tmpC = sel[0] ? tmpX : tmpA;
assign tmpD = sel[0] ? inA : tmpO;

assign outC = sel[1] ? tmpD : tmpC;

endmodule