module KnightsTourTestBench1 ();
  //<< import or include tasks?>>
  import tb_tasks::*;
    
  
  /////////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk, RST_n;
  reg [15:0] cmd;
  reg send_cmd;
  
  ///////////////////////////////////
  // Declare any internal signals //
  /////////////////////////////////
  wire SS_n,SCLK,MOSI,MISO,INT;
  wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
  wire TX_RX, RX_TX;
  logic cmd_sent;
  logic resp_rdy;
  logic [7:0] resp;
  wire IR_en;
  wire lftIR_n,rghtIR_n,cntrIR_n;
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  KnightsTour iDUT(.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
                   .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
				   .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
				   .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
				   .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
				   .cntrIR_n(cntrIR_n));
				  
  /////////////////////////////////////////////////////
  // Instantiate RemoteComm to send commands to DUT //
  ///////////////////////////////////////////////////
  //<< This is my remoteComm.  It is possible yours has a slight variation
  //   in port names>>
  RemoteComm iRMT(.clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
             .send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));
				   
  //////////////////////////////////////////////////////
  // Instantiate model of Knight Physics (and board) //
  ////////////////////////////////////////////////////
  KnightPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                      .MOSI(MOSI),.INT(INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.IR_en(IR_en),
					  .lftIR_n(lftIR_n),.rghtIR_n(rghtIR_n),.cntrIR_n(cntrIR_n)); 
				   
  initial begin
	Initialize(clk, RST_n, send_cmd);
	
	@(posedge iPHYS.iNEMO.NEMO_setup);
	SendCmd(clk, 16'h4X31, cmd, send_cmd);  // Send command that asserts tour go and initial positions (3, 1)
	
	fork
	  begin: timeout1
		repeat (200000) @(posedge clk);
		$display("Error: timed out waiting for cal_done.");
		$stop();
	  end
	  begin
	    @(posedge iDUT.iCMD.cal_done);
	    disable timeout1;
	  end
    join
	
	ChkPosAck(clk, resp_rdy);
	
	// Check final position (0.5, 0.5)
	if (iPHYS.xx !== 15'h0800 || iPHYS.yy !== 15'h0800) begin
	  $display("Error: Knight not at the right position");
		$display("Expected: (x = 0, y = 0)    Actual: (x = %h, y = %h)", iPHYS.xx, iPHYS.yy);
		$stop;
	end
	
	// Check if angular velocities of the wheels are 0, which means not moving after all the moves
	if (iPHYS.omega_lft !== 13'h0000 || iPHYS.omega_rght !== 13'h0000)
	  $display("Error: Knight did not stop moving after the 23rd move");
	
	$stop;
  end
  
  always
    #5 clk = ~clk;
  
  
endmodule