/**
 * common testbench stuffs for 8085 core
 *
 * - the expected module declaration and port definitions:
 *
module <name> ( CLK, RST_, READY, HOLD, SID, INTR, TRAP, RST75, RST65, RST55,
	ADDRDATA, ADDR, CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_,
	ALE, HLDA, SOD ); //VCC, VSS // power lines //X1, X2, // cystal input
input CLK, RST_, READY, HOLD, SID, INTR, TRAP, RST75, RST65, RST55;
inout[7:0] ADDRDATA;
output[15:8] ADDR;
output CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_, ALE, HLDA, SOD;
 *
 *
**/

// signals for 8085 core
reg clk, rst, ready, hold, sid, intr, trap, rst75, rst65, rst55;
wire[7:0] addrdata, addrhigh;
wire clk_out, rst_out, iom_, s1, s0, inta_, wr_, rd_, ale, hlda, sod;

// temp signal - to filter out other than 0->1 transitions (sim issue)
reg f_wr, f_rd, f_ia;
initial begin
	f_wr = 1'b0; f_rd = 1'b0; f_ia = 1'b0;
end
always @(negedge wr_) begin
	if (wr_===1'b0)	f_wr = 1'b1;
end
always @(negedge rd_) begin
	if (rd_===1'b0)	f_rd = 1'b1;
end
always @(negedge inta_) begin
	if (inta_===1'b0)	f_ia = 1'b1;
end

// memory model for 8085 testbench
reg[7:0] memory[(2**16)-1:0];
reg[15:0] mem_addr;
// memory address select
assign addrdata = (rd_===1'b0&&iom_===1'b0) ? memory[mem_addr] : 16'hzzzz;
// memory content setup
initial begin
	$readmemh("memory.txt",memory);
end
// memory address latch
always @(ale) begin
	if (ale) begin
		mem_addr =  { addrhigh, addrdata };
	end
end
// memory write
always @(posedge wr_) begin
	if (iom_===1'b0&&f_wr===1'b1) begin
		f_wr = 1'b0;
		$write("[%05g] WR MEM@%h: %h => ",$time,mem_addr,memory[mem_addr]);
		memory[mem_addr] = addrdata;
		$write("%h\n",memory[mem_addr]);
	end
end
// memory read
always @(posedge rd_) begin
	if (iom_===1'b0&&f_rd===1'b1) begin
		f_rd = 1'b0;
		$write("[%05g] RD MEM@%h: %h\n",$time,mem_addr,memory[mem_addr]);
	end
end

// i/o model for 8085 testbench
reg[7:0] dev_addr;
// device address select - returns device address on read
assign addrdata = (rd_===1'b0&&iom_===1'b1) ? dev_addr : 8'hzz;
// device address latch
always @(ale) begin
	if (ale===1'b1&&iom_===1'b1) begin
		dev_addr =  addrdata;
		if(addrdata!==addrhigh) // upper byte should be equal to low byte
			$write("[%05g] INVALID I/O? (%h:%h)\n",$time,addrhigh,addrdata);
	end
end
// device write
always @(posedge wr_) begin
	if (iom_===1'b1&&f_wr===1'b1) begin
		f_wr = 1'b0;
		$write("[%05g] WR DEV@%h => %h\n",$time,dev_addr,addrdata);
	end
end
// device read
always @(posedge rd_) begin
	if (iom_===1'b1&&f_rd===1'b1) begin
		f_rd = 1'b0;
		$write("[%05g] RD DEV@%h: %h\n", $time,dev_addr,dev_addr);
	end
end

// tasks/functions for 8085 testbench

task deassemble;
	input[7:0] inst;
	reg[8-1:0] text;
	begin
		$write("==> ");
		case(inst[7:6])
			2'b00: begin
				if (inst[2:0]===3'b000) begin
					case(inst[5:3])
						3'b000: $write("nop\n");
						3'b100: $write("rim\n");
						3'b110: $write("sim\n");
						default: begin
							$write("NOT USED!\n");
							$finish;
						end
					endcase
				end else if (inst[2:0]===3'b001) begin
					if (inst[3]) $write("dad %s\n",decode_rpr(inst[5:4]));
					else $write("lxi %s,dat16\n",decode_rpr(inst[5:4]));
				end else if (inst[2:0]===3'b010) begin
					case(inst[5:3])
						3'b000: $write("stax %s\n",decode_rpr(inst[5:4]));
						3'b001: $write("ldax %s\n",decode_rpr(inst[5:4]));
						3'b010: $write("stax %s\n",decode_rpr(inst[5:4]));
						3'b011: $write("ldax %s\n",decode_rpr(inst[5:4]));
						3'b100: $write("shld\n");
						3'b101: $write("lhld\n");
						3'b110: $write("sta add16\n");
						3'b111: $write("lda add16\n");
					endcase
				end else if (inst[2:0]===3'b011) begin
					if (inst[3]) $write("dcx %s\n",decode_rpr(inst[5:4]));
					else $write("inx %s\n",decode_rpr(inst[5:4]));
				end else if (inst[2:0]===3'b100) begin
					$write("inr %s\n",decode_reg(inst[5:3]));
				end else if (inst[2:0]===3'b101) begin
					$write("dcr %s\n",decode_reg(inst[5:3]));
				end else if (inst[2:0]===3'b110) begin
					$write("mvi %s,data8\n",decode_reg(inst[5:3]));
				end else if (inst[2:0]===3'b111) begin
					case(inst[5:3])
						3'b000: $write("rlc\n");
						3'b001: $write("rrc\n");
						3'b010: $write("ral\n");
						3'b011: $write("rar\n");
						3'b100: $write("daa\n");
						3'b101: $write("cma\n");
						3'b110: $write("stc\n");
						3'b111: $write("cmc\n");
					endcase
				end else begin
					$write("INVALID!\n");
					$finish;
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
				if (inst[2:0]===3'b000) begin
					$write("r%s\n",decode_ccc(inst[5:3]));
				end else if (inst[2:0]===3'b010) begin
					$write("j%s add16\n",decode_ccc(inst[5:3]));
				end else if (inst[2:0]===3'b100) begin
					$write("c%s add16\n",decode_ccc(inst[5:3]));
				end else if (inst[2:0]===3'b110) begin
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
				end else if (inst[2:0]===3'b001) begin
					case(inst[5:3])
						3'b000: $write("pop %s\n",decode_rpx(inst[5:4]));
						3'b001: $write("ret\n");
						3'b010: $write("pop %s\n",decode_rpx(inst[5:4]));
						3'b011: begin $write("NOT USED!\n"); $finish; end
						3'b100: $write("pop %s\n",decode_rpx(inst[5:4]));
						3'b101: $write("pchl\n");
						3'b110: $write("pop %s\n",decode_rpx(inst[5:4]));
						3'b111: $write("sphl\n");
					endcase
				end else if (inst[2:0]===3'b011) begin
					case(inst[5:3])
						3'b000: $write("jmp add16\n");
						3'b001: begin $write("NOT USED!\n"); $finish; end
						3'b010: $write("out port8\n");
						3'b011: $write("in port8\n");
						3'b100: $write("xthl\n");
						3'b101: $write("xchg\n");
						3'b110: $write("di\n");
						3'b111: $write("ei\n");
					endcase
				end else if (inst[2:0]===3'b101) begin
					case(inst[5:3])
						3'b000: $write("push %s\n",decode_rpx(inst[5:4]));
						3'b001: $write("call add16\n");
						3'b010: $write("push %s\n",decode_rpx(inst[5:4]));
						3'b011: begin $write("NOT USED!\n"); $finish; end
						3'b100: $write("push %s\n",decode_rpx(inst[5:4]));
						3'b101: begin $write("NOT USED!\n"); $finish; end
						3'b110: $write("push %s\n",decode_rpx(inst[5:4]));
						3'b111: begin $write("NOT USED!\n"); $finish; end
					endcase
				end else if (inst[2:0]===3'b111) begin
					$write("rst %g\n",inst[5:3]);
				end else begin
					$write("INVALID!\n");
					$finish;
				end
			end
		endcase
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

function[2*8-1:0] decode_rpr;
	input[1:0] radd;
	reg[2*8-1:0] text;
	begin
		case(radd)
			2'b00: text = "b ";
			2'b01: text = "d ";
			2'b10: text = "h ";
			2'b11: text = "sp";
		endcase
		decode_rpr = text;
	end
endfunction

function[3*8-1:0] decode_rpx;
	input[1:0] radd;
	reg[3*8-1:0] text;
	begin
		case(radd)
			2'b00: text = "b  ";
			2'b01: text = "d  ";
			2'b10: text = "h  ";
			2'b11: text = "psw";
		endcase
		decode_rpx = text;
	end
endfunction

function[2*8-1:0] decode_ccc;
	input[2:0] cond;
	reg[2*8-1:0] text;
	begin
		case(cond)
			3'b000: text = "nz";
			3'b001: text = "z ";
			3'b010: text = "nc";
			3'b011: text = "c ";
			3'b100: text = "po";
			3'b101: text = "pe";
			3'b110: text = "p ";
			3'b111: text = "m ";
		endcase
		decode_ccc = text;
	end
endfunction

function[7:0] reg8_name;
	input[2:0] radd;
	reg[7:0] text;
	begin
		case(radd)
			3'b000: text = "B";
			3'b001: text = "C";
			3'b010: text = "D";
			3'b011: text = "E";
			3'b100: text = "H";
			3'b101: text = "L";
			3'b110: text = "F";
			3'b111: text = "A";
		endcase
		reg8_name = text;
	end
endfunction
