module DDR3_Memory_Interface_Top (
    input          memory_clk,
    input          clk,
    input          pll_lock,
    input          rst_n,
    input  [  5:0] app_burst_number,
    output         cmd_ready,
    input  [  2:0] cmd,
    input          cmd_en,
    input  [ 27:0] addr,
    output         wr_data_rdy,
    input  [127:0] wr_data,
    input          wr_data_en,
    input          wr_data_end,
    input  [ 15:0] wr_data_mask,
    output [127:0] rd_data,
    output         rd_data_valid,
    output         rd_data_end,
    input          sr_req,
    input          ref_req,
    output         sr_ack,
    output         ref_ack,
    output         init_calib_complete,
    output         clk_out,
    output         ddr_rst,
    input          burst,
    output [ 13:0] O_ddr_addr,
    output [  2:0] O_ddr_ba,
    output         O_ddr_cs_n,
    output         O_ddr_ras_n,
    output         O_ddr_cas_n,
    output         O_ddr_we_n,
    output         O_ddr_clk,
    output         O_ddr_clk_n,
    output         O_ddr_cke,
    output         O_ddr_odt,
    output         O_ddr_reset_n,
    output [  1:0] O_ddr_dqm,
    inout  [ 15:0] IO_ddr_dq,
    inout  [  1:0] IO_ddr_dqs,
    inout  [  1:0] IO_ddr_dqs_n
);

  localparam WT_CMD = 3'd0;
  localparam RD_CMD = 3'd1;
  localparam WIDTH = 128;

  assign sr_ack        = 'd0;
  assign ref_ack       = 'd0;
  assign ddr_rst       = 'd0;

  assign O_ddr_addr    = 'd0;
  assign O_ddr_ba      = 'd0;
  assign O_ddr_cs_n    = 'd0;
  assign O_ddr_ras_n   = 'd0;
  assign O_ddr_cas_n   = 'd0;
  assign O_ddr_we_n    = 'd0;
  assign O_ddr_clk     = 'd0;
  assign O_ddr_clk_n   = 'd0;
  assign O_ddr_cke     = 'd0;
  assign O_ddr_odt     = 'd0;
  assign O_ddr_reset_n = 'd0;
  assign O_ddr_dqm     = 'd0;
  assign IO_ddr_dq     = 'dz;
  assign IO_ddr_dqs    = 'dz;
  assign IO_ddr_dqs_n  = 'dz;


  reg [WIDTH-1:0] int_wt_mask;
  reg [      1:0] int_cmd;
  reg [      7:0] init_calib_cnt;
  reg             int_wt_data_ready;
  reg             int_rd_data_valid;
  reg [WIDTH-1:0] int_rd_data;
  reg             int_init_calib_complete;
  reg             int_clk_out;
  reg [      1:0] clk_div_cnt;

  assign cmd_ready           = 1'd1;  // fake
  assign wr_data_rdy         = int_wt_data_ready;
  assign rd_data_valid       = int_rd_data_valid;
  assign rd_data             = int_rd_data;
  assign init_calib_complete = int_init_calib_complete;
  assign clk_out             = int_clk_out;

  // 128 x 128bits
  reg [WIDTH-1:0] mem[0:WIDTH-1];


  initial begin
    for (integer i = 0; i < WIDTH; i = i + 1) begin
      mem[i] <= 'd0;
    end
  end

  always @(posedge memory_clk or negedge rst_n) begin
    if (~rst_n) begin
      clk_div_cnt <= 'd0;
    end else begin
      clk_div_cnt <= clk_div_cnt + 1'd1;
    end
  end

  always @(posedge memory_clk or negedge rst_n) begin
    if (~rst_n) begin
      int_clk_out <= 'd0;
    end else begin
      if (clk_div_cnt == 2'd0 || clk_div_cnt == 2'd2) begin
        int_clk_out <= ~int_clk_out;
      end
    end
  end

  always @(posedge memory_clk or negedge rst_n) begin
    if (~rst_n) begin
      int_init_calib_complete <= 'd0;
      init_calib_cnt          <= 'd0;
    end else if (init_calib_cnt == 8'd255) begin
      int_init_calib_complete <= 'd1;
    end else begin
      init_calib_cnt <= init_calib_cnt + 1'd1;
    end
  end

  always @(posedge memory_clk or negedge rst_n) begin
    if (~rst_n) begin
      int_cmd <= WT_CMD;
    end else if (cmd_en) begin
      int_cmd <= cmd;
    end
  end

  always @(posedge memory_clk or negedge rst_n) begin
    if (~rst_n) begin
      int_wt_data_ready <= 1'd0;
      int_rd_data_valid <= 1'd0;
    end else begin
      if (int_cmd == WT_CMD) begin
        int_wt_data_ready <= 1'd1;
        int_rd_data_valid <= 1'd0;
      end else begin
        int_wt_data_ready <= 1'd0;
        int_rd_data_valid <= 1'd1;
      end
    end
  end

  always @(*) begin
    int_wt_mask[7:0]     = {8{wr_data_mask[0]}};
    int_wt_mask[15:8]    = {8{wr_data_mask[1]}};
    int_wt_mask[23:16]   = {8{wr_data_mask[2]}};
    int_wt_mask[31:24]   = {8{wr_data_mask[3]}};
    int_wt_mask[39:32]   = {8{wr_data_mask[4]}};
    int_wt_mask[47:40]   = {8{wr_data_mask[5]}};
    int_wt_mask[55:48]   = {8{wr_data_mask[6]}};
    int_wt_mask[63:56]   = {8{wr_data_mask[7]}};
    int_wt_mask[71:64]   = {8{wr_data_mask[8]}};
    int_wt_mask[79:72]   = {8{wr_data_mask[9]}};
    int_wt_mask[87:80]   = {8{wr_data_mask[10]}};
    int_wt_mask[95:88]   = {8{wr_data_mask[11]}};
    int_wt_mask[103:96]  = {8{wr_data_mask[12]}};
    int_wt_mask[111:104] = {8{wr_data_mask[13]}};
    int_wt_mask[119:112] = {8{wr_data_mask[14]}};
    int_wt_mask[127:120] = {8{wr_data_mask[15]}};
  end

  always @(posedge memory_clk) begin
    if (int_wt_data_ready && wr_data_en) begin
      mem[addr] <= wr_data & int_wt_mask;
    end
  end

  always @(posedge memory_clk or negedge rst_n) begin
    if (~rst_n) begin
      int_rd_data <= {WIDTH{1'd0}};
    end
    if (int_rd_data_valid) begin
      int_rd_data <= mem[addr];
    end
  end
endmodule
