`timescale 1ns / 1ps

module ddr3_tb ();
  reg lock;
  reg clk_25MHz;
  reg clk_400MHz;
  always #20.000 clk_25MHz <= ~clk_25MHz;
  always #2.500 clk_400MHz <= ~clk_400MHz;

  initial begin
    clk_25MHz  = 1'b0;
    clk_400MHz = 1'b0;
    lock       = 1'b0;
    // repeat (10) @(posedge clk_25MHz);
    #97 lock = 1;  // 97 for aync to clk edge
    #500 $finish;
  end


  initial begin
    $dumpfile("build/ddr3.wave");
    $dumpvars(0, ddr3_tb);
  end


  localparam WR_CMD = 3'd0;
  localparam RD_CMD = 3'd1;



  DDR3_Memory_Interface_Top u_ddr3_ctrl (
      .memory_clk         (clk_400MHz),
      .clk                (clk_25MHz),
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

      .O_ddr_addr   (),
      .O_ddr_ba     (),
      .O_ddr_cs_n   (),
      .O_ddr_ras_n  (),
      .O_ddr_cas_n  (),
      .O_ddr_we_n   (),
      .O_ddr_clk    (),
      .O_ddr_clk_n  (),
      .O_ddr_cke    (),
      .O_ddr_odt    (),
      .O_ddr_reset_n(),
      .O_ddr_dqm    (),
      .IO_ddr_dq    (),
      .IO_ddr_dqs   (),
      .IO_ddr_dqs_n ()
  );

endmodule
