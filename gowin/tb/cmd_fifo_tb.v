`timescale 1ns / 1ps

module cmd_fifo_tb ();
  reg rstn;
  reg clk_25MHz;
  reg clk_100MHz;
  always #20.000 clk_25MHz <= ~clk_25MHz;
  always #5.000 clk_100MHz <= ~clk_100MHz;

  initial begin
    clk_25MHz  = 1'b0;
    clk_100MHz = 1'b0;
    rstn       = 1'b0;
    #97 rstn = 1;  // 97 for aync to clk edge
    #3000 $finish;
  end


  initial begin
    $dumpfile("build/cmd_fifo.wave");
    $dumpvars(0, cmd_fifo_tb);
  end


  localparam TYPE_WIDTH = 2;
  localparam ADDR_WIDTH = 27;
  localparam BRST_WIDTH = 6;
  localparam DATA_WIDTH = 128;
  localparam MASK_WIDTH = 16;

  localparam FIFO_IDE_TYPE = 2'd0;
  localparam FIFO_CMD_TYPE = 2'd1;
  localparam FIFO_WT_TYPE = 2'd2;
  localparam FIFO_RD_TYPE = 2'd3;

  localparam FSM_IDLE = 2'd0;
  localparam FSM_WT = 2'd1;
  localparam FSM_RD = 2'd2;

  wire                  wt_clk;
  wire                  rd_clk;

  reg                   wt_rd_sw;
  reg  [           2:0] addr_offset;
  reg  [           1:0] state;
  reg  [           3:0] wt_cnt;
  reg                   push_valid;
  wire                  push_ready;
  reg  [TYPE_WIDTH-1:0] push_type;
  reg  [ADDR_WIDTH-1:0] push_addr;
  reg  [BRST_WIDTH-1:0] push_burst_cnt;
  reg  [DATA_WIDTH-1:0] push_wt_data;
  reg  [MASK_WIDTH-1:0] push_wt_mask;

  reg                   pop_valid;
  wire                  pop_ready;
  wire [TYPE_WIDTH-1:0] pop_type;
  wire [ADDR_WIDTH-1:0] pop_addr;
  wire [BRST_WIDTH-1:0] pop_burst_cnt;
  wire [DATA_WIDTH-1:0] pop_wt_data;
  wire [MASK_WIDTH-1:0] pop_wt_mask;

  assign wt_clk = clk_25MHz;
  assign rd_clk = clk_100MHz;

  always @(posedge wt_clk or negedge rstn) begin
    if (~rstn) begin
      state          <= FSM_IDLE;
      wt_rd_sw       <= 'd0;
      addr_offset    <= 'd0;
      wt_cnt         <= 'd0;
      push_valid     <= 'd0;
      push_type      <= FIFO_IDE_TYPE;
      push_addr      <= 'd0;
      push_burst_cnt <= 'd0;
      push_wt_data   <= 'd0;
      push_wt_mask   <= 'hFFFF;
    end else begin
      case (state)
        FSM_IDLE: begin
          wt_cnt     <= 'd0;
          push_valid <= 'd1;
          push_addr  <= (wt_rd_sw == 0) ? addr_offset : push_addr;
          if (~wt_rd_sw) begin
            state          <= FSM_WT;
            push_type      <= FIFO_WT_TYPE;
            push_burst_cnt <= 'd7;
            push_wt_data   <= 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;
            push_wt_mask   <= push_wt_mask << 1;
          end else begin
            state          <= FSM_RD;
            push_type      <= FIFO_RD_TYPE;
            push_burst_cnt <= 'd7;
          end
          wt_rd_sw    <= ~wt_rd_sw;
          addr_offset <= addr_offset + 1'd1;
        end
        FSM_WT: begin
          if (push_valid && push_ready) begin
            if (wt_cnt == push_burst_cnt) begin
              state          <= FSM_IDLE;
              wt_cnt         <= 'd0;
              push_valid     <= 'd0;
              push_type      <= FIFO_IDE_TYPE;
              push_addr      <= 'd0;
              push_burst_cnt <= 'd0;
              push_wt_data   <= 'd0;
              push_wt_mask   <= 'hFFFF;
            end else begin
              wt_cnt       <= wt_cnt + 1'd1;
              push_wt_data <= push_wt_data + 1'd1;
              push_wt_mask <= push_wt_mask << 1;
            end
          end
        end
        FSM_RD: begin
          if (push_valid && push_ready) begin
            state <= FSM_IDLE;
          end
        end
        default: begin
          state <= FSM_IDLE;
        end
      endcase
    end
  end

  always @(posedge rd_clk or negedge rstn) begin
    if (~rstn) begin
      pop_valid <= 'd1;
    end
  end

  cmd_fifo u_cmd_fifo (
      .rstn(rstn),

      .push_clk         (wt_clk),
      .io_push_valid    (push_valid),
      .io_push_ready    (push_ready),
      .io_push_cmd_type (push_type),
      .io_push_addr     (push_addr),
      .io_push_burst_cnt(push_burst_cnt),
      .io_push_wt_data  (push_wt_data),
      .io_push_wt_mask  (push_wt_mask),

      .pop_clk         (rd_clk),
      .io_pop_valid    (pop_valid),
      .io_pop_ready    (pop_ready),
      .io_pop_cmd_type (pop_type),
      .io_pop_addr     (pop_addr),
      .io_pop_burst_cnt(pop_burst_cnt),
      .io_pop_wt_data  (pop_wt_data),
      .io_pop_wt_mask  (pop_wt_mask)
  );
endmodule
