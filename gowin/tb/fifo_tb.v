`timescale 1ns / 1ps

module fifo_tb ();
  reg rstn;
  reg clk_25MHz;
  reg clk_100MHz;
  always #20.000 clk_25MHz <= ~clk_25MHz;
  always #5.000 clk_100MHz <= ~ clk_100MHz;

  initial begin
    clk_25MHz  = 1'b0;
    clk_100MHz = 1'b0;
    rstn       = 1'b0;
    repeat (100) @(posedge clk_25MHz);
    #100 rstn = 1;
    $finish;
  end


  initial begin
    $dumpfile("build/fifo.wave");
    $dumpvars(0, fifo_tb);
  end

  FIFO_HS_CMD fifo_hs_cmd (
    .Data(179'd0),
    .Reset(~rstn),
    .WrClk(clk_25MHz),
    .RdClk(clk_100MHz),
    .WrEn (1'b1),
    .RdEn (1'b1),
    .Q    (),
    .Empty(),
    .Full ()
  );

endmodule
