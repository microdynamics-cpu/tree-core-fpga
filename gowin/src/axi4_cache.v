module axi4_cache (
    input clk,  // 27MHz
    input rstn,

    // axi4 interface
    output        io_axi4_awready,
    input         io_axi4_awvalid,
    input  [ 3:0] io_axi4_awid,
    input  [31:0] io_axi4_awaddr,
    input  [ 7:0] io_axi4_awlen,
    input  [ 2:0] io_axi4_awsize,
    input  [ 1:0] io_axi4_awburst,

    output        io_axi4_wready,
    input         io_axi4_wvalid,
    input  [63:0] io_axi4_wdata,
    input  [ 7:0] io_axi4_wstrb,
    input         io_axi4_wlast,

    input        io_axi4_bready,
    output       io_axi4_bvalid,
    output [3:0] io_axi4_bid,
    output [1:0] io_axi4_bresp,

    output        io_axi4_arready,
    input         io_axi4_arvalid,
    input  [ 3:0] io_axi4_arid,
    input  [31:0] io_axi4_araddr,
    input  [ 7:0] io_axi4_arlen,
    input  [ 2:0] io_axi4_arsize,
    input  [ 1:0] io_axi4_arburst,

    input         io_axi4_rready,
    output        io_axi4_rvalid,
    output [ 3:0] io_axi4_rid,
    output [63:0] io_axi4_rdata,
    output [ 1:0] io_axi4_rresp,
    output        io_axi4_rlast,

    // fifo cache interface
    output         fifo_cmd_valid,
    input          fifo_cmd_rdy,
    output         fifo_cmd_type,
    output [ 26:0] fifo_cmd_addr,
    output [  5:0] fifo_cmd_burst_cnt,
    output [127:0] fifo_cmd_wt_data,
    output [ 15:0] fifo_cmd_wt_mask,
    input          fifo_rsp_valid,
    output         fifo_rsp_rdy,
    input  [127:0] fifo_rsp_data
);


endmodule
