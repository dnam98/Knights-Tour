//////////////////////////////////////////////////////
// Interfaces with ST 6-axis inertial sensor.  In  //
// this application we only use Z-axis gyro for   //
// heading of robot.  Fusion correction comes    //
// from "gaurdrail" signals lftIR/rghtIR.       //
/////////////////////////////////////////////////
module inert_intf(clk,rst_n,strt_cal,cal_done,heading,rdy,lftIR,
                  rghtIR,SS_n,SCLK,MOSI,MISO,INT,moving);

  parameter FAST_SIM = 1;	// used to speed up simulation
  
  input clk, rst_n;
  input MISO;					// SPI input from inertial sensor
  input INT;					// goes high when measurement ready
  input strt_cal;				// initiate claibration of yaw readings
  input moving;					// Only integrate yaw when going
  input lftIR,rghtIR;			// gaurdrail sensors
  
  output cal_done;				// pulses high for 1 clock when calibration done
  output signed [11:0] heading;	// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
  output rdy;					// goes high for 1 clock when new outputs ready (from inertial_integrator)
  output SS_n,SCLK,MOSI;		// SPI outputs
 

  ////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
   logic [7:0] readY_L;
   logic [7:0] readY_H;
  
  //////////////////////////////////////////////
  // Declare outputs of SM are of type logic //
  ////////////////////////////////////////////
  //SM signals
  logic wrt, vld, C_Y_L, C_Y_H;
  logic [15:0] timer;
  logic INT_ff1, INT_ff2;
  
 
  //Signals for instantiation for SPI_mnrch
  logic done;
  logic [15:0] inert_data, cmd;
 
  //Signals for instantiation for inertial_integrator
  logic signed [15:0] yaw_rt;
  logic vld_ff;
 
 
  ///////////////////////////////////////
  // Create enumerated type for state //
  /////////////////////////////////////
  typedef enum logic [2:0] {INIT1, INIT2, INIT3, INT_wait, RD_Y_L, RD_Y_H, VLD} state_t;
 state_t state, nxt_state;
  
  ////////////////////////////////////////////////////////////
  // Instantiate SPI monarch for Inertial Sensor interface //
  //////////////////////////////////////////////////////////
  SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),
                 .MISO(MISO),.MOSI(MOSI),.wrt(wrt),.done(done),
				 .rd_data(inert_data),.wt_data(cmd));
				  
  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and acceleration info and produces a heading reading         //
  /////////////////////////////////////////////////////////////////
  inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal),.vld(vld_ff),
                           .rdy(rdy),.cal_done(cal_done), .yaw_rt(yaw_rt),.moving(moving),.lftIR(lftIR),
                           .rghtIR(rghtIR),.heading(heading));
	

 //FF state transition logic
always_ff@(posedge clk, negedge rst_n)
if(!rst_n)
state <= INIT1;
else
state <= nxt_state;

//Timer flop
always_ff@(posedge clk, negedge rst_n) begin
if(!rst_n)
timer <= 16'd0;
else 
timer <= timer+1;
end

//Double flopping INT
always_ff@(posedge clk, negedge rst_n) begin
if(!rst_n)
INT_ff1 <= 1'b0;
else
INT_ff1 <= INT;
end

always_ff@(posedge clk, negedge rst_n) begin
if(!rst_n)
INT_ff2 <= 1'b0;
else
INT_ff2 <= INT_ff1;
end


//Flopping vld once 
always_ff@(posedge clk, negedge rst_n) begin
if(!rst_n)
vld_ff <= 1'b0;
else
vld_ff <= vld;
end

//readY_L register
always_ff@(posedge clk, negedge rst_n) begin
if(!rst_n)
readY_L <= 8'b0;
else if(C_Y_L)
readY_L <= inert_data[7:0];
end

//readY_H register
always_ff@(posedge clk, negedge rst_n) begin
if(!rst_n)
readY_H <= 8'b0;
else if(C_Y_H)
readY_H <= inert_data[7:0];
end

assign yaw_rt = {readY_H, readY_L};


 always_comb begin
//Setting default outputs
nxt_state = state;
wrt = 0;
vld =0;
C_Y_H=0;
C_Y_L=0;
cmd= 16'd0;

case(state)

    INIT1: begin
       if(&timer) begin
	        cmd =16'h0d02; 
			nxt_state = INIT2;   
			wrt =1;
	   end
	end

    INIT2: begin
       if(done) begin
	        cmd =16'h1160; 
			nxt_state = INIT3;   
			wrt =1;
	   end
	end
	
    INIT3: begin
       if(done) begin
	        cmd =16'h1440; 
			nxt_state = INT_wait;   
			wrt =1;
	   end
	end	
 
    INT_wait: begin
       if(INT_ff2) begin
	        cmd =16'ha6xx; 
			nxt_state = RD_Y_L;   
			wrt =1;
	   end
	end 

    RD_Y_L: begin
       if(done) begin
	        cmd =16'ha7xx; 
			nxt_state = RD_Y_H;
            C_Y_L =1;			
			wrt =1;
	   end
	end  

    RD_Y_H: begin
       if(done) begin  
			nxt_state = INT_wait;   
			C_Y_H =1;
			vld=1;
	   end
	end 
 
 default: nxt_state = INIT1;
 
 endcase

end
 
endmodule
	  