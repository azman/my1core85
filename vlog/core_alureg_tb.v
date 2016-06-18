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

reg clk, rst, enb_c, enb_d, enbrr, enbwr;
reg[DATASIZE-1:0] bus_d;
wire[dut.INSTSIZE-1:0] chk_i;
wire[DATASIZE*2-1:0] outpc;

task reg_data;
	input iscode;
	input[DATASIZE-1:0] data;
	begin
		if (iscode) $display("[%04g] Issue code {%h}", $time,data);
		else $display("[%04g] Issue data {%h}", $time,data);
		bus_d = data;
		#(1*CLKPTIME); if (iscode) enb_c = 1'b1; else enb_d = 1'b1;
		#(1*CLKPTIME); enb_c = 1'b0; enb_d = 1'b0;
		if (iscode) begin
			$write("[%04g] Checking code {%h} => ", $time,
				dut.inst_reg.odata);
			if (dut.inst_reg.odata===data) $display("[OK]");
			else $display("[ERROR!]");
		end
		else begin
			$write("[%04g] Checking data {%h} => ", $time,
				dut.temp_reg.odata);
			if (dut.temp_reg.odata===data) $display("[OK]");
			else $display("[ERROR!]");
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
	input[ADDRSIZE-1:0] reg_;
	input[DATASIZE-1:0] data;
	reg[DATASIZE-1:0] code;
	begin
		code = { 2'b01,reg_,3'b110 };
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
	input[ADDRSIZE-1:0] reg_;
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
	input[ADDRSIZE-1:0] reg2,reg1;
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
	$monitor("[%04g] CHK_I={%b} PC={%b}",$time,chk_i,outpc);
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

alureg dut (clk,rst,enb_c,enb_d,1'b1,enbrr,enbwr,bus_d,chk_i,outpc);

endmodule
