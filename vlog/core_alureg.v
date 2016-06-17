module alureg (clk, enb_code, enb_data, enb_rreg, enb_wreg, bus_d, chk_inst);

parameter DATASIZE = 8;
//parameter PAIRSIZE = DATASIZE*2;
parameter ADDRSIZE = 16;
parameter REGSBITS = 3;
parameter REGCOUNT = 2**REGSBITS;
parameter REG_B = 3'b000;
parameter REG_C = 3'b001;
parameter REG_D = 3'b010;
parameter REG_E = 3'b011;
parameter REG_H = 3'b100;
parameter REG_L = 3'b101;
parameter REG_F = 3'b110;
parameter REG_A = 3'b111;
//parameter REGP_BC = 3'b00;
//parameter REGP_DE = 3'b01;
//parameter REGP_HL = 3'b10;
//parameter REGP_SP = 3'b11;
//parameter REGPSIZE = REGCOUNT/2;
parameter FLAGMASK = 8'b11010101;
parameter FLAGBITS = 7;
parameter FLAGBITZ = 6;
parameter FLAGBITA = 4;
parameter FLAGBITP = 2;
parameter FLAGBITC = 0;
parameter INST_GO6 = 0;
parameter INST_DAD = 1;
parameter INST_HLT = 2;
parameter INST_DIO = 3;
parameter INFO_CYC = 4; // 4-bits cycle info
parameter INST_CYL = 4;
parameter INST_CYH = 7;
parameter INST_RWL = 8;
parameter INST_RWH = 11;
// 8-bit machine cycle info (4-11)
parameter INST_CCC = 12; // condition flag
parameter INSTSIZE = 13;

input clk, enb_code, enb_data, enb_rreg, enb_wreg;
input[DATASIZE-1:0] bus_d;
output[INSTSIZE-1:0] chk_inst;
wire[INSTSIZE-1:0] chk_inst;

// for instruction decoding
wire i_txa, i_mov, i_alu, i_sic;
wire i_hlt;
wire tmp04, tmp05, tmp06;
wire lo000, lo001, lo010, lo011, lo110, lo111;
wire lo10x, lox00, lox01, lox11;
wire hi110, hi00x, hi01x, hi1x1;
wire mem_d, mem_s;
// machine cycles required by current inst? - need always block for this
wire cyc_1,cyc_2,cycw2;
reg[INFO_CYC-1:0] cycgo, cycrw;
reg flags;

// reg block signals
wire[DATASIZE-1:0] wdata, rdata, mdata;
wire[REGSBITS-1:0] waddr, raddr;
wire wr_rr, rd_rr, wr_fl;
// 'internals'
wire[DATASIZE-1:0] ddata[REGCOUNT-1:0],qdata[REGCOUNT-1:0];
wire[REGCOUNT-1:0] enbwr, enbrd, bufwr, bufrd;
//wire[PAIRSIZE-1:0] prdat[REGPSIZE-1:0], pwdat[REGPSIZE-1:0];
wire[DATASIZE-1:0] rinst, rtemp;

// alu block signals
wire[DATASIZE-1:0] op1_d, op2_d, res_d, rflag, wflag;
wire[REGSBITS-1:0] selop;

// top 2-bits instruction decoding
assign i_txa = ~rinst[7] & ~rinst[6]; // 00 - transfer + arithmetic
assign i_mov = ~rinst[7] & rinst[6]; // 01 - register move + halt
assign i_alu = rinst[7] & ~rinst[6]; // 10 - basic alu (ad,as,&,|,^,cmp)
assign i_sic = rinst[7] & rinst[6]; // 11 - stack, i/o & control
// 'helper' signals :p
assign tmp04 = ~rinst[3] & rinst[2];
assign tmp05 = rinst[3] & ~rinst[2];
assign tmp06 = rinst[3] & rinst[2];
// mid 3-bits
assign hi110 = rinst[5] & rinst[4] & ~rinst[3];
assign hi00x = ~rinst[5] & ~rinst[4];
assign hi01x = ~rinst[5] & rinst[4]; // 01x - io inst sig 2
assign hi0x0 = ~rinst[5] & ~rinst[3];
assign hi0x1 = ~rinst[5] & rinst[3];
assign hi1x1 = rinst[5] & rinst[3];
// low 3-bits
assign lo000 = ~rinst[2] & ~rinst[1] & ~rinst[0];
assign lo001 = ~rinst[2] & ~rinst[1] & rinst[0];
assign lo010 = ~rinst[2] & rinst[1] & ~rinst[0];
assign lo011 = ~rinst[2] & rinst[1] & rinst[0]; // 011 - io inst sig 1
assign lo110 = rinst[2] & rinst[1] & ~rinst[0];
assign lo111 = rinst[2] & rinst[1] & rinst[0];
assign lo10x = rinst[2] & ~rinst[1];
assign lox00 = ~rinst[1] & ~rinst[0];
assign lox01 = ~rinst[1] & rinst[0];
assign lox11 = rinst[1] & rinst[0];
// alias?
assign mem_d = hi110; // 110 - mov dst = mem
assign mem_s = lo110; // 110 - mov src = mem
assign i_hlt = i_mov & mem_d & mem_s;

