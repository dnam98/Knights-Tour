module TourCmd(clk, rst_n, start_tour, mv_indx, move, cmd_UART, cmd_rdy_UART, cmd, cmd_rdy, clr_cmd_rdy, send_resp, resp);
	input clk, rst_n, start_tour, cmd_rdy_UART, clr_cmd_rdy, send_resp;
	input [7:0] move;
	input [15:0] cmd_UART;
	output cmd_rdy;
	output logic [4:0] mv_indx;
	output [15:0] cmd;
	output [7:0] resp;
	
	// internal signals
	logic mv_dir; // if 0 X else Y
	logic mux_sel;
	logic set_cmd_rdy;
	logic [15:0] set_cmd;
	logic clr_cntr, inc_cntr;
	
	typedef enum reg [2:0] {IDLE, XSTART, XWAIT, YSTART, YWAIT} state_t;
	state_t state, nxt_state;

	//fanfare or no
	assign set_cmd[15:12] = mv_dir ? 4'b0011 : 4'b0010;
	// heading
    assign set_cmd[11:4] = mv_dir ? (move[0] || move[1] || move[2] || move[7] ? 0 : 8'h7f) :
								(move[0] || move[2] || move[3] || move[4] ? 8'h3f : 8'hbf);
	// number of squares
	assign set_cmd[3:0] = mv_dir ? (move[2] || move[3] || move[6] || move[7] ? 4'h1 : 4'h2) :
								(move[0] || move[1] || move[4] || move[5] ? 4'h1 : 4'h2);
	
	// mux for output signals
	assign cmd = mux_sel ? set_cmd : cmd_UART;
	assign cmd_rdy = mux_sel ? set_cmd_rdy : cmd_rdy_UART;
	
	assign resp = mv_indx == 5'd23 ? 8'ha5 : 8'h5a;

	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			mv_indx <= 0;
		else if(clr_cntr)
			mv_indx <= 0;
		else if(inc_cntr)
			mv_indx <= mv_indx + 1;
			
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
			
	always_comb begin
		nxt_state = state;
		clr_cntr = 0;
		mux_sel = 1;
		set_cmd_rdy = 0;
		mv_dir = 0;
		inc_cntr =0;
		
		case(state)
			IDLE: begin
				mux_sel = 0;
				if(start_tour) begin
					clr_cntr = 1;
					mux_sel = 1;
					nxt_state = XSTART;
				end
			end
			XSTART: begin
				mv_dir = 0;
				set_cmd_rdy = 1;
				if(clr_cmd_rdy) begin
					nxt_state = XWAIT;
				end
			end
			XWAIT: begin
				if(send_resp) begin
					nxt_state = YSTART;
				end
			end
			YSTART: begin
				mv_dir = 1;
				set_cmd_rdy = 1;
				if(clr_cmd_rdy) begin
					nxt_state = YWAIT;
				end
			end
			YWAIT: begin
			    mv_dir = 1;
				if(send_resp) begin
				    inc_cntr=1;	
					if(mv_indx == 5'd23) begin
						nxt_state = IDLE;
					end
					else begin
						nxt_state = XSTART;
					end
				end
			end
		endcase
	end
endmodule