module UART_tx(input clk, input rst_n, output TX, input trmt, input [7:0]tx_data, output logic tx_done);
	// internal signals
	logic init, shift, transmitting, set_done;
	logic [8:0] tx_shft_reg;
	logic [3:0] bit_cnt;
	logic [11:0] baud_cnt;
	
	// states
	typedef enum logic {IDLE, TRANSMIT} state_t;
	state_t state, nxt_state;
						 
	assign shift = baud_cnt == 12'd2604 ? 1'b1 : 1'b0;
	
	assign TX = tx_shft_reg[0];
				
	// shift_reg mux and flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			tx_shft_reg <= 9'b111111111;
		else if(init)
			tx_shft_reg <= {tx_data, 1'b0};
		else if(shift)
			tx_shft_reg <= {1'b1, tx_shft_reg[8:1]};
		else
			tx_shft_reg <= tx_shft_reg;
		
		
	// bit_cnt mux and flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			bit_cnt <= 0;
		else if(init)
			bit_cnt <= 0;
		else if(shift)
			bit_cnt <= bit_cnt + 1;
		else
			bit_cnt <= bit_cnt;	
		
	// baud_cnt mux and flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			baud_cnt <= 0;
		else if(init | shift)
			baud_cnt <= 0;
		else if(transmitting)
			baud_cnt <= baud_cnt + 1;
		else
			baud_cnt <= baud_cnt;
			
	// tx_done
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			tx_done <= 0;
		else if(init)
			tx_done <= 0;
		else if(set_done)
			tx_done <= 1;
			
	// state flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;

	// state machine
	always_comb begin
		nxt_state <= state;
		init <= 0;
		set_done <= 0;
		transmitting <= 0;
		case(state)
			IDLE: begin
				if(trmt) begin
					nxt_state <= TRANSMIT;
					init <= 1;
				end
			end
			TRANSMIT: begin
				transmitting <= 1;
				if(bit_cnt == 10) begin
					set_done <= 1;
					transmitting <= 0;
					nxt_state <= IDLE;
				end
			end
			default:
				nxt_state <= IDLE;
		endcase
	end
endmodule