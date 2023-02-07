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

  wire         axi4_awready;
  wire         axi4_awvalid;
  wire [  3:0] axi4_awid;
  wire [ 31:0] axi4_awaddr;
  wire [  7:0] axi4_awlen;
  wire [  2:0] axi4_awsize;
  wire [  1:0] axi4_awburst;
  wire         axi4_wready;
  wire         axi4_wvalid;
  wire [ 63:0] axi4_wdata;
  wire [  7:0] axi4_wstrb;
  wire         axi4_wlast;
  wire         axi4_bready;
  wire         axi4_bvalid;
  wire [  3:0] axi4_bid;
  wire [  1:0] axi4_bresp;
  wire         axi4_arready;
  wire         axi4_arvalid;
  wire [  3:0] axi4_arid;
  wire [ 31:0] axi4_araddr;
  wire [  7:0] axi4_arlen;
  wire [  2:0] axi4_arsize;
  wire [  1:0] axi4_arburst;
  wire         axi4_rready;
  wire         axi4_rvalid;
  wire [  3:0] axi4_rid;
  wire [ 63:0] axi4_rdata;
  wire [  1:0] axi4_rresp;
  wire         axi4_rlast;

  // fifo ctrl
  wire         cmd_valid;
  wire         cmd_rdy;
  wire         cmd_type;
  wire [ 26:0] cmd_addr;
  wire [  5:0] cmd_burst_cnt;
  wire [127:0] cmd_wt_data;
  wire [ 15:0] cmd_wt_mask;
  wire         rsp_valid;
  wire         rsp_rdy;
  wire [127:0] rsp_data;

  // ddr3 ctrl
  wire [  5:0] ddr3_burst_number;
  wire         ddr3_cmd_rdy;
  wire [  2:0] ddr3_cmd;
  wire         ddr3_cmd_en;
  wire [ 26:0] ddr3_addr;
  wire         ddr3_wdata_rdy;
  wire [127:0] ddr3_wdata;
  wire         ddr3_wdata_en;
  wire         ddr3_wdata_end;
  wire [ 15:0] ddr3_wdata_mask;
  wire [127:0] ddr3_rdata;
  wire         ddr3_rdata_valid;
  wire         ddr3_rdata_end;
  wire         ddr3_init_calib_complete;

  axi4_cache u_axi4_cache (
      .clk (clk),
      .rstn(lock),

      .io_axi4_awready(axi4_awready),
      .io_axi4_awvalid(axi4_awvalid),
      .io_axi4_awid   (axi4_awid),
      .io_axi4_awaddr (axi4_awaddr),
      .io_axi4_awlen  (axi4_awlen),
      .io_axi4_awsize (axi4_awsize),
      .io_axi4_awburst(axi4_awburst),
      .io_axi4_wready (axi4_wready),
      .io_axi4_wvalid (axi4_wvalid),
      .io_axi4_wdata  (axi4_wdata),
      .io_axi4_wstrb  (axi4_wstrb),
      .io_axi4_wlast  (axi4_wlast),
      .io_axi4_bready (axi4_bready),
      .io_axi4_bvalid (axi4_bvalid),
      .io_axi4_bid    (axi4_bid),
      .io_axi4_bresp  (axi4_bresp),
      .io_axi4_arready(axi4_arready),
      .io_axi4_arvalid(axi4_arvalid),
      .io_axi4_arid   (axi4_arid),
      .io_axi4_araddr (axi4_araddr),
      .io_axi4_arlen  (axi4_arlen),
      .io_axi4_arsize (axi4_arsize),
      .io_axi4_arburst(axi4_arburst),
      .io_axi4_rready (axi4_rready),
      .io_axi4_rvalid (axi4_rvalid),
      .io_axi4_rid    (axi4_rid),
      .io_axi4_rdata  (axi4_rdata),
      .io_axi4_rresp  (axi4_rresp),
      .io_axi4_rlast  (axi4_rlast),

      .fifo_cmd_valid    (cmd_valid),
      .fifo_cmd_rdy      (cmd_rdy),
      .fifo_cmd_type     (cmd_type),
      .fifo_cmd_addr     (cmd_addr),
      .fifo_cmd_burst_cnt(cmd_burst_cnt),
      .fifo_cmd_wt_data  (cmd_wt_data),
      .fifo_cmd_wt_mask  (cmd_wt_mask),
      .fifo_rsp_valid    (rsp_valid),
      .fifo_rsp_rdy      (rsp_rdy),
      .fifo_rsp_dat      (rsp_dat)
  );


  axi4_bridge u_axi4_bridge (
      .clk    (clk),
      .clk_ref(clk_mem_div4),
      .rstn   (lock),

      .fifo_cmd_valid    (cmd_valid),
      .fifo_cmd_rdy      (cmd_rdy),
      .fifo_cmd_type     (cmd_type),
      .fifo_cmd_addr     (cmd_addr),
      .fifo_cmd_burst_cnt(cmd_burst_cnt),
      .fifo_cmd_wt_data  (cmd_wt_data),
      .fifo_cmd_wt_mask  (cmd_wt_mask),
      .fifo_rsp_valid    (rsp_valid),
      .fifo_rsp_rdy      (rsp_rdy),
      .fifo_rsp_data     (rsp_data),

      .app_burst_number   (ddr3_burst_number),
      .app_cmd_rdy        (ddr3_cmd_rdy),
      .app_cmd            (ddr3_cmd),
      .app_cmd_en         (ddr3_cmd_en),
      .app_addr           (ddr3_addr),
      .app_wdata_rdy      (ddr3_wdata_rdy),
      .app_wdata          (ddr3_wdata),
      .app_wdata_en       (ddr3_wdata_en),
      .app_wdata_end      (ddr3_wdata_end),
      .app_wdata_mask     (ddr3_wdata_mask),
      .app_rdata          (ddr3_rdata),
      .app_rdata_valid    (ddr3_rdata_valid),
      .app_rdata_end      (ddr3_rdata_end),
      .init_calib_complete(ddr3_init_calib_complete)
  );


  // bank: 2:0(8) row: 13:0(16k) col: 9~0(1024, 1k) cell: 16bits
  DDR3_Memory_Interface_Top u_ddr3_ctrl (
      .memory_clk         (clk_mem),
      .clk                (clk),
      .pll_lock           (lock),
      .rst_n              (lock),
      .app_burst_number   (ddr3_burst_number),
      .cmd_ready          (ddr3_cmd_rdy),
      .cmd                (ddr3_cmd),
      .cmd_en             (ddr3_cmd_en),
      .addr               (ddr3_addr),
      .wr_data_rdy        (ddr3_wdata_rdy),
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
