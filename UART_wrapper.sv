module UART_wrapper(input clk, input rst_n, input clr_cmd_rdy, input RX, output TX, input trmt, input [7:0] resp, output [15:0] cmd, output tx_done, output logic cmd_rdy);
	logic rx_rdy, clr_rdy, ctrl, set_rdy;
	logic [7:0] rx_data, rx_flop;
	
	typedef enum {IDLE, BYTE} state_t;
	state_t state, nxt_state;
	
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(rx_rdy), .clr_rx_rdy(clr_rdy), .rx_data(rx_data), .trmt(trmt), .tx_data(resp), .tx_done(tx_done));
	
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			rx_flop <= 0;
		else if(ctrl)
			rx_flop <= rx_data;
		else
			rx_flop <= rx_flop;
			
	assign cmd = {rx_flop, rx_data};
			
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			cmd_rdy <= 0;
		else if(clr_cmd_rdy)
			cmd_rdy <= 0;
		else if(set_rdy)
			cmd_rdy <= 1;
		else
			cmd_rdy <= cmd_rdy;
			
			
	// state flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;	
			
	// FSM
	always_comb begin
		nxt_state <= state;
		ctrl <= 0;
		clr_rdy <= 0;
		set_rdy <= 0;
		case(state)
			IDLE:
				if(rx_rdy) begin
					clr_rdy <= 1;
					ctrl <= 1;
					nxt_state <= BYTE;
				end
			BYTE:
				if(rx_rdy) begin
					clr_rdy <= 1;
					set_rdy <= 1;
					nxt_state <= IDLE;
				end
		endcase
	end
endmodule