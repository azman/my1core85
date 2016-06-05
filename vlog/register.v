module register ( clk, rst, enb, data_in, data_out );

parameter DATASIZE=8;

input clk, rst, enb;
input[DATASIZE-1:0] data_in;
output[DATASIZE-1:0] data_out;
reg[DATASIZE-1:0] data_out;

always @(posedge clk or posedge rst)  // asynchronous reset!?
begin
	if (rst==1)
	begin
		data_out <= {DATASIZE{1'b0}};
	end
	else
	begin
		if (enb==1) data_out <= data_in;
	end
end

endmodule
