module uart_tx (
    input            clk,
    input      [7:0] din,
    input            wen,
    output           busy,
    output reg       txd
);

  initial begin
    txd = 1'd1;
  end

  parameter freq = 27000000;
  parameter bsp = 115200;

  localparam STATE_IDLE = 2'd0;
  localparam STATE_START = 2'd1;
  localparam STATE_DATA = 2'd2;
  localparam STATE_STOP = 2'd3;
  localparam TX_CLK_MAX = (freq / bsp) - 1;


  reg  [                     7:0] int_din;
  reg                             int_wen;
  reg  [                     7:0] data = 'd0;
  reg  [                     2:0] bitpos = 'd0;
  reg  [                     1:0] state = STATE_IDLE;
  reg  [$clog2(TX_CLK_MAX+1)+1:0] clk_txcnt;
  wire                            clk_tx;

  initial clk_txcnt = 0;

  always @(*) begin
    int_din <= din;
    int_wen <= wen;
  end

  assign clk_tx = (clk_txcnt == 0);

  always @(posedge clk) begin
    if (clk_txcnt >= TX_CLK_MAX) clk_txcnt <= 'd0;
    else clk_txcnt <= clk_txcnt + 1'd1;
  end


  always @(posedge clk) begin
    case (state)
      STATE_IDLE: begin
        if (int_wen) begin
          state  <= STATE_START;
          data   <= int_din;
          bitpos <= 3'd0;
        end
      end
      STATE_START: begin
        if (clk_tx) begin
          txd   <= 'd0;
          state <= STATE_DATA;
        end
      end
      STATE_DATA: begin
        if (clk_tx) begin
          if (bitpos == 3'd7) state <= STATE_STOP;
          else bitpos <= bitpos + 3'd1;
          txd <= data[bitpos];
        end
      end
      STATE_STOP: begin
        if (clk_tx) begin
          txd   <= 1'd1;
          state <= STATE_IDLE;
        end
      end
      default: begin
        txd   <= 1'd1;
        state <= STATE_IDLE;
      end
    endcase
  end

  assign busy = (state != STATE_IDLE);

endmodule
