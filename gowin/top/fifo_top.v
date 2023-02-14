module fifo_top (
    input clk
);

  wire lock;
  wire clk_mem;
  Gowin_rPLL u_pll (
      .clkout(clk_mem),
      .lock  (lock),
      .clkin (clk)
  );

  wire        wen;
  wire        ren;
  wire        empty;
  wire        full;
  wire [63:0] wdata;
  wire [63:0] rdata;

  fifo_tester u_fifo_tester (
      .clk    (clk),
      .wdata  (wdata),
      .clk_mem(clk_mem),
      .rstn   (lock),
      .wen    (wen),
      .ren    (ren),
      .rdata  (rdata),
      .empty  (empty),
      .full   (full)
  );

  FIFO_HS_WT_Top u_wt_fifo (
      .Data (wdata),
      .Reset(~lock),
      .WrClk(clk),
      .RdClk(clk_mem),
      .WrEn (wen),
      .RdEn (ren),
      .Q    (rdata),
      .Empty(empty),
      .Full (full)
  );

endmodule
