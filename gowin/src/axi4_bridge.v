module axi4_bridge (
    input clk,      // 27MHz
    input clk_ref,  // 100MHz
    input rstn,

    // fifo cache slave
    input          fifo_cmd_valid,
    output         fifo_cmd_rdy,
    input          fifo_cmd_type,
    input  [ 26:0] fifo_cmd_addr,
    input  [  5:0] fifo_cmd_burst_cnt,
    input  [127:0] fifo_cmd_wt_data,
    input  [ 15:0] fifo_cmd_wt_mask,
    output         fifo_rsp_valid,
    input          fifo_rsp_rdy,
    output [127:0] fifo_rsp_data,

    // ddr3 ip interface
    output reg [  5:0] app_burst_number,
    input              app_cmd_rdy,
    output reg [  2:0] app_cmd,
    output reg         app_cmd_en,
    output     [ 26:0] app_addr,
    input              app_wdata_rdy,
    output reg [127:0] app_wdata,
    output reg         app_wdata_en,
    output reg         app_wdata_end,
    output reg [ 15:0] app_wdata_mask,
    input      [127:0] app_rdata,
    input              app_rdata_valid,
    input              app_rdata_end,
    input              init_calib_complete
);

  localparam FSM_IDLE = 3'd0;
  localparam FSM_AW = 3'd1;
  localparam FSM_WT = 3'd2;
  localparam FSM_RSP = 3'd3;
  localparam FSM_AR = 3'd4;
  localparam FSM_RD = 3'd5;

  localparam WT_CMD = 3'd0;
  localparam RD_CMD = 3'd1;

  reg [ 3:0] state;
  reg [26:0] int_app_addr;
  assign app_addr = int_app_addr;

  reg  cmd_free;
  wire cmd_can_send;
  assign cmd_can_send = app_cmd_rdy && app_wdata_rdy && init_calib_complete;

  // handshake signal
  wire wt_fire;
  wire rd_fire;
  wire data_fire;

  assign wt_fire   = app_wdata_en && app_wdata_rdy;
  assign rd_fire   = app_rdata_valid;
  assign data_fire = wt_fire || rd_fire;

  always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      state            <= FSM_IDLE;
      int_app_addr     <= 27'd0;

      app_burst_number <= 6'd0;
      app_cmd_en       <= 1'b0;
      app_cmd          <= 3'd0;
      app_wdata_en     <= 1'b0;
      app_wdata_end    <= 1'b0;
      app_wdata        <= 128'd0;
    end else begin
    end
  end
endmodule