// assign output - decoded instruction info
assign chk_inst[INST_DAD] = i_txa & lo001 & rinst[3];
assign chk_inst[INST_HLT] = i_hlt;
assign chk_inst[INST_DIO] = i_sic & lo011 & hi01x;
assign chk_inst[INST_GO6] =
	//(i_txa & ~rinst[2] & lox11) | // 00xxx011 - INX (4) @ DCX (4)
	//(i_sic & rinst[2] & lox11) | // 11xxx111 - RST n (8)
	//(i_sic & ~rinst[2] & lox00) | // 11xxx000 - Rccc (8)
	//(i_sic & rinst[2] & lox00) | // 11xxx100 - Cccc (8)
	((i_sic|i_txa) & lox11) | (i_sic & lox00) |
	(i_sic & tmp04 & lox01) | // 11xx0101 - push (4)
	(i_sic & rinst[5] & tmp05 & lox01) | // 111x1001 - pchl, sphl (2)
	(i_sic & hi00x & tmp06 & lox01); // 11001101 - call (1)
assign chk_inst[INST_RWH:INST_RWL] = cycrw;
assign chk_inst[INST_CYH:INST_CYL] = cycgo;
assign chk_inst[INST_CCC] = flags;
// assign extra cycles if needed
assign cyc_1 = // 148 instructions (5 unused)
	(i_txa & ~hi110 & lo10x) | // inc & dcr (14)
	(i_txa & lo000) | // nop, unused{5}, sim, rim (8)
	(i_txa & lo011) | // inx, dcx (8)
	(i_txa & lo111) | // rlc,rrc,ral,rar,daa,cma,stc,cmc (8)
	(i_sic & lo001 & hi1x1) | // pchl, sphl (2)
	(i_sic & lo011 & rinst[5] & (rinst[4]|rinst[3])) | // xchg,di,ei (3)
	(i_mov & ~mem_d & ~mem_s) | // all mov with no m (49)
	(i_alu & ~mem_s); // all alu with no m (56)
assign cyc_2 = // 41 instructions
	(i_txa & lo110 & ~hi110) | // mvi with no m (7)
	(i_txa & lo010 & hi0x1) | // ldax (2)
	(i_sic & lo110 ) | // alu immediate (8)
	(i_mov & ~mem_d & mem_s) | // all mov with src=m &dst!=m (7)
	(i_alu & mem_s) | // all alu with m (8)
	cycw2 ; // (9)
assign cycw2 = // sub:9-instructions
	(i_txa & lo010 & hi0x0) | // stax (2)
	(i_mov & mem_d & ~mem_s); // all mov with dst=m &src!=m (7)
// combinational logic in always block
always @(rinst) begin
	cycgo = 4'b0000;
	cycrw = 4'b0000;
	if (cyc_2) begin
		cycgo = 4'b0001;
	end
	if (cycw2) cycrw[0] = 1'b1; // write cycle
	if (i_hlt) cycgo = 4'b0001;
	// status for conditional instruction
	case (rinst[5:3])
		3'b000: flags = ~qdata[REG_F][FLAGBITZ]; // NZ
		3'b001: flags = qdata[REG_F][FLAGBITZ]; // Z
		3'b010: flags = ~qdata[REG_F][FLAGBITC]; // NC
		3'b011: flags = qdata[REG_F][FLAGBITC]; // C
		3'b100: flags = ~qdata[REG_F][FLAGBITP]; // PO
		3'b101: flags = qdata[REG_F][FLAGBITP]; // PE
		3'b110: flags = ~qdata[REG_F][FLAGBITS]; // P
		3'b111: flags = qdata[REG_F][FLAGBITS]; // M
	endcase
end

// reg block connections
assign mdata = mem_s ? rtemp : rdata; // if mem src, get from temp reg!
assign wdata = i_alu ? res_d : mdata; // if not alu op, must be mov?
assign waddr = i_alu ? REG_A : rinst[5:3]; // always write to acc if alu op
assign raddr = rinst[2:0];
//assign enbwr = bufwr & {REGCOUNT{wr_rr}}; // generate these!
assign enbrd = bufrd & {REGCOUNT{rd_rr}};
assign wr_rr = enb_wreg;
assign rd_rr = enb_rreg;
assign wr_fl = enb_wreg & i_alu; // only alu op writes to flag!
//assign prdat[REGP_BC] = {qdata[0],qdata[1]};
//assign prdat[REGP_DE] = {qdata[2],qdata[3]};
//assign prdat[REGP_HL] = {qdata[4],qdata[5]};
//assign prdat[REGP_SP] = {qdata[6],qdata[7]};

// reg block components
genvar index;
generate
for (index=0;index<REGCOUNT;index=index+1) begin : reg_block
	if (index==REG_F) begin
		assign enbwr[index] = wr_fl;
		assign ddata[index] = wflag & FLAGMASK; // make sure unused is 0!
	end else begin
		assign enbwr[index] = bufwr[index] & wr_rr;
		assign ddata[index] = wdata;
	end
	register regs (clk,1'b0,enbwr[index],ddata[index],qdata[index]);
	zbuffer buff (enbrd[index],qdata[index],rdata);
end
endgenerate
register inst_reg (clk,1'b0,enb_code,bus_d,rinst);
register temp_reg (clk,1'b0,enb_data,bus_d,rtemp);
decoder wrdec (waddr,bufwr);
decoder rddec (raddr,bufrd);
//register #(.DATASIZE(PAIRSIZE)) r16pc (clk,1'b0,enb,data_in,data_out);

// alu block connections
assign op1_d = qdata[REG_A];
assign op2_d = mdata;
assign selop = rinst[5:3];
assign rflag = qdata[REG_F];

// alu block components
alu alu_block (selop,op1_d,op2_d,rflag,res_d,wflag);

endmodule
