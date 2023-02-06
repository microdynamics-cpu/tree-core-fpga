module axi4_ddr3_ctrl (
    input clk,
    input rstn,

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

    output [13:0] ddr_addr,
    output [ 2:0] ddr_bank,
    output        ddr_cs,
    output        ddr_ras,
    output        ddr_cas,
    output        ddr_we,
    output        ddr_ck,
    output        ddr_ck_n,
    output        ddr_cke,
    output        ddr_odt,
    output        ddr_reset_n,
    output [ 1:0] ddr_dm,
    inout  [15:0] ddr_dq,
    inout  [ 1:0] ddr_dqs,
    inout  [ 1:0] ddr_dqs_n
);

  assign ddr_cs = 1'b0;


  wire lock;
  wire clk_mem;
  wire clk_mem_div4;
  Gowin_rPLL u_pll (
      .clkout(clk_mem),
      .lock  (lock),
      .clkin (clk)
  );


  // ddr3 misc channel
  wire         init_calib_complete;
  wire [  5:0] app_burst_number;
  wire [ 27:0] app_addr;
  // ddr3 cmd channel
  wire         app_cmd_en;
  wire [  2:0] app_cmd;
  wire         app_cmd_rdy;
  // ddr3 w channel
  wire         app_wdata_en;
  wire         app_wdata_end;
  wire [127:0] app_wdata;
  wire         app_wdata_rdy;
  // ddr3 r channel
  wire         app_rdata_valid;
  wire         app_rdata_end;
  wire [127:0] app_rdata;

  // bank: 2:0(8) row: 13:0(16k) col: 9~0(1024, 1k) cell: 16bits
  DDR3_Memory_Interface_Top u_ddr3_ctrl (
      .memory_clk         (clk_mem),
      .clk                (clk),
      .pll_lock           (lock),
      .rst_n              (lock),
      .app_burst_number   (app_burst_number),
      .cmd_ready          (app_cmd_rdy),
      .cmd                (app_cmd),
      .cmd_en             (app_cmd_en),
      .addr               (app_addr),
      .wr_data_rdy        (app_wdata_rdy),
      .wr_data            (app_wdata),
      .wr_data_en         (app_wdata_en),
      .wr_data_end        (app_wdata_end),
      .wr_data_mask       (16'h0000),
      .rd_data            (app_rdata),
      .rd_data_valid      (app_rdata_valid),
      .rd_data_end        (app_rdata_end),
      .sr_req             (1'b0),
      .ref_req            (1'b0),
      .sr_ack             (),
      .ref_ack            (),
      .init_calib_complete(init_calib_complete),
      .clk_out            (clk_mem_div4),
      .ddr_rst            (),
      .burst              (1'b1),

      .O_ddr_addr   (ddr_addr),
      .O_ddr_ba     (ddr_bank),
      .O_ddr_cs_n   (),
      .O_ddr_ras_n  (ddr_ras),
      .O_ddr_cas_n  (ddr_cas),
      .O_ddr_we_n   (ddr_we),
      .O_ddr_clk    (ddr_ck),
      .O_ddr_clk_n  (ddr_ck_n),
      .O_ddr_cke    (ddr_cke),
      .O_ddr_odt    (ddr_odt),
      .O_ddr_reset_n(ddr_reset_n),
      .O_ddr_dqm    (ddr_dm),
      .IO_ddr_dq    (ddr_dq),
      .IO_ddr_dqs   (ddr_dqs),
      .IO_ddr_dqs_n (ddr_dqs_n)
  );
endmodule
