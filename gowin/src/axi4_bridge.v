module axi4_bridge #(
    parameter TYPE_WIDTH = 2,
    parameter ADDR_WIDTH = 27,
    parameter BRST_WIDTH = 6,
    parameter DATA_WIDTH = 128,
    parameter MASK_WIDTH = 16

) (
    input clk,      // 25MHz
    input clk_ref,  // 100MHz
    input rstn,

    // fifo cache slave
    input                   io_fifo_cmd_valid,
    output                  io_fifo_cmd_ready,
    input  [TYPE_WIDTH-1:0] io_fifo_cmd_type,
    input  [ADDR_WIDTH-1:0] io_fifo_cmd_addr,
    input  [BRST_WIDTH-1:0] io_fifo_cmd_burst_cnt,
    input  [DATA_WIDTH-1:0] io_fifo_cmd_wt_data,
    input  [MASK_WIDTH-1:0] io_fifo_cmd_wt_mask,
    input                   io_fifo_rsp_valid,
    output                  io_fifo_rsp_ready,
    output [DATA_WIDTH-1:0] io_fifo_rsp_data,

    // ddr3 master
    output reg [BRST_WIDTH-1:0] io_app_burst_number,
    input                       io_app_cmd_ready,
    output reg [           2:0] io_app_cmd,
    output reg                  io_app_cmd_en,
    output reg [ADDR_WIDTH-1:0] io_app_addr,
    input                       io_app_wdata_ready,
    output reg [DATA_WIDTH-1:0] io_app_wdata,
    output reg                  io_app_wdata_en,
    output reg                  io_app_wdata_end,
    output reg [MASK_WIDTH-1:0] io_app_wdata_mask,
    input      [DATA_WIDTH-1:0] io_app_rdata,
    input                       io_app_rdata_valid,
    input                       io_app_rdata_end,           // no used
    input                       io_app_init_calib_complete
);

  localparam FIFO_IDE_TYPE = 2'd0;
  localparam FIFO_CMD_TYPE = 2'd1;
  localparam FIFO_WT_TYPE = 2'd2;
  localparam FIFO_RD_TYPE = 2'd3;

  localparam DDR_WT_CMD = 3'd0;
  localparam DDR_RD_CMD = 3'd1;

  wire                  pop_cmd_valid;
  wire                  pop_cmd_ready;
  wire [TYPE_WIDTH-1:0] pop_cmd_type;
  wire [ADDR_WIDTH-1:0] pop_cmd_addr;
  wire [BRST_WIDTH-1:0] pop_cmd_burst_cnt;
  wire [DATA_WIDTH-1:0] pop_cmd_wt_data;
  wire [MASK_WIDTH-1:0] pop_cmd_wt_mask;
  wire                  push_rsp_valid;
  wire                  push_rsp_ready;
  wire [DATA_WIDTH-1:0] push_rsp_data;


  reg                   int_cmd_en;
  reg  [  BRST_WIDTH:0] burst_cnt;  // for compare with 64 burst + 1
  wire                  app_wt_fire;
  wire                  app_rd_fire;
  wire                  app_data_fire;

  assign pop_cmd_valid  = io_app_init_calib_complete && io_app_cmd_ready && io_app_wdata_ready;
  assign push_rsp_valid = io_app_rdata_valid;  // end is same as valid, not used
  assign push_rsp_data  = (push_rsp_valid && push_rsp_ready) ? io_app_rdata : 'd0;

  assign app_wt_fire    = io_app_wdata_en && io_app_wdata_ready;
  assign app_rd_fire    = io_app_rdata_valid;
  assign app_data_fire  = app_wt_fire || app_rd_fire;

  always @(posedge clk_ref or negedge rstn) begin
    if (~rstn) begin
      io_app_burst_number <= 'd0;
      io_app_cmd          <= DDR_WT_CMD;
      io_app_cmd_en       <= 'd0;
      io_app_addr         <= 'd0;
      io_app_wdata        <= 'd0;
      io_app_wdata_en     <= 'd0;
      io_app_wdata_end    <= 'd0;
      io_app_wdata_mask   <= 'hFFFF;
      burst_cnt           <= 'd0;
    end else begin
      // handle the new cmd fifo data
      if (pop_cmd_valid && pop_cmd_ready) begin
        if (pop_cmd_type == FIFO_CMD_TYPE) begin
          io_app_burst_number <= pop_cmd_burst_cnt;
          io_app_cmd          <= DDR_WT_CMD;
          io_app_cmd_en       <= 1'd1;
          io_app_addr         <= pop_cmd_addr;
          io_app_wdata        <= pop_cmd_wt_data;
          io_app_wdata_en     <= (burst_cnt != io_app_burst_number + 1'd1) && io_app_wdata_ready;
          io_app_wdata_end    <= (burst_cnt != io_app_burst_number + 1'd1) && io_app_wdata_ready;
          io_app_wdata_mask   <= pop_cmd_wt_mask;
          burst_cnt           <= 7'd0;
        end else if (pop_cmd_type == FIFO_WT_TYPE) begin
          io_app_wdata      <= pop_cmd_wt_data;
          io_app_wdata_en   <= (burst_cnt != io_app_burst_number + 1'd1) && io_app_wdata_ready;
          io_app_wdata_end  <= (burst_cnt != io_app_burst_number + 1'd1) && io_app_wdata_ready;
          io_app_wdata_mask <= pop_cmd_wt_mask;
        end else if (pop_cmd_type == FIFO_RD_TYPE) begin
          io_app_burst_number <= pop_cmd_burst_cnt;
          io_app_cmd          <= DDR_RD_CMD;
          io_app_cmd_en       <= 1'd1;
          io_app_addr         <= pop_cmd_addr;
          io_app_wdata_en     <= 1'd0;
          io_app_wdata_end    <= 1'd0;
          burst_cnt           <= 7'd0;
        end
      end

      // only keep one cycle
      if (int_cmd_en) int_cmd_en <= 1'd0;
      if (app_data_fire) burst_cnt <= burst_cnt + 1'd1;
      if (burst_cnt == io_app_burst_number + 1'd1) begin

      end
    end
  end

  cmd_fifo u_cmd_fifo (
      .rstn(rstn),

      .push_clk         (clk),
      .io_push_valid    (io_fifo_cmd_valid),
      .io_push_ready    (io_fifo_cmd_ready),
      .io_push_cmd_type (io_fifo_cmd_type),
      .io_push_addr     (io_fifo_cmd_addr),
      .io_push_burst_cnt(io_fifo_cmd_burst_cnt),
      .io_push_wt_data  (io_fifo_cmd_wt_data),
      .io_push_wt_mask  (io_fifo_cmd_wt_mask),

      .pop_clk         (clk_ref),
      .io_pop_valid    (pop_cmd_valid),
      .io_pop_ready    (pop_cmd_ready),
      .io_pop_cmd_type (pop_cmd_type),
      .io_pop_addr     (pop_cmd_addr),
      .io_pop_burst_cnt(pop_cmd_burst_cnt),
      .io_pop_wt_data  (pop_cmd_wt_data),
      .io_pop_wt_mask  (pop_cmd_wt_mask)
  );

  rsp_fifo u_rsp_fifo (
      .rstn(rstn),

      .push_clk        (clk_ref),
      .io_push_valid   (push_rsp_valid),
      .io_push_ready   (push_rsp_ready),
      .io_push_rsp_data(push_rsp_data),

      .pop_clk        (clk),
      .io_pop_valid   (io_fifo_rsp_valid),
      .io_pop_ready   (io_fifo_rsp_ready),
      .io_pop_rsp_data(io_fifo_rsp_data)
  );

endmodule
