module cmd_fifo (
    input rstn,

    input          push_clk,
    input          io_push_valid,
    output         io_push_ready,
    input  [  1:0] io_push_cmd_type,
    input  [ 26:0] io_push_addr,
    input  [  5:0] io_push_burst_cnt,
    input  [127:0] io_push_wt_data,
    input  [ 15:0] io_push_wt_mask,

    input          pop_clk,
    input          io_pop_valid,
    output         io_pop_ready,
    output [  1:0] io_pop_cmd_type,
    output [ 26:0] io_pop_addr,
    output [  5:0] io_pop_burst_cnt,
    output [127:0] io_pop_wt_data,
    output [ 15:0] io_pop_wt_mask
);

  // 2 + 27 + 6 + 128 + 16 = 179bits
  wire [178:0] push_data;
  wire [178:0] pop_data;
  wire         empty;
  wire         full;

  assign push_data = {
    io_push_cmd_type, io_push_addr, io_push_burst_cnt, io_push_wt_data, io_push_wt_mask
  };
  assign {io_pop_cmd_type, io_pop_addr, io_pop_burst_cnt, io_pop_wt_data, io_pop_wt_mask} = pop_data;

  assign io_push_ready = rstn && (~full);
  assign io_pop_ready = rstn && (~empty);

  FIFO_HS_CMD fifo_hs_cmd (
      .Data (push_data),
      .Reset(~rstn),
      .WrClk(push_clk),
      .RdClk(pop_clk),
      .WrEn (io_push_valid && io_push_ready),
      .RdEn (io_pop_valid && io_pop_ready),
      .Q    (pop_data),
      .Empty(empty),
      .Full (full)
  );

endmodule
