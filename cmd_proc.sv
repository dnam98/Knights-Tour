module cmd_proc(clk,rst_n,cmd,cmd_rdy,clr_cmd_rdy,send_resp,strt_cal,
                cal_done,heading,heading_rdy,lftIR,cntrIR,rghtIR,error,
                frwrd,moving,tour_go,fanfare_go);
                
  parameter FAST_SIM = 1;       // speeds up incrementing of frwrd register for faster simulation
                
  input clk,rst_n;                  // 50MHz clock and asynch active low reset
  input [15:0] cmd;                 // command from BLE
  input cmd_rdy;                    // command ready
  output logic clr_cmd_rdy;         // mark command as consumed
  output logic send_resp;           // command finished, send_response via UART_wrapper/BT
  output logic strt_cal;            // initiate calibration of gyro
  input cal_done;                   // calibration of gyro done
  input signed [11:0] heading;      // heading from gyro
  input heading_rdy;                // pulses high 1 clk for valid heading reading
  input lftIR;                      // nudge error +
  input cntrIR;                     // center IR reading (have I passed a line)
  input rghtIR;                     // nudge error -
  output reg signed [11:0] error;   // error to PID (heading - desired_heading)
  output reg [9:0] frwrd;           // forward speed register
  output logic moving;              // asserted when moving (allows yaw integration)
  output logic tour_go;             // pulse to initiate TourCmd block
  output logic fanfare_go;          // kick off the "Charge!" fanfare on piezo

  // Internal Signals
  logic move_cmd;
  logic inc_frwrd, dec_frwrd;
  logic move_done;
  logic signed [11:0] err_nudge;
  logic [3:0] q;
  logic [3:0] count;
  logic signed [11:0] desired_heading;
  logic cntrIR_rise_edge, cntrIR_q;
  logic max_speed;
  logic [9:0] incrementor;
  logic zero;
  
  // Forward Register
  assign max_speed = &frwrd[9:8];
  assign zero = ~(|frwrd);
  // slow down twice the rate of speeding up
  always_ff @(posedge clk, negedge rst_n)
    if(!rst_n)
	  frwrd <= 0;
	else if(heading_rdy && ((!max_speed && inc_frwrd) || (!zero && dec_frwrd)))
	  if(FAST_SIM) 
	    if(inc_frwrd)
		  frwrd <= frwrd + 9'h20;
		else
		  frwrd <= frwrd - 9'h20;
	  else
        if(inc_frwrd)
          frwrd <= frwrd + 9'h4;
        else
          frwrd <= frwrd - 9'h8;
  
  // Counting squares
  always_ff @(posedge clk)
	  cntrIR_q <= cntrIR;
  
  assign cntrIR_rise_edge = cntrIR && !cntrIR_q;

  always_ff @(posedge clk)
    if (move_cmd)
	  count <= 0;
	else if (cntrIR_rise_edge)
	  count <= count + 1;
  
  always_ff @(posedge clk)
    if (move_cmd)
	  q <= {cmd, 1'b0};
  
  assign move_done = (q == count) ? 1'b1 : 1'b0;
  
  // PID Interface
  always_ff @(posedge clk)
    if (move_cmd)
      desired_heading <= (cmd[11:4] == 8'h00) ? 12'h000 : {cmd[11:4],4'hF};
  
  assign err_nudge = lftIR ? 12'h05F : (rghtIR ? 12'hFA1 : 12'h000);
  
  assign error = heading - desired_heading + err_nudge;
  
  // SM
  typedef enum logic [2:0] {IDLE, CAL, MOVE, RUP, RDOWN} state_t;
  state_t state, nxt_state;
  
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  
  always_comb begin
    // default values
    strt_cal = 0;
    clr_cmd_rdy = 0;
    send_resp = 0;
    move_cmd = 0;
    fanfare_go = 0;
    tour_go = 0;
    inc_frwrd = 0;
    dec_frwrd = 0;
	moving = 0;
    nxt_state = state;
    
    case (state)
      IDLE:
        if (cmd_rdy) begin
		  // calibrate command
          if (cmd[15:12] == 4'b0000) begin
            clr_cmd_rdy = 1;
            strt_cal = 1;
            nxt_state = CAL;
          end
          
		  // move cammand
          else if (cmd[15:13] == 3'b001) begin
            move_cmd = 1;
			clr_cmd_rdy = 1;
            nxt_state = MOVE;
          end
          
		  // tour command
          else if (cmd[15:12] == 4'b0100) begin
            clr_cmd_rdy = 1;
			tour_go = 1;
		  end
        end
      
      CAL: 
        if (cal_done) begin
          send_resp = 1;
          nxt_state = IDLE;
        end
      
      MOVE: begin
	    inc_frwrd = 1;
	    moving = 1;
	    if (error < 12'h030 && error > 12'shfc0)
          nxt_state = RUP;
      end
	  // ramp up
      RUP: begin
        inc_frwrd = 1;
		moving = 1;
        if (move_done) begin
          if (cmd[12] == 1) fanfare_go = 1; // if fanfare
          nxt_state = RDOWN;
        end
      end
      // ramp down
      RDOWN: begin
        dec_frwrd = 1;
		moving  = 1;
        if (frwrd == 0) begin
          send_resp = 1;
          nxt_state = IDLE;
        end
      end
    endcase
  end
  
endmodule
  