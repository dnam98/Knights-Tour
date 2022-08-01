module I_term(
	input clk, rst_n, err_vld, moving,
	input [9:0] err_sat,
	output [8:0] I_term
);
	logic[14:0] err_sat_ext, integrator, add_rslt;
	logic ov, mux1_select;

assign err_sat_ext = {{5{err_sat[9]}}, err_sat};
assign add_rslt = err_sat_ext + integrator;
assign ov = !(err_sat_ext [14] ^ integrator [14]) & (err_sat_ext [14] ^ add_rslt [14]);
assign mux1_select=!ov & err_vld;
	
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		integrator <= 15'h0000;
	else if (!moving)
		integrator <= 15'h0;
	else if (mux1_select)
		integrator <= add_rslt;

assign I_term=integrator[14:6];

endmodule