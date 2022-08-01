module charge(
	input clk, rst_n, go,		//go initializes tune//
	output logic piezo, piezo_n		//differential piezo drive//
);

logic cnt;				//tells duration and frequency counters to increment//
logic [4:0] dur_inc;			//the amount by which the duration counter increments each time//
logic comp_rslt;			//denotes whether frequency counter result is greater than duty value//
logic [3:0] offset;

//SM inputs//
logic [23:0] dur_cnt;			//duration counter output//
logic [14:0] freq_cnt;			//frequency counter output//

//SM outputs//
logic init;				//asserted upon initialization of tune//
logic clr_dur, clr_freq;		//asserted when duration annd frequency counters need to be reset//
logic term;				//asserted upon termination of tune//

//FAST_SIM speeds up simulation time when high//
parameter FAST_SIM = 1;

parameter OFFSET = 4'hf;

//generates value by which duration counter imcrements depending on FAST_SIM//
generate if (FAST_SIM) begin
		assign dur_inc = 5'h10;
		assign offset = 4'hf; end
	else begin
		assign dur_inc = 5'h01;
		assign offset = 4'h0; end
endgenerate

//sets the duty ratio for each frequency counter//
localparam duty = 14'h2EB6;

typedef enum reg [2:0] {IDLE, G6, C7, E7, G7, E7_2, G7_2} state_t;
state_t state, nxtState;

//setting reset state for SM//
always_ff@(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxtState;

//frequency counter//
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		freq_cnt <= 15'h000;
	else if (clr_freq)
		freq_cnt <= 15'h0000;
	else if (cnt)
		freq_cnt <= freq_cnt + 1;
end

//piezo flop//
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		piezo <= 1'b0;
	else
		piezo <= comp_rslt;
end

//assign high value to piezo as long as duty is greater than the output of the frequency counter//
always_comb begin
	if (freq_cnt < duty)
		comp_rslt=1;
	else
		comp_rslt=0;
end

assign piezo_n = !piezo;

//duration counter//
always_ff@(posedge clk, negedge rst_n)
	if (!rst_n)
		dur_cnt <= 24'h000000;
	else if (clr_dur)
		dur_cnt <= 24'h000000;
	else if (cnt)
		dur_cnt <= dur_cnt + dur_inc;

//cnt implementation using SR latch based on initiation and termination of SM//
always_ff@(posedge clk, negedge rst_n)
if (!rst_n)
	cnt <= 1'b0;
else if (init && !term)
	cnt <= 1'b1;
else if (term && !init)
	cnt <= 1'b0;

//SM logic//
always_comb begin
//initilization of SM outputs//
init = 0;
term = 0;
clr_dur = 0;
clr_freq = 0;
nxtState = state;

case(state)

G6: begin
	if (&(dur_cnt[22:0] + offset)) begin
		clr_dur = 1;
		clr_freq = 1;
		nxtState = C7; end

	else if (freq_cnt == 15'h7C90) begin
		clr_freq = 1; end
end

C7: begin
	if (&(dur_cnt[22:0] + offset)) begin
		clr_dur = 1;
		clr_freq = 1;
		nxtState = E7; end

	else if (freq_cnt == 15'h5051) begin
		clr_freq = 1; end
end

E7: begin
	if (&(dur_cnt[22:0] + offset)) begin
		clr_dur = 1;
		clr_freq = 1;
		nxtState = G7; end

	else if (freq_cnt == 15'h4A11) begin
		clr_freq = 1; end
end

G7: begin
	if (dur_cnt + offset == 24'hBFFFFF) begin
		clr_dur = 1;
		clr_freq = 1;
		nxtState = E7_2; end 

	else if (freq_cnt == 15'h3E48) begin
		clr_freq = 1; end
end

E7_2: begin
	if (&(dur_cnt[21:0] + offset)) begin
		clr_dur = 1;
		clr_freq = 1;
		nxtState = G7_2; end

	else if (freq_cnt == 15'h4A11) begin
		clr_freq = 1; end
end

G7_2: begin
	if (&(dur_cnt + offset)) begin
		clr_dur = 1;
		clr_freq = 1;
		term = 1;
		nxtState = IDLE; end

	else if (freq_cnt == 15'h3E48) begin
		clr_freq = 1; end
end

default:
	if(go) begin
		init = 1;
		clr_dur = 1;
		clr_freq = 1;
		nxtState = G6; end

endcase

end

endmodule
