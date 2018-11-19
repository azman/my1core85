module io8255_tb ();

parameter MYCLKP = 10;
parameter DATASIZE = 8;
parameter ADDRSIZE = 2;

reg clk, rst, rd_, wr_, cs_;
reg[ADDRSIZE-1:0] addr;
reg[DATASIZE-1:0] data_chk;
wire[DATASIZE-1:0] chkA, chkB, chkC, data;

assign data = (wr_==1'b0) ? data_chk : {DATASIZE{1'bZ}};

task put_data;
	input[DATASIZE-1:0] that;
	input[ADDRSIZE-1:0] port; // 00-PA,01-PB,10-PC,11-CP
	integer loop;
	begin
		$write("[%04g] Sending data {%h} to ", $time,that);
		case(port)
			2'b00: $write("Port A\n");
			2'b01: $write("Port B\n");
			2'b10: $write("Port C\n");
			2'b11: $write("Control Port\n");
			default: begin
				$write("INVALID!\n");
				$finish;
			end
		endcase
		addr = port;
		#(1*MYCLKP); data_chk = that; wr_ = 1'b0;
		#(1*MYCLKP); wr_ = 1'b1;
	end
endtask

// monitor change in latch value
always @(chkA) begin
	$strobe("[%04g] Port A: {%h}",$time, chkA);
end
always @(chkB) begin
	$strobe("[%04g] Port B: {%h}",$time, chkB);
end
always @(chkC) begin
	$strobe("[%04g] Port C: {%h}",$time, chkC);
end
always @(dut.outS) begin
	$strobe("[%04g] CtlReg: {%h}",$time, dut.outS);
end
always @(data) begin
	$strobe("[%04g] Data Bus: {%h}",$time, data);
end

// reset stuffs
initial begin
	clk = 1'b0; rst = 1'b0;
	cs_ = 1'b0; wr_ = 1'b1; rd_ = 1'b1; // always selected! deassert wr/rd!
	data_chk = {DATASIZE{1'b1}};
	#(1*MYCLKP) rst = 1'b0;
	#(3*MYCLKP) rst = 1'b1;
	$display("[%04g] RESET BEGIN", $time);
	#(3*MYCLKP) rst = 1'b0;
	$display("[%04g] RESET END", $time);
end

// generate clock
always #(MYCLKP/2) clk = !clk;

//generate stimuli
always begin
	#(8*MYCLKP)
	$display("[%04g] Writing 0x80 to CtReg...", $time);
	put_data(8'h80,2'b11);
	#(1*MYCLKP)
	$display("[%04g] Writing 0x55 to Reg A...", $time);
	put_data(8'h55,2'b00);
	#(1*MYCLKP)
	$display("[%04g] Writing 0xAA to Reg B...", $time);
	put_data(8'haa,2'b01);
	#(1*MYCLKP)
	$display("[%04g] Writing 0x55 to Reg C...", $time);
	put_data(8'h55,2'b10);
	$finish;
end

// dut
io8255 dut (rst, wr_, rd_, cs_, addr, data, chkA, chkB, chkC);

endmodule
