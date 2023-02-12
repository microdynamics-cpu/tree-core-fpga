module cmd_fifo #(
    parameter TYPE_WIDTH = 2,
    parameter ADDR_WIDTH = 27,
    parameter BRST_WIDTH = 6,
    parameter DATA_WIDTH = 128,
    parameter MASK_WIDTH = 16
) (
    input rstn,

    input                   push_clk,
    input                   io_push_valid,
    output                  io_push_ready,
    input  [TYPE_WIDTH-1:0] io_push_cmd_type,
    input  [ADDR_WIDTH-1:0] io_push_addr,
    input  [BRST_WIDTH-1:0] io_push_burst_cnt,
    input  [DATA_WIDTH-1:0] io_push_wt_data,
    input  [MASK_WIDTH-1:0] io_push_wt_mask,

    input                   pop_clk,
    input                   io_pop_valid,
    output                  io_pop_ready,
    output [TYPE_WIDTH-1:0] io_pop_cmd_type,
    output [ADDR_WIDTH-1:0] io_pop_addr,
    output [BRST_WIDTH-1:0] io_pop_burst_cnt,
    output [DATA_WIDTH-1:0] io_pop_wt_data,
    output [MASK_WIDTH-1:0] io_pop_wt_mask
);

  // 2 + 27 + 6 + 128 + 16 = 179bits
  wire [TYPE_WIDTH + ADDR_WIDTH + BRST_WIDTH + DATA_WIDTH + MASK_WIDTH-1:0] push_data;
  wire [TYPE_WIDTH + ADDR_WIDTH + BRST_WIDTH + DATA_WIDTH + MASK_WIDTH-1:0] pop_data;
  wire                                                                      empty;
  wire                                                                      full;

  assign push_data = {
    io_push_cmd_type, io_push_addr, io_push_burst_cnt, io_push_wt_data, io_push_wt_mask
  };
  assign {io_pop_cmd_type, io_pop_addr, io_pop_burst_cnt, io_pop_wt_data, io_pop_wt_mask} = pop_data;

  assign io_push_ready = rstn && (~full);
  assign io_pop_ready = rstn && (~empty);

  FIFO_HS #(
      .WIDTH(TYPE_WIDTH + ADDR_WIDTH + BRST_WIDTH + DATA_WIDTH + MASK_WIDTH)
  ) u_fifo_hs_cmd (
      // FIFO_HS_CMD u_fifo_hs_cmd ( // for fpga
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
