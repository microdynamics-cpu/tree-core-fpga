`timescale 1ns / 1ps

module fifo_tb ();
  reg rstn;
  reg clk_25MHz;
  reg clk_100MHz;
  always #20.000 clk_25MHz <= ~clk_25MHz;
  always #5.000 clk_100MHz <= ~clk_100MHz;

  initial begin
    clk_25MHz  = 1'b0;
    clk_100MHz = 1'b0;
    rstn       = 1'b0;
    // repeat (10) @(posedge clk_25MHz);
    #97 rstn = 1;  // 97 for aync to clk edge
    #500 $finish;
  end


  initial begin
    $dumpfile("build/fifo.wave");
    $dumpvars(0, fifo_tb);
  end


  localparam WIDTH = 179;
  localparam DEPTH = 4;


  wire             wt_clk;
  wire             rd_clk;
  reg  [WIDTH-1:0] wt_data;
  wire [WIDTH-1:0] rd_data;
  wire             wt_en;
  wire             rd_en;
  wire             empty;
  wire             full;

  // assign wt_clk = clk_25MHz;
  assign wt_clk = clk_100MHz;
  // assign rd_clk = clk_100MHz;
  assign rd_clk = clk_25MHz;
  assign wt_en  = rstn && (~full);
  assign rd_en  = rstn && (~empty);

  always @(posedge wt_clk or negedge rstn) begin
    if (~rstn) begin
      wt_data <= 'b0;
    end else begin
      wt_data <= wt_data + 1'b1;
    end
  end

  FIFO_HS_CMD #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
  ) fifo_hs_cmd (
      .Data (wt_data),
      .Reset(~rstn),
      .WrClk(wt_clk),
      .RdClk(rd_clk),
      .WrEn (wt_en),
      .RdEn (rd_en),
      .Q    (rd_data),
      .Empty(empty),
      .Full (full)
  );

endmodule
