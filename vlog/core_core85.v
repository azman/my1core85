module core85 ( CLK, RST_, READY, HOLD, SID, INTR, TRAP, RST75, RST65, RST55,
	ADDRDATA, ADDR, CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_,
	ALE, HLDA, SOD );
//VCC, VSS // power lines
//X1, X2, // cystal input

parameter DATASIZE = proc.DATASIZE;
parameter ADDRSIZE = proc.ADDRSIZE;

input CLK, RST_, READY, HOLD, SID, INTR, TRAP, RST75, RST65, RST55;
inout[DATASIZE-1:0] ADDRDATA;
output[ADDRSIZE-1:DATASIZE] ADDR;
output CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_, ALE, HLDA, SOD;

wire[DATASIZE-1:0] ADDRDATA;
wire[ADDRSIZE-1:DATASIZE] ADDR;
wire CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_, ALE, HLDA, SOD;

wire[ctrl.IPIN_COUNT-1:0] ipin;
wire[ctrl.OENB_COUNT-1:0] oenb;
wire[ctrl.OPIN_COUNT-1:0] opin;
wire[DATASIZE-1:0] bus_d;
wire[proc.INSTSIZE-1:0] chk_i;
wire[ADDRSIZE-1:0] outpc;

assign bus_d = (oenb[ctrl.OENB_ADDL]|oenb[ctrl.OENB_DATA]) ?
	{DATASIZE{1'b0}} : ADDRDATA;
// temporarily disabled?
assign ipin[ctrl.IPIN_READY] = 1'b1; // always ready! READY;
assign ipin[ctrl.IPIN_HOLD] = 1'b0; // no holding! HOLD;

// assign output pins
assign CLK_OUT = CLK; // simply pass
assign RST_OUT = ~RST_; // simply pass
assign IOM_ = opin[ctrl.OPIN_IOM_];
assign S1 = opin[ctrl.OPIN_S1];
assign S0 = opin[ctrl.OPIN_S0];
assign INTA_ = opin[ctrl.OPIN_INTA_];
assign WR_ = opin[ctrl.OPIN_WR_];
assign RD_ = opin[ctrl.OPIN_RD_];
assign ALE = opin[ctrl.OPIN_ALE];
// not implementing these for now
assign HLDA = 1'b0;
assign SOD = 1'b0;

control ctrl (~CLK, ~RST_, chk_i, ipin, oenb, opin);
alureg proc (CLK,~RST_,enb_c,enb_d,enbpc,enbrr,enbwr,bus_d,chk_i,outpc);

endmodule
