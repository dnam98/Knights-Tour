module PID(clk, rst_n, moving, err_vld, error, frwrd, lft_spd, rght_spd);
	input clk, rst_n, moving, err_vld;
	input signed [11:0] error;
	input [9:0] frwrd;
	output signed [10:0] lft_spd, rght_spd;
	
	// P_term
	// intermediate signals
	logic signed [9:0] err_sat;
	logic signed [13:0] P_term;
	logic signed [13:0] P_term_pf;
	localparam signed P_COEFF = 5'h8; // 0 1000 (8)
	
	// I_term
	// intermediate signals
	logic [14:0]err_sat_ext;
	logic [14:0]sum_term;
	logic [14:0]integrator;
	logic [14:0]nxt_integrator;
	logic [14:0]poss_nxt_integrator;
	logic OV, mux_0;
	logic signed [8:0]I_term;
	logic signed [13:0] I_term_se;
	logic signed [13:0] I_term_se_pf;
	
	// D_term
	// intermediate signals
	logic signed [9:0] flopQ1, flopQ2;
	logic signed [9:0] D_diff;
	logic signed [6:0] saturated;
	logic signed [12:0] D_term;
	logic signed [13:0] D_term_se;
	logic signed [13:0] D_term_se_pf;
	localparam signed D_COEFF = 6'sh0B;
	
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			flopQ1 <= 0;
		else if(err_vld)
			flopQ1 <= err_sat;
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			flopQ2 <= 0;
		else if(err_vld)
			flopQ2 <= flopQ1;
		
	assign D_diff = err_sat - flopQ2;
	
	assign saturated = D_diff[9] && ~&(D_diff[8:6]) ? 7'sb1000000 : // -64
				 ~D_diff[9] && |(D_diff[8:6]) ? 7'sb0111111 : // 63
				 D_diff[6:0];
				 
	assign D_term = saturated * D_COEFF;
	assign D_term_se_pf = {D_term[12], D_term};
	
	//pipeline flop 1//
	always@(posedge clk, negedge rst_n)
	if(!rst_n)
		D_term_se <= 14'h0000;
	else 
		D_term_se <= D_term_se_pf;
	
	
	// I_term
	assign err_sat_ext = {{5{err_sat[9]}}, err_sat};
	assign sum_term = err_sat_ext + integrator;
	
	assign OV = (integrator[14] & err_sat_ext[14] & ~sum_term[14]) || (~integrator[14] & ~err_sat_ext[14] & sum_term[14]);
	and AND0(mux_0, ~OV, err_vld);
	
	assign poss_nxt_integrator = mux_0 ? sum_term : integrator;
	assign nxt_integrator = moving ? poss_nxt_integrator : 15'h0000;
	
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			integrator <= 15'h0000;
		else
			integrator <= nxt_integrator;

	assign I_term = integrator[14:6];
	assign I_term_se_pf = {{5{I_term[8]}}, I_term};

	//pipeline flop 2//
	always@(posedge clk, negedge rst_n)
	if(!rst_n)
		I_term_se <= 14'h0000;
	else 
		I_term_se <= I_term_se_pf;

		
	// P_term
	assign err_sat = error[11] && ~&(error[10:9]) ? 10'b1000000000 : // -512
				 ~error[11] && |(error[10:9]) ? 10'b0111111111 : // 511
				 error[9:0];
				 
	assign P_term_pf = err_sat * P_COEFF;
	
	//pipeline flop 3//
	always@(posedge clk, negedge rst_n)
	if(!rst_n)
		P_term <= 14'h0000;
	else 
		P_term <= P_term_pf;
	
	
	// intermediate signals
	logic signed [13:0] PID, PID_flopped;
	logic signed [10:0] frwrd_ze;
	logic [10:0] frwrd_lft, frwrd_rght;
	
	assign PID = P_term + I_term_se + D_term_se;
	
	assign frwrd_ze = {1'sb0, frwrd};
	
	assign frwrd_lft = moving ? frwrd_ze + PID[13:3] : 11'h000;
	assign frwrd_rght = moving ? frwrd_ze - PID[13:3] : 11'h000;

	
	assign lft_spd = PID > 0 && frwrd_lft[10] ? 11'sh3ff : frwrd_lft;
	assign rght_spd = PID < 0 && frwrd_rght[10] ? 11'sh3ff : frwrd_rght;
	
endmodule
