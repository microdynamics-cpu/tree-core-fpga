module rsp_fifo (
    input rstn,

    input          push_clk,
    input          io_push_valid,
    output         io_push_ready,
    input  [127:0] io_push_rsp_data,

    input          pop_clk,
    input          io_pop_valid,
    output         io_pop_ready,
    output [127:0] io_pop_rsp_data
);

  wire empty;
  wire full;
  assign io_push_ready = rstn && (~full);
  assign io_pop_ready  = rstn && (~empty);

  FIFO_HS_RSP fifo_hs_rsp (
      .Data (io_push_rsp_data),
      .Reset(~rstn),
      .WrClk(push_clk),
      .RdClk(pop_clk),
      .WrEn (io_push_valid && io_push_ready),
      .RdEn (io_pop_valid && io_pop_ready),
      .Q    (io_pop_rsp_data),
      .Empty(empty),
      .Full (full)
  );

endmodule
