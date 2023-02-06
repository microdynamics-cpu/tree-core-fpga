module fifo_tester (
    input              clk,
    input              clk_mem,
    input              rstn,
    input              empty,
    input              full,
    input      [127:0] rdata,
    output reg         wen,
    output reg         ren
);

  always @(posedge clk) begin
    if (~rstn) begin
      wen <= 1'b0;
    end else begin
      if (full) begin
        wen <= 1'b0;
      end else begin
        wen <= 1'd1;
      end
    end
  end

  reg [127:0] int_data;
  always @(posedge clk_mem) begin
    if (~rstn) begin
      ren      <= 1'b0;
      int_data <= 128'd0;
    end else begin
      if (empty) begin
        ren <= 1'b0;
      end else begin
        ren      <= 1'b1;
        int_data <= rdata;
      end
    end
  end

endmodule
