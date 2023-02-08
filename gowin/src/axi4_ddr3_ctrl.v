module axi4_ddr3_ctrl (
    input clk,

    // axi4 slave
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
    input         io_axi4_bready,
    output        io_axi4_bvalid,
    output [ 3:0] io_axi4_bid,
    output [ 1:0] io_axi4_bresp,
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

    // ddr3 ctrl
    output [13:0] io_ddr_addr,
    output [ 2:0] io_ddr_bank,
    output        io_ddr_cs,
    output        io_ddr_ras,
    output        io_ddr_cas,
    output        io_ddr_we,
    output        io_ddr_ck,
    output        io_ddr_ck_n,
    output        io_ddr_cke,
    output        io_ddr_odt,
    output        io_ddr_reset_n,
    output [ 1:0] io_ddr_dm,
    inout  [15:0] io_ddr_dq,
    inout  [ 1:0] io_ddr_dqs,
    inout  [ 1:0] io_ddr_dqs_n
);

  wire lock;
  wire clk_mem;
  wire clk_mem_div4;
  Gowin_rPLL u_pll (
      .clkout(clk_mem),
      .lock  (lock),
      .clkin (clk)
  );

  wire         fifo_cmd_valid;
  wire         fifo_cmd_ready;
  wire         fifo_cmd_type;
  wire [ 26:0] fifo_cmd_addr;
  wire [  5:0] fifo_cmd_burst_cnt;
  wire [127:0] fifo_cmd_wt_data;
  wire [ 15:0] fifo_cmd_wt_mask;
  wire         fifo_rsp_valid;
  wire         fifo_rsp_ready;
  wire [127:0] fifo_rsp_data;

  wire [  5:0] ddr3_burst_number;
  wire         ddr3_cmd_ready;
  wire [  2:0] ddr3_cmd;
  wire         ddr3_cmd_en;
  wire [ 26:0] ddr3_addr;
  wire         ddr3_wdata_ready;
  wire [127:0] ddr3_wdata;
  wire         ddr3_wdata_en;
  wire         ddr3_wdata_end;
  wire [ 15:0] ddr3_wdata_mask;
  wire [127:0] ddr3_rdata;
  wire         ddr3_rdata_valid;
  wire         ddr3_rdata_end;
  wire         ddr3_init_calib_complete;

  assign ddr_cs = 1'b0;

  axi4_cache u_axi4_cache (
      .clk (clk),
      .rstn(lock),

      .io_axi4_awready(io_axi4_awready),
      .io_axi4_awvalid(io_axi4_awvalid),
      .io_axi4_awid   (io_axi4_awid),
      .io_axi4_awaddr (io_axi4_awaddr),
      .io_axi4_awlen  (io_axi4_awlen),
      .io_axi4_awsize (io_axi4_awsize),
      .io_axi4_awburst(io_axi4_awburst),
      .io_axi4_wready (io_axi4_wready),
      .io_axi4_wvalid (io_axi4_wvalid),
      .io_axi4_wdata  (io_axi4_wdata),
      .io_axi4_wstrb  (io_axi4_wstrb),
      .io_axi4_wlast  (io_axi4_wlast),
      .io_axi4_bready (io_axi4_bready),
      .io_axi4_bvalid (io_axi4_bvalid),
      .io_axi4_bid    (io_axi4_bid),
      .io_axi4_bresp  (io_axi4_bresp),
      .io_axi4_arready(io_axi4_arready),
      .io_axi4_arvalid(io_axi4_arvalid),
      .io_axi4_arid   (io_axi4_arid),
      .io_axi4_araddr (io_axi4_araddr),
      .io_axi4_arlen  (io_axi4_arlen),
      .io_axi4_arsize (io_axi4_arsize),
      .io_axi4_arburst(io_axi4_arburst),
      .io_axi4_rready (io_axi4_rready),
      .io_axi4_rvalid (io_axi4_rvalid),
      .io_axi4_rid    (io_axi4_rid),
      .io_axi4_rdata  (io_axi4_rdata),
      .io_axi4_rresp  (io_axi4_rresp),
      .io_axi4_rlast  (io_axi4_rlast),

      .io_fifo_cmd_valid    (fifo_cmd_valid),
      .io_fifo_cmd_ready    (fifo_cmd_ready),
      .io_fifo_cmd_type     (fifo_cmd_type),
      .io_fifo_cmd_addr     (fifo_cmd_addr),
      .io_fifo_cmd_burst_cnt(fifo_cmd_burst_cnt),
      .io_fifo_cmd_wt_data  (fifo_cmd_wt_data),
      .io_fifo_cmd_wt_mask  (fifo_cmd_wt_mask),
      .io_fifo_rsp_valid    (fifo_rsp_valid),
      .io_fifo_rsp_ready    (fifo_rsp_ready),
      .io_fifo_rsp_dat      (fifo_rsp_data)
  );


  axi4_bridge u_axi4_bridge (
      .clk    (clk),
      .clk_ref(clk_mem_div4),
      .rstn   (lock),

      .io_fifo_cmd_valid    (fifo_cmd_valid),
      .io_fifo_cmd_ready    (fifo_cmd_ready),
      .io_fifo_cmd_type     (fifo_cmd_type),
      .io_fifo_cmd_addr     (fifo_cmd_addr),
      .io_fifo_cmd_burst_cnt(fifo_cmd_burst_cnt),
      .io_fifo_cmd_wt_data  (fifo_cmd_wt_data),
      .io_fifo_cmd_wt_mask  (fifo_cmd_wt_mask),
      .io_fifo_rsp_valid    (fifo_rsp_valid),
      .io_fifo_rsp_ready    (fifo_rsp_ready),
      .io_fifo_rsp_data     (fifo_rsp_data),

      .io_app_burst_number   (ddr3_burst_number),
      .io_app_cmd_ready      (ddr3_cmd_ready),
      .io_app_cmd            (ddr3_cmd),
      .io_app_cmd_en         (ddr3_cmd_en),
      .io_app_addr           (ddr3_addr),
      .io_app_wdata_ready    (ddr3_wdata_ready),
      .io_app_wdata          (ddr3_wdata),
      .io_app_wdata_en       (ddr3_wdata_en),
      .io_app_wdata_end      (ddr3_wdata_end),
      .io_app_wdata_mask     (ddr3_wdata_mask),
      .io_app_rdata          (ddr3_rdata),
      .io_app_rdata_valid    (ddr3_rdata_valid),
      .io_app_rdata_end      (ddr3_rdata_end),
      .io_init_calib_complete(ddr3_init_calib_complete)
  );


  // bank: 2:0(8) row: 13:0(16k) col: 9~0(1024, 1k) cell: 16bits
  DDR3_Memory_Interface_Top u_ddr3_ctrl (
      .memory_clk         (clk_mem),
      .clk                (clk),
      .pll_lock           (lock),
      .rst_n              (lock),
      .app_burst_number   (ddr3_burst_number),
      .cmd_ready          (ddr3_cmd_ready),
      .cmd                (ddr3_cmd),
      .cmd_en             (ddr3_cmd_en),
      .addr               ({1'b0, ddr3_addr}),
      .wr_data_rdy        (ddr3_wdata_ready),
      .wr_data            (ddr3_wdata),
      .wr_data_en         (ddr3_wdata_en),
      .wr_data_end        (ddr3_wdata_end),
      .wr_data_mask       (ddr3_wdata_mask),
      .rd_data            (ddr3_rdata),
      .rd_data_valid      (ddr3_rdata_valid),
      .rd_data_end        (ddr3_rdata_end),
      .sr_req             (1'b0),
      .ref_req            (1'b0),
      .sr_ack             (),
      .ref_ack            (),
      .init_calib_complete(ddr3_init_calib_complete),
      .clk_out            (clk_mem_div4),
      .ddr_rst            (),
      .burst              (1'b1),

      .O_ddr_addr   (io_ddr_addr),
      .O_ddr_ba     (io_ddr_bank),
      .O_ddr_cs_n   (),
      .O_ddr_ras_n  (io_ddr_ras),
      .O_ddr_cas_n  (io_ddr_cas),
      .O_ddr_we_n   (io_ddr_we),
      .O_ddr_clk    (io_ddr_ck),
      .O_ddr_clk_n  (io_ddr_ck_n),
      .O_ddr_cke    (io_ddr_cke),
      .O_ddr_odt    (io_ddr_odt),
      .O_ddr_reset_n(io_ddr_reset_n),
      .O_ddr_dqm    (io_ddr_dm),
      .IO_ddr_dq    (io_ddr_dq),
      .IO_ddr_dqs   (io_ddr_dqs),
      .IO_ddr_dqs_n (io_ddr_dqs_n)
  );
endmodule
