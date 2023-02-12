module rsp_fifo #(
    parameter DATA_WIDTH = 128
) (
    input rstn,

    input                   push_clk,
    input                   io_push_valid,
    output                  io_push_ready,
    input  [DATA_WIDTH-1:0] io_push_rsp_data,

    input                   pop_clk,
    input                   io_pop_valid,
    output                  io_pop_ready,
    output [DATA_WIDTH-1:0] io_pop_rsp_data
);

  wire empty;
  wire full;
  assign io_push_ready = rstn && (~full);
  assign io_pop_ready  = rstn && (~empty);

  FIFO_HS #(
      .WIDTH(DATA_WIDTH)
  ) u_fifo_hs_rsp (
      // FIFO_HS_RSP u_fifo_hs_rsp ( // for fpga
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
