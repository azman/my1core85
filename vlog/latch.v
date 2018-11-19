module latch ( rst, enb, data_in, data_out );

parameter DATASIZE=8;
parameter ACTLEVEL=1;

input rst, enb;
input[DATASIZE-1:0] data_in;
output[DATASIZE-1:0] data_out;
reg[DATASIZE-1:0] data_out;

always @(rst or enb)  // asynchronous reset!?
begin
	if (rst==1)
	begin
		data_out <= {DATASIZE{1'b0}};
	end
	else
	begin
		if (enb==ACTLEVEL) data_out <= data_in;
	end
end

endmodule
