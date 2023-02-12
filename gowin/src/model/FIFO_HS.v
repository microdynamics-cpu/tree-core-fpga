module FIFO_HS #(
    parameter WIDTH = 16,
    parameter DEPTH = 4
) (
    input  [WIDTH-1:0] Data,
    input              Reset,
    input              WrClk,
    input              RdClk,
    input              WrEn,
    input              RdEn,
    output [WIDTH-1:0] Q,
    output             Empty,
    output             Full
);

  localparam ADDR = $clog2(DEPTH);
  reg [ADDR:0] wt_bin_ptr;
  reg [ADDR:0] wt_gray_ptr;
  reg [ADDR:0] sync2wt_gray_ptr1;
  reg [ADDR:0] sync2wt_gray_ptr2;
  reg [ADDR:0] sync2wt_bin_ptr;

  reg [ADDR:0] rd_bin_ptr;
  reg [ADDR:0] rd_gray_ptr;
  reg [ADDR:0] sync2rd_gray_ptr1;
  reg [ADDR:0] sync2rd_gray_ptr2;
  reg [ADDR:0] sync2rd_bin_ptr;

  reg          empty;
  reg          full;
  assign Empty = empty;
  assign Full  = full;

  always @(posedge WrClk or posedge Reset) begin
    if (Reset) begin
      wt_bin_ptr <= 'b0;
    end else if (WrEn && (~Full)) begin
      wt_bin_ptr <= wt_bin_ptr + 1'b1;
    end
  end

  always @(posedge WrClk or posedge Reset) begin
    if (Reset) begin
      wt_gray_ptr <= 'b0;
    end else begin
      wt_gray_ptr <= {wt_bin_ptr[ADDR], wt_bin_ptr[ADDR:1] ^ wt_bin_ptr[ADDR-1:0]};
    end
  end

  always @(posedge WrClk or posedge Reset) begin
    if (Reset) begin
      sync2wt_gray_ptr1 <= 'b0;
      sync2wt_gray_ptr2 <= 'b0;
    end else begin
      sync2wt_gray_ptr1 <= rd_gray_ptr;
      sync2wt_gray_ptr2 <= sync2wt_gray_ptr1;
    end
  end

  always @(*) begin
    sync2wt_bin_ptr[ADDR] = sync2wt_gray_ptr2[ADDR];
    for (integer i = ADDR - 1; i >= 0; i = i - 1) begin
      sync2wt_bin_ptr[i] = sync2wt_bin_ptr[i+1] ^ sync2wt_gray_ptr2[i];
    end
  end

  always @(*) begin
    if((wt_bin_ptr[ADDR] != sync2wt_bin_ptr[ADDR]) && (wt_bin_ptr[ADDR-1:0] == sync2wt_bin_ptr[ADDR-1:0])) begin
      full = 1'b1;
    end else begin
      full = 1'b0;
    end
  end


  always @(posedge RdClk or posedge Reset) begin
    if (Reset) begin
      rd_bin_ptr <= 'b0;
    end else if (RdEn && (~Empty)) begin
      rd_bin_ptr <= rd_bin_ptr + 1'b1;
    end
  end

  always @(posedge RdClk or posedge Reset) begin
    if (Reset) begin
      rd_gray_ptr <= 'b0;
    end else begin
      rd_gray_ptr <= {rd_bin_ptr[ADDR], rd_bin_ptr[ADDR:1] ^ rd_bin_ptr[ADDR-1:0]};
    end
  end

  always @(posedge RdClk or posedge Reset) begin
    if (Reset) begin
      sync2rd_gray_ptr1 <= 'b0;
      sync2rd_gray_ptr2 <= 'b0;
    end else begin
      sync2rd_gray_ptr1 <= wt_gray_ptr;
      sync2rd_gray_ptr2 <= sync2rd_gray_ptr1;
    end
  end

  always @(*) begin
    sync2rd_bin_ptr[ADDR] = sync2rd_gray_ptr2[ADDR];
    for (integer i = ADDR - 1; i >= 0; i = i - 1) begin
      sync2rd_bin_ptr[i] = sync2rd_bin_ptr[i+1] ^ sync2rd_gray_ptr2[i];
    end
  end

  always @(*) begin
    if (rd_bin_ptr == sync2rd_bin_ptr) begin
      empty = 1'b1;
    end else begin
      empty = 1'b0;
    end
  end


  wire             dpram_wt_en;
  wire [ ADDR-1:0] dpram_wt_addr;
  wire [WIDTH-1:0] dpram_wt_data;
  wire             dpram_rd_en;
  wire [ ADDR-1:0] dpram_rd_addr;
  wire [WIDTH-1:0] dpram_rd_data;

  DPRAM #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
  ) u_DPARM (
      .wt_clk (WrClk),
      .wt_en  (dpram_wt_en),
      .wt_addr(dpram_wt_addr),
      .wt_data(dpram_wt_data),
      .rd_clk (RdClk),
      .rd_rstn(~Reset),
      .rd_en  (dpram_rd_en),
      .rd_addr(dpram_rd_addr),
      .rd_data(dpram_rd_data)
  );

  assign dpram_wt_en   = WrEn && (~Full);
  assign dpram_wt_addr = wt_bin_ptr[ADDR-1:0];
  assign dpram_wt_data = Data;

  assign dpram_rd_en   = RdEn && (~Empty);
  assign dpram_rd_addr = rd_bin_ptr[ADDR-1:0];
  assign Q             = dpram_rd_data;

endmodule


module DPRAM #(
    parameter WIDTH = 16,
    parameter DEPTH = 4
) (
    input                          wt_clk,
    input                          wt_en,
    input      [$clog2(DEPTH)-1:0] wt_addr,
    input      [        WIDTH-1:0] wt_data,
    input                          rd_clk,
    input                          rd_rstn,
    input                          rd_en,
    input      [$clog2(DEPTH)-1:0] rd_addr,
    output reg [        WIDTH-1:0] rd_data
);

  // DEPTH = 2 ^ ADDR
  reg [WIDTH-1:0] mem[0:DEPTH-1];

  initial begin
    for (integer i = 0; i < DEPTH; ++i) begin
      mem[i] <= 'b0;
    end
  end

  always @(posedge wt_clk) begin
    if (wt_en) mem[wt_addr] <= wt_data;
  end

  always @(posedge rd_clk or negedge rd_rstn) begin
    if (!rd_rstn) rd_data <= 'b0;
    else if (rd_en) rd_data <= mem[rd_addr];
  end
endmodule
