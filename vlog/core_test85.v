module test85 ( CLK, RST_, READY, HOLD, SID, INTR, TRAP, RST75, RST65, RST55,
	ADDRDATA, ADDR, CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_,
	ALE, HLDA, SOD ); //VCC, VSS // power lines //X1, X2, // cystal input

// state register
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
// machine cycle status & control - ctrl:{inta_,wr_,rd_}, stat:{io/m_,s1,s0}
parameter CYCLE_OF = 6'b110011; // opcode fetch
parameter CYCLE_MW = 6'b101001; // memory write
parameter CYCLE_MR = 6'b110010; // memory read
parameter CYCLE_DW = 6'b101101; // device write
parameter CYCLE_DR = 6'b110110; // device read
parameter CYCLE_INA = 6'b011111; // interrupt acknowledge
parameter CYCLE_BID = 6'b111010; // bus idle - DAD (2 cycles?)
parameter CYCLE_BIT = 6'b111111; // ack reset/trap
parameter CYCLE_BIH = 6'b111100; // halt ; actually 6'b1zzz00
parameter CYCLE_ERR = 6'b000000; // internal error
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

input CLK, RST_, READY, HOLD, SID, INTR, TRAP, RST75, RST65, RST55;
inout[7:0] ADDRDATA;
output[15:8] ADDR;
output CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_, ALE, HLDA, SOD;

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
wire ctrl_inta_, ctrl_wr_, ctrl_rd_;
wire ctrl_ale;
wire chk_adh, chk_adl, chk_dat; // assignments needs control signal
wire chk_ext, chk_mov; // must be exclusive!
wire[15:0] busa_q;
wire[7:0] busd_d, busd_q; // incoming & outgoing data bus signal
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

