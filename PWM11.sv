module PWM11(input clk, input rst_n, input [10:0]duty, output reg PWM_sig, output reg PWM_sig_n);

logic [10:0] cnt;


always_ff @(posedge clk, negedge rst_n) begin
   if (!rst_n)
      cnt <= 1'b0;
   else
      cnt <= cnt + 1;
end 
	  

always_ff @(posedge clk, negedge rst_n) begin
   if (!rst_n)
      PWM_sig <= 1'b0;
   else if( cnt < duty) 
      PWM_sig <= 1;
	else
	  PWM_sig <= 0;
end 	  

assign PWM_sig_n = ~PWM_sig;

endmodule