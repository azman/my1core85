module alureg_tb ();

parameter DATASIZE = 8;
parameter CLKPTIME = 10;
parameter ADDRSIZE = 3;
parameter REGCOUNT = 2**ADDRSIZE;
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
parameter REG_B = 3'b000;
parameter REG_C = 3'b001;
parameter REG_D = 3'b010;
parameter REG_E = 3'b011;
parameter REG_H = 3'b100;
parameter REG_L = 3'b101;
parameter REG_M = 3'b110;
parameter REG_A = 3'b111;

reg clk, iENC, iEND, iRRD, iRWR;
reg[DATASIZE-1:0] iCOD, iDAT;

task reg_data;
	input iscode;
	input[DATASIZE-1:0] data;
	begin
		if (iscode) $display("[%04g] Issue code {%h}", $time,data);
		else $display("[%04g] Issue data {%h}", $time,data);
		iDAT = data;
		#(1*CLKPTIME); if (iscode) iENC = 1'b1; else iEND = 1'b1;
		#(1*CLKPTIME); iENC = 1'b0; iEND = 1'b0;
		if (iscode) begin
			$write("[%04g] Checking code {%h} => ", $time,
				dut.inst_reg.data_out);
			if (dut.inst_reg.data_out===data) $display("[OK]");
			else $display("[ERROR!]");
		end
		else begin
			$write("[%04g] Checking data {%h} => ", $time,
				dut.temp_reg.data_out);
			if (dut.temp_reg.data_out===data) $display("[OK]");
			else $display("[ERROR!]");
		end
	end
endtask

task reg_print;
	begin
		$write("[%04g] Registers [I:%h] [T:%h] ", $time,
			dut.inst_reg.data_out,dut.temp_reg.data_out);
		$write("[B:%h] [C:%h] [D:%h] [E:%h] ",
			dut.reg_block.reg_block[0].regs.data_out,
			dut.reg_block.reg_block[1].regs.data_out,
			dut.reg_block.reg_block[2].regs.data_out,
			dut.reg_block.reg_block[3].regs.data_out);
		$display("[H:%h] [L:%h] [F:%h] [A:%h]",
			dut.reg_block.reg_block[4].regs.data_out,
			dut.reg_block.reg_block[5].regs.data_out,
			dut.reg_block.reg_block[6].regs.data_out,
			dut.reg_block.reg_block[7].regs.data_out);
	end
endtask

task code_mvi;
	input[ADDRSIZE-1:0] reg_;
	input[DATASIZE-1:0] data;
	reg[DATASIZE-1:0] code;
	begin
		code = { 2'b01,reg_,3'b110 };
		reg_data(DO_CODE,code);
		reg_data(DO_DATA,data);
		#(1*CLKPTIME); iRRD = 1'b1;
		#(1*CLKPTIME); iRWR = 1'b1;
		#(1*CLKPTIME); iRWR = 1'b0; iRRD = 1'b0;
		$display("[%04g] MVI operation completed.",$time);
	end
endtask

task code_alu;
	input[2:0] opr_;
	input[ADDRSIZE-1:0] reg_;
	reg[DATASIZE-1:0] code;
	begin
		code = { 2'b10,opr_,reg_ };
		reg_data(DO_CODE,code);
		#(1*CLKPTIME); iRRD = 1'b1;
		#(1*CLKPTIME); iRWR = 1'b1;
		#(1*CLKPTIME); iRWR = 1'b0;
		$display("[%04g] ALU operation completed.",$time);
	end
endtask

task code_mov;
	input[ADDRSIZE-1:0] reg2,reg1;
	reg[DATASIZE-1:0] code;
	begin
		code = { 2'b01,reg2,reg1 };
		reg_data(DO_CODE,code);
		#(1*CLKPTIME); iRRD = 1'b1;
		#(1*CLKPTIME); iRWR = 1'b1;
		#(1*CLKPTIME); iRWR = 1'b0;
		$display("[%04g] MOV operation completed.",$time);
	end
endtask

// reset stuffs
initial begin
	clk = 1'b0; iENC = 1'b0; iEND = 1'b0;
	iRRD = 1'b0; iRWR = 1'b0; #(CLKPTIME*2);
end

// generate clock
always #(CLKPTIME/2) clk = !clk;

//generate stimuli
always begin
	$display("[%04g] Testing core ALU_REG module...", $time);
	#(CLKPTIME*4);
	reg_print;
	code_mvi(REG_A,8'b10101010);
	reg_print;
	code_mov(REG_B,REG_A);
	reg_print;
	code_alu(ALU_XOR,REG_A);
	reg_print;
	code_mov(REG_C,REG_A);
	reg_print;
	$finish;
end

defparam dut.DATASIZE = DATASIZE;
alureg dut (clk,iENC,iEND,iRRD,iRWR,iDAT);

endmodule
