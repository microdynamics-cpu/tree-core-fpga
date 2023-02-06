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

  wire         wen;
  wire         ren;
  wire         is_empty;
  wire         is_full;
  wire [127:0] rdata;

  fifo_tester u_fifo_tester (
      .clk    (clk),
      .clk_mem(clk_mem),
      .rstn   (lock),
      .wen    (wen),
      .ren    (ren),
      .rdata  (rdata),
      .empty  (is_empty),
      .full   (is_full)
  );

  FIFO_HS_WT_Top u_wt_fifo (
      .Data (64'h1234_5678),
      .Reset(~lock),
      .WrClk(clk),
      .RdClk(clk_mem),
      .WrEn (wen),
      .RdEn (ren),
      .Q    (rdata),
      .Empty(is_empty),
      .Full (is_full)
  );

endmodule
