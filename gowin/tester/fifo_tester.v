module fifo_tester (
    input         clk,
    output [63:0] wdata,
    input         clk_mem,
    input         rstn,
    input         empty,
    input         full,
    input  [63:0] rdata,
    output        wen,
    output        ren
);


  reg [63:0] int_wdata;
  reg [63:0] int_rdata;
  reg [ 2:0] rd_cnt;

  assign wen   = rstn && (~full);
  assign ren   = rstn && (~empty) && rd_cnt[2];
  assign wdata = int_wdata;

  always @(posedge clk) begin
    if (~rstn) int_wdata <= 64'h1234_5678;
    else int_wdata <= int_wdata + 1'd1;
  end

  always @(posedge clk_mem) begin
    if (~rstn) begin
      int_rdata <= 'd0;
      rd_cnt    <= 'd0;
    end else begin
      int_rdata <= rdata;
      rd_cnt <= rd_cnt + 1'd1;
    end
  end

endmodule
