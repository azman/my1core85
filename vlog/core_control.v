module control (clk_, rst_, inst, ipin, oenb, opin);

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
parameter STAT_S0 = 0;
parameter STAT_S1 = 1;
parameter STAT_IOM_ = 2;
parameter CTRL_RD_ = 3;
parameter CTRL_WR_ = 4;
parameter CTRL_INTA_ = 5;
// these are from alureg
parameter INST_GO6 = 0;
parameter INST_DAD = 1;
parameter INST_HLT = 2;
parameter INSTSIZE = 3;
// input pins
parameter IPIN_READY = 0;
parameter IPIN_HOLD = 1;
parameter IPIN_COUNT = 2;
// output enables (control)
parameter OENB_ADDL = 0;
parameter OENB_ADDH = 1;
parameter OENB_DATA = 2;
parameter OENB_COUNT = 3;
// direct ouput pins
parameter OPIN_S0 = 0;
parameter OPIN_S1 = 1;
parameter OPIN_IOM_ = 2;
parameter OPIN_RD_ = 3;
parameter OPIN_WR_ = 4;
parameter OPIN_INTA_ = 5;
parameter OPIN_ALE = 6;
parameter OPIN_COUNT = 7;

// port i/o declaration
input clk_,rst_;
input[INSTSIZE-1:0] inst;
input[IPIN_COUNT-1:0] ipin;
output[OENB_COUNT-1:0] oenb;
output[OPIN_COUNT-1:0] opin;
wire[OENB_COUNT-1:0] oenb;
wire[OPIN_COUNT-1:0] opin;

// internal registers
reg[STATECNT-1:0] cstate, nstate; // 1-hot encoded states
reg[6:0] stactl; // stat:{io/m_,s1,s0} , ctrl:{inta_,wr_,rd_}
reg is_bimc, is_last, is_init;
// output logic - used in always block
reg pin_ale, pin_ia_, pin_wr_, pin_rd_, pin_im_, pin_sta;
reg enb_adh, enb_adl, enb_dat, enb_ctl;

// drive enb port with internal registers
assign oenb[OENB_ADDL] = enb_adl;
assign oenb[OENB_ADDH] = enb_adh;
assign oenb[OENB_DATA] = enb_dat;
// direct reg to pin
assign opin[OPIN_S0] = pin_sta | stactl[STAT_S0];
assign opin[OPIN_S1] = pin_sta | stactl[STAT_S1];
assign opin[OPIN_IOM_] = enb_ctl ? pin_im_ & stactl[STAT_IOM_] : 1'bz;
assign opin[OPIN_RD_] = enb_ctl ? pin_rd_ | stactl[CTRL_RD_] : 1'bz;
assign opin[OPIN_WR_] = enb_ctl ? pin_wr_ | stactl[CTRL_WR_] : 1'bz;
assign opin[OPIN_INTA_] = pin_ia_ | stactl[CTRL_INTA_];
assign opin[OPIN_ALE] = pin_ale;

// output logic - depends on state only
always @(cstate) begin
	case (cstate)
		STATE_T1: begin
			if (is_bimc|inst[INST_DAD]) //inst[INST_DAD] always bimc?
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
always @(cstate or inst or ipin or stactl or
		is_bimc or is_last or is_init) begin
	nstate = cstate;
	case (cstate)
		STATE_TR: begin
			nstate = STATE_T1;
		end
		STATE_T1: begin
			if (inst[INST_HLT]) begin
				nstate = STATE_TT;
			end else begin
				nstate = STATE_T2;
			end
		end
		STATE_T2: begin
			if (ipin[IPIN_READY]|is_bimc) begin
				nstate = STATE_T3;
			end else begin
				nstate = STATE_TW;
			end
		end
		STATE_T3: begin
			if (is_init) begin
				nstate = STATE_T4;
			end else begin
				nstate = STATE_T1;
			end
		end
		STATE_T4: begin
			if (inst[INST_GO6]) begin
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
			if (ipin[IPIN_READY]|is_bimc) begin
				nstate = STATE_T3;
			end
		end
		STATE_TH: begin
			if (~ipin[IPIN_HOLD]) begin
				if (inst[INST_HLT]) nstate = STATE_TT;
				else nstate = STATE_T1;
			end
		end
		STATE_TT: begin
			if (ipin[IPIN_HOLD]) begin
				nstate = STATE_TH;
			end
			// valid interrupt can get us out back to circulation?
		end
	endcase
end

// state register - transition on negative edge!
always @(posedge clk_ or posedge rst_) begin // asynchronous reset, active low
	if(rst_ == 1) begin // actually active low
		cstate <= STATE_TR;
		// internal registers
		stactl <= CYCLE_OF; // always reset to opcode fetch cycle
		is_bimc <= 1'b0;
		is_last <= 1'b0;
		is_init <= 1'b1;
	end else begin
		cstate <= nstate;
		case (nstate)
			STATE_TR: begin
				stactl <= CYCLE_OF;
				is_bimc <= 1'b0;
				is_last <= 1'b0;
				is_init <= 1'b1;
			end
			STATE_T4: begin
				// check next machine cycle here?
				stactl <= CYCLE_OF;
				is_bimc <= 1'b0;
				is_last <= 1'b0;
				is_init <= 1'b1;
			end
		endcase
	end
end

endmodule
