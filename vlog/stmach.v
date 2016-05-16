module stmach (clock, reset, codein, status);
input clock,reset;
input[7:0] codein; // code instructions
output[2:0] status; // machine cycle types (output pin!)
reg[2:0] status; // regged to maintain value through cycles

// internal registers & nodes
reg[3:0] state; // 4-bit encoded states = 6+4 used states
// 0 - RESET State, 1:6 - State 1 to State 6
// 7 - HOLD State, 9 - HALT State, 10 - WAIT State
reg bimc, halt, lmc, fmc, go6;
wire[15:0] decstate; // decoded states - active high
wire[8:0] tmpstate; // tmp nxtstate values (T10 to T0,T9 to T8)
wire[3:0] nxstate; // encoded calculated next state values

// state machine trigger

always @(posedge clock or reset)
begin
	if(reset == 1) // actually active low
	begin
		state <= 4'b0; // goto state T0
		// FIND!: how many clocks in RESET states??
		status <= 0; // opcode fetch cycle
		outpin <= 0; // actually active low? - invert!
		bimc <= 0; // not bus idle cycle
		halt <= 0; // no halt
		lmc <= 0; // not last cycle
		fmc <= 1; // is first cycle
		go6 <= 0; // not 6-state cycle
	end
	else
	begin
		state <= nxstate;
		// internal register & node updates??
		//status <= 0; // opcode fetch cycle
		//outpin <= 0; // actually active low? - invert!
		//bimc <= 0; // not bus idle cycle
		halt <= 0; // no halt
		lmc <= 0; // not last cycle
		fmc <= 1; // is first cycle
		go6 <= 0; // not 6-state cycle
	end
end

// state selection logic

assign tmpstate[0] = decstate[2] & ~(inpin[0] | bimc); // wait state
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
assign tmpstate[8] = decstate[1] & halt; // halt state

assign nxstate[0] = tmpstate[1] | tmpstate[3] | tmpstate[5] |
	tmpstate[7] | tmpstate[8];
assign nxstate[1] = tmpstate[2] | tmpstate[3] | tmpstate[6] |
	tmpstate[7] | tmpstate[0];
assign nxstate[2] = tmpstate[4] | tmpstate[5] | tmpstate[6] | tmpstate[7];
assign nxstate[3] = tmpstate[8] | tmpstate[0];

// output assignment

decode4b decst (state,decstate); // not all output used

endmodule