module zbuffer ( enable, idata, odata );

parameter DATASIZE=8;

input enable;
input[DATASIZE-1:0] idata;
output[DATASIZE-1:0] odata;
wire[DATASIZE-1:0] odata;

assign odata = (enable==1)? idata : {DATASIZE{1'bZ}};

endmodule
