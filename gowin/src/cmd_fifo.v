module cmd_fifo (
    input rstn,

    input          push_valid,
    output         push_ready,
    input          push_clk,
    input          push_cmd_type,
    input  [ 26:0] push_addr,
    input  [  5:0] push_burst_cnt,
    input  [127:0] push_wt_data,
    input  [ 15:0] push_wt_mask,

    output         pop_valid,
    input          pop_ready,
    input          pop_clk,
    output         pop_cmd_type,
    output [ 26:0] pop_addr,
    output [  5:0] pop_burst_cnt,
    output [127:0] pop_wt_data,
    output [ 15:0] pop_wt_mask
);

  // 1 + 27 + 6 + 128 + 16 = 178bits
  wire [177:0] push_data;
  wire [177:0] pop_data;

  assign push_data = {push_cmd_type, push_addr, push_burst_cnt, push_wt_data, push_wt_mask};
  assign {pop_cmd_type, pop_addr, pop_burst_cnt, pop_wt_data, pop_wt_mask} = pop_data;

  FIFO_HS_CMD fifo_hs_cmd (
      .Data (push_data),
      .Reset(~rstn),
      .WrClk(push_clk),
      .RdClk(pop_clk),
      .WrEn (push_valid && push_ready),
      .RdEn (pop_valid && pop_ready),
      .Q    (pop_data),
      .Empty(~push_ready),
      .Full (~pop_ready)
  );

endmodule