// data/addr bus
zbuffer bus_addh (chk_adh,busa_q[15:8],ADDR);
zbuffer bus_addl (chk_adl,busa_q[7:0],ADDRDATA);
zbuffer bus_odat (chk_dat,busd_q,ADDRDATA);
zbuffer bus_idat (chk_ext,ADDRDATA,busd_d);
zbuffer bus_mdat (chk_mov,busd_q,busd_d);

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
register #(16) r16pc (clk,rst,pcpc_w,pcpc_d,pcpc_q);

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
wire intr_w, intr_r;
register intr (clk,1'b0,intr_w,intr_d,intr_q);
zbuffer intb (intr_r,intr_q,busd_q);

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

// alias data pointer
wire[15:0] rpbc_q, rpde_q, rphl_q, sptr_q, tptr_q;
assign rpbc_q = {rgq[0],rgq[1]};
assign rpde_q = {rgq[2],rgq[3]};
assign rphl_q = {rgq[4],rgq[5]};
assign sptr_q = {sprh_q,sprl_q}; // stack pointer
assign tptr_q = {tprh_q,tprl_q}; // temp pointer

// for instruction decoding
wire i_txa, i_mov, i_alu, i_sic, i_hlt, i_aid, i_ali, i_lxi;
wire i_tmp, i_dad, i_idx, i_nop, i_mmx, i_acc, i_imk, i_mmt;
wire i_rim, i_sim, i_dio, i_go6, i_mvi, i_sta, i_lda;
wire tmp04, tmp05, tmp06;
wire lo000, lo001, lo010, lo011, lo101, lo110, lo111;
wire lo10x, lox00, lox01, lox11;
wire hi000, hi001, hi010, hi011, hi100, hi110, hi111;
wire hi00x, hi01x, hi10x, hi11x;
wire hi0x0, hi0x1, hi1x0, hi1x1;
wire mem_d, mem_s, chk_p;
// machine cycles required by current inst? - need always block for this
wire cyc_1, cyc_2, cyc_3, cyc_4, cyc_5;
wire cycw2, cycw3, cycw4, cycw5;
wire cycd2, cycd3, cycd4, cycd5;
reg[INFO_CYC-1:0] cycgo, cycrw, cyccd;
reg flags;
// top 2-bits instruction decoding
assign i_txa = ~ireg_q[7] & ~ireg_q[6]; // 00 - transfer + arithmetic
assign i_mov = ~ireg_q[7] & ireg_q[6]; // 01 - register move + halt
assign i_alu = ireg_q[7] & ~ireg_q[6]; // 10 - basic alu (ad,as,&,|,^,cmp)
assign i_sic = ireg_q[7] & ireg_q[6]; // 11 - stack, i/o & control
// 'helper' signals :p
assign tmp04 = ~ireg_q[3] & ireg_q[2];
assign tmp05 = ireg_q[3] & ~ireg_q[2];
assign tmp06 = ireg_q[3] & ireg_q[2];
// mid 3-bits
assign hi000 = ~ireg_q[5] & ~ireg_q[4] & ~ireg_q[3];
assign hi001 = ~ireg_q[5] & ~ireg_q[4] & ireg_q[3];
assign hi010 = ~ireg_q[5] & ireg_q[4] & ~ireg_q[3];
assign hi011 = ~ireg_q[5] & ireg_q[4] & ireg_q[3];
assign hi100 = ireg_q[5] & ~ireg_q[4] & ~ireg_q[3];
assign hi110 = ireg_q[5] & ireg_q[4] & ~ireg_q[3];
assign hi111 = ireg_q[5] & ireg_q[4] & ireg_q[3];
assign hi00x = ~ireg_q[5] & ~ireg_q[4];
assign hi01x = ~ireg_q[5] & ireg_q[4]; // 01x - io inst sig 2
assign hi10x = ireg_q[5] & ~ireg_q[4];
assign hi11x = ireg_q[5] & ireg_q[4];
assign hi0x0 = ~ireg_q[5] & ~ireg_q[3];
assign hi0x1 = ~ireg_q[5] & ireg_q[3];
assign hi1x0 = ireg_q[5] & ~ireg_q[3];
assign hi1x1 = ireg_q[5] & ireg_q[3];
// low 3-bits
assign lo000 = ~ireg_q[2] & ~ireg_q[1] & ~ireg_q[0];
assign lo001 = ~ireg_q[2] & ~ireg_q[1] & ireg_q[0];
assign lo010 = ~ireg_q[2] & ireg_q[1] & ~ireg_q[0];
assign lo011 = ~ireg_q[2] & ireg_q[1] & ireg_q[0]; // 011 - io inst sig 1
assign lo101 = ireg_q[2] & ~ireg_q[1] & ireg_q[0];
assign lo110 = ireg_q[2] & ireg_q[1] & ~ireg_q[0];
assign lo111 = ireg_q[2] & ireg_q[1] & ireg_q[0];
assign lo10x = ireg_q[2] & ~ireg_q[1];
assign lox00 = ~ireg_q[1] & ~ireg_q[0];
assign lox01 = ~ireg_q[1] & ireg_q[0];
assign lox11 = ireg_q[1] & ireg_q[0];
// alias?
assign mem_d = hi110; // 110 - mov dst = mem
assign mem_s = lo110; // 110 - mov src = mem
assign i_hlt = i_mov & mem_d & mem_s;
assign i_aid = i_txa & lo10x; // increment/decrement
assign i_ali = i_sic & lo110; // alu immediate
assign i_mvi = i_txa & lo110; // mov immediate
assign chk_p =
	(i_txa & lo011) | // inx, dcx (8)
	(i_txa & lo001); // dad, lxi (8)
//	(i_txa & lo010 & hi10x); // shld, lhld (2)
assign i_lxi = i_txa & lo001 & ~ireg_q[3];
assign i_tmp = //(i_aid & mem_d);
	(i_txa & hi110 & ireg_q[2] & ~(ireg_q[1]&ireg_q[0])); // inr,dcr,mvi m (3)
assign i_dad = i_txa & lo001 & ireg_q[3];
assign i_idx = i_txa & lo011; // increment/decrement pair
assign i_nop = i_idx | (i_txa & hi000 & lo000); // nop
assign i_mmx = (i_txa & lo010 & ~ireg_q[5]); // ldax,stax (4)
assign i_acc = i_mmx;
assign i_imk = i_rim | i_sim;
assign i_mmt = (i_txa & lo010 & hi11x); // sta,lda (2)
assign i_rim = (i_txa & hi100 & lo000);
assign i_sim = (i_txa & hi110 & lo000);
assign i_dio = i_sic & lo011 & hi01x;
assign i_sta = (i_txa & lo010 & ~ireg_q[3] & ~(ireg_q[5]&~ireg_q[4])); // sta(x)
assign i_lda = (i_txa & lo010 & ireg_q[3] & ~(ireg_q[5]&~ireg_q[4])); // lda(x)
assign i_go6 =
	(i_txa & lo011) | // 00xxx011 - INX (4) @ DCX (4)
	(i_sic & lo111) | // 11xxx111 - RST n (8)
	//(i_sic & lo000) | // 11xxx000 - Rccc (8)
	//(i_sic & lo100) | // 11xxx100 - Cccc (8)
	(i_sic & lox00) |
	(i_sic & tmp04 & lox01) | // 11xx0101 - push (4)
	(i_sic & ireg_q[5] & tmp05 & lox01) | // 111x1001 - pchl, sphl (2)
	(i_sic & hi00x & tmp06 & lox01); // 11001101 - call (1)
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
	(i_sic & lo110 ) | // alu immediate (8)
	(i_mov & (mem_d ^ mem_s)) | // all mov with m except hlt (14)
	(i_alu & mem_s) | // all alu with m (8)
	i_hlt ; // (1)
assign cycw2 =
	// cyc_3
	(i_sic & lo111) | // rst (8)
	(i_sic & lo101 & ~ireg_q[3]) | // push (4)
	// cyc_2 - sub:9-instructions
	(i_txa & lo010 & hi0x0) | // stax (2)
	(i_mov & mem_d & ~mem_s); // all mov with dst=m &src!=m (7)
assign cycd2 =
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
	(i_sic & lo101 & ~ireg_q[3]) | // push (4)
	(i_sic & lo001 & ~ireg_q[3]) | // pop (4)
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
	(i_txa & hi110 & ireg_q[2] & ~(ireg_q[1]&ireg_q[0])); // inr,dcr,mvi m (3)
assign cyc_4 = // 2 instructions
	(i_mmt); // sta,lda (2)
assign cycw4 =
	// cyc_5
	(i_sic & lo010) | // cccc (8)
	(i_sic & lo011 & hi100) | // xthl (1)
	(i_sic & lo101 & hi001) | // call (1)
	(i_txa & lo010 & hi100) | // shld (1)
	// cyc_4 - sub:1-instruction
	(i_txa & lo010 & hi110); // sta (1)
assign cycd4 =
	(i_txa & lo010 & hi11x); // sta,lda (2)
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

// internal registers
reg[STATECNT-1:0] cstate, nstate; // 1-hot encoded states
reg[STACTLSZ-1:0] stactl;
reg isfirst, is_next, is_last, is_nxta;
reg[INFO_CYC-1:0] do_more, dowrite, do_data;
// control signals
wire do_bimc, do_memr, do_memw, do_devr, do_devw;
// control logic
assign do_bimc = (i_dad|i_hlt)&do_more[0];
assign do_memr = ~dowrite[0]&~i_dio;
assign do_memw = dowrite[0]&~i_dio;
assign do_devr = ~dowrite[0]&i_dio;
assign do_devw = dowrite[0]&i_dio;
// state register - transition on negative edge!
always @(posedge clk_ or posedge rst) begin // asynchronous reset, active low
	if(rst == 1) begin // actually active low
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
			end
			STATE_T1: begin
				isfirst <= ~do_more[0];
				is_next <= do_more[1];
				is_last <= do_more[0] & ~do_more[1];
				is_nxta <= do_more[2];
				if (~do_more[0]) begin
					// update stactl on first state
					// stat:{io/m_,s1,s0} , ctrl:{inta_,wr_,rd_}
					stactl <= CYCLE_OF;
				end else if (i_dad) begin
					stactl <= CYCLE_BID;
				end else if (i_hlt) begin
					stactl <= CYCLE_BIH;
				end else begin
					case ({do_memr,do_memw,do_devr,do_devw})
						4'b1000: stactl <= CYCLE_MR;
						4'b0100: stactl <= CYCLE_MW;
						4'b0010: stactl <= CYCLE_DR;
						4'b0001: stactl <= CYCLE_DW;
						default: stactl <= CYCLE_ERR;
					endcase
				end
			end
			STATE_T3: begin
				do_more <= do_more >> 1;
				dowrite <= dowrite >> 1;
				do_data <= do_data >> 1;
			end
			STATE_T4: begin
				// assign next machine cycle here
				if (~i_go6) begin
					if (cycgo[0]) begin
						do_more <= cycgo;
						dowrite <= cycrw;
						do_data <= cyccd;
					end
				end
			end
			STATE_T6: begin
				// assign next machine cycle here
				if (cycgo[0]) begin
					do_more <= cycgo;
					dowrite <= cycrw;
					do_data <= cyccd;
				end
			end
		endcase
	end
end

// output logic
reg pin_ale, pin_ia_, pin_wr_, pin_rd_, pin_im_, pin_sta;
// enable logic
reg enb_adh, enb_adl, enb_dat, enb_ctl;
// internal wiring (combinational logic)
wire chk_rd_, chk_wr_, chk_ia_, chk_nxt;
wire chk_rgr, chk_rgw, chk_irw, chk_pcw;
// drive enb signals
assign chk_adh = enb_adh;
assign chk_adl = enb_adl;
assign chk_dat = enb_dat;
assign chk_rgr = (((cstate[2]|cstate[3])&~isfirst&~stactl[CTRL_WR_])|
	((cstate[4]|cstate[5]|cstate[6])&~cycgo[0]));
assign chk_rgw = (cstate[3]&~isfirst&stactl[CTRL_WR_])|
	(((cstate[4]&~i_go6)|cstate[6])&~do_more[0]);
assign chk_irw = (cstate[3]&isfirst&stactl[CTRL_WR_]);
assign chk_nxt = (cstate[5]|cstate[6]);
assign chk_pcw = (cstate[2]&(isfirst|(~do_bimc&~do_data[0])));
// where to do this???
assign chk_ext = ((cstate[2]|cstate[3])&stactl[CTRL_WR_]);
assign chk_mov = ((cstate[4]|cstate[6])&~cycgo[0]);

// half-cycle logic
reg q_ale, q_rwi;
// create half cycles
always @(posedge clk or posedge rst)
begin
	if (rst=== 1'b1) begin
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
assign ctrl_rd_ = enb_ctl ? pin_rd_ | chk_rd_ : 1'bz;
assign ctrl_wr_ = enb_ctl ? pin_wr_ | chk_wr_ : 1'bz;
assign ctrl_inta_ = pin_ia_ | chk_ia_;
assign ctrl_ale = pin_ale & q_ale;
assign chk_rd_ = stactl[CTRL_RD_] | q_rwi;
assign chk_wr_ = stactl[CTRL_WR_] | q_rwi;
assign chk_ia_ = stactl[CTRL_INTA_] | q_rwi;

// output logic - depends on state only
always @(cstate) begin
	case (cstate)
		STATE_T1: begin
			if (do_bimc) //i_dad always bimc?
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

// next-state logic
always @(cstate or ireg_q or stactl or do_bimc or isfirst or HOLD or READY)
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
			if (READY|do_bimc) begin
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
			if (READY|do_bimc) begin
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

// drive address bus (busa_q)
wire use_d, sel_p;
wire usepc, usemm, usem0, usem1;
wire usems, usemt;
assign use_d = do_data[0];
assign sel_p = is_next;
assign usepc = ~use_d;
assign usemm = ~i_mmx & use_d & ~i_mmt;
assign usem0 = i_mmx & use_d & ~ireg_q[4];
assign usem1 = i_mmx & use_d & ireg_q[4];
assign usems = 1'b0; // no stack for now
assign usemt = i_mmt & use_d;
zbuffer #(16) add0 (usepc,pcpc_q,busa_q);
zbuffer #(16) add1 (usemm,rphl_q,busa_q);
zbuffer #(16) add2 (usem0,rpbc_q,busa_q);
zbuffer #(16) add3 (usem1,rpde_q,busa_q);
zbuffer #(16) add4 (usems,sptr_q,busa_q);
zbuffer #(16) add5 (usemt,tptr_q,busa_q);

// register addressing
wire[2:0] r1add, r2add, rpadd, rxadd;
wire[7:0] addwr, addrd, addrx, addrp;
assign r1add = ireg_q[5:3];
assign r2add = ireg_q[2:0];
assign rpadd = ireg_q[5:4];
assign rxadd = {rpadd,sel_p};
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

// general address selector
wire is_rr, is_wr, is_rx, is_wx;
assign is_rr = i_mov | i_mvi | i_alu | i_ali;
assign is_wr = i_mov | i_mvi | i_aid;
assign is_rx = 1'b0;
assign is_wx = i_lxi;

// acc input select
wire accu_w;
wire[7:0] accu_d;
zbuffer acc0 (i_alu|i_ali,res8_q,accu_d);
zbuffer acc1 (is_wr,busd_d,accu_d);
zbuffer acc2 (i_rim,intr_q,accu_d);
zbuffer acc3 (i_lda,busd_d,accu_d);
assign accu_w = (i_alu|i_ali|i_rim|i_lda)|((i_mov|i_mvi|i_aid)&addwr[7]);
// acc drives data bus
zbuffer bufa (i_sta,rgq[7],busd_q);
assign intr_w = chk_rgw & i_sim;
assign intr_d = rgq[7];

// flag input select
wire flag_w;
wire[7:0] flag_d, flag_1, flag_2;
assign flag_w = (i_alu|i_ali|i_aid|i_dad); // on alu op & pop psw?
assign flag_1 = i_aid ? idr_of&FLAGMASK : alu_of&FLAGMASK;
assign flag_2 = ((alu_of&FLAGMSKC)|(rgq[6]&~FLAGMSKC));
assign flag_d = i_dad ? flag_2 : flag_1;

// connecting the dots
assign pcpc_w = chk_pcw;
assign pcpc_d = idxp_q;
assign ireg_w = chk_irw;
assign ireg_d = busd_d;
wire regh_w, regl_w;
wire[7:0] rgu, rgv, rgt;
wire[7:0] rgz[7:0],regh_d,regl_d;
generate
	for(i=0;i<8;i=i+1) begin
		if(i==7) begin // accumulator
			assign rgw[i] = chk_rgw & accu_w;
			assign rgd[i] = accu_d;
			assign rgr[i] = chk_rgr & is_rr & addrd[i];
		end else if(i==6) begin // flag
			assign rgw[i] = chk_rgw & flag_w;
			assign rgd[i] = flag_d;
			assign rgr[i] = 1'b0; // only on push psw?
		end else if(i==5) begin
			assign regl_w = chk_rgw & ((is_wr & addwr[i])|(is_wx & addrx[i]));
			assign regl_d = i_dad ? res8_q : busd_d;
			assign rgv[i] = i_dad ? chk_rgw & sel_p : regl_w;
			assign rgu[i] = chk_rgw & i_idx & rgt[i];
			assign rgw[i] = i_idx ? rgu[i] : rgv[i];
			assign rgd[i] = i_idx ? rgz[i] : regl_d;
			assign rgr[i] = chk_rgr & is_rr & addrd[i];
		end else if(i==4) begin
			assign regh_w = chk_rgw & ((is_wr & addwr[i])|(is_wx & addrx[i]));
			assign regh_d = i_dad ? res8_q : busd_d;
			assign rgv[i] = i_dad ? chk_rgw & ~sel_p : regh_w;
			assign rgu[i] = chk_rgw & i_idx & rgt[i];
			assign rgw[i] = i_idx ? rgu[i] : rgv[i];
			assign rgd[i] = i_idx ? rgz[i] : regh_d;
			assign rgr[i] = chk_rgr & is_rr & addrd[i];
		end else begin
			assign rgv[i] = chk_rgw & ((is_wr & addwr[i])|(is_wx & addrx[i]));
			assign rgu[i] = chk_rgw & i_idx & rgt[i];
			assign rgw[i] = i_idx ? rgu[i] : rgv[i];
			assign rgd[i] = i_idx ? rgz[i] : busd_d;
			assign rgr[i] = chk_rgr & is_rr & addrd[i];
		end
	end
	for(i=0;i<4;i=i+1) begin
		assign rgz[i*2] = idxp_q[15:8];
		assign rgz[i*2+1] = idxp_q[7:0];
		assign rgt[i*2] = addrp[i];
		assign rgt[i*2+1] = addrp[i];
	end
endgenerate
assign sprh_r = 1'b0;
assign sprh_w = chk_rgw & ((is_wx & addrx[6])|(i_idx & rgt[6]));
assign sprh_d = i_idx ? rgz[6] : busd_d;
assign sprl_r = 1'b0;
assign sprl_w = chk_rgw & ((is_wx & addrx[7])|(i_idx & rgt[7]));
assign sprl_d = i_idx ? rgz[7] : busd_d;
assign tprh_r = 1'b0;
assign tprh_w = chk_rgw & i_mmt & ~is_nxta & ~is_last;
assign tprh_d = busd_d;
assign tprl_r = 1'b0;
assign tprl_w = chk_rgw & i_mmt & is_nxta & ~is_last;
assign tprl_d = busd_d;
assign temp_r = chk_rgr & ((is_rr & addrd[6])|(i_aid & addwr[6] & is_last));
assign temp_w = chk_rgw & is_wr & addwr[6];
assign temp_d = i_aid ? idrg_q : busd_d;
assign intr_r = 1'b0;
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
wire[7:0] oprx_d;
assign oprx_d = sel_p ? rgq[5] : rgq[4];
assign opr1_d = i_dad ? oprx_d : rgq[7];
generate
	for(i=0;i<8;i=i+1) begin
		if(i==6) begin // memory: from bus?
			zbuffer op2s (~i_dad&addrd[i],busd_d,opr2_d);
			zbuffer op2x (i_dad&addrx[i],sprh_q,opr2_d);
		end else if(i==7) begin
			zbuffer op2s (~i_dad&addrd[i],rgq[i],opr2_d);
			zbuffer op2x (i_dad&addrx[i],sprl_q,opr2_d);
		end else begin
			zbuffer op2s (~i_dad&addrd[i],rgq[i],opr2_d);
			zbuffer op2x (i_dad&addrx[i],rgq[i],opr2_d);
		end
	end
endgenerate
assign alu_op = i_dad ? {2'b000,~sel_p} : ireg_q[5:3];

// input for inx/dcx op
assign idx_op = chk_pcw ? 1'b0 : ireg_q[3];
assign idxp_d = chk_pcw ? pcpc_q : rprp_q;

endmodule
