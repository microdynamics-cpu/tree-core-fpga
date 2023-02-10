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

  reg [1:0] clk_div_cnt;
  reg       int_clk_out;

  assign clk_out = int_clk_out;
  always @(posedge memory_clk or negedge rst_n) begin
    if (~rst_n) begin
      clk_div_cnt <= 'd0;
    end else begin
      clk_div_cnt <= clk_div_cnt + 1'b1;
    end
  end

always @(posedge memory_clk or negedge rst_n) begin
    if(~rst_n) begin
        int_clk_out <= 'b0;
    end
    else begin
        if(clk_div_cnt == 2'd0 || clk_div_cnt == 2'd2) begin
            int_clk_out <= ~int_clk_out;
        end
    end
end

  assign O_ddr_addr    = 'b0;
  assign O_ddr_ba      = 'b0;
  assign O_ddr_cs_n    = 'b0;
  assign O_ddr_ras_n   = 'b0;
  assign O_ddr_cas_n   = 'b0;
  assign O_ddr_we_n    = 'b0;
  assign O_ddr_clk     = 'b0;
  assign O_ddr_clk_n   = 'b0;
  assign O_ddr_cke     = 'b0;
  assign O_ddr_odt     = 'b0;
  assign O_ddr_reset_n = 'b0;
  assign O_ddr_dqm     = 'b0;
  assign IO_ddr_dq     = 'bz;
  assign IO_ddr_dqs    = 'bz;
  assign IO_ddr_dqs_n  = 'bz;

endmodule
