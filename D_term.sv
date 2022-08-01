module D_term(clk, rst_n, err_vld, err_sat, D_term);

localparam signed D_COEFF = 6'h0B;

input clk, rst_n, err_vld;
input signed [9:0] err_sat;				//error term//
output logic signed [12:0] D_term; 			//derivative term//

logic signed [9:0] intermediate, prev_err, D_diff;
logic signed [6:0] D_diff_sat;

always_ff@(posedge clk, negedge rst_n)		//holds previous err_sat term//
	if(!rst_n) begin
	intermediate <= 0;
	prev_err <= 0; end
	else if (err_vld) begin
	intermediate <= err_sat;
	prev_err <= intermediate; end

assign D_diff = err_sat - prev_err;		//derivative difference term//

assign D_diff_sat = (!D_diff[9] && |D_diff[8:6]) ? 7'h3F:
	(D_diff[9] && !(&D_diff[8:6])) ? 7'h40:
	D_diff[6:0];

assign D_term = D_diff_sat * D_COEFF;

endmodule 
