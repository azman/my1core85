module alureg (clk, rst_, ienb, bus_d, bus_q, chk_i, chk_a);

parameter DATASIZE = 8;
parameter PAIRSIZE = DATASIZE*2;
parameter ADDRSIZE = 16;
parameter REGSBITS = 3;
parameter REGPBITS = REGSBITS-1;
parameter REGCOUNT = 2**REGSBITS;
parameter REG_B = 3'b000;
parameter REG_C = 3'b001;
parameter REG_D = 3'b010;
parameter REG_E = 3'b011;
parameter REG_H = 3'b100;
parameter REG_L = 3'b101;
parameter REG_F = 3'b110;
parameter REG_A = 3'b111;
parameter REGP_BC = 3'b00;
parameter REGP_DE = 3'b01;
parameter REGP_HL = 3'b10;
parameter REGP_SP = 3'b11;
parameter REGPSIZE = REGCOUNT/2;
parameter FLAGMASK = 8'b11010101;
parameter FLAGBITS = 7;
parameter FLAGBITZ = 6;
parameter FLAGBITA = 4;
parameter FLAGBITP = 2;
parameter FLAGBITC = 0;
// enb signals from control unit?
parameter IENB_OFF = 3; // bus enable signals
parameter IENB_RRD = 0;
parameter IENB_RWR = 1;
parameter IENB_COD = 2;
parameter IENB_DAT = 3;
parameter IENB_PC_ = 4;
parameter IENB_PD_ = 5; // data rw cycle - do not use pc!
parameter IENBSIZE = 6;
// instruction flags
parameter INST_GO6 = 0;
parameter INST_DAD = 1;
parameter INST_HLT = 2;
parameter INST_DIO = 3;
parameter INFO_CYC = 4; // 4-bits machine cycle info (post fetch)
parameter INST_CYL = 4;
parameter INST_CYH = 7;
parameter INST_RWL = 8;
parameter INST_RWH = 11;
parameter INST_CDL = 12; // code/data select
parameter INST_CDH = 15;
// 12-bit machine cycle info (4-15)
parameter INST_CCC = 16; // condition flag
parameter INSTSIZE = 17;

input clk, rst_;
input[IENBSIZE-1:0] ienb;
input[DATASIZE-1:0] bus_d;
output[DATASIZE-1:0] bus_q;
output[INSTSIZE-1:0] chk_i;
output[ADDRSIZE-1:0] chk_a;
wire[DATASIZE-1:0] bus_q;
wire[INSTSIZE-1:0] chk_i;
wire[ADDRSIZE-1:0] chk_a;

// internal wiring
wire enb_r, enb_w, enb_c, enb_d, enbpc, use_d;
// for instruction decoding
wire i_txa, i_mov, i_alu, i_sic;
wire i_hlt, i_aid, i_ali;
wire tmp04, tmp05, tmp06;
wire lo000, lo001, lo010, lo011, lo101, lo110, lo111;
wire lo10x, lox00, lox01, lox11;
wire hi000, hi001, hi010, hi011, hi100, hi110;
wire hi00x, hi01x, hi10x, hi11x, hi1x1;
wire mem_d, mem_s, chk_p;
// machine cycles required by current inst? - need always block for this
wire cyc_1, cyc_2, cyc_3, cyc_4, cyc_5;
wire cycw2, cycw3, cycw4, cycw5;
wire cycd2, cycd3, cycd4, cycd5;
reg[INFO_CYC-1:0] cycgo, cycrw, cyccd;
reg flags;

