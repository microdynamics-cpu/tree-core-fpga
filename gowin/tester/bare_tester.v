module bare_tester (
    input clk,
    input rstn,

    input              init_calib_complete,
    output reg [  5:0] app_burst_number,
    output     [ 27:0] app_addr,
    output reg         app_cmd_en,
    output reg [  2:0] app_cmd,
    input              app_cmd_rdy,
    output reg         app_wdata_en,
    output reg         app_wdata_end,
    output reg [127:0] app_wdata,
    input              app_wdata_rdy,
    input              app_rdata_valid,
    input              app_rdata_end,
    input      [127:0] app_rdata
);


  localparam FSM_WAIT_INIT = 3'd0;
  localparam FSM_FILL_INIT = 3'd1;
  localparam FSM_FILL_WT = 3'd2;
  localparam FSM_CHECK_INIT = 3'd3;
  localparam FSM_CHECK_RD = 3'd4;
  localparam FSM_CHECK_COMP = 3'd5;
  localparam FSM_CHECK_FAIL = 3'd6;

  localparam WR_CMD = 3'h0;
  localparam RD_CMD = 3'h1;
  localparam INIT_DATA = 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3218;
  localparam DATA_NUM = 4;

  reg [  3:0] state;
  reg [ 26:0] int_app_addr;

  reg [  7:0] init_cnt;
  reg [  5:0] wt_cnt;

  reg [127:0] rdata_buf    [5:0];
  reg [  2:0] rdata_idx;
  reg         sw_flag;
  reg [  2:0] addr_offset;

  initial begin
    for (integer i = 0; i < 6; i = i + 1) begin
      rdata_buf[i] <= 'd0;
    end
  end
  // int_app_addr: bank: [3bit] row: [13bit] col: [10bit]
  assign app_addr = {1'b0, int_app_addr};

  always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0) begin
      state            <= FSM_WAIT_INIT;

      int_app_addr     <= 'd0;
      app_burst_number <= 'd0;
      app_cmd_en       <= 'b0;
      app_cmd          <= 'd0;
      app_wdata_en     <= 'b0;
      app_wdata_end    <= 'b0;
      app_wdata        <= 'd0;
      init_cnt         <= 'd0;
      wt_cnt           <= 'd0;
      rdata_idx        <= 'd0;
      addr_offset      <= 'd0;
      sw_flag          <= 'd0;
    end else begin
      init_cnt <= init_cnt + 1'd1;
      case (state)
        FSM_WAIT_INIT: begin
          if (init_calib_complete == 1'b0) init_cnt <= 8'd0;
          if (init_cnt == 8'd255) state <= FSM_FILL_INIT;
        end

        FSM_FILL_INIT: begin
          if (app_cmd_rdy && app_wdata_rdy) begin
            app_cmd_en       <= 1'd1;
            app_cmd          <= WR_CMD;
            int_app_addr     <= addr_offset;
            app_wdata        <= (~addr_offset) ? INIT_DATA : app_wdata + 1;
            app_burst_number <= DATA_NUM - 1;
            state            <= FSM_FILL_WT;
            app_wdata_en     <= 1'd1;
            app_wdata_end    <= 1'd1;
            wt_cnt           <= 'd0;
          end
        end

        FSM_FILL_WT: begin
          app_cmd_en <= 1'd0;
          if (app_wdata_rdy) begin
            if (wt_cnt == DATA_NUM - 1) begin
              app_wdata_en  <= 'd0;
              app_wdata_end <= 'd0;
              app_wdata     <= 'd0;
              wt_cnt        <= 'd0;
              state         <= FSM_CHECK_INIT;
            end else begin
              app_wdata_en  <= 1'd1;
              app_wdata_end <= 1'd1;
              app_wdata     <= app_wdata + 1'd1;
              wt_cnt        <= wt_cnt + 1'd1;
            end
          end else begin
            app_wdata_en  <= 1'd0;
            app_wdata_end <= 1'd0;
          end
        end

        FSM_CHECK_INIT: begin
          if (app_cmd_rdy) begin
            app_cmd_en       <= 1'd1;
            app_cmd          <= RD_CMD;
            int_app_addr     <= addr_offset;  // because wt add
            app_burst_number <= DATA_NUM - 1;
            state            <= FSM_CHECK_RD;
            rdata_idx        <= 'd0;
          end
        end

        FSM_CHECK_RD: begin
          app_cmd_en <= 1'd0;
          if (app_rdata_valid) begin
            if (rdata_idx == 3'd3) begin
              state       <= FSM_FILL_INIT;
              rdata_idx   <= 'd0;
              addr_offset <= addr_offset + 1;
            end
            rdata_buf[rdata_idx] <= app_rdata;
            rdata_idx            <= rdata_idx + 1'd1;
          end
        end

        FSM_CHECK_COMP: begin

        end
        FSM_CHECK_FAIL: begin

        end
        default: begin
          state <= FSM_WAIT_INIT;
        end
      endcase

    end
  end
endmodule
