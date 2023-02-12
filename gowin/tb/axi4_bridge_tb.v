`timescale 1ns / 1ps

module axi4_bridge_tb ();
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
    $dumpfile("build/axi4_bridge.wave");
    $dumpvars(0, axi4_bridge_tb);
  end


  localparam WAIT_INIT = 3'd0;
  localparam FILL_INIT = 3'd1;
  localparam FILL_WT = 3'd2;
  localparam CHECK_INIT = 3'd3;
  localparam CHECK_RD = 3'd4;
  localparam CHECK_COMP = 3'd5;

  localparam TYPE_WIDTH = 2;
  localparam ADDR_WIDTH = 27;
  localparam BRST_WIDTH = 6;
  localparam DATA_WIDTH = 128;
  localparam MASK_WIDTH = 16;
  localparam DATA_NUM = 8;
  localparam DATA_ADDR = $clog2(DATA_NUM);


  localparam FIFO_IDE_TYPE = 2'd0;
  localparam FIFO_CMD_TYPE = 2'd1;
  localparam FIFO_WT_TYPE = 2'd2;
  localparam FIFO_RD_TYPE = 2'd3;

  wire                  clk_mem_div4;

  reg                   fifo_cmd_valid;
  wire                  fifo_cmd_ready;
  reg  [TYPE_WIDTH-1:0] fifo_cmd_type;
  reg  [ADDR_WIDTH-1:0] fifo_cmd_addr;
  reg  [BRST_WIDTH-1:0] fifo_cmd_burst_cnt;
  reg                   fifo_wt_valid;
  reg  [DATA_WIDTH-1:0] fifo_cmd_wt_data;
  reg  [MASK_WIDTH-1:0] fifo_cmd_wt_mask;

  reg                   fifo_rsp_valid;
  wire                  fifo_rsp_ready;
  wire [DATA_WIDTH-1:0] fifo_rsp_data;

  wire [BRST_WIDTH-1:0] ddr3_burst_number;
  wire                  ddr3_cmd_ready;
  wire [           2:0] ddr3_cmd;
  wire                  ddr3_cmd_en;
  wire [ADDR_WIDTH-1:0] ddr3_addr;
  wire                  ddr3_wdata_ready;
  wire [DATA_WIDTH-1:0] ddr3_wdata;
  wire                  ddr3_wdata_en;
  wire                  ddr3_wdata_end;
  wire [MASK_WIDTH-1:0] ddr3_wdata_mask;
  wire [DATA_WIDTH-1:0] ddr3_rdata;
  wire                  ddr3_rdata_valid;
  wire                  ddr3_rdata_end;
  wire                  ddr3_init_calib_complete;


  reg  [           2:0] state;
  reg  [ DATA_ADDR-1:0] wt_cnt;
  reg  [ DATA_ADDR-1:0] rd_cnt;

  always @(posedge clk_25MHz or negedge rstn) begin
    if (~rstn) begin
      state              <= WAIT_INIT;
      wt_cnt             <= 'd0;
      rd_cnt             <= 'd0;
      fifo_cmd_valid     <= 'd1;
      fifo_cmd_type      <= FIFO_IDE_TYPE;
      fifo_cmd_addr      <= 'd0;
      fifo_cmd_burst_cnt <= 'd0;
      fifo_wt_valid      <= 'd0;
      fifo_cmd_wt_data   <= 'd0;
      fifo_cmd_wt_mask   <= 'hFFFF;
      fifo_rsp_valid     <= 'd0;
    end else begin
      case (state)
        WAIT_INIT: begin
          if (ddr3_init_calib_complete) state <= FILL_INIT;
        end
        FILL_INIT: begin
          if (fifo_cmd_valid && fifo_cmd_ready) begin
            state              <= FILL_WT;
            wt_cnt             <= wt_cnt + 1'd1;
            fifo_cmd_type      <= FIFO_CMD_TYPE;
            fifo_cmd_addr      <= 'd0;
            fifo_cmd_burst_cnt <= DATA_NUM - 1;
            fifo_wt_valid      <= 1'd1;
            fifo_cmd_wt_data   <= 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;
            fifo_cmd_wt_mask   <= fifo_cmd_wt_mask << 1;
            fifo_rsp_valid     <= 1'd0;
          end
        end
        FILL_WT: begin
          fifo_cmd_valid <= 1'd0;
          if (fifo_wt_valid && fifo_cmd_ready) begin
            if (wt_cnt == DATA_NUM - 1) begin
              state          <= CHECK_INIT;
              wt_cnt         <= 'd0;
              fifo_cmd_type  <= FIFO_IDE_TYPE;
              fifo_cmd_valid <= 1'd1;
            end else begin
              wt_cnt           <= wt_cnt + 1'd1;
              fifo_cmd_wt_data <= fifo_cmd_wt_data + 1'd1;
              fifo_cmd_wt_mask <= fifo_cmd_wt_mask << 1;
            end
          end
        end
        CHECK_INIT: begin
          if (fifo_cmd_valid && fifo_cmd_ready) begin
            state              <= CHECK_RD;
            rd_cnt             <= rd_cnt + 1'd1;
            fifo_cmd_type      <= FIFO_CMD_TYPE;
            fifo_cmd_addr      <= 'd0;
            fifo_cmd_burst_cnt <= DATA_NUM - 1;
            fifo_rsp_valid     <= 1'd1;
          end
        end
        CHECK_RD: begin
          if (fifo_rsp_valid && fifo_rsp_ready) begin
            if (rd_cnt == DATA_NUM - 1) begin
              state          <= CHECK_COMP;
              rd_cnt         <= 'd0;
              fifo_cmd_type  <= FIFO_IDE_TYPE;
              fifo_cmd_valid <= 1'd1;
            end else begin
              rd_cnt <= rd_cnt + 1'd1;
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

  axi4_bridge u_axi4_bridge (
      .clk    (clk_25MHz),
      .clk_ref(clk_mem_div4),
      .rstn   (rstn),

      .io_fifo_cmd_valid    (fifo_cmd_valid || fifo_wt_valid),
      .io_fifo_cmd_ready    (fifo_cmd_ready),
      .io_fifo_cmd_type     (fifo_cmd_type),
      .io_fifo_cmd_addr     (fifo_cmd_addr),
      .io_fifo_cmd_burst_cnt(fifo_cmd_burst_cnt),
      .io_fifo_cmd_wt_data  (fifo_cmd_wt_data),
      .io_fifo_cmd_wt_mask  (fifo_cmd_wt_mask),
      .io_fifo_rsp_valid    (fifo_rsp_valid),
      .io_fifo_rsp_ready    (fifo_rsp_ready),
      .io_fifo_rsp_data     (fifo_rsp_data),

      .io_app_burst_number       (ddr3_burst_number),
      .io_app_cmd_ready          (ddr3_cmd_ready),
      .io_app_cmd                (ddr3_cmd),
      .io_app_cmd_en             (ddr3_cmd_en),
      .io_app_addr               (ddr3_addr),
      .io_app_wdata_ready        (ddr3_wdata_ready),
      .io_app_wdata              (ddr3_wdata),
      .io_app_wdata_en           (ddr3_wdata_en),
      .io_app_wdata_end          (ddr3_wdata_end),
      .io_app_wdata_mask         (ddr3_wdata_mask),
      .io_app_rdata              (ddr3_rdata),
      .io_app_rdata_valid        (ddr3_rdata_valid),
      .io_app_rdata_end          (ddr3_rdata_end),
      .io_app_init_calib_complete(ddr3_init_calib_complete)
  );


  // bank: [2:0](8) row: [13:0](16k) col: [9~0](1024, 1k) cell: 16bits
  DDR3_Memory_Interface_Top u_ddr3_ctrl (
      .memory_clk         (clk_400MHz),
      .clk                (clk_25MHz),
      .pll_lock           (lock),
      .rst_n              (rstn),
      .app_burst_number   (ddr3_burst_number),
      .cmd_ready          (ddr3_cmd_ready),
      .cmd                (ddr3_cmd),
      .cmd_en             (ddr3_cmd_en),
      .addr               ({1'b0, ddr3_addr}),
      .wr_data_rdy        (ddr3_wdata_ready),
      .wr_data            (ddr3_wdata),
      .wr_data_en         (ddr3_wdata_en),
      .wr_data_end        (ddr3_wdata_end),
      .wr_data_mask       (ddr3_wdata_mask),
      .rd_data            (ddr3_rdata),
      .rd_data_valid      (ddr3_rdata_valid),
      .rd_data_end        (ddr3_rdata_end),
      .sr_req             (1'b0),
      .ref_req            (1'b0),
      .sr_ack             (),
      .ref_ack            (),
      .init_calib_complete(ddr3_init_calib_complete),
      .clk_out            (clk_mem_div4),
      .ddr_rst            (),
      .burst              (1'b1),

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
