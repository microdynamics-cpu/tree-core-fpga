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
    input      [127:0] app_rdata,

    // test
    output [31:0] test_pin
);


  localparam WORK_WAIT_INIT = 3'd0;
  localparam WORK_FILL_INIT = 3'd1;
  localparam WORK_FILL_WT = 3'd2;
  localparam WORK_CHECK_INIT = 3'd3;
  localparam WORK_CHECK_RD = 3'd4;
  localparam WORK_CHECK_COMP = 3'd5;

  localparam WR_CMD = 3'h0;
  localparam RD_CMD = 3'h1;

  reg [  3:0] work_state;
  reg [ 26:0] int_app_addr;

  reg [  7:0] work_counter;
  reg [  5:0] wr_cnt;

  reg [127:0] rdata_buf    [5:0];
  reg [  2:0] rdata_idx;

  // int_app_addr: bank: [3bit] row: [13bit] col: [10bit]
  assign app_addr = {1'b0, int_app_addr};

  always @(posedge clk or negedge rstn) begin
    if (rstn == 1'b0) begin
      work_state       <= WORK_WAIT_INIT;

      int_app_addr     <= 27'd0;
      app_burst_number <= 6'd0;
      app_cmd_en       <= 1'b0;
      app_cmd          <= 3'd0;
      app_wdata_en     <= 1'b0;
      app_wdata_end    <= 1'b0;
      app_wdata        <= 128'd0;

      work_counter     <= 8'd0;
      wr_cnt           <= 6'd0;
      rdata_idx        <= 3'd0;
    end else begin
      // read_buf_s1 <= read_buf_s0;
      // read_buf_s0 <= read_data[read_data_pos];
      work_counter <= work_counter + 1'd1;
      case (work_state)
        WORK_WAIT_INIT: begin
          if (init_calib_complete == 1'b0) work_counter <= 8'd0;
          if (work_counter == 8'd255) work_state <= WORK_FILL_INIT;
        end

        WORK_FILL_INIT: begin
          if (app_cmd_rdy && app_wdata_rdy) begin
            app_cmd_en       <= 1'd1;
            app_cmd          <= WR_CMD;
            int_app_addr     <= 27'd0;
            app_burst_number <= 6'd3;
            work_state       <= WORK_FILL_WT;

            app_wdata_en     <= 1'd1;
            app_wdata_end    <= 1'd1;
            app_wdata        <= 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;
            wr_cnt           <= wr_cnt + 1'd1;
          end
        end

        WORK_FILL_WT: begin
          app_cmd_en <= 1'd0;
          if (app_wdata_rdy) begin
            if (wr_cnt == 6'd3) begin
              app_wdata_en  <= 1'd0;
              app_wdata_end <= 1'd0;
              wr_cnt        <= 6'd0;
              work_state    <= WORK_CHECK_INIT;
            end else begin
              app_wdata_en  <= 1'd1;
              app_wdata_end <= 1'd1;
              app_wdata     <= 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;
              wr_cnt        <= wr_cnt + 1'd1;
            end
          end else begin
            app_wdata_en  <= 1'd0;
            app_wdata_end <= 1'd0;
          end
        end

        WORK_CHECK_INIT: begin
          if (app_cmd_rdy) begin
            app_cmd_en       <= 1'd1;
            app_cmd          <= RD_CMD;
            int_app_addr     <= 27'd0;
            app_burst_number <= 6'd3;
            work_state       <= WORK_CHECK_RD;
            rdata_idx        <= 3'd0;
          end
        end

        WORK_CHECK_RD: begin
          app_cmd_en <= 1'd0;
          if (app_rdata_valid) begin
            rdata_buf[rdata_idx] <= app_rdata;
            rdata_idx            <= rdata_idx + 1'd1;
            if (rdata_idx == 3'd3) begin
              work_state <= WORK_CHECK_COMP;
              rdata_idx  <= 3'd0;
            end
          end
        end

        WORK_CHECK_COMP: begin

        end
        default: begin
          work_state <= WORK_WAIT_INIT;
        end
      endcase

    end
  end

  assign test_pin = rdata_buf[0];

endmodule