// reg block signals
wire[DATASIZE-1:0] wdata, rdata, mdata;
wire[REGSBITS-1:0] waddr, raddr;
wire wr_rr, rd_rr, wr_fl, wr_rp, rd_rp;
wire[REGPBITS-1:0] rpadd; // register pair address
wire[ADDRSIZE-1:0] pcinc, pcout , pdout;
wire[DATASIZE-1:0] pcflg;
// 'internals'
wire[DATASIZE-1:0] ddata[REGCOUNT-1:0],qdata[REGCOUNT-1:0];
wire[REGCOUNT-1:0] enbwr, enbrd, bufwr, bufrd;
wire[REGPSIZE-1:0] enbrp, bufrp;
// write to reg always in bytes! not byte-pairs!
wire[PAIRSIZE-1:0] prdat[REGPSIZE-1:0]; //, pwdat[REGPSIZE-1:0];
wire[DATASIZE-1:0] rinst, rtemp;

// alu block signals
wire[DATASIZE-1:0] op1_d, op2_d, res_d, rflag, wflag;
wire[REGSBITS-1:0] selop;

// assign internal signals - avoid having to replace previous code!
assign enb_r = ienb[IENB_RRD];
assign enb_w = ienb[IENB_RWR];
assign enb_c = ienb[IENB_COD];
assign enb_d = ienb[IENB_DAT];
assign enbpc = ienb[IENB_PC_];
assign use_d = ienb[IENB_PD_];

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
assign hi000 = ~rinst[5] & ~rinst[4] & ~rinst[3];
assign hi001 = ~rinst[5] & ~rinst[4] & rinst[3];
assign hi010 = ~rinst[5] & rinst[4] & ~rinst[3];
assign hi011 = ~rinst[5] & rinst[4] & rinst[3];
assign hi100 = rinst[5] & ~rinst[4] & ~rinst[3];
assign hi110 = rinst[5] & rinst[4] & ~rinst[3];
assign hi00x = ~rinst[5] & ~rinst[4];
assign hi01x = ~rinst[5] & rinst[4]; // 01x - io inst sig 2
assign hi10x = rinst[5] & ~rinst[4];
assign hi11x = rinst[5] & rinst[4];
assign hi0x0 = ~rinst[5] & ~rinst[3];
assign hi0x1 = ~rinst[5] & rinst[3];
assign hi1x1 = rinst[5] & rinst[3];
// low 3-bits
assign lo000 = ~rinst[2] & ~rinst[1] & ~rinst[0];
assign lo001 = ~rinst[2] & ~rinst[1] & rinst[0];
assign lo010 = ~rinst[2] & rinst[1] & ~rinst[0];
assign lo011 = ~rinst[2] & rinst[1] & rinst[0]; // 011 - io inst sig 1
assign lo101 = rinst[2] & ~rinst[1] & rinst[0];
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
assign i_aid = i_txa & lo10x; // increment/decrement
assign i_ali = i_sic & mem_s; // alu immediate
assign chk_p =
	(i_txa & lo011) | // inx, dcx (8)
	(i_txa & lo001) | // dad, lxi (8)
	(i_txa & lo010 & hi10x); // shld, lhld (2)

// assign output - decoded instruction info
assign chk_i[INST_DAD] = i_txa & lo001 & rinst[3];
assign chk_i[INST_HLT] = i_hlt;
assign chk_i[INST_DIO] = i_sic & lo011 & hi01x;
assign chk_i[INST_GO6] =
	(i_txa & lo011) | // 00xxx011 - INX (4) @ DCX (4)
	(i_sic & lo111) | // 11xxx111 - RST n (8)
	//(i_sic & lo000) | // 11xxx000 - Rccc (8)
	//(i_sic & lo100) | // 11xxx100 - Cccc (8)
	(i_sic & lox00) |
	(i_sic & tmp04 & lox01) | // 11xx0101 - push (4)
	(i_sic & rinst[5] & tmp05 & lox01) | // 111x1001 - pchl, sphl (2)
	(i_sic & hi00x & tmp06 & lox01); // 11001101 - call (1)
