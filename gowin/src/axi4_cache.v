module axi4_cache (
    input clk,  // 27MHz
    input rstn,

    // axi4 slave
    output        io_axi4_awready,
    input         io_axi4_awvalid,
    input  [ 3:0] io_axi4_awid,
    input  [31:0] io_axi4_awaddr,
    input  [ 7:0] io_axi4_awlen,
    input  [ 2:0] io_axi4_awsize,
    input  [ 1:0] io_axi4_awburst,
    output        io_axi4_wready,
    input         io_axi4_wvalid,
    input  [63:0] io_axi4_wdata,
    input  [ 7:0] io_axi4_wstrb,
    input         io_axi4_wlast,
    input         io_axi4_bready,
    output        io_axi4_bvalid,
    output [ 3:0] io_axi4_bid,
    output [ 1:0] io_axi4_bresp,
    output        io_axi4_arready,
    input         io_axi4_arvalid,
    input  [ 3:0] io_axi4_arid,
    input  [31:0] io_axi4_araddr,
    input  [ 7:0] io_axi4_arlen,
    input  [ 2:0] io_axi4_arsize,
    input  [ 1:0] io_axi4_arburst,
    input         io_axi4_rready,
    output        io_axi4_rvalid,
    output [ 3:0] io_axi4_rid,
    output [63:0] io_axi4_rdata,
    output [ 1:0] io_axi4_rresp,
    output        io_axi4_rlast,

    // fifo cache master
    output         io_fifo_cmd_valid,
    input          io_fifo_cmd_ready,
    output         io_fifo_cmd_type,
    output [ 26:0] io_fifo_cmd_addr,
    output [  5:0] io_fifo_cmd_burst_cnt,
    output [127:0] io_fifo_cmd_wt_data,
    output [ 15:0] io_fifo_cmd_wt_mask,
    input          io_fifo_rsp_valid,
    output         io_fifo_rsp_ready,
    input  [127:0] io_fifo_rsp_data
);

  localparam WT_CMD = 3'd0;
  localparam RD_CMD = 3'd1;

  reg          int_cmd_valid;
  reg          int_cmd_type;
  reg  [ 26:0] int_cmd_addr;
  wire [  5:0] int_cmd_burst_cnt;
  wire [127:0] int_cmd_wt_data;
  wire [ 15:0] int_cmd_wt_mask;

  reg  [ 26:0] cache_addr;
  reg  [127:0] cache_data;
  reg  [ 15:0] cache_dirty_bit;

  reg          arw_free;
  reg          no_same_trigger;
  reg          is_dirty_trigger;
  wire         no_same;
  wire         is_dirty;
  wire         axi4_aw_fire;
  wire         axi4_w_fire;
  wire         axi4_b_fire;
  wire         axi4_ar_fire;
  wire         axi4_r_fire;

  reg  [  3:0] int_axi4_arw_id;
  reg  [ 31:0] int_axi4_arw_addr;
  reg          int_axi4_arw_last;
  reg          int_axi4_arw_type;

  reg          int_axi4_w_ready;
  reg          int_axi4_b_valid;
  reg          int_axi4_r_data;
  reg          int_axi4_r_valid;


  assign io_fifo_cmd_valid     = int_cmd_valid;
  assign io_fifo_cmd_type      = int_cmd_type;
  assign io_fifo_cmd_addr      = int_cmd_addr;
  assign io_fifo_cmd_burst_cnt = int_cmd_burst_cnt;
  assign io_fifo_cmd_wt_data   = int_cmd_wt_data;
  assign io_fifo_cmd_wt_mask   = int_cmd_wt_mask;
  assign io_fifo_rsp_ready     = 1'b1;

  assign no_same               = cache_addr[26:4] != int_axi4_arw_addr[26:4];
  assign is_dirty              = cache_dirty_bit != 16'hFFFF;
  assign axi4_aw_fire          = io_axi4_awvalid && io_axi4_awready;
  assign axi4_w_fire           = io_axi4_wvalid && io_axi4_wready;
  assign axi4_b_fire           = io_axi4_bvalid && io_axi4_bready;
  assign axi4_ar_fire          = io_axi4_arvalid && io_axi4_arready;
  assign axi4_r_fire           = io_axi4_rvalid && io_axi4_rready;

  assign io_axi4_awready       = arw_free;
  assign io_axi4_arready       = arw_free;
  assign io_axi4_wready        = int_axi4_w_ready;
  assign io_axi4_bid           = int_axi4_arw_id;
  assign io_axi4_bvalid        = int_axi4_b_valid;
  assign io_axi4_bresp         = 2'b00;
  assign io_axi4_rid           = int_axi4_arw_id;
  assign io_axi4_rdata         = int_axi4_r_data;
  assign io_axi4_rlast         = int_axi4_arw_last;
  assign io_axi4_rresp         = 2'b00;
  assign io_axi4_rvalid        = int_axi4_r_valid;


  assign int_cmd_burst_cnt     = 6'd0;
  assign int_cmd_wt_data       = cache_data;
  assign int_cmd_wt_mask       = cache_dirty_bit;
  always @(*) begin
    int_cmd_addr    = 27'd0;
    int_cmd_type    = WT_CMD;
    int_axi4_r_data = 32'd0;
    if (arw_free == 1'b0) begin
      if (no_same) begin
        if (is_dirty_trigger) begin
          int_cmd_addr = {cache_addr[26:4], 4'b0000};
          int_cmd_type = WT_CMD;
        end else if (no_same_trigger) begin
          int_cmd_addr = {int_axi4_arw_addr[26:4], 4'b0000};
          int_cmd_type = RD_CMD;
        end
      end else begin
        if (int_axi4_arw_type == RD_CMD) begin
          case (int_axi4_arw_addr[4])
            1'b0: begin
              int_axi4_r_data = cache_data[63:0];
            end
            default: begin
              int_axi4_r_data = cache_data[127:64];
            end
          endcase
        end
      end
    end
  end


  always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      int_cmd_valid    <= 1'b0;
      cache_addr       <= 27'd0;
      cache_data       <= 128'd0;
      cache_dirty_bit  <= 16'hFFFF;

      no_same_trigger  <= 1'b0;
      is_dirty_trigger <= 1'b0;
      arw_free         <= 1'b1;

      int_axi4_w_ready <= 1'b0;
      int_axi4_b_valid <= 1'b0;
      int_axi4_r_valid <= 1'b0;

    end else begin
      // have aw/ar req
      if (axi4_aw_fire || axi4_ar_fire) begin
        arw_free         <= 1'b0;
        no_same_trigger  <= 1'b1;
        is_dirty_trigger <= is_dirty;

        // save the axi4 data into reg
        if (axi4_aw_fire) begin
          int_axi4_arw_id   <= io_axi4_awid;
          int_axi4_arw_addr <= io_axi4_awaddr;
          int_axi4_arw_type <= WT_CMD;
        end else begin
          int_axi4_arw_id   <= io_axi4_arid;
          int_axi4_arw_addr <= io_axi4_araddr;
          int_axi4_arw_type <= RD_CMD;
        end
      end

      if (arw_free == 1'b0) begin
        if (no_same) begin
          if (is_dirty_trigger) begin
            int_cmd_valid <= ~(io_fifo_cmd_valid && io_fifo_cmd_ready);
            if (io_fifo_cmd_valid && io_fifo_cmd_ready) begin
              is_dirty_trigger <= 1'b0;
            end
          end else if (no_same_trigger) begin
            int_cmd_valid <= ~(io_fifo_cmd_valid && io_fifo_cmd_ready);
            if (io_fifo_cmd_valid && io_fifo_cmd_ready) begin
              no_same_trigger <= 1'b0;
            end
          end
        end else begin
          if (int_axi4_arw_type == WT_CMD) begin
            if (axi4_w_fire) begin
              case (int_axi4_arw_addr[3])
                1'b0: begin
                  if (io_axi4_wstrb[0]) begin
                    cache_addr[7:0]    <= io_axi4_wdata[7:0];
                    cache_dirty_bit[0] <= 1'b0;
                  end
                  if (io_axi4_wstrb[1]) begin
                    cache_addr[15:8]   <= io_axi4_wdata[15:8];
                    cache_dirty_bit[1] <= 1'b0;
                  end
                  if (io_axi4_wstrb[2]) begin
                    cache_addr[23:16]  <= io_axi4_wdata[23:16];
                    cache_dirty_bit[2] <= 1'b0;
                  end
                  if (io_axi4_wstrb[3]) begin
                    cache_addr[31:24]  <= io_axi4_wdata[31:24];
                    cache_dirty_bit[3] <= 1'b0;
                  end
                  if (io_axi4_wstrb[4]) begin
                    cache_addr[39:32]  <= io_axi4_wdata[39:32];
                    cache_dirty_bit[4] <= 1'b0;
                  end
                  if (io_axi4_wstrb[5]) begin
                    cache_addr[47:40]  <= io_axi4_wdata[47:40];
                    cache_dirty_bit[5] <= 1'b0;
                  end
                  if (io_axi4_wstrb[6]) begin
                    cache_addr[55:48]  <= io_axi4_wdata[55:48];
                    cache_dirty_bit[6] <= 1'b0;
                  end
                  if (io_axi4_wstrb[7]) begin
                    cache_addr[63:56]  <= io_axi4_wdata[63:56];
                    cache_dirty_bit[7] <= 1'b0;
                  end
                end
                default: begin
                  if (io_axi4_wstrb[8]) begin
                    cache_addr[71:64]  <= io_axi4_wdata[7:0];
                    cache_dirty_bit[8] <= 1'b0;
                  end
                  if (io_axi4_wstrb[9]) begin
                    cache_addr[79:72]  <= io_axi4_wdata[15:8];
                    cache_dirty_bit[9] <= 1'b0;
                  end
                  if (io_axi4_wstrb[10]) begin
                    cache_addr[87:80]   <= io_axi4_wdata[23:16];
                    cache_dirty_bit[10] <= 1'b0;
                  end
                  if (io_axi4_wstrb[11]) begin
                    cache_addr[95:88]   <= io_axi4_wdata[31:24];
                    cache_dirty_bit[11] <= 1'b0;
                  end
                  if (io_axi4_wstrb[12]) begin
                    cache_addr[103:96]  <= io_axi4_wdata[39:32];
                    cache_dirty_bit[12] <= 1'b0;
                  end
                  if (io_axi4_wstrb[13]) begin
                    cache_addr[111:104] <= io_axi4_wdata[47:40];
                    cache_dirty_bit[13] <= 1'b0;
                  end
                  if (io_axi4_wstrb[14]) begin
                    cache_addr[119:112] <= io_axi4_wdata[55:48];
                    cache_dirty_bit[14] <= 1'b0;
                  end
                  if (io_axi4_wstrb[15]) begin
                    cache_addr[127:120] <= io_axi4_wdata[63:56];
                    cache_dirty_bit[15] <= 1'b0;
                  end
                end
              endcase

              int_axi4_w_ready <= 1'b0;
              int_axi4_b_valid <= 1'b1;
            end

            int_axi4_w_ready <= ~int_axi4_b_valid;
            if (axi4_b_fire) begin
              int_axi4_b_valid <= 1'b0;
              arw_free         <= 1'b1;
            end
          end else begin
            int_axi4_r_valid <= ~axi4_r_fire;
            if (axi4_r_fire) begin
              arw_free <= 1'b1;
            end
          end
        end
      end

      if (io_fifo_rsp_valid && io_fifo_rsp_ready) begin
        cache_addr      <= {int_axi4_arw_addr[26:4], 4'b0000};
        cache_data      <= io_fifo_rsp_data;
        cache_dirty_bit <= 16'b0;
      end
    end
  end


endmodule
