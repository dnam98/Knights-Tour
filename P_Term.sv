module P_term(
input [11:0] error,
output [13:0] P_term
);

logic signed [9:0] err_sat;
logic signed [4:0] P_Coeff;

assign err_sat = (~error[11] & |error[11:9]) ? 10'h1FF:
	(error[11] & ~&error[11:9]) ? 10'h200:
	error;

assign P_Coeff = 5'h8;

assign P_term = err_sat*P_Coeff;
endmodule

