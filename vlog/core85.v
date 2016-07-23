module test85 ( CLK, RST_, READY, HOLD, SID, INTR, TRAP, RST75, RST65, RST55,
	ADDRDATA, ADDR, CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_,
	ALE, HLDA, SOD ); //VCC, VSS // power lines //X1, X2, // cystal input

// state name designations
parameter STATECNT = 10;
parameter STATE_TR = 10'b0000000001; // reset state
parameter STATE_T1 = 10'b0000000010; // state 1
parameter STATE_T2 = 10'b0000000100; // state 2
parameter STATE_T3 = 10'b0000001000; // state 3
parameter STATE_T4 = 10'b0000010000; // state 4
parameter STATE_T5 = 10'b0000100000; // state 5
parameter STATE_T6 = 10'b0001000000; // state 6
parameter STATE_TH = 10'b0010000000; // hold state
parameter STATE_TW = 10'b0100000000; // wait state
parameter STATE_TT = 10'b1000000000; // halt state
// machine cycle control & status
// {ctrl:{inta_,wr_,rd_},stat:{io/m_,s1,s0}}
parameter CYCLE_OF = 6'b110011; // opcode fetch
parameter CYCLE_MW = 6'b101001; // memory write
parameter CYCLE_MR = 6'b110010; // memory read
parameter CYCLE_DW = 6'b101101; // device write
parameter CYCLE_DR = 6'b110110; // device read
parameter CYCLE_INA = 6'b011111; // interrupt acknowledge
parameter CYCLE_BID = 6'b111010; // bus idle - DAD (2 cycles?)
parameter CYCLE_BIT = 6'b111111; // ack reset/trap
parameter CYCLE_BIH = 6'b111100; // halt ; actually 6'b1zzz00
parameter CYCLE_ERR = 6'b000000; // internal error??
// control/status line indices
parameter STAT_S0 = 0;
parameter STAT_S1 = 1;
parameter STAT_IOM_ = 2;
parameter CTRL_RD_ = 3;
parameter CTRL_WR_ = 4;
parameter CTRL_INTA_ = 5;
parameter STACTLSZ = 6;
// cycle info
parameter INFO_CYC = 4;
// flag stuff
parameter FLAGMASK = 8'b11010101;
parameter FLAGBITS = 7;
parameter FLAGBITZ = 6;
parameter FLAGBITA = 4;
parameter FLAGBITP = 2;
parameter FLAGBITC = 0;
parameter FLAGMSKC = 8'b00000001;
// interrupt enable bit!
parameter INTE_BIT = 8'b00100000;

// port definitions (i/o)
input CLK, RST_, READY, HOLD, SID, INTR, TRAP, RST75, RST65, RST55;
inout[7:0] ADDRDATA;
output[15:8] ADDR;
output CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_, ALE, HLDA, SOD;

// output ports as wires
wire[7:0] ADDRDATA;
wire[15:8] ADDR;
wire CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_, ALE, HLDA, SOD;

// alias for input signals
wire clk, clk_, rst;
assign clk = CLK;
assign clk_ = ~CLK;
assign rst = ~RST_;

// alias for output signals (driver)
wire stat_iom_, stat_s1, stat_s0;
wire ctrl_inta_, ctrl_wr_, ctrl_rd_, ctrl_ale;
// assign output pins
assign CLK_OUT = clk; // simply pass
assign RST_OUT = rst; // simply pass
assign IOM_ = stat_iom_;
assign S1 = stat_s1;
assign S0 = stat_s0;
assign INTA_ = ctrl_inta_;
assign WR_ = ctrl_wr_;
assign RD_ = ctrl_rd_;
assign ALE = ctrl_ale;
// not implementing these for now
assign HLDA = 1'b0;
assign SOD = 1'b0;

// alias/control signals for data/address busses
wire chk_adh, chk_adl, chk_dat;
wire chk_ext, chk_mov;
wire[15:0] busa_q;
wire[7:0] busd_d, busd_q; // incoming & outgoing data bus signal
// data/addr bus
zbuffer bus_addh (chk_adh,busa_q[15:8],ADDR);
zbuffer bus_addl (chk_adl,busa_q[7:0],ADDRDATA);
zbuffer bus_odat (chk_dat,busd_q,ADDRDATA);
zbuffer bus_idat (chk_ext,ADDRDATA,busd_d);
zbuffer bus_mdat (chk_mov,busd_q,busd_d);

//------------------------------------------------------------------------------
// REGISTER BLOCK
//------------------------------------------------------------------------------

