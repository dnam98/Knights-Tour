module RemoteComm(clk, rst_n, RX, TX, cmd, send_cmd, cmd_sent, resp_rdy, resp);

input clk, rst_n;       // clock and active low reset
input RX;               // serial data input
input send_cmd;         // indicates to tranmit 24-bit command (cmd)
input [15:0] cmd;       // 16-bit command

output TX;              // serial data output
output logic cmd_sent;  // indicates transmission of command complete
output resp_rdy;        // indicates 8-bit response has been received
output [7:0] resp;      // 8-bit response from DUT

wire [7:0] tx_data;     // 8-bit data to send to UART
wire tx_done;           // indicates 8-bit was sent over UART

///////////////////////////////////////////////
// Registers needed...state machine control //
/////////////////////////////////////////////
logic sel, trmt, set_cmd_snt;
logic [7:0] q;
logic resp_rdy_ff;

///////////////////////////////
// state definitions for SM //
/////////////////////////////
typedef enum logic [1:0] {IDLE, TRAN, FIN} state_t;
state_t state, nxt_state;

///////////////////////////////////////////////
// Instantiate basic 8-bit UART transceiver //
/////////////////////////////////////////////
UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
           .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(resp_rdy_ff));


always_ff @(posedge clk, negedge rst_n)
	resp_rdy_ff <= resp_rdy;

always_ff @(posedge clk, negedge rst_n)
  if (send_cmd)
    q <= cmd[7:0];

assign tx_data = sel ? cmd[15:8] : q;


// SM
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;

always_comb begin
  sel = 0;
  trmt = 0;
  set_cmd_snt = 0;
  nxt_state = state;
  
  case (state)
    IDLE: if (send_cmd) begin
      sel = 1;
      trmt = 1;
      nxt_state = TRAN;
    end
      
    TRAN: if (tx_done) begin
      trmt = 1;
      nxt_state = FIN;
    end
      
    FIN: if (tx_done) begin
      set_cmd_snt = 1;
      nxt_state = IDLE;
    end
  endcase
end

// SR
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    cmd_sent <= 0;
  else if (send_cmd)
    cmd_sent <= 0;
  else if (set_cmd_snt)
    cmd_sent <= 1;

endmodule   
