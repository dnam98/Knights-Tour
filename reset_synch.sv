module reset_synch(input clk, input RST_n, output logic rst_n);

logic rst_n_int;

always_ff@(negedge clk, negedge RST_n)
if(!RST_n)
 rst_n_int <= 0;
else
 rst_n_int <= 1;

always_ff@(negedge clk, negedge RST_n)
if(!RST_n)
 rst_n <= 0;
else
 rst_n <= rst_n_int;
 
endmodule
 


