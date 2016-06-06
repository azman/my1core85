module control (clk, rst, code, ipin, opin);

parameter DATASIZE = 8;
parameter STATE_TR = 4'b0000; // reset state
parameter STATE_T1 = 4'b0001; // state 1
parameter STATE_T2 = 4'b0010; // state 2
parameter STATE_T3 = 4'b0011; // state 3
parameter STATE_T4 = 4'b0100; // state 4
parameter STATE_T5 = 4'b0101; // state 5
parameter STATE_T6 = 4'b0110; // state 6
parameter STATE_TH = 4'b0111; // hold state
parameter STATE_TW = 4'b1000; // wait state
parameter STATE_TT = 4'b1001; // halt state
parameter STAT_OF = 3'b011; // opcode fetch
parameter STAT_MW = 3'b001; // memory write
parameter STAT_MR = 3'b010; // memory read
parameter STAT_DW = 3'b101; // device write
parameter STAT_DR = 3'b110; // device read
parameter STAT_INTA = 3'b111; // interrupt acknowledge
parameter STAT_HALT = 3'bz00; // halt
parameter STAT_HRST = 3'bzxx; // hold/reset
parameter IPIN_READY = 0;
parameter IPIN_HOLD = 1;
parameter IPIN_COUNT = 2;
parameter OPIN_S0 = 0;
parameter OPIN_S1 = 1;
parameter OPIN_IOM_ = 2;
parameter OPIN_HLDA = 3;
parameter OPIN_RD_ = 4;
parameter OPIN_WR_ = 5;
parameter OPIN_INTA_ = 6;
parameter OPIN_ALE = 7;
parameter OPIN_COUNT = 8;

input clk,rst;
input[DATASIZE-1:0] code; // code from Instruction Register
input[IPIN_COUNT-1:0] ipin;
output[OPIN_COUNT-1:0] opin;
wire[OPIN_COUNT-1:0] opin;

// internal registers & nodes
reg[3:0] cstate; // 4-bit encoded states = 6+4 used states
reg[2:0] stat, ctrl; // stat:{io/m_,s1,s0} , ctrl:{inta_,wr_,rd_}
reg hlda, ale, bimc, halt, lmc, fmc, go6, putZ;
reg[3:0] nstate; // encoded calculated next state values

// direct reg to pin
assign opin[OPIN_S0] = stat[0];
assign opin[OPIN_S1] = stat[1];
assign opin[OPIN_IOM_] = putZ ? 1'bz : stat[2];
assign opin[OPIN_HLDA] = hlda;
assign opin[OPIN_INTA_] = ctrl[2];
assign opin[OPIN_WR_] = putZ ? 1'bz : ctrl[1];
assign opin[OPIN_RD_] = putZ ? 1'bz : ctrl[2];

// state machine trigger
always @(posedge clk or posedge rst)  // asynchronous reset!?
begin
	if(rst == 1) begin // actually active low
		// should remain low for 10ms after min vcc
		// 3 clock cycles for correct reset operation?
		cstate <= STATE_TR;
		// internal register & node updates??
		stat <= STAT_OF;
		ctrl <= 3'b111; // inta_:hi, wr_:hi, rd_:hi
		hlda <= 1'b0;
		ale <= 1'b0;
		bimc <= 1'b0; // not bus idle cycle
		halt <= 1'b0; // no halt
		lmc <= 1'b0; // not last cycle
		fmc <= 1'b1; // is first cycle
		go6 <= 1'b0; // not 6-state cycle
		putZ <= 1'b1; // high when in reset/hold/halt states
	end
	else begin
		cstate <= nstate;
		case (cstate)
			STATE_T2:
				hlda <= 1'b0;
		endcase
		case (nstate)
			STATE_TR: begin
				stat <= STAT_OF;
				ctrl <= 3'b111; // inta_:hi, wr_:hi, rd_:hi
				hlda <= 1'b0;
				ale <= 1'b0;
				bimc <= 1'b0; // not bus idle cycle
				halt <= 1'b0; // no halt
				lmc <= 1'b0; // not last cycle
				fmc <= 1'b1; // is first cycle
				go6 <= 1'b0; // not 6-state cycle
				putZ <= 1'b1; // high when in reset/hold/halt states
			end
			STATE_T1: begin
				hlda <= 1'b0;
				ale <= 1'b1; // except 2nd/3rd cycle of DAD
			end
			STATE_T2: begin
				hlda <= 1'b0;
			end
			STATE_T3: begin
				hlda <= 1'b0;
			end
			STATE_T4: begin
				hlda <= 1'b0;
			end
			STATE_T5: begin
				hlda <= 1'b0;
			end
			STATE_T6: begin
				hlda <= 1'b0;
			end
			STATE_TW: begin
				hlda <= 1'b0;
			end
			STATE_TH: begin
				hlda <= 1'b1;
			end
			STATE_TT: begin
				hlda <= 1'b0;
			end
		endcase
	end
end

// state selection logic
always @(cstate or ipin or stat or bimc or halt or lmc or fmc or go6)
begin
	case (cstate)
		STATE_TR: begin
			nstate <= STATE_T1;
		end
		STATE_T1: begin
			if (halt) begin
				nstate <= STATE_TT;
			end
			else begin
				nstate <= STATE_T2;
			end
		end
		STATE_T2: begin
			if (ipin[IPIN_READY]|bimc) begin
				nstate <= STATE_T3;
			end
			else begin
				nstate <= STATE_TW;
			end
		end
		STATE_T3: begin
			if (fmc) begin
				nstate <= STATE_T4;
			end
			else begin
				nstate <= STATE_T1;
			end
		end
		STATE_T4: begin
			if (go6) begin
				nstate <= STATE_T5;
			end
			else begin
				nstate <= STATE_T1;
			end
		end
		STATE_T5: begin
			nstate <= STATE_T6;
		end
		STATE_T6: begin
			nstate <= STATE_T1;
		end
		STATE_TW: begin
			if (ipin[IPIN_READY]|bimc) begin
				nstate <= STATE_T3;
			end
		end
		STATE_TH: begin
			if (~ipin[IPIN_HOLD]) begin
				if (halt) nstate <= STATE_TT;
				else nstate <= STATE_T1;
			end
		end
		STATE_TT: begin
			if (ipin[IPIN_HOLD]) begin
				nstate <= STATE_TH;
			end
		end
	endcase
end

// output assignment

endmodule
