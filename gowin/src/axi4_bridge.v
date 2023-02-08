module axi4_bridge (
    input clk,      // 27MHz
    input clk_ref,  // 100MHz
    input rstn,

    // fifo cache slave
    input          io_fifo_cmd_valid,
    output         io_fifo_cmd_ready,
    input          io_fifo_cmd_type,
    input  [ 26:0] io_fifo_cmd_addr,
    input  [  5:0] io_fifo_cmd_burst_cnt,
    input  [127:0] io_fifo_cmd_wt_data,
    input  [ 15:0] io_fifo_cmd_wt_mask,
    output         io_fifo_rsp_valid,
    input          io_fifo_rsp_ready,
    output [127:0] io_fifo_rsp_data,

    // ddr3 master
    output     [  5:0] io_app_burst_number,
    input              io_app_cmd_ready,
    output reg [  2:0] io_app_cmd,
    output             io_app_cmd_en,
    output     [ 26:0] io_app_addr,
    input              io_app_wdata_ready,
    output     [127:0] io_app_wdata,
    output reg         io_app_wdata_en,
    output             io_app_wdata_end,
    output     [ 15:0] io_app_wdata_mask,
    input      [127:0] io_app_rdata,
    input              io_app_rdata_valid,
    input              io_app_rdata_end,
    input              io_init_calib_complete
);

  localparam WT_CMD = 3'd0;
  localparam RD_CMD = 3'd1;

  wire         cmd_valid;
  wire         cmd_ready;
  wire         cmd_type;
  wire [ 26:0] cmd_addr;
  wire [  5:0] cmd_burst_cnt;
  wire [127:0] cmd_wt_data;
  wire [ 15:0] cmd_wt_mask;
  wire         cmd_rsp_valid;
  wire         cmd_rsp_ready;
  wire [127:0] cmd_rsp_data;

  reg          int_cmd_type;
  reg  [ 26:0] int_cmd_addr;
  reg  [  5:0] int_cmd_burst_cnt;
  reg  [127:0] int_cmd_wt_data;
  reg  [ 15:0] int_cmd_wt_mask;


  // handshake signal
  reg          cmd_free;
  reg          cmd_can_send;
  reg          cmd_trigger;
  reg          cmd_en;
  reg  [  6:0] burst_cnt;
  wire         wt_fire;
  wire         rd_fire;
  wire         data_fire;
  reg  [ 26:0] int_app_addr;

  assign app_addr = int_app_addr;

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
      .io_pop_valid    (cmd_valid),
      .io_pop_ready    (cmd_ready),
      .io_pop_cmd_type (cmd_type),
      .io_pop_addr     (cmd_addr),
      .io_pop_burst_cnt(cmd_burst_cnt),
      .io_pop_wt_data  (cmd_wt_data),
      .io_pop_wt_ma    (cmd_wt_mask)
  );


  rsp_fifo u_rsp_fifo (
      .rstn(rstn),

      .push_clk        (clk_ref),
      .io_push_valid   (cmd_rsp_valid),
      .io_push_ready   (cmd_rsp_ready),
      .io_push_rsp_data(cmd_rsp_data),

      .pop_clk        (clk),
      .io_pop_valid   (io_fifo_rsp_valid),
      .io_pop_ready   (io_fifo_rsp_ready),
      .io_pop_rsp_data(io_fifo_rsp_data)
  );






  assign wt_fire             = io_app_wdata_en && io_app_wdata_ready;
  assign rd_fire             = io_app_rdata_valid;
  assign data_fire           = wt_fire || rd_fire;

  assign io_app_cmd_en       = cmd_en;
  assign io_app_burst_number = int_cmd_burst_cnt;

  assign cmd_rsp_valid       = io_app_rdata_valid;
  assign cmd_rsp_data        = io_app_rdata;

  always @(posedge clk_ref or negedge rstn) begin
    if (~rstn) begin
      cmd_free     <= 1'b1;
      cmd_can_send <= 1'b0;
      cmd_trigger  <= 1'b0;
      cmd_en       <= 1'b0;
      burst_cnt    <= 7'd0;
    end else begin
      cmd_can_send <= io_app_cmd_ready && io_app_wdata_ready && io_init_calib_complete;
      cmd_en       <= cmd_trigger;

    end
  end
endmodule