assign chk_i[INST_RWH:INST_RWL] = cycrw;
assign chk_i[INST_CYH:INST_CYL] = cycgo;
assign chk_i[INST_CDH:INST_CDL] = cyccd;
assign chk_i[INST_CCC] = flags;
// assign extra cycles if needed - cyc_1 NOT needed?!
assign cyc_1 = // 148 instructions (5 unused)
	(i_txa & ~hi110 & lo10x) | // inc & dcr (14)
	(i_txa & lo000) | // nop, unused{5}, sim, rim (8)
	(i_txa & lo011) | // inx, dcx (8)
	(i_txa & lo111) | // rlc,rrc,ral,rar,daa,cma,stc,cmc (8)
	(i_sic & lo001 & hi1x1) | // pchl, sphl (2)
	(i_sic & lo011 & rinst[5] & (rinst[4]|rinst[3])) | // xchg,di,ei (3)
	(i_mov & ~mem_d & ~mem_s) | // all mov with no m (49)
	(i_alu & ~mem_s); // all alu with no m (56)
assign cyc_2 = // 42 instructions
	(i_txa & lo110 & ~hi110) | // mvi with no m (7)
	(i_txa & lo010 & ~rinst[2]) | // ldax,stax (4)
	(i_sic & lo110 ) | // alu immediate (8)
	(i_mov & (mem_d ^ mem_s)) | // all mov with m except hlt (14)
	(i_alu & mem_s) | // all alu with m (8)
	i_hlt ; // (1)
assign cycw2 =
	// cyc_3
	(i_sic & lo111) | // rst (8)
	(i_sic & lo101 & ~rinst[3]) | // push (4)
	// cyc_2 - sub:9-instructions
	(i_txa & lo010 & hi0x0) | // stax (2)
	(i_mov & mem_d & ~mem_s); // all mov with dst=m &src!=m (7)
assign cycd2 =
	(i_mov & (mem_d ^ mem_s)) | // all mov with m except hlt (14)
	(i_alu & mem_s); // all alu with m (8)
assign cyc_3 = // 47 instructions
	// conditionals
	(i_sic & lo000 ) | // rccc (8) - or one
	(i_sic & lo010 ) | // jccc (8) - or two
	// always
	(i_sic & lo111) | // rst (8)
	(i_sic & lo101 & ~rinst[3]) | // push (4)
	(i_sic & lo001 & ~rinst[3]) | // pop (4)
	(i_sic & lo011 & hi000 ) | // jmp (1)
	(i_sic & lo001 & hi001 ) | // ret (1)
	(i_txa & lo001) | // dad, lxi (8)
	(i_txa & hi110 & rinst[2] & ~(rinst[1]&rinst[0])) | // inr,dcr,mvi m (3)
	(i_sic & lo011 & hi01x); // i/o instruction (2)
assign cycw3 = // sub:16-instructions
	(i_txa & hi110 & rinst[2] & ~(rinst[1]&rinst[0])) | // inr,dcr,mvi m (3)
	(i_sic & lo111) | // rst (8)
	(i_sic & lo101 & ~rinst[3]) | // push (4)
	(i_sic & lo011 & hi010); // out instruction (1)
assign cycd3 =
	(i_txa & hi110 & rinst[2] & ~(rinst[1]&rinst[0])); // inr,dcr,mvi m (3)
assign cyc_4 = // 2 instructions
	(i_txa & lo010 & hi11x); // sta,lda (2)
assign cycw4 =
	// cyc_5
	(i_sic & lo010) | // cccc (8)
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo101 & hi001) | // call (1)
	(i_txa & lo010 & hi100) | // shld (1)
	// cyc_4 - sub:1-instruction
	(i_txa & lo010 & hi110); // sta (1)
assign cycd4 = 1'b0;
assign cyc_5 = // 12 instructions
	// conditionals
	(i_sic & lo010) | // cccc (8)
	// always
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo101 & hi001) | // call (1)
	(i_txa & lo010 & hi10x); // shld, lhld (2)
assign cycw5 =
	(i_sic & lo010) | // cccc (8)
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo101 & hi001) | // call (1)
	(i_txa & lo010 & hi100); // shld (1)
