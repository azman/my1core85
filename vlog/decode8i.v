module decode8i (inD,outM);
input[7:0] inDI; // 8-bit instruction decoder
output[2:0] outM; // machine cycle count

wire[3:0] tmp8i; // basic 4 instruction class
wire[1:0] tmp2d; // tri-6 val (i5,i4,i3) = (i2,i1,i0) = 110

assign tmp8i[0] = ~inDI[7] & ~inDI[6]; // transfer + arithmetic // ta
assign tmp8i[1] = ~inDI[7] & inDI[6]; // register move + halt // mv
assign tmp8i[2] = inDI[7] & ~inDI[6]; // basic alu (ad,as,&,|,^,cmp) // al
assign tmp8i[3] = inDI[7] & inDI[6]; // stack, i/o & control // sc

assign tmp2d[0] = inDI[2] & inDI[1] & ~inDI[0]; // ld
assign tmp2d[1] = inDI[5] & inDI[4] & ~inDI[3]; // hd



endmodule