module alureg_tb ();

parameter CLKPTIME = 10;
parameter DATASIZE = dut.DATASIZE;
parameter ADDRSIZE = dut.ADDRSIZE;
parameter REGSBITS = dut.REGSBITS;
parameter INSTSIZE = dut.INSTSIZE;
parameter IENB_COD = dut.IENB_COD;
parameter IENB_DAT = dut.IENB_DAT;
parameter IENB_PC_ = dut.IENB_PC_;
parameter IENB_PD_ = dut.IENB_PD_;
parameter IENB_RRD = dut.IENB_RRD;
parameter IENB_RWR = dut.IENB_RWR;
parameter IENBSIZE = dut.IENBSIZE;
parameter REG_B = dut.REG_B;
parameter REG_C = dut.REG_C;
parameter REG_D = dut.REG_D;
parameter REG_E = dut.REG_E;
parameter REG_H = dut.REG_H;
parameter REG_L = dut.REG_L;
parameter REG_M = dut.REG_F;
parameter REG_A = dut.REG_A;
parameter DO_DATA = 0;
parameter DO_CODE = 1;
parameter ALU_ADD = 3'b000;
parameter ALU_ADC = 3'b001;
parameter ALU_SUB = 3'b010;
parameter ALU_SBB = 3'b011;
parameter ALU_AND = 3'b100;
parameter ALU_XOR = 3'b101;
parameter ALU_ORR = 3'b110;
parameter ALU_CMP = 3'b111;

reg clk, rst, enbrr, enbwr, enb_c, enb_d;
reg[DATASIZE-1:0] bus_d;
wire[DATASIZE-1:0] bus_q;
wire[INSTSIZE-1:0] chk_i;
wire[ADDRSIZE-1:0] chk_a;
wire[IENBSIZE-1:0] ienb;

assign ienb[IENB_COD] = enb_c;
assign ienb[IENB_DAT] = enb_d;
assign ienb[IENB_PC_] = 1'b0;
assign ienb[IENB_PD_] = 1'b0;
assign ienb[IENB_RRD] = enbrr;
assign ienb[IENB_RWR] = enbwr;

task reg_data;
	input iscode;
	input[DATASIZE-1:0] data;
	reg[8*4-1:0] text;
	begin
		if (iscode) text = "code";
		else text = "data";
		$display("[%04g] Issue %s {%h}",$time,text,data);
		bus_d = data;
		#(1*CLKPTIME); if (iscode) enb_c = 1'b1; else enb_d = 1'b1;
		#(1*CLKPTIME); enb_c = 1'b0; enb_d = 1'b0;
		if (iscode) begin
			if (dut.rinst!==data) begin
				$write("[%04g] Checking code {%h} => ",$time,dut.rinst);
				$display("[ERROR!]");
			end
		end
		else begin
			if (dut.rtemp!==data) begin
				$write("[%04g] Checking data {%h} => ",$time,dut.rtemp);
				$display("[ERROR!]");
			end
		end
	end
endtask

task reg_print;
	begin
		$write("[%04g] Registers [I:%h] [T:%h] ", $time,
			dut.inst_reg.odata,dut.temp_reg.odata);
		$write("[B:%h] [C:%h] [D:%h] [E:%h] ",
			dut.qdata[0], dut.qdata[1], dut.qdata[2], dut.qdata[3]);
		$display("[H:%h] [L:%h] [F:%h] [A:%h]",
			dut.qdata[4], dut.qdata[5], dut.qdata[6], dut.qdata[7]);
	end
endtask

task code_mvi;
	input[REGSBITS-1:0] reg_;
	input[DATASIZE-1:0] data;
	reg[DATASIZE-1:0] code;
	begin
		code = { 2'b00,reg_,3'b110 };
		reg_data(DO_CODE,code);
		reg_data(DO_DATA,data);
		#(1*CLKPTIME); enbrr = 1'b1;
		#(1*CLKPTIME); enbwr = 1'b1;
		#(1*CLKPTIME); enbwr = 1'b0; enbrr = 1'b0;
		$display("[%04g] MVI operation completed.",$time);
	end
endtask

task code_alu;
	input[2:0] opr_;
	input[REGSBITS-1:0] reg_;
	reg[DATASIZE-1:0] code;
	begin
		code = { 2'b10,opr_,reg_ };
		reg_data(DO_CODE,code);
		#(1*CLKPTIME); enbrr = 1'b1;
		#(1*CLKPTIME); enbwr = 1'b1;
		#(1*CLKPTIME); enbwr = 1'b0;
		$display("[%04g] ALU operation completed.",$time);
	end
endtask

task code_mov;
	input[REGSBITS-1:0] reg2,reg1;
	reg[DATASIZE-1:0] code;
	begin
		code = { 2'b01,reg2,reg1 };
		reg_data(DO_CODE,code);
		#(1*CLKPTIME); enbrr = 1'b1;
		#(1*CLKPTIME); enbwr = 1'b1;
		#(1*CLKPTIME); enbwr = 1'b0;
		$display("[%04g] MOV operation completed.",$time);
	end
endtask

// reset stuffs
initial begin
	clk = 1'b0; rst = 1'b1; enb_c = 1'b0; enb_d = 1'b0;
	enbrr = 1'b0; enbwr = 1'b0; #(CLKPTIME*2); rst = 1'b0;
	$monitor("[%04g] CHK_I={%b} PC={%b}",$time,chk_i,chk_a);
end

// generate clock
always #(CLKPTIME/2) clk = !clk;

//generate stimuli
always begin
	$display("[%04g] Testing core ALU_REG module...", $time);
	#(CLKPTIME*4);
	reg_print;
	$display("[%04g] Executing: MVI A, %bb",$time,8'b10101010);
	code_mvi(REG_A,8'b10101010);
	reg_print;
	$display("[%04g] Executing: MOV B, A",$time);
	code_mov(REG_B,REG_A);
	reg_print;
	$display("[%04g] Executing: XRA A",$time);
	code_alu(ALU_XOR,REG_A);
	reg_print;
	$display("[%04g] Executing: MOV C, A",$time);
	code_mov(REG_C,REG_A);
	reg_print;
	$finish;
end

alureg dut (clk,rst,ienb,bus_d,bus_q,chk_i,chk_a);

endmodule
