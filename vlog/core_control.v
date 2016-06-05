module control (clk, rst, code, ipin, opin);

parameter DATASIZE=8;
parameter STATE_TR=4'b0000; // reset state
parameter STATE_T1=4'b0001; // state 1
parameter STATE_T2=4'b0010; // state 2
parameter STATE_T3=4'b0011; // state 3
parameter STATE_T4=4'b0100; // state 4
parameter STATE_T5=4'b0101; // state 5
parameter STATE_T6=4'b0110; // state 6
parameter STATE_TH=4'b0111; // hold state
parameter STATE_TW=4'b1000; // wait state
parameter STATE_TT=4'b1001; // halt state
parameter STAT_OF=3'b000; // opcode fetch cycle
parameter IPIN_READY=0;
parameter IPIN_HOLD=1;
parameter IPIN_COUNT=2;
parameter OPIN_S0=0;
parameter OPIN_S1=1;
parameter OPIN_IOM_=2;
parameter OPIN_COUNT=3;

input clk,rst;
input[DATASIZE-1:0] code; // code from Instruction Register
input[IPIN_COUNT-1:0] ipin;
output[OPIN_COUNT-1:0] opin;
wire[OPIN_COUNT-1:0] opin;

// internal registers & nodes
reg[3:0] cstate; // 4-bit encoded states = 6+4 used states
reg[2:0] stat;
reg bimc, halt, lmc, fmc, go6;
reg[3:0] nstate; // encoded calculated next state values

// direct reg to pin
assign opin[2:0] = stat;

// state machine trigger
always @(posedge clk or posedge rst)  // asynchronous reset!?
begin
	if(rst == 1) begin // actually active low
		cstate <= STATE_TR;
		// internal register & node updates??
		stat <= STAT_OF;
		bimc <= 0; // not bus idle cycle
		halt <= 0; // no halt
		lmc <= 0; // not last cycle
		fmc <= 1; // is first cycle
		go6 <= 0; // not 6-state cycle
	end
	else begin
		cstate <= nstate;
	end
end

// state selection logic
always @(cstate or ipin of stat or bimc or halt or lmc or fmc or go6)
begin
	case (cstate)
		STATE_TR: begin
			// FIND!: how many clocks in RESET states??
			nstate <= STATE_T1;
		end
		STATE_T1: begin
			if (halt) begin
				nstate <= STATE_TH;
			end
			else begin
				nstate <= STATE_T2;
			end
		end
		STATE_T2: begin
			if (~(ipin[IPIN_READY]|bimc)) begin
				nstate <= STATE_TW;
			end
			else begin
				nstate <= STATE_T3;
			end
		end
		STATE_T3: begin
			nstate <= STATE_T3;
		end
		STATE_TW: begin
			if (ipin[IPIN_READY]|bimc) begin
				nstate <= STATE_T1;
			end
		end
	endcase
end

assign tmpstate[1] = decstate[0] | (((decstate[3] & ~fmc) |
	(decstate[4] & ~go6) | decstate[6]) & (~lmc | ~outpin[0]));
assign tmpstate[2] = decstate[1];
assign tmpstate[3] = (decstate[2] | decstate[10]) &
	(inpin[0] | bimc);
assign tmpstate[4] = decstate[3] & fmc;
assign tmpstate[5] = decstate[4] & go6;
assign tmpstate[6] = decstate[5];
assign tmpstate[7] = ((decstate[3] & ~fmc) | (decstate[4] & ~go6) |
	decstate[6]) & lmc & outpin[0] ; // hold state

assign nxstate[0] = tmpstate[1] | tmpstate[3] | tmpstate[5] |
	tmpstate[7] | tmpstate[8];
assign nxstate[1] = tmpstate[2] | tmpstate[3] | tmpstate[6] |
	tmpstate[7] | tmpstate[0];
assign nxstate[2] = tmpstate[4] | tmpstate[5] | tmpstate[6] | tmpstate[7];
assign nxstate[3] = tmpstate[8] | tmpstate[0];

// output assignment

endmodule