// main registers
wire[7:0] rgd[7:0], rgq[7:0];
wire[7:0] rgw, rgr;
genvar i;
generate
	for(i=0;i<8;i=i+1) begin
		register regs (clk,1'b0,rgw[i],rgd[i],rgq[i]);
		zbuffer bufr (rgr[i],rgq[i],busd_q);
	end
endgenerate

// program counter
wire[15:0] pcpc_d, pcpc_q;
wire pcpc_w;
register #(16) pc16 (clk,rst,pcpc_w,pcpc_d,pcpc_q);

// stack pointer - high byte
wire[7:0] sprh_d, sprh_q;
wire sprh_w, sprh_r;
register sprh (clk,1'b0,sprh_w,sprh_d,sprh_q);
zbuffer spbh (sprh_r,sprh_q,busd_q);

// stack pointer - low byte
wire[7:0] sprl_d, sprl_q;
wire sprl_w, sprl_r;
register sprl (clk,1'b0,sprl_w,sprl_d,sprl_q);
zbuffer spbl (sprl_r,sprl_q,busd_q);

// temp pointer - high byte
wire[7:0] tprh_d, tprh_q;
wire tprh_w;
register tprh (clk,1'b0,tprh_w,tprh_d,tprh_q);

// temp pointer - low byte
wire[7:0] tprl_d, tprl_q;
wire tprl_w;
register tprl (clk,1'b0,tprl_w,tprl_d,tprl_q);

// temp register
wire[7:0] temp_d, temp_q;
wire temp_w, temp_r;
register tmpr (clk,1'b0,temp_w,temp_d,temp_q);
zbuffer tmpb (temp_r,temp_q,busd_q);

// instruction register
wire[7:0] ireg_d, ireg_q;
wire ireg_w;
register ireg (clk,1'b0,ireg_w,ireg_d,ireg_q);

// serial/interrupt register
wire[7:0] intr_d, intr_q;
wire intr_w, intr_r, inte_q, inte_d;
register intr (clk,rst,intr_w,intr_d,intr_q);
zbuffer intb (intr_r,intr_q,busd_q);

// alias data pointer
wire[15:0] rpbc_q, rpde_q, rphl_q, sptr_q, tptr_q, dptr_q;
assign rpbc_q = {rgq[0],rgq[1]};
assign rpde_q = {rgq[2],rgq[3]};
assign rphl_q = {rgq[4],rgq[5]};
assign sptr_q = {sprh_q,sprl_q}; // stack pointer
assign tptr_q = {tprh_q,tprl_q}; // temp pointer
assign dptr_q = {temp_q,temp_q}; // device pointer

//------------------------------------------------------------------------------
// ARITHMETIC/LOGIC UNIT BLOCK
//------------------------------------------------------------------------------

// alu block
wire[7:0] opr1_d, opr2_d, res8_q;
wire[7:0] alu_if, alu_of;
wire[2:0] alu_op;
alu aluc (alu_op,opr1_d,opr2_d,alu_if,res8_q,alu_of);
assign alu_if = rgq[6];

// increment/decrement block
wire[7:0] idrg_d, idrg_q, idr_of;
wire idr_op, idrg_r;
incdec iduc (idr_op,idrg_d,idrg_q,idr_of);
zbuffer idub (idrg_r,idrg_q,busd_q);

// increment/decrement block - 16-bit
wire[15:0] idxp_d, idxp_q;
wire[7:0] idx_of;
wire idx_op;
incdec #(16) id16 (idx_op,idxp_d,idxp_q,idx_of);

// daa comparators
wire daal_b, daah_b;
assign daal_b = rgq[7][3]&(rgq[7][2]|rgq[7][1])|rgq[6][4];
assign daah_b = rgq[7][7]&(rgq[7][6]|rgq[7][5])|rgq[6][0];
wire[7:0] daad_d;
assign daad_d[3:0] = daal_b ? 4'b0110 : 4'b0000;
assign daad_d[7:4] = daah_b ? 4'b0110 : 4'b0000;

//------------------------------------------------------------------------------
// INSTRUCTION DECODING LOGIC BLOCK
//------------------------------------------------------------------------------

// top 2-bits instruction decoding
wire i_txa, i_mov, i_alu, i_sic;
assign i_txa = ~ireg_q[7] & ~ireg_q[6]; // 00 - transfer + arithmetic
assign i_mov = ~ireg_q[7] & ireg_q[6]; // 01 - register move + halt
assign i_alu = ireg_q[7] & ~ireg_q[6]; // 10 - basic alu (ad,as,&,|,^,cmp)
assign i_sic = ireg_q[7] & ireg_q[6]; // 11 - stack, i/o & control

// decode lower 3-bits
wire lo000, lo001, lo010, lo011, lo101, lo110, lo111;
wire lo10x, lox00, lox01, lox11;
assign lo000 = ~ireg_q[2] & ~ireg_q[1] & ~ireg_q[0];
assign lo001 = ~ireg_q[2] & ~ireg_q[1] & ireg_q[0];
assign lo010 = ~ireg_q[2] & ireg_q[1] & ~ireg_q[0];
assign lo011 = ~ireg_q[2] & ireg_q[1] & ireg_q[0];
assign lo100 = ireg_q[2] & ~ireg_q[1] & ~ireg_q[0];
assign lo101 = ireg_q[2] & ~ireg_q[1] & ireg_q[0];
assign lo110 = ireg_q[2] & ireg_q[1] & ~ireg_q[0];
assign lo111 = ireg_q[2] & ireg_q[1] & ireg_q[0];
assign lo10x = ireg_q[2] & ~ireg_q[1];
assign lox00 = ~ireg_q[1] & ~ireg_q[0];
assign lox01 = ~ireg_q[1] & ireg_q[0];
assign lox11 = ireg_q[1] & ireg_q[0];

// decode middle 3-bits
wire hi000, hi001, hi010, hi011, hi100, hi101, hi110, hi111;
wire hi00x, hi01x, hi10x, hi11x;
wire hi0x0, hi0x1, hi1x0, hi1x1;
assign hi000 = ~ireg_q[5] & ~ireg_q[4] & ~ireg_q[3];
assign hi001 = ~ireg_q[5] & ~ireg_q[4] & ireg_q[3];
assign hi010 = ~ireg_q[5] & ireg_q[4] & ~ireg_q[3];
assign hi011 = ~ireg_q[5] & ireg_q[4] & ireg_q[3];
assign hi100 = ireg_q[5] & ~ireg_q[4] & ~ireg_q[3];
assign hi101 = ireg_q[5] & ~ireg_q[4] & ireg_q[3];
assign hi110 = ireg_q[5] & ireg_q[4] & ~ireg_q[3];
assign hi111 = ireg_q[5] & ireg_q[4] & ireg_q[3];
assign hi00x = ~ireg_q[5] & ~ireg_q[4];
assign hi01x = ~ireg_q[5] & ireg_q[4];
assign hi10x = ireg_q[5] & ~ireg_q[4];
assign hi11x = ireg_q[5] & ireg_q[4];
assign hi0x0 = ~ireg_q[5] & ~ireg_q[3];
assign hi0x1 = ~ireg_q[5] & ireg_q[3];
assign hi1x0 = ireg_q[5] & ~ireg_q[3];
assign hi1x1 = ireg_q[5] & ireg_q[3];

// useful alias - memory dst/src indicator
wire mem_d, mem_s;
assign mem_d = hi110; // 110 - mov dst = mem
assign mem_s = lo110; // 110 - mov src = mem

// for specific instruction decoding
wire i_hlt, i_aid, i_ali, i_lxi;
wire i_dad, i_idx, i_mmx, i_mmt, i_mms;
wire i_rim, i_sim, i_dio, i_go6, i_mvi, i_sta, i_lda;
wire i_shl, i_lhl, i_rot, i_acc, i_daa, i_flc;
wire i_pop, i_psh, i_jmp, i_cll, i_ret;
wire i_jcc, i_ccc, i_rcc, i_zcc;
wire i_hpc, i_hsp, i_xch; // pchl & sphl & xchg
wire i_rst, i_edi, i_xhl; // xthl
wire i_jxx, i_cxx, i_rxx;
assign i_hlt = i_mov & mem_d & mem_s;
assign i_aid = i_txa & lo10x; // increment/decrement
assign i_ali = i_sic & lo110; // alu immediate
assign i_mvi = i_txa & lo110; // mov immediate
assign i_lxi = i_txa & lo001 & ~ireg_q[3];
assign i_dad = i_txa & lo001 & ireg_q[3];
assign i_idx = i_txa & lo011; // increment/decrement pair
assign i_mmx = i_txa & lo010 & ~ireg_q[5]; // ldax,stax (4)
assign i_mmt = i_txa & lo010 & ireg_q[5]; // sta,lda (2) shld, lhld (2)
assign i_rim = i_txa & hi100 & lo000;
assign i_sim = i_txa & hi110 & lo000;
assign i_dio = i_sic & lo011 & hi01x;
assign i_sta = i_txa & lo010 & ~ireg_q[3] & ~(ireg_q[5]&~ireg_q[4]); // sta(x)
assign i_lda = i_txa & lo010 & ireg_q[3] & ~(ireg_q[5]&~ireg_q[4]); // lda(x)
assign i_shl = i_txa & lo010 & hi100; // shld
assign i_lhl = i_txa & lo010 & hi101; // lhld
assign i_rot = i_txa & lo111 & ~ireg_q[5]; // all rotations (4)
assign i_acc = i_txa & lo111 & hi10x;
assign i_daa = i_txa & lo111 & hi100;
assign i_flc = i_txa & lo111 & hi11x;
assign i_pop = i_sic & lo001 & ~ireg_q[3];
assign i_psh = i_sic & lo101 & ~ireg_q[3];
assign i_mms = i_pop | i_psh | i_cxx | i_rxx | i_rst;
assign i_jmp = i_sic & lo011 & hi000;
assign i_cll = i_sic & lo101 & hi001; // call
assign i_ret = i_sic & lo001 & hi001; // ret
assign i_hpc = i_sic & lo001 & hi101;
assign i_hsp = i_sic & lo001 & hi111;
assign i_xch = i_sic & lo011 & hi101;
assign i_edi = i_sic & lo011 & hi11x;
assign i_xhl = i_sic & lo011 & hi100;
assign i_rst = i_sic & lo111;
assign i_jcc = i_sic & lo010;
assign i_ccc = i_sic & lo100;
assign i_rcc = i_sic & lo000;
assign i_zcc = (i_jcc|i_ccc|i_rcc);
assign i_jxx = i_jmp | i_jcc;
assign i_cxx = i_cll | i_ccc;
assign i_rxx = i_ret | i_rcc;
assign i_go6 =
	(i_txa & lo011) | // 00xxx011 - inx/dcx (8)
	(i_sic & lo111) | // 11xxx111 - rst n (8)
	(i_sic & lox00) | // Rccc, Cccc (16)
	(i_sic & ~ireg_q[3] & lo101) | // 11xx0101 - push (4)
	(i_sic & hi1x1 & lo001) | // 111x1001 - pchl, sphl (2)
	(i_sic & hi001 & lo101); // 11001101 - call (1)

// register pair ops?
wire chk_p;
assign chk_p =
	(i_txa & lo011) | // inx, dcx (8)
	(i_txa & lo001); // dad, lxi (8)
//	(i_txa & lo010 & hi10x); // shld, lhld (2)

// machine cycles required by current inst? - need always block for this
wire cyc_1, cyc_2, cyc_3, cyc_4, cyc_5;
wire cycw2, cycw3, cycw4, cycw5;
wire cycd2, cycd3, cycd4, cycd5;
// assign extra cycles if needed - cyc_1 NOT needed?!
assign cyc_1 = // 148 instructions (5 unused)
	(i_txa & ~hi110 & lo10x) | // inc & dcr (14)
	(i_txa & lo000) | // nop, unused{5}, sim, rim (8)
	(i_txa & lo011) | // inx, dcx (8)
	(i_txa & lo111) | // rlc,rrc,ral,rar,daa,cma,stc,cmc (8)
	(i_sic & lo001 & hi1x1) | // pchl, sphl (2)
	(i_sic & lo011 & ireg_q[5] & (ireg_q[4]|ireg_q[3])) | // xchg,di,ei (3)
	(i_mov & ~mem_d & ~mem_s) | // all mov with no m (49)
	(i_alu & ~mem_s); // all alu with no m (56)
assign cyc_2 = // 42 instructions
	(i_txa & lo110 & ~hi110) | // mvi with no m (7)
	(i_txa & lo010 & ~ireg_q[5]) | // ldax,stax (4)
	(i_sic & lo110) | // alu immediate (8)
	(i_mov & (mem_d | mem_s)) | // all mov with m incl. hlt (14+1)
	(i_alu & mem_s); // all alu with m (8)
assign cycw2 =
	// cyc_3
	(i_sic & lo111) | // rst (8)
	(i_sic & lo101 & ~ireg_q[3]) | // push (4)
	// cyc_2
	(i_txa & lo010 & hi0x0) | // stax (2)
	(i_mov & mem_d & ~mem_s); // all mov with dst=m &src!=m (7)
assign cycd2 =
	// cyc_5
	(i_sic & lo011 & hi100) | // xthl (1)
	// cyc_3
	(i_sic & lo000 ) | // rccc (8) - or one
	(i_sic & lo111) | // rst (8)
	(i_sic & lo001 & hi001 ) | // ret (1)
	(i_sic & lox01 & ~ireg_q[3]) | // pop, push (4)
	// cyc_2
	(i_txa & lo010 & ~ireg_q[5]) | // ldax,stax (4)
	(i_txa & hi110 & lo10x) | // inr,dcr m (2)
	(i_mov & (mem_d ^ mem_s)) | // all mov with m except hlt (14)
	(i_alu & mem_s); // all alu with m (8)
assign cyc_3 = // 47 instructions
	// conditionals
	(i_sic & lo000 ) | // rccc (8) - or one
	(i_sic & lo010 ) | // jccc (8) - or two
	// always
	(i_sic & lo111) | // rst (8)
	(i_sic & lox01 & ~ireg_q[3]) | // pop, push (4)
	(i_sic & lo011 & hi000 ) | // jmp (1)
	(i_sic & lo001 & hi001 ) | // ret (1)
	(i_txa & lo001) | // dad, lxi (8)
	(i_txa & hi110 & ireg_q[2] & ~(ireg_q[1]&ireg_q[0])) | // inr,dcr,mvi m (3)
	(i_sic & lo011 & hi01x); // i/o instruction (2)
assign cycw3 = // sub:16-instructions
	(i_txa & hi110 & ireg_q[2] & ~(ireg_q[1]&ireg_q[0])) | // inr,dcr,mvi m (3)
	(i_sic & lo111) | // rst (8)
	(i_sic & lo101 & ~ireg_q[3]) | // push (4)
	(i_sic & lo011 & hi010); // out instruction (1)
assign cycd3 =
	(i_sic & lo000 ) | // rccc (8) - or one
	(i_sic & lo111) | // rst (8)
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo001 & hi001 ) | // ret (1)
	(i_sic & lo011 & hi01x) | // i/o instruction (2)
	(i_sic & lox01 & ~ireg_q[3]) | // pop, push (4)
	(i_txa & hi110 & ireg_q[2] & ~(ireg_q[1]&ireg_q[0])); // inr,dcr,mvi m (3)
assign cyc_4 = // 2 instructions
	(i_txa & lo010 & hi11x); // sta,lda (2)
assign cycw4 =
	// cyc_5
	(i_sic & lo100) | // cccc (8)
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo101 & hi001) | // call (1)
	(i_txa & lo010 & hi100) | // shld (1)
	// cyc_4 - sub:1-instruction
	(i_txa & lo010 & hi110); // sta (1)
assign cycd4 =
	(i_sic & lo100) | // cccc (8)
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo101 & hi001) | // call (1)
	(i_txa & lo010 & hi11x) | // sta,lda (2)
	(i_txa & lo010 & hi10x); // shld, lhld (2)
assign cyc_5 = // 12 instructions
	// conditionals
	(i_sic & lo100) | // cccc (8)
	// always
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo101 & hi001) | // call (1)
	(i_txa & lo010 & hi10x); // shld, lhld (2)
assign cycw5 =
	(i_sic & lo100) | // cccc (8)
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo101 & hi001) | // call (1)
	(i_txa & lo010 & hi100); // shld (1)
assign cycd5 =
	(i_sic & lo100) | // cccc (8)
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo101 & hi001) | // call (1)
	(i_txa & lo010 & hi10x); // shld, lhld (2)

// decode cycles required (combinational logic in always block)
reg[INFO_CYC-1:0] cycgo, cycrw, cyccd;
reg flags; // flag status as selected by current instruction
always @(ireg_q) begin
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
	case (ireg_q[5:3])
		3'b000: flags = ~rgq[6][FLAGBITZ]; // NZ
		3'b001: flags = rgq[6][FLAGBITZ]; // Z
		3'b010: flags = ~rgq[6][FLAGBITC]; // NC
		3'b011: flags = rgq[6][FLAGBITC]; // C
		3'b100: flags = ~rgq[6][FLAGBITP]; // PO
		3'b101: flags = rgq[6][FLAGBITP]; // PE
		3'b110: flags = ~rgq[6][FLAGBITS]; // P
		3'b111: flags = rgq[6][FLAGBITS]; // M
	endcase
end

//------------------------------------------------------------------------------
// CONTROL BLOCK (STATE MACHINE)
//------------------------------------------------------------------------------

// state/control/status register
reg[STATECNT-1:0] cstate, nstate; // 1-hot encoded states
reg[STACTLSZ-1:0] stactl;
reg[INFO_CYC-1:0] do_more, dowrite, do_data;
reg isfirst, is_bimc, is_next, is_last, is_nxta, is_data;
reg is_nxtp, is_fin1, is_cond, do_skip;
// state register - transition on negative edge!
always @(posedge clk_ or posedge rst) begin
	if(rst == 1) begin // asynchronous reset
		cstate <= STATE_TR;
		// internal registers
		do_more <= {INFO_CYC{1'b0}};
		dowrite <= {INFO_CYC{1'b0}};
		do_data <= {INFO_CYC{1'b0}};
	end else begin
		cstate <= nstate;
		// entry action
		case (nstate)
			STATE_TR: begin
				do_more <= {INFO_CYC{1'b0}};
				dowrite <= {INFO_CYC{1'b0}};
				do_data <= {INFO_CYC{1'b0}};
				is_cond <= 1'b0;
			end
			STATE_T1: begin
				isfirst <= ~do_more[0];
				is_bimc <= (i_dad|i_hlt)&do_more[0];
				is_next <= do_more[1];
				is_last <= do_more[0] & ~do_more[1];
				is_nxta <= do_more[0] & do_more[1] & ~do_data[0] & ~do_data[1];
				is_data <= do_data[0];
				is_nxtp <= do_more[2];
				is_fin1 <= ~do_more[3];
				do_skip <= 1'b0;
				// update stactl on T1
				if (~do_more[0]) begin
					stactl <= CYCLE_OF;
				end else if (i_dad) begin
					stactl <= CYCLE_BID;
				end else if (i_hlt) begin
					stactl <= CYCLE_BIH;
				end else if (~dowrite[0]&(~i_dio|~do_data[0])) begin
					stactl <= CYCLE_MR;
				end else if (dowrite[0]&(~i_dio|~do_data[0])) begin
					stactl <= CYCLE_MW;
				end else if (~dowrite[0]&i_dio&do_data[0]) begin
					stactl <= CYCLE_DR;
				end else if (dowrite[0]&i_dio&do_data[0]) begin
					stactl <= CYCLE_DW;
				end else begin
					stactl <= CYCLE_ERR;
				end
			end
			STATE_T3: begin
				// update next machine cycle here
				if (is_cond&~flags) begin
					do_more <= {INFO_CYC{1'b0}};
					dowrite <= {INFO_CYC{1'b0}};
					do_data <= {INFO_CYC{1'b0}};
					is_cond <= 1'b0;
					do_skip <= 1'b1;
				end else begin
					do_more <= do_more >> 1;
					dowrite <= dowrite >> 1;
					do_data <= do_data >> 1;
				end
			end
			STATE_T4: begin
				// assign next machine cycle here
				do_more <= cycgo;
				dowrite <= cycrw;
				do_data <= cyccd;
				// check conditional instructions
				is_cond <= i_zcc;
			end
			STATE_T6: begin
				if (is_cond&~flags) begin // conditional returns need this!
					do_more <= {INFO_CYC{1'b0}};
					dowrite <= {INFO_CYC{1'b0}};
					do_data <= {INFO_CYC{1'b0}};
					is_cond <= 1'b0;
				end
			end
		endcase
	end
end

// next-state logic
always @(cstate or ireg_q or stactl or is_bimc or isfirst or HOLD or READY)
begin
	nstate = cstate;
	case (cstate)
		STATE_TR: begin
			nstate = STATE_T1;
		end
		STATE_T1: begin
			if (i_hlt) begin
				nstate = STATE_TT;
			end else begin
				nstate = STATE_T2;
			end
		end
		STATE_T2: begin
			if (READY|is_bimc) begin
				nstate = STATE_T3;
			end else begin
				nstate = STATE_TW;
			end
		end
		STATE_T3: begin
			if (isfirst) begin
				nstate = STATE_T4;
			end else begin
				nstate = STATE_T1;
			end
		end
		STATE_T4: begin
			if (i_go6) begin
				nstate = STATE_T5;
			end else begin
				nstate = STATE_T1;
			end
		end
		STATE_T5: begin
			nstate = STATE_T6;
		end
		STATE_T6: begin
			nstate = STATE_T1;
		end
		STATE_TW: begin
			if (READY|is_bimc) begin
				nstate = STATE_T3;
			end
		end
		STATE_TH: begin
			if (~HOLD) begin
				if (i_hlt) nstate = STATE_TT;
				else nstate = STATE_T1;
			end
		end
		STATE_TT: begin
			if (HOLD) begin
				nstate = STATE_TH;
			end
			// valid interrupt can get us out back to circulation?
		end
	endcase
end

// output logic - depends on state only
reg pin_ale, pin_ia_, pin_wr_, pin_rd_, pin_im_, pin_sta;
reg enb_adh, enb_adl, enb_dat, enb_ctl; // pin enable logic
always @(cstate) begin
	case (cstate)
		STATE_T1: begin
			if (is_bimc) //i_dad always bimc?
				pin_ale <= 1'b0;
			else
				pin_ale <= 1'b1;
			pin_ia_ <= 1'b1; // must be high
			pin_wr_ <= 1'b1; // must be high
			pin_rd_ <= 1'b1; // must be high
			pin_im_ <= 1'b1;
			pin_sta <= 1'b0;
			enb_adh <= 1'b1; // always enable T1-T6
			enb_adl <= 1'b1;
			enb_dat <= 1'b0;
			enb_ctl <= 1'b1;
		end
		STATE_T2: begin
			pin_ale <= 1'b0;
			pin_ia_ <= 1'b0; // depends on machine cycle
			pin_wr_ <= 1'b0; // depends on machine cycle
			pin_rd_ <= 1'b0; // depends on machine cycle
			pin_im_ <= 1'b1;
			pin_sta <= 1'b0;
			enb_adh <= 1'b1; // always enable T1-T6
			enb_adl <= 1'b0;
			enb_dat <= ~stactl[CTRL_WR_]; // enable only if writing
			enb_ctl <= 1'b1;
		end
		STATE_TW: begin
			pin_ale <= 1'b0;
			pin_ia_ <= 1'b0; // depends on machine cycle
			pin_wr_ <= 1'b0; // depends on machine cycle
			pin_rd_ <= 1'b0; // depends on machine cycle
			pin_im_ <= 1'b1;
			pin_sta <= 1'b0;
			enb_adh <= 1'b1; // always enable T1-T6
			enb_adl <= 1'b0;
			enb_dat <= ~stactl[CTRL_WR_]; // enable only if writing
			enb_ctl <= 1'b1;
		end
		STATE_T3: begin
			pin_ale <= 1'b0;
			pin_ia_ <= 1'b0; // depends on machine cycle
			pin_wr_ <= 1'b0; // depends on machine cycle
			pin_rd_ <= 1'b0; // depends on machine cycle
			pin_im_ <= 1'b1;
			pin_sta <= 1'b0;
			enb_adh <= 1'b1; // always enable T1-T6
			enb_adl <= 1'b0;
			enb_dat <= ~stactl[CTRL_WR_]; // enable only if writing
			enb_ctl <= 1'b1;
		end
		STATE_T4: begin
			pin_ale <= 1'b0;
			pin_ia_ <= 1'b1; // must be high
			pin_wr_ <= 1'b1; // must be high
			pin_rd_ <= 1'b1; // must be high
			pin_im_ <= 1'b0; // overrides status lines
			pin_sta <= 1'b1; // overrides status lines
			enb_adh <= 1'b1; // always enable T1-T6
			enb_adl <= 1'b0; // high-z T4-T6
			enb_dat <= 1'b0; // high-z T4-T6
			enb_ctl <= 1'b1;
		end
		STATE_T5: begin
			pin_ale <= 1'b0;
			pin_ia_ <= 1'b1; // must be high
			pin_wr_ <= 1'b1; // must be high
			pin_rd_ <= 1'b1; // must be high
			pin_im_ <= 1'b0; // overrides status lines
			pin_sta <= 1'b1; // overrides status lines
			enb_adh <= 1'b1; // always enable T1-T6
			enb_adl <= 1'b0; // high-z T4-T6
			enb_dat <= 1'b0; // high-z T4-T6
			enb_ctl <= 1'b1;
		end
		STATE_T6: begin
			pin_ale <= 1'b0;
			pin_ia_ <= 1'b1; // must be high
			pin_wr_ <= 1'b1; // must be high
			pin_rd_ <= 1'b1; // must be high
			pin_im_ <= 1'b0; // overrides status lines
			pin_sta <= 1'b1; // overrides status lines
			enb_adh <= 1'b1; // always enable T1-T6
			enb_adl <= 1'b0; // high-z T4-T6
			enb_dat <= 1'b0; // high-z T4-T6
			enb_ctl <= 1'b1;
		end
		STATE_TR: begin
			pin_ale <= 1'b0;
			pin_ia_ <= 1'b1;
			pin_wr_ <= 1'b0;
			pin_rd_ <= 1'b0;
			pin_im_ <= 1'b1;
			pin_sta <= 1'b0;
			enb_adh <= 1'b0;
			enb_adl <= 1'b0;
			enb_dat <= 1'b0;
			enb_ctl <= 1'b0;
		end
		STATE_TT: begin
			pin_ale <= 1'b0;
			pin_ia_ <= 1'b1;
			pin_wr_ <= 1'b0;
			pin_rd_ <= 1'b0;
			pin_im_ <= 1'b1;
			pin_sta <= 1'b0;
			enb_adh <= 1'b0;
			enb_adl <= 1'b0;
			enb_dat <= 1'b0;
			enb_ctl <= 1'b0;
		end
		STATE_TH: begin
			pin_ale <= 1'b0;
			pin_ia_ <= 1'b1;
			pin_wr_ <= 1'b0;
			pin_rd_ <= 1'b0;
			pin_im_ <= 1'b1;
			pin_sta <= 1'b0;
			enb_adh <= 1'b0;
			enb_adl <= 1'b0;
			enb_dat <= 1'b0;
			enb_ctl <= 1'b0;
		end
	endcase
end
// drive enb signals
assign chk_adh = enb_adh;
assign chk_adl = enb_adl;
assign chk_dat = enb_dat;
assign chk_ext = (cstate[2]|cstate[3]) & stactl[CTRL_WR_];
assign chk_mov = (cstate[4]|cstate[6]) & ~cycgo[0];

// create half cycles for ale and rd/wr/inta
reg q_ale, q_rwi;
always @(posedge clk or posedge rst)
begin
	if (rst == 1) begin
		q_ale <= 1'b1;
		q_rwi <= 1'b0;
	end else begin
		q_ale <= ~pin_ale;
		q_rwi <= cstate[3];
	end
end

// drive output pins
assign stat_s0 = pin_sta | stactl[STAT_S0];
assign stat_s1 = pin_sta | stactl[STAT_S1];
assign stat_iom_ = enb_ctl ? pin_im_ & stactl[STAT_IOM_] : 1'bz;
assign ctrl_rd_ = enb_ctl ? pin_rd_ | stactl[CTRL_RD_] | q_rwi : 1'bz;
assign ctrl_wr_ = enb_ctl ? pin_wr_ | stactl[CTRL_WR_] | q_rwi : 1'bz;
assign ctrl_inta_ = pin_ia_ | stactl[CTRL_INTA_] | q_rwi;
assign ctrl_ale = pin_ale & q_ale;

// internal wiring (combinational logic)
wire chk_rgr, chk_rgw, chk_irw, chk_nxt, chk_pci, chk_tpi;
assign chk_rgr = (((cstate[2]|cstate[3])&~isfirst&~stactl[CTRL_WR_])|
	((cstate[4]|cstate[5]|cstate[6])&~cycgo[0]));
assign chk_rgw = (cstate[3]&~isfirst&stactl[CTRL_WR_])|
	(((cstate[4]&~i_go6)|cstate[6])&~do_more[0]);
assign chk_irw = (cstate[3]&isfirst&stactl[CTRL_WR_]);
assign chk_nxt = (cstate[5]|cstate[6]);
assign chk_pci = (cstate[2]&(isfirst|(~is_bimc&~do_data[0])))|do_skip;
assign chk_tpi = (cstate[2]&~is_bimc&do_data[0]&(do_data[1]|i_pop|i_rxx))|
	(cstate[5]&~is_bimc&((do_data[0]&~i_rcc)|i_cxx));

//------------------------------------------------------------------------------
// SELECTOR SIGNALS
//------------------------------------------------------------------------------

// drive address bus (busa_q)
wire use_d, usepc, usemm, usem0, usem1;
wire usems, usemt, useio, usemx;
assign use_d = do_data[0];
assign usepc = ~use_d;
assign usemm = ~i_mmx & use_d & ~i_mmt & ~i_mms & ~i_dio & ~i_xhl;
assign usem0 = i_mmx & use_d & ~ireg_q[4];
assign usem1 = i_mmx & use_d & ireg_q[4];
assign usems = i_mms & use_d;
assign usemt = i_mmt & use_d;
assign useio = i_dio & use_d;
assign usemx = i_xhl & use_d;
zbuffer #(16) add0 (usepc,pcpc_q,busa_q);
zbuffer #(16) add1 (usemm,rphl_q,busa_q);
zbuffer #(16) add2 (usem0,rpbc_q,busa_q);
zbuffer #(16) add3 (usem1,rpde_q,busa_q);
zbuffer #(16) add4 (usems,sptr_q,busa_q);
zbuffer #(16) add5 (usemt,tptr_q,busa_q);
zbuffer #(16) add6 (useio,dptr_q,busa_q);
zbuffer #(16) add7 (usemx,sptr_q,busa_q);

// register addressing
wire sel_p;
assign sel_p = is_next;
wire[2:0] r1add, r2add, rpadd, rxadd;
wire[7:0] addwr, addrd, addrx, addrp;
assign r1add = ireg_q[5:3];
assign r2add = ireg_q[2:0];
assign rpadd = ireg_q[5:4];
assign rxadd = {rpadd,i_psh?~sel_p:sel_p};
decoder r1dec (r1add,addwr);
decoder r2dec (r2add,addrd);
decoder rxdec (rxadd,addrx);
decoder #(2) rpdec (rpadd,addrp);

// register pair selector
wire[15:0] rprp_q;
zbuffer #(16) rps0 (addrx[0]|addrx[1],rpbc_q,rprp_q);
zbuffer #(16) rps1 (addrx[2]|addrx[3],rpde_q,rprp_q);
zbuffer #(16) rps2 (addrx[4]|addrx[5],rphl_q,rprp_q);
zbuffer #(16) rps3 (addrx[6]|addrx[7],sptr_q,rprp_q);

// register selector
wire is_rr, is_wr, isalu;
assign isalu = i_alu | i_ali;
assign is_rr = i_mov | i_mvi | isalu; // using src (addrd) - bus_q
assign is_wr = i_mov | i_mvi | i_aid; // using dst (addwr) - bus_d

// acc rotate signals
wire[7:0] rotl_d, rotr_d, rota_d;
wire rota_b; // for carry flag input
assign rotl_d = ireg_q[4] ? {rgq[7][6:0],rgq[6][0]} : {rgq[7][6:0],rgq[7][7]};
assign rotr_d = ireg_q[4] ? {rgq[6][0],rgq[7][7:1]} : {rgq[7][0],rgq[7][7:1]};
assign rota_d = ireg_q[3] ? rotr_d : rotl_d;
assign rota_b = ireg_q[3] ? rgq[7][0] : rgq[7][7];

// acc special op - daa,cma
wire[7:0] aspc_d, idaa_d, icma_d;
assign aspc_d = ireg_q[3] ? icma_d : idaa_d;
assign idaa_d = res8_q;
assign icma_d = ~rgq[7];

// acc input select
wire accu_w, go_acc;
wire[7:0] accu_d;
zbuffer acc0 (isalu,res8_q,accu_d);
zbuffer acc1 (is_wr,busd_d,accu_d);
zbuffer acc2 (i_rim,intr_q&~INTE_BIT,accu_d);
zbuffer acc3 (i_lda,busd_d,accu_d);
zbuffer acc4 (i_rot,rota_d,accu_d);
zbuffer acc5 (i_acc,aspc_d,accu_d);
zbuffer acc6 (i_pop,busd_d,accu_d);
zbuffer acc7 (i_dio&is_last,busd_d,accu_d);
assign go_acc = isalu|i_rim|i_rot|i_acc|((i_lda|i_dio)&is_last);
assign accu_w = go_acc|(is_wr&addwr[7])|(i_pop&addrx[7]);
// acc drives data bus
zbuffer bufa (i_sta,rgq[7],busd_q);
zbuffer bufb (i_dio&is_last,rgq[7],busd_q);

// input for inx/dcx op
wire[15:0] pptr_q;
wire pptr_s;
assign pptr_q = i_mms | i_xhl ? sptr_q : tptr_q;
assign pptr_s = i_mms ? ireg_q[2] : i_xhl?~is_nxtp:is_nxtp;
assign idx_op = chk_pci|chk_tpi ? (chk_pci?1'b0:pptr_s) : ireg_q[3];
assign idxp_d = chk_pci|chk_tpi ? (chk_pci?pcpc_q:pptr_q) : rprp_q;
// inx/dcx op to reg
wire[7:0] addrz;
wire[7:0] rgz[7:0];
generate
	for(i=0;i<4;i=i+1) begin
		assign addrz[i*2] = addrp[i];
		assign addrz[i*2+1] = addrp[i];
		assign rgz[i*2] = idxp_q[15:8];
		assign rgz[i*2+1] = idxp_q[7:0];
	end
endgenerate

// hl input select
wire is_wx;
assign is_wx = is_wr | i_lxi | i_lhl | i_pop | i_xhl;
wire regh_w, regl_w;
wire[7:0] regh_d,regl_d;
zbuffer rgh0 (i_dad,res8_q,regh_d);
zbuffer rgh1 (is_wx,busd_d,regh_d);
zbuffer rgh2 (i_idx,rgz[4],regh_d);
zbuffer rgh3 (i_xch,rgq[2],regh_d);
assign regh_w = ((i_dad|i_lhl)&~sel_p)|(is_wr&addwr[4])|
	(i_lxi&addrx[4])|(i_idx&addrz[4])|(i_pop&addrx[4])|i_xch|(i_xhl&is_fin1);
zbuffer rgl0 (i_dad,res8_q,regl_d);
zbuffer rgl1 (is_wx,busd_d,regl_d);
zbuffer rgl2 (i_idx,rgz[5],regl_d);
zbuffer rgl3 (i_xch,rgq[3],regl_d);
assign regl_w = ((i_dad|i_lhl)&sel_p)|(is_wr&addwr[5])|
	(i_lxi&addrx[5])|(i_idx&addrz[5])|(i_pop&addrx[5])|i_xch|(i_xhl&~is_fin1);
// hl drives data bus
zbuffer bufh (i_shl&is_last,rgq[4],busd_q);
zbuffer bufl (i_shl&~is_last,rgq[5],busd_q);

// interrupt mask register
wire [7:0] intr_j, intr_k;
assign intr_k = (rgq[7]&~INTE_BIT)|(intr_q&INTE_BIT);
assign intr_j = (intr_q&~INTE_BIT)|({2'b00,ireg_q[3],5'b00000});
assign intr_w = chk_rgw & (i_sim|i_edi);
assign intr_d = i_sim ? intr_k : intr_j;
assign intr_r = 1'b0;

// flag input select
wire flag_w;
wire[7:0] flag_d, flag_0, flag_1, flag_2, flag_3, flag_4;
assign flag_w = (i_alu|i_ali|i_aid|i_dad|i_rot|i_daa|i_flc)|(i_pop&addrx[6]);
assign flag_0 = (alu_of&FLAGMASK);
assign flag_1 = (idr_of&FLAGMASK);
assign flag_2 = {rgq[6][7:1],alu_of[0]};
assign flag_3 = {rgq[6][7:1],rota_b};
assign flag_4 = {rgq[6][7:1],(ireg_q[3]?~rgq[6][0]:1'b1)};
zbuffer flg0 (i_alu|i_ali|i_daa,flag_0,flag_d);
zbuffer flg1 (i_aid,flag_1,flag_d);
zbuffer flg2 (i_dad,flag_2,flag_d);
zbuffer flg3 (i_rot,flag_3,flag_d);
zbuffer flg4 (i_flc,flag_4,flag_d);
zbuffer flg5 (i_pop,busd_d,flag_d);

// main register select - the actual signal :p
generate
	for(i=0;i<8;i=i+1) begin
		if(i==7) begin // accumulator
			assign rgw[i] = chk_rgw & accu_w;
			assign rgd[i] = accu_d;
			assign rgr[i] = chk_rgr & ((is_rr&addrd[i])|(i_psh&addrx[i]));
		end else if(i==6) begin // flag
			assign rgw[i] = chk_rgw & flag_w;
			assign rgd[i] = flag_d;
			assign rgr[i] = chk_rgr & (i_psh&addrx[i]); // only on push psw?
		end else if(i==5) begin
			assign rgw[i] = chk_rgw & regl_w;
			assign rgd[i] = regl_d;
			assign rgr[i] = chk_rgr & ((is_rr&addrd[i])|(i_psh&addrx[i]));
		end else if(i==4) begin
			assign rgw[i] = chk_rgw & regh_w;
			assign rgd[i] = regh_d;
			assign rgr[i] = chk_rgr & ((is_rr&addrd[i])|(i_psh&addrx[i]));
		end else if(i==3) begin
			assign rgw[i] = chk_rgw &
				((is_wr&addwr[i])|(i_lxi&addrx[i])|
				(i_idx&addrz[i])|(i_pop&addrx[i])|i_xch);
			assign rgd[i] = i_idx ? rgz[i] : i_xch ? rgq[5] : busd_d;
			assign rgr[i] = chk_rgr & ((is_rr&addrd[i])|(i_psh&addrx[i]));
		end else if(i==2) begin
			assign rgw[i] = chk_rgw &
				((is_wr&addwr[i])|(i_lxi&addrx[i])|
				(i_idx&addrz[i])|(i_pop&addrx[i])|i_xch);
			assign rgd[i] = i_idx ? rgz[i] : i_xch ? rgq[4] : busd_d;
			assign rgr[i] = chk_rgr & ((is_rr&addrd[i])|(i_psh&addrx[i]));
		end else begin
			assign rgw[i] = chk_rgw &
				((is_wr&addwr[i])|(i_lxi&addrx[i])|
				(i_idx&addrz[i])|(i_pop&addrx[i]));
			assign rgd[i] = i_idx ? rgz[i] : busd_d;
			assign rgr[i] = chk_rgr & ((is_rr&addrd[i])|(i_psh&addrx[i]));
		end
	end
endgenerate

// program counter select
wire[15:0] pctr_q;
wire pctr_w, chk_pcc;
assign chk_pcc = (cstate[3] & ~isfirst & is_data);
assign pctr_w = (chk_rgw&((i_jxx&is_last)|(i_hpc)))|
	(chk_pcc&(i_cxx|i_rxx|i_rst)&is_last);
assign pcpc_w = chk_pci | pctr_w;
assign pcpc_d = chk_pci ? idxp_q : pctr_q;
zbuffer #(16) pcw0 (i_cxx,tptr_q,pctr_q);
zbuffer #(16) pcw1 (i_jxx,{busd_d,temp_q},pctr_q);
zbuffer #(16) pcw2 (i_rxx,{busd_d,temp_q},pctr_q);
zbuffer #(16) pcw3 (i_hpc,rphl_q,pctr_q);
zbuffer #(16) pcw4 (i_rst,{10'h000,ireg_q[5:3],3'b000},pctr_q);
// program counter drives data bus?
zbuffer bpc0 (i_cxx&is_data&~is_last,pcpc_q[15:8],busd_q);

// instruction register select
assign ireg_w = chk_irw;
assign ireg_d = busd_d;

// stack pointer select
assign sprh_r = 1'b0;
assign sprh_w = (chk_rgw&((i_lxi&addrx[6])|(i_idx&addrz[6])|i_hsp))|
	(chk_tpi&(i_mms|(i_xhl&(~is_nxtp|(is_nxtp&~is_fin1)))));
zbuffer sph0 (i_lxi,busd_d,sprh_d);
zbuffer sph1 (i_idx,rgz[6],sprh_d);
zbuffer sph2 (i_mms|i_xhl,idxp_q[15:8],sprh_d);
zbuffer sph3 (i_hsp,rgq[4],sprh_d);
assign sprl_r = 1'b0;
assign sprl_w = (chk_rgw&((i_lxi&addrx[7])|(i_idx&addrz[7])|i_hsp))|
	(chk_tpi&(i_mms|(i_xhl&(~is_nxtp|(is_nxtp&~is_fin1)))));
zbuffer spl0 (i_lxi,busd_d,sprl_d);
zbuffer spl1 (i_idx,rgz[7],sprl_d);
zbuffer spl2 (i_mms|i_xhl,idxp_q[7:0],sprl_d);
zbuffer spl3 (i_hsp,rgq[5],sprl_d);

// temporary pointer select
assign tprh_r = 1'b0;
assign tprh_w = (chk_rgw&~is_nxta&~is_data&(i_mmt|i_cxx))|
	(chk_tpi&i_mmt)|(cstate[4]&i_xhl)|(cstate[4]&i_rst);
zbuffer tph0 (chk_tpi,idxp_q[15:8],tprh_d);
zbuffer tph1 (i_xhl,rgq[4],tprh_d);
zbuffer tph2 (~chk_tpi&~i_xhl&~i_rst,busd_d,tprh_d);
zbuffer tph3 (i_rst,pcpc_q[15:8],tprh_d);
assign tprl_r = 1'b0;
assign tprl_w = (chk_rgw&is_nxta&~is_data&(i_mmt|i_cxx))|
	(chk_tpi&i_mmt)|(cstate[4]&i_xhl)|(cstate[4]&i_rst);
assign tprl_d = chk_tpi ? idxp_q[7:0] : i_xhl?rgq[5]:busd_d;
zbuffer tpl0 (chk_tpi,idxp_q[7:0],tprl_d);
zbuffer tpl1 (i_xhl,rgq[5],tprl_d);
zbuffer tpl2 (~chk_tpi&~i_xhl&~i_rst,busd_d,tprl_d);
zbuffer tpl3 (i_rst,pcpc_q[7:0],tprl_d);
// temp pointer drives data bus?
zbuffer tpp0 (i_xhl&~is_nxtp&~is_last,tprh_q,busd_q);
zbuffer tpp1 (i_xhl&~is_nxtp&is_last,tprl_q,busd_q);
zbuffer tpp2 (i_rst&~is_last,tprh_q,busd_q);
zbuffer tpp3 (i_rst&is_last,tprl_q,busd_q);

// temp register select
wire[7:0] tmpi_q, tmpc_q;
assign temp_r = chk_rgr&((is_rr&addrd[6])|(i_aid&addwr[6]&is_last)|
	(i_dio&~is_last));
assign temp_w = (chk_rgw&((is_wr&addwr[6])|((i_jxx|i_dio)&~is_last)))|
	(chk_pcc&(i_cxx|i_rxx)&~is_last);
zbuffer tmp0 (is_wr&~i_aid,busd_d,temp_d); // simplify this later!
zbuffer tmp1 (i_aid,idrg_q,temp_d);
zbuffer tmp2 (i_cxx,pcpc_q[7:0],temp_d);
zbuffer tmp3 (i_jxx|i_dio|i_rxx,busd_d,temp_d);
// temp register drives data bus
zbuffer bft0 (i_cxx&is_data&is_last,temp_q,busd_q);

// increment/decrement for 8-bit registers
assign idrg_r = chk_rgr & i_aid & ~is_last;
generate
	for(i=0;i<8;i=i+1) begin // select increment/decrement input
		if(i==6) begin // memory: from bus?
			zbuffer idud (addwr[i],busd_d,idrg_d);
		end else begin
			zbuffer idud (addwr[i],rgq[i],idrg_d);
		end
	end
endgenerate
assign idr_op = ireg_q[0];

// alu inputs select
wire[7:0] oprx_d;
wire e_bus;
assign e_bus = ~i_dad & ~i_acc;
assign oprx_d = sel_p ? rgq[5] : rgq[4];
assign opr1_d = i_dad ? oprx_d : rgq[7];
generate
	for(i=0;i<8;i=i+1) begin
		if(i==6) begin // memory: from bus?
			zbuffer op2s (e_bus&addrd[i],busd_d,opr2_d);
			zbuffer op2x (i_dad&addrx[i],sprh_q,opr2_d);
		end else if(i==7) begin
			zbuffer op2s (e_bus&addrd[i],rgq[i],opr2_d);
			zbuffer op2x (i_dad&addrx[i],sprl_q,opr2_d);
		end else begin
			zbuffer op2s (e_bus&addrd[i],rgq[i],opr2_d);
			zbuffer op2x (i_dad&addrx[i],rgq[i],opr2_d);
		end
	end
endgenerate
zbuffer op2x (i_acc,daad_d,opr2_d);
assign alu_op = i_dad ? {2'b00,~sel_p} : (i_acc ? 3'b000 : ireg_q[5:3]);

endmodule
