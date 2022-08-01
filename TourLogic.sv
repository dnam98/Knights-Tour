module TourLogic(clk,rst_n,x_start,y_start,go,done,indx,move);

  input clk,rst_n;				// 50MHz clock and active low asynch reset
  input [2:0] x_start, y_start;			// starting position on 5x5 board
  input go;					// initiate calculation of solution
  input [4:0] indx;				// used to specify index of move to read out
  output logic done;				// pulses high for 1 clock when solution complete
  output logic [7:0] move;			// the move addressed by indx (1 of 24 moves)
  
  /////////////////////////
  // internal registers //
  ////////////////////////
  
  logic [4:0] visited [4:0][4:0];			//tracks where on the board the knight's been//
  logic [7:0] last_move [23:0]; 			//keeps track of move taken from each move index//
  logic [7:0] possible_moves [4:0][4:0];		//keeps track of possible moves from each space//
  logic [7:0] try; 					//holds move to try next//
  logic [4:0] move_number;				//counts current move number//
  logic [2:0] xx;					//represents current x coordinates of knight//
  logic [2:0] yy;  					//represents current y coordinates of knight//
  
  
  //Calculated parameters of logic//
  logic [2:0] xx_next;					//next x coordinate of knight//
  logic [2:0] yy_next;					//next y coordinate of knight//
  logic [2:0] xx_prev;					//previous x coordinate of knight//
  logic [2:0] yy_prev;					//previous y coordinate of knight//	
  logic [2:0] x_offset;					//the number of horizontal spaces to be moved//
  logic [2:0] y_offset;					//the number of vertical spaces to be moved//
  logic shift;
  
  //SM outputs//
  logic init_try;					//initializes move to be tried to 1//
  logic update_position;				//asserts with each change of knight's position//
  logic move_xy;					//asserts when a move is made//
  logic back_xy;					//asserts when the knight backs up//
  logic init;						//asserted upno entry into the init state//
  logic update_pos_mv;					//stores possible moves at a certain space//
  logic set_done;					//sets the done signal when the tour has been solved//


