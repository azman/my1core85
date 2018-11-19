module register (clk, rst, enb, idata, odata);

parameter DATASIZE = 8;

input clk, rst, enb;
input[DATASIZE-1:0] idata;
output[DATASIZE-1:0] odata;
reg[DATASIZE-1:0] odata;

always @(posedge clk or posedge rst)  // asynchronous reset!?
begin
	if (rst==1) begin
		odata <= {DATASIZE{1'b0}};
	end else begin
		if (enb==1) odata <= idata;
	end
end

endmodule
