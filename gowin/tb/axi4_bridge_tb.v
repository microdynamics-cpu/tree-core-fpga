`timescale 1ns / 1ps

module axi4_bridge_tb ();
  reg lock;
  reg rstn;
  reg clk_25MHz;
  reg clk_400MHz;
  always #20.000 clk_25MHz <= ~clk_25MHz;
  always #2.500 clk_400MHz <= ~clk_400MHz;

  initial begin
    clk_25MHz  = 1'd0;
    clk_400MHz = 1'd0;
    lock       = 1'd0;
    rstn       = 1'd0;
    #40 rstn = 1'd1;
    #97 lock = 1;  // 97 for aync to clk edge
    #500 $finish;
  end


  initial begin
    $dumpfile("build/axi4_bridge.wave");
    $dumpvars(0, axi4_bridge_tb);
  end



endmodule