typedef enum reg [2:0] {IDLE, INIT, POSS_MOVE, MAKE_MOVE, BACK_UP} state_t;
  state_t state, nxt_state;

  //reset state flop//
  always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
  
  function [7:0] calc_poss(input [2:0] xpos,ypos);
	///////////////////////////////////////////////////
	//function checks if a move is in bounds for each//
	//space, assigns one hot bit to 1 in calc_poss if so
	////////////////////////////////////////////////////
	logic [7:0] move0;
	logic [7:0] move1;
	logic [7:0] move2;
	logic [7:0] move3;
	logic [7:0] move4;
	logic [7:0] move5;
	logic [7:0] move6;
	logic [7:0] move7;	
	
		if ((xpos - 1 >= 0) && (xpos - 1 <= 4) && (ypos + 2 >= 0) && (ypos + 2 <= 4))
			move0 = 8'h01;
		else
			move0 = 8'h00;

		if ((xpos + 1 >= 0) && (xpos + 1 <= 4) && (ypos + 2 >= 0) && (ypos + 2 <= 4))
			move1 = 8'h02;
		else
			move1 = 8'h00;

		if ((xpos - 2 >= 0) && (xpos - 2 <= 4) && (ypos + 1 >= 0) && (ypos + 1 <= 4))
			move2 = 8'h04;
		else
			move2 = 8'h00;

		if ((xpos - 2 >= 0) && (xpos - 2 <= 4) && (ypos - 1 >= 0) && (ypos - 1 <= 4))
			move3 = 8'h08;
		else
			move3 = 8'h00;

		if ((xpos - 1 >= 0) && (xpos - 1 <= 4) && (ypos - 2 >= 0) && (ypos - 2 <= 4))
			move4 = 8'h10;
		else
			move4 = 8'h00;

		if ((xpos + 1 >= 0) && (xpos + 1 <= 4) && (ypos - 2 >= 0) && (ypos - 2 <= 4))
			move5 = 8'h20;
		else
			move5 = 8'h00;

		if ((xpos + 2 >= 0) && (xpos + 2 <= 4) && (ypos -1  >= 0) && (ypos - 1 <= 4))
			move6 = 8'h40;
		else
			move6 = 8'h00;

		if ((xpos + 2 >= 0) && (xpos + 2 <= 4) && (ypos + 1 >= 0) && (ypos + 1 <= 4))
			move7 = 8'h80;
		else
			move7 = 8'h00;

		calc_poss = move0 | move1 | move2 | move3 | move4 | move5 | move6 | move7;
		
  endfunction
 
  
  function signed [2:0] off_x(input [7:0] try);
         ////////////////////////////////////////////////////
	 // function returns the x-offset the Knight will move 
	 //given the encoding of the move being tried
	 ////////////////////////////////////////////////////
	begin 
		if ((try == 8'h01) || (try == 8'h10))
			off_x = 3'h7;
		else if ((try == 8'h04) || (try == 8'h08))
			off_x = 3'h6;
		else if ((try == 8'h02) || (try == 8'h20))
			off_x = 3'h1;
		else if ((try == 8'h40) || (try == 8'h80))
			off_x = 3'h2;
	end
  endfunction
  
  function signed [2:0] off_y(input [7:0] try);
   	///////////////////////////////////////////////
	// function returns the y-offset the Knight will move 
	//given the encoding of the move being tried
	////////////////////////////////////////////////////
	begin 
		if ((try == 8'h01) || (try == 8'h02))
			off_y = 3'h2;
		else if ((try == 8'h04) || (try == 8'h80))
			off_y = 3'h1;
		else if ((try == 8'h08) || (try == 8'h40))
			off_y = 3'h7;
		else if ((try == 8'h10) || (try == 8'h20))
			off_y = 3'h6;
	end
  endfunction

  //holds current move number//
  always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		move_number <= 5'h00;
	else if (init)
		move_number <= 5'h00;
	else if(move_xy)
		move_number <= move_number + 1;
	else if(back_xy)
		move_number <= move_number - 1;
  
  //holds move to try next//
  always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		try <= 8'h00;
	else if(init_try)
		try <= 8'h01;
	else if (shift)
		try <= {try[6:0], 1'b0};
	else if (back_xy) begin
		if(!last_move[move_number - 1][7])
			try <= {last_move[move_number - 1][6:0], 1'b0};
		else
			try <= last_move[move_number - 1]; end
  end
 
 //holds current x and y positions//
  always_ff@(posedge clk)
	if (init) begin
		xx <= x_start;
		yy <= y_start; end
	else if (move_xy) begin
		xx <= xx_next;
		yy <= yy_next; end
	else if (back_xy) begin
		xx <= xx_prev;
		yy <= yy_prev; end

  //saves possible moves at each space//
  always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		possible_moves <= '{'{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}};
	else if (update_pos_mv)
		possible_moves [xx][yy] <= calc_poss(xx,yy);
  
  //saves the move made at each move index//
  always_ff@(posedge clk)
	if (!rst_n)
		last_move <= '{8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
	else if (move_xy)
		last_move[move_number] <= try; //  try is assigned to index of its move minus 1

  //keeps track of spaces on the board that have been visited//
  always_ff@(posedge clk)
	if(!rst_n)
		visited <= '{'{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}};
  	else if (go)
		visited <= '{'{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}, '{5'h00, 5'h00, 5'h00, 5'h00, 5'h00}};
	else if (init)
		visited[x_start][y_start] <= 5'h01;
	else if (move_xy)
		visited [xx_next][yy_next] <= move_number + 2;
	else if (back_xy)
		visited [xx][yy] <= 5'h00;

  //SR flop to set done upon solution//
  always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		done <= 0;
	else if (go)
		done <= 0;
	else if (set_done)
		done <= 1;

  assign x_offset = off_x(try);
  assign y_offset = off_y(try);
  assign xx_next = xx + x_offset;
  assign yy_next = yy + y_offset;
  assign xx_prev = xx - off_x(last_move[move_number - 1]);
  assign yy_prev = yy - off_y(last_move[move_number - 1]);
  
  assign move = last_move[indx];


  always_comb begin
  
  //initialize SM outputs//
  set_done = 0;
  shift = 0;
  init_try = 0;
  update_position = 0;
  update_pos_mv = 0;
  move_xy = 0;
  back_xy = 0;
  init = 0;
  nxt_state = state;

  //SM logic//
  case(state)

  	IDLE: if (go) begin
		nxt_state = INIT; end
	
	////////////////////////////////////////////////////////////////////////////////////
	//INIT state clears board and move counter, initializes knight to beginning space//
	INIT: begin
		init = 1;
		nxt_state = POSS_MOVE; end
	
	////////////////////////////////////////////////////////////
	//poss_move state calculates possible moves of a new space// 
	//that has not been visited before//////////////////////////
	POSS_MOVE: begin
		update_pos_mv = 1;
		init_try = 1;
		nxt_state = MAKE_MOVE; end

	//////////////////////////////////////////////////////////////////
	//make_move state determines appropriate move to make and makes //
	//it, sends into back_up state if no moves can be made///////////
	MAKE_MOVE:
		
		if (|(possible_moves [xx][yy] & try) & (!visited[xx_next][yy_next])) begin
			if (move_number == 5'h17) begin
				move_xy = 1;
				update_position = 1;
				set_done = 1;
				nxt_state = IDLE; end
			else begin
				move_xy = 1;
				update_position = 1;
				nxt_state = POSS_MOVE; end
		end

		else if((!(|(possible_moves [xx][yy] & try)) & !try[7]) | (|(possible_moves [xx][yy] & try) & (|visited[xx_next][yy_next])& !try[7])) begin
			shift = 1;
			nxt_state = MAKE_MOVE; end
	
		else if((!(|(possible_moves [xx][yy] & try)) & try[7]) | (|(possible_moves [xx][yy] & try) & (|visited[xx_next][yy_next])& try[7])) begin
			nxt_state = BACK_UP; end

	////////////////////////////////////////////////////////////////////////////////
	//back_up state moves the knight to its previous state, and determines whether// 
	//another move should be attempted or another back-up is necessary//////////////
	BACK_UP: begin
			back_xy = 1;
			update_position = 1;
		 if (last_move[move_number - 1][7]) 
			nxt_state = BACK_UP;
		else 
			nxt_state = MAKE_MOVE;
		end
	endcase
	end
		 
  
endmodule
