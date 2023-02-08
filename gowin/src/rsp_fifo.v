module rsp_fifo (
    input rstn,

    input          push_clk,
    input          io_push_valid,
    output         io_push_ready,
    input  [127:0] io_push_rsp_data,

    input          pop_clk,
    output         io_pop_valid,
    input          io_pop_ready,
    output [127:0] io_pop_rsp_data
);

  FIFO_HS_RSP fifo_hs_rsp (
      .Data (io_push_rsp_data),
      .Reset(~rstn),
      .WrClk(push_clk),
      .RdClk(pop_clk),
      .WrEn (io_push_valid && io_push_ready),
      .RdEn (io_pop_valid && io_pop_ready),
      .Q    (io_pop_rsp_data),
      .Empty(~io_push_ready),
      .Full (~io_pop_ready)
  );

endmodule
