module alureg ( clk, enb_code, enb_data, enb_rreg, enb_wreg,
	bus_data, chk_inst );

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
parameter INST_GO6 = 0;
parameter INST_DAD = 1;
parameter INSTSIZE = 2;

input clk, enb_code, enb_data, enb_rreg, enb_wreg;
input[DATASIZE-1:0] bus_data;
output[INSTSIZE-1:0] chk_inst;
wire[INSTSIZE-1:0] chk_inst;

wire[DATASIZE-1:0] tDT1, tDT2, tDTW, tOP1, tOP2, tRES;
wire[DATASIZE-1:0] tIFL, tOFL, tCOD, tDAT;
wire[ADDRSIZE-1:0] tAD1, tAD2, tADW, tSRC, tDST;
wire[2:0] tALU;
wire cTXA, cMOV, cALU, cSIC; // top 2-bits instruction decoding
wire tmp1;

// output signals - decoded instruction info
assign tmp1 = tCOD[3] & ~tCOD[1] & tCOD[0];
assign chk_inst[INST_GO6] =
	(cTXA & ~tCOD[2] & tCOD[1] & tCOD[0]) | // 00xxx011 - INX (4) @ DCX (4)
	(cSIC & ~tCOD[2] & ~tCOD[1] & ~tCOD[0]) | // 11xxx000 - Rccc (8)
	(cSIC & tCOD[2] & ~tCOD[1] & ~tCOD[0]) | // 11xxx100 - Cccc (8)
	(cSIC & tCOD[2] & tCOD[1] & tCOD[0]) | // 11xxx111 - RST n (8)
	(cSIC & ~tCOD[3] & tCOD[2] & ~tCOD[1] & tCOD[0]) | // 11xx0101 - push (4)
	(cSIC & tCOD[5] & ~tCOD[2] & tmp1) | // 111x1001 - pchl, sphl (2)
	(cSIC & ~tCOD[5] & ~tCOD[4] & tCOD[2] & tmp1); // 11001101 - call (1)
assign chk_inst[INST_DAD] = cTXA & tCOD[3] & ~tCOD[2] & ~tCOD[1] & tCOD[0];

// selector signals
assign tALU = tCOD[5:3];
assign tDST = tCOD[5:3];
assign tSRC = tCOD[2:0];

// top 2-bits instruction decoding
assign cTXA = ~tCOD[7] & ~tCOD[6]; // 00 - transfer + arithmetic
assign cMOV = ~tCOD[7] & tCOD[6]; // 01 - register move + halt
assign cALU = tCOD[7] & ~tCOD[6]; // 10 - basic alu (ad,as,&,|,^,cmp)
assign cSIC = tCOD[7] & tCOD[6]; // 11 - stack, i/o & control

// first operand is ALWAYS accumulator
assign tAD1 = REG_A;
assign tOP1 = tDT1;
// second operand from instruction
assign tAD2 = tSRC;
assign tOP2 = tSRC==3'b110 ? tDAT : tDT2;
// always write to accumulator if alu op
assign tADW = cALU ? REG_A : tDST;
assign tDTW = cALU ? tRES : tOP2;

register inst_reg (clk,1'b0,enb_code,bus_data,tCOD);
register temp_reg (clk,1'b0,enb_data,bus_data,tDAT);
alu alu_block (tALU,tOP1,tOP2,tIFL,tRES,tOFL);
registerfile reg_block (clk,1'b0,enb_wreg,enb_wreg&cALU,enb_rreg,enb_rreg,
	tADW,tAD1,tAD2,tDTW,tIFL,tDT1,tDT2,tOFL);

endmodule
