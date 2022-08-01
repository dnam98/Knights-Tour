module SPI_mnrch (clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, wt_data, done, rd_data);
  input clk, rst_n;
  input MISO;
  input wrt;
  input [15:0] wt_data;
  
  output logic SS_n;
  output SCLK;
  output MOSI;
  output logic done;
  output [15:0] rd_data;
  
  // Internal signals
  logic [3:0] cntr;
  logic done15;
  
  logic [4:0] d_SCLK;
  logic SCLK_fall, SCLK_rise;
  
  logic MISO_smpl;
  logic [15:0] shft_reg;
  
  typedef enum logic [1:0] {IDLE, WAIT, RUN, END} state_t;
  state_t state, nxt_state;
  logic init, shft, set_done;
  logic smpl, ld_SCLK;
  
  // Implementation
  
  // Bit counter
  always_ff @(posedge clk)
    cntr <= init ? 4'b0000 : (shft ? cntr + 1 : cntr);

  assign done15 = &cntr;
  
  // SCLK
  assign SCLK = d_SCLK[4];
  assign SCLK_rise = (d_SCLK == 5'b01111) ? 1 : 0;
  assign SCLK_fall = (d_SCLK == 5'b11111) ? 1 : 0;
  
  always_ff @(posedge clk)  
    d_SCLK <= ld_SCLK ? 5'b10111 : d_SCLK + 1;
  
  // Main register
  assign MOSI = shft_reg[15];
  always_ff @(posedge clk) begin
    MISO_smpl <= smpl ? MISO : MISO_smpl;
    shft_reg <= init ? wt_data : (shft ? {shft_reg[14:0], MISO_smpl} : shft_reg);
  end
  assign rd_data = shft_reg;
  
  // SM
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
      SS_n <= 1'b1;
      done <= 1'b0;
    end
    else if (init) begin
      SS_n <= 1'b0;
      done <= 1'b0;
    end
    else if (set_done) begin
      SS_n <= 1'b1;
      done <= 1'b1; 
    end
 
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  
  always_comb begin
    init = 0;
    ld_SCLK = 0;
    shft = 0;
    smpl = 0;
    set_done = 0;
    nxt_state = state;
    
    case (state)
      IDLE: begin
        if (wrt) begin
          init = 1;
          ld_SCLK = 1;
          nxt_state = WAIT;
		end
        else
          ld_SCLK = 1;
      end
      
      WAIT: if (SCLK_fall)
        nxt_state = RUN;
        
      RUN: 
	    if (done15)
          nxt_state = END;
        else if (!done15 & SCLK_rise)
          smpl = 1;
        else if (!done15 & SCLK_fall)
          shft = 1;
      
      END: if (SCLK_rise)
        smpl = 1;
        else if (SCLK_fall) begin
          set_done = 1;
          ld_SCLK = 1;
		  shft = 1;
          nxt_state = IDLE;
        end
        
    endcase
  end
endmodule