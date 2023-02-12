`timescale 1ns / 1ps

module ddr3_tb ();
  reg lock;
  reg rstn;
  reg clk_25MHz;
  reg clk_400MHz;
  always #20.000 clk_25MHz <= ~clk_25MHz;
  always #2.500 clk_400MHz <= ~clk_400MHz;

  initial begin
    clk_25MHz  = 1'd0;
    clk_400MHz = 1'd0;
    lock       = 1'd0;
    rstn       = 1'd0;
    #40 rstn = 1'd1;
    #97 lock = 1;  // 97 for aync to clk edge
    #500 $finish;
  end


  initial begin
    $dumpfile("build/ddr3.wave");
    $dumpvars(0, ddr3_tb);
  end


  localparam WAIT_INIT = 3'd0;
  localparam FILL_INIT = 3'd1;
  localparam FILL_WT = 3'd2;
  localparam CHECK_INIT = 3'd3;
  localparam CHECK_RD = 3'd4;
  localparam CHECK_COMP = 3'd5;

  localparam WT_CMD = 3'd0;
  localparam RD_CMD = 3'd1;

  localparam WIDTH = 128;
  localparam DDR3_ADDR = 28;
  localparam DATA_NUM = 8;
  localparam DATA_ADDR = $clog2(DATA_NUM);

  // MSB: |rank: 0 | bank: [3bit] | row: 0 [13bit] | col: [10bit]
  wire                   clk_mem_div4;
  wire                   int_app_init_calib_complete;
  wire                   int_app_cmd_ready;
  reg                    int_app_cmd_en;
  reg  [            2:0] int_app_cmd;
  reg  [DDR3_ADDR-1 : 0] int_app_addr;
  reg  [            5:0] int_app_burst_number;
  wire                   int_app_wdata_ready;
  reg                    int_app_wdata_en;
  reg                    int_app_wdata_end;
  reg  [           15:0] int_app_wdata_mask;
  reg  [      WIDTH-1:0] int_app_wdata;
  wire                   int_app_rdata_valid;
  wire                   int_app_rdata_end;
  wire [      WIDTH-1:0] int_app_rdata;


  reg  [            2:0] state;
  reg  [  DATA_ADDR-1:0] wt_cnt;
  reg  [  DATA_ADDR-1:0] rdata_ptr;
  reg  [      WIDTH-1:0] mem                         [0:DATA_NUM-1];


  always @(posedge clk_mem_div4 or negedge lock) begin
    if (~lock) begin
      state                <= WAIT_INIT;
      int_app_addr         <= 'd0;
      int_app_burst_number <= 'd0;
      int_app_cmd_en       <= 'd0;
      int_app_cmd          <= 'd0;
      int_app_wdata_en     <= 'd0;
      int_app_wdata_end    <= 'd0;
      int_app_wdata_mask   <= 'd0;
      int_app_wdata        <= 'd0;
      wt_cnt               <= 'd0;
      rdata_ptr            <= 'd0;
    end else begin
      case (state)
        WAIT_INIT: begin
          if (int_app_init_calib_complete) state <= FILL_INIT;
        end

        FILL_INIT: begin
          if (int_app_cmd_ready && int_app_wdata_ready) begin
            int_app_cmd_en       <= 1'd1;
            int_app_cmd          <= WT_CMD;
            int_app_addr         <= {DDR3_ADDR{1'd0}};
            int_app_burst_number <= DATA_NUM - 1;

            int_app_wdata_en     <= 1'd1;
            int_app_wdata_end    <= 1'd1;
            int_app_wdata        <= 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;
            wt_cnt               <= wt_cnt + 1'd1;
            state                <= FILL_WT;
          end
        end

        FILL_WT: begin
          int_app_cmd_en <= 1'd0;
          if (int_app_wdata_ready) begin
            if (wt_cnt == DATA_NUM - 1) begin
              int_app_wdata_en  <= 1'd0;
              int_app_wdata_end <= 1'd0;
              wt_cnt            <= {DATA_ADDR{1'd0}};
              state             <= CHECK_INIT;
            end else begin
              int_app_wdata_en  <= 1'd1;
              int_app_wdata_end <= 1'd1;
              int_app_wdata     <= int_app_wdata + 1'd1;
              wt_cnt            <= wt_cnt + 1'd1;
            end
          end
        end

        CHECK_INIT: begin
          if (int_app_cmd_ready) begin
            int_app_cmd_en       <= 1'd1;
            int_app_cmd          <= RD_CMD;
            int_app_addr         <= {DDR3_ADDR{1'd0}};
            int_app_burst_number <= DATA_NUM - 1;
            state                <= CHECK_RD;
            rdata_ptr            <= 3'd0;
          end
        end

        CHECK_RD: begin
          int_app_cmd_en <= 1'd0;
          if (int_app_rdata_valid) begin
            mem[rdata_ptr] <= int_app_rdata;
            rdata_ptr      <= rdata_ptr + 1'd1;
            if (rdata_ptr == 3'd3) begin
              state     <= CHECK_COMP;
              rdata_ptr <= 3'd0;
            end
          end
        end

        CHECK_COMP: begin
        end
        default: begin
          state <= WAIT_INIT;
        end
      endcase
    end
  end

  DDR3_Memory_Interface_Top u_ddr3_ctrl (
      .memory_clk         (clk_400MHz),
      .clk                (clk_25MHz),
      .pll_lock           (lock),
      .rst_n              (rstn),
      .app_burst_number   (int_app_burst_number),
      .cmd_ready          (int_app_cmd_ready),
      .cmd                (int_app_cmd),
      .cmd_en             (int_app_cmd_en),
      .addr               (int_app_addr),
      .wr_data_rdy        (int_app_wdata_ready),
      .wr_data            (int_app_wdata),
      .wr_data_en         (int_app_wdata_en),
      .wr_data_end        (int_app_wdata_end),
      .wr_data_mask       (int_app_wdata_mask),
      .rd_data            (int_app_rdata),
      .rd_data_valid      (int_app_rdata_valid),
      .rd_data_end        (int_app_rdata_end),
      .sr_req             (1'd0),
      .ref_req            (1'd0),
      .sr_ack             (),
      .ref_ack            (),
      .init_calib_complete(int_app_init_calib_complete),
      .clk_out            (clk_mem_div4),
      .ddr_rst            (),
      .burst              (1'd1),

      .O_ddr_addr   (),
      .O_ddr_ba     (),
      .O_ddr_cs_n   (),
      .O_ddr_ras_n  (),
      .O_ddr_cas_n  (),
      .O_ddr_we_n   (),
      .O_ddr_clk    (),
      .O_ddr_clk_n  (),
      .O_ddr_cke    (),
      .O_ddr_odt    (),
      .O_ddr_reset_n(),
      .O_ddr_dqm    (),
      .IO_ddr_dq    (),
      .IO_ddr_dqs   (),
      .IO_ddr_dqs_n ()
  );

endmodule