assign cycd5 = 1'b0;
// combinational logic in always block
always @(rinst) begin
	// mark extra machine cycles
	if (cyc_2) cycgo = 4'b0001;
	else if (cyc_3) cycgo = 4'b0011;
	else if (cyc_4) cycgo = 4'b0111;
	else if (cyc_5) cycgo = 4'b1111;
	else cycgo = 4'b0000;
	cycrw = 4'b0000;
	if (cycw2) cycrw[0] = 1'b1; // write cycle
	if (cycw3) cycrw[1] = 1'b1; // write cycle
	if (cycw4) cycrw[2] = 1'b1; // write cycle
	if (cycw5) cycrw[3] = 1'b1; // write cycle
	cyccd = 4'b0000;
	if (cycd2) cyccd[0] = 1'b1; // use data memory pointer
	if (cycd3) cyccd[1] = 1'b1;
	if (cycd4) cyccd[2] = 1'b1;
	if (cycd5) cyccd[3] = 1'b1;
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
assign chk_a = use_d ? pdout : pcout; // drive address bus
assign bus_q = mem_s ? rtemp : rdata; // get from temp instead of flag?
assign pdout = prdat[REGP_HL];

// reg block connections
assign mdata = mem_s ? bus_d : rdata; // if mem src, get from bus
assign wdata = i_alu|i_ali ? res_d : mdata; // if not alu op, must be mov?
assign waddr = i_alu|i_ali ? REG_A : rinst[5:3]; // alu op writes to acc
assign raddr = rinst[2:0];
assign rpadd = rinst[5:4];
//assign enbwr = bufwr & {REGCOUNT{wr_rr}}; // generate these!
assign enbrd = bufrd & {REGCOUNT{rd_rr}};
assign enbrp = bufrp & {REGPSIZE{wr_rp}};
assign wr_rr = enb_w & ~chk_p;
assign rd_rr = enb_r & ~chk_p;
assign wr_fl = enb_w & i_alu; // only alu op writes to flag! & pop psw?
assign wr_rp = enb_w & chk_p;
assign rd_rp = enb_r & chk_p;
assign prdat[REGP_BC] = {qdata[0],qdata[1]};
assign prdat[REGP_DE] = {qdata[2],qdata[3]};
assign prdat[REGP_HL] = {qdata[4],qdata[5]};
assign prdat[REGP_SP] = {qdata[6],qdata[7]}; // only for push psw???

// reg block components
genvar index;
generate
for (index=0;index<REGCOUNT;index=index+1) begin : reg_block
	if (index==REG_F) begin
		assign enbwr[index] = wr_fl;
		assign ddata[index] = wflag & FLAGMASK; // make sure unused is 0!
	end else begin
		assign enbwr[index] = bufwr[index] & wr_rr; // |enbrp[index]
		assign ddata[index] = wdata;
	end
	register regs (clk,1'b0,enbwr[index],ddata[index],qdata[index]);
	zbuffer buff (enbrd[index],qdata[index],rdata);
end
endgenerate
register inst_reg (clk,rst_,enb_c,bus_d,rinst); // reset to NOP?
register temp_reg (clk,1'b0,enb_d,bus_d,rtemp);
decoder wrdec (waddr,bufwr);
decoder rddec (raddr,bufrd);
decoder #(.SEL_SIZE(REGPBITS)) rpdec (rpadd,bufrp);
register #(.DATASIZE(PAIRSIZE)) r16pc (clk,rst_,enbpc,pcinc,pcout);
register #(.DATASIZE(PAIRSIZE)) r16sp (clk,1'b0,enbsp,spdwr,spdrd);
incdec #(.DATASIZE(PAIRSIZE)) incpc (1'b0,pcout,pcinc,pcflg);

// alu block connections
assign op1_d = qdata[REG_A];
assign op2_d = mdata;
assign selop = rinst[5:3];
assign rflag = qdata[REG_F];

// alu block components
alu alu_block (selop,op1_d,op2_d,rflag,res_d,wflag);

endmodule
