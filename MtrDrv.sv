module MtrDrv(input clk, input rst_n, input signed [10:0] lft_spd, input signed [10:0] rght_spd, output lftPWM1, output lftPWM2, output rghtPWM1, output rghtPWM2);

logic signed [10:0] lft_add, rght_add;

assign lft_add = lft_spd + 11'h400;
assign rght_add = rght_spd + 11'h400;

PWM11 iDUT1(.clk(clk), .rst_n(rst_n), .duty(lft_add), .PWM_sig(lftPWM1), .PWM_sig_n(lftPWM2));
PWM11 iDUT2(.clk(clk), .rst_n(rst_n), .duty(rght_add), .PWM_sig(rghtPWM1), .PWM_sig_n(rghtPWM2));

endmodule
