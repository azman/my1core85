module alureg ( clk, iENC, iEND, iRRD, iRWR, iDAT );

parameter DATASIZE = 8;
parameter ADDRSIZE = 3;
parameter FLAG_S = 7;
parameter FLAG_Z = 6;
parameter FLAG_A = 4;
parameter FLAG_P = 2;
parameter FLAG_C = 0;
parameter REG_B = 3'b000;
parameter REG_C = 3'b001;
parameter REG_D = 3'b010;
parameter REG_E = 3'b011;
parameter REG_H = 3'b100;
parameter REG_L = 3'b101;
parameter REG_F = 3'b110;
parameter REG_A = 3'b111;

input clk, iENC, iEND, iRRD, iRWR;
input[DATASIZE-1:0] iDAT;

wire[DATASIZE-1:0] tDT1, tDT2, tDTW, tOP1, tOP2, tRES;
wire[DATASIZE-1:0] tIFL, tOFL, tCOD, tDAT;
wire[ADDRSIZE-1:0] tAD1, tAD2, tADW, tSRC, tDST;
wire[2:0] tALU;
wire cALU, cMOV;

// selector signals
assign tALU = tCOD[5:3];
assign tDST = tCOD[5:3];
assign tSRC = tCOD[2:0];

// conditions
assign cALU = tCOD[7] & ~tCOD[6];
assign cMOV = ~tCOD[7] & tCOD[6];

// first operand is ALWAYS accumulator
assign tAD1 = REG_A;
assign tOP1 = tDT1;
// second operand from instruction
assign tAD2 = tSRC;
assign tOP2 = tSRC==3'b110 ? tDAT : tDT2;
// always write to accumulator if alu op
assign tADW = cALU ? REG_A : tDST;
assign tDTW = cALU ? tRES : tOP2;

register inst_reg (clk,1'b0,iENC,iDAT,tCOD);
register temp_reg (clk,1'b0,iEND,iDAT,tDAT);
alu alu_block (tALU,tOP1,tOP2,tIFL,tRES,tOFL);
registerfile reg_block (clk,1'b0,iRWR,iRWR&cALU,iRRD,iRRD,
	tADW,tAD1,tAD2,tDTW,tIFL,tDT1,tDT2,tOFL);

// top 2-bits instruction decoding
// 00 - transfer + arithmetic // ta
// 01 - register move + halt // mv
// 10 - basic alu (ad,as,&,|,^,cmp) // al
// 11 - stack, i/o & control // sc

endmodule
