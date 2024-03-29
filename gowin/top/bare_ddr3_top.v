module bare_ddr3_top (
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
    inout  [ 1:0] ddr_dqs_n,

    input  clk,
    output txp
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

  wire         rstn;
  wire         init_calib_complete;
  wire [  5:0] app_burst_number;
  wire [ 26:0] app_addr;
  wire         app_cmd_en;
  wire [  2:0] app_cmd;
  wire         app_cmd_rdy;
  wire         app_wdata_en;
  wire         app_wdata_end;
  wire [ 15:0] app_wdata_mask;
  wire [127:0] app_wdata;
  wire         app_wdata_rdy;
  wire         app_rdata_valid;
  wire         app_rdata_end;
  wire [127:0] app_rdata;


  DDR3_Memory_Interface_Top u_ddr3_ctrl (
      .memory_clk         (clk_mem),
      .clk                (clk),
      .pll_lock           (lock),
      .rst_n              (rstn),
      .app_burst_number   (app_burst_number),
      .cmd_ready          (app_cmd_rdy),
      .cmd                (app_cmd),
      .cmd_en             (app_cmd_en),
      .addr               ({1'd0, app_addr}),
      .wr_data_rdy        (app_wdata_rdy),
      .wr_data            (app_wdata),
      .wr_data_en         (app_wdata_en),
      .wr_data_end        (app_wdata_end),
      .wr_data_mask       (app_wdata_mask),
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

  //   bare_random_tester u_bare_random_tester (
  bare_tester u_bare_tester (
      .clk                (clk),
      .clk_ref            (clk_mem_div4),
      .rstn               (rstn),
      .init_calib_complete(init_calib_complete),
      .app_burst_number   (app_burst_number),
      .app_addr           (app_addr),
      .app_cmd_en         (app_cmd_en),
      .app_cmd            (app_cmd),
      .app_cmd_rdy        (app_cmd_rdy),
      .app_wdata_en       (app_wdata_en),
      .app_wdata_end      (app_wdata_end),
      .app_wdata_mask     (app_wdata_mask),
      .app_wdata          (app_wdata),
      .app_wdata_rdy      (app_wdata_rdy),
      .app_rdata_valid    (app_rdata_valid),
      .app_rdata_end      (app_rdata_end),
      .app_rdata          (app_rdata),
      .txp                (txp)
  );
endmodule
