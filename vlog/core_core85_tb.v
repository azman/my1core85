module core85_tb();

parameter CLKPTIME = 10;
parameter DATASIZE = dut.DATASIZE;
parameter ADDRSIZE = dut.ADDRSIZE;

reg clk, rst, ready, hold, sid, intr, trap, rst75, rst65, rst55;
wire[DATASIZE-1:0] addrdata;
wire[ADDRSIZE-1:DATASIZE] addr;
wire clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_, ale, hlda, sod;

// system memory
reg[DATASIZE-1:0] memory[(2**ADDRSIZE)-1:0];
reg[ADDRSIZE-1:0] mem_addr;
//integer loop;

// memory read
assign addrdata = (rd_===1'b0&&iom_===1'b0) ?
	memory[mem_addr] : {DATASIZE{1'bz}};

task reg_print;
	begin
		$write("[%04g] REGS: ", $time/CLKPTIME);
		$write("[B:%h] [C:%h] ", dut.proc.qdata[0], dut.proc.qdata[1]);
		$write("[D:%h] [E:%h] ", dut.proc.qdata[2], dut.proc.qdata[3]);
		$write("[H:%h] [L:%h] ", dut.proc.qdata[4], dut.proc.qdata[5]);
		$write("[F:%h] [A:%h] ", dut.proc.qdata[6], dut.proc.qdata[7]);
		$write("[I:%h] [T:%h] ", dut.proc.rinst, dut.proc.rtemp);
		$write("[PC:%h]\n", dut.proc.pcout);
	end
endtask

function[7:0] decode_reg;
	input[2:0] radd;
	reg[7:0] text;
	begin
		case(radd)
			3'b000: text = "b";
			3'b001: text = "c";
			3'b010: text = "d";
			3'b011: text = "e";
			3'b100: text = "h";
			3'b101: text = "l";
			3'b110: text = "m";
			3'b111: text = "a";
		endcase
		decode_reg = text;
	end
endfunction

task deassemble;
	input[7:0] inst;
	reg[8-1:0] text;
	begin
		$write("[%04g] ==> INSTRUCTION: ", $time/CLKPTIME);
		case(inst[7:6])
			2'b00: begin
				if (inst[2:0]===3'b110) begin
					$write("mvi %s,data8\n",decode_reg(inst[5:3]));
				end else if (inst[2:0]===3'b100) begin
					$write("inr %s\n",decode_reg(inst[5:3]));
				end else if (inst[2:0]===3'b101) begin
					$write("dcr %s\n",decode_reg(inst[5:3]));
				end else begin
					$write("UNKNOWN! %b\n",inst);
				end
			end
			2'b01: begin
				// mov instructions... plus hlt
				if (inst[5:3]===3'b110&&inst[2:0]===3'b110) begin
					$write("hlt\n");
				end else begin
					$write("mov %s, %s\n",decode_reg(inst[5:3]),
						decode_reg(inst[2:0]));
				end
			end
			2'b10: begin
				// alu instructions
				case(inst[5:3])
					3'b000: $write("add ");
					3'b001: $write("adc ");
					3'b010: $write("sub ");
					3'b011: $write("sbb ");
					3'b100: $write("ana ");
					3'b101: $write("xra ");
					3'b110: $write("ora ");
					3'b111: $write("cmp ");
				endcase
				$write("%s\n",decode_reg(inst[2:0]));
			end
			2'b11: begin
				if (inst[2:0]===3'b110) begin
					case(inst[5:3])
						3'b000: $write("adi ");
						3'b001: $write("aci ");
						3'b010: $write("sui ");
						3'b011: $write("sbi ");
						3'b100: $write("ani ");
						3'b101: $write("xri ");
						3'b110: $write("ori ");
						3'b111: $write("cpi ");
					endcase
					$write("data8\n");
				end else begin
					$write("UNKNOWN! %b\n",inst);
				end
			end
		endcase
	end
endtask

task mem_print;
	input[ADDRSIZE-1:0] addr;
	begin
		$write("[%04g] MEM@%h: %h %h %h %h\n", $time/CLKPTIME,
			addr, memory[addr], memory[addr+1],
			memory[addr+2], memory[addr+3]);
	end
endtask

// reset block
initial begin
	$readmemh("memory.txt",memory);
	//$display("[DEBUG] MEMORY LOADED");
	//for (loop=0;loop<8;loop=loop+1) begin
	//	$display("[DEBUG] %d:%h",loop,memory[loop]);
	//end
	clk = 1'b0; rst = 1'b1; // power-on reset
	#(CLKPTIME*3) rst = 1'b0; // 3-clock cycle reset
	$monitor("[%04g] STATE: %b {%b,%b} [%h][%h]",$time/CLKPTIME,
		dut.ctrl.cstate,dut.oenb,dut.opin,addr,addrdata);
end

// generate clock
always begin
	#(CLKPTIME/2) clk = !clk;
end

// memory address latch
always @(ale) begin
	if (ale) begin
		mem_addr =  { addr, addrdata };
	end
end

// memory writes
always @(wr_) begin
	if (wr_===1'b0&&iom_===1'b0) begin
		memory[mem_addr] = addrdata;
	end
end

// check on register value on every T1 state
always @(dut.ctrl.cstate[1]) begin
	if (dut.ctrl.cstate[1]) begin
		reg_print;
		mem_print(16'h2000);
	end
end

// detect instruction on every T4 state
always @(dut.ctrl.cstate[4]) begin
	if (dut.ctrl.cstate[4]) begin
		deassemble(dut.proc.rinst);
	end
end

// detect stop condition
always begin
	while (dut.proc.rinst!==8'h76) #1; // wait for halt instruction
	while (dut.ctrl.cstate[9]!==1'b1) #1; // wait for halt state
	$finish;
end

core85 dut (clk, ~rst, ready, hold, sid, intr, trap, rst75, rst65, rst55,
	addrdata, addr, clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_,
	ale, hlda, sod);

endmodule
