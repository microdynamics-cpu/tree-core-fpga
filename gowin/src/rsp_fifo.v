module rsp_fifo (
    input rstn,

    input          push_valid,
    output         push_ready,
    input          push_clk,
    input  [127:0] push_rsp_data,

    output         pop_valid,
    input          pop_ready,
    input          pop_clk,
    output [127:0] pop_rsp_data
);

  FIFO_HS_RSP fifo_hs_rsp (
      .Data (push_rsp_data),
      .Reset(~rstn),
      .WrClk(push_clk),
      .RdClk(pop_clk),
      .WrEn (push_valid && push_ready),
      .RdEn (pop_valid && pop_ready),
      .Q    (pop_rsp_data),
      .Empty(~push_ready),
      .Full (~pop_ready)
  );

endmodule
