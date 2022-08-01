package tb_tasks;
	
	localparam CAL_CMD = 16'h0000;
	
	task automatic Initialize(ref clk, RST_n, send_cmd);
		begin
			send_cmd = 0;
			clk = 0;
			RST_n = 0;
			
			@(posedge clk);
			@(negedge clk);
			RST_n = 1;
		end
	endtask
	
	task automatic SendCmd(ref clk, input [15:0] cmd2send, ref [15:0] cmd, ref send_cmd);
		begin
			cmd = cmd2send;
			
			@(posedge clk);
			send_cmd = 1;
			@(posedge clk);
			send_cmd = 0;
		end
	endtask
	
	task automatic ChkPosAck(ref clk, ref resp_rdy);
		begin
			fork
				begin: timeout
					repeat (20000000) @(posedge clk);
					$display("Error: timed out waiting for resp_rdy");
					$stop();
				end
				begin
					@(posedge resp_rdy);
					disable timeout;
				end
			join
		end
	endtask
endpackage