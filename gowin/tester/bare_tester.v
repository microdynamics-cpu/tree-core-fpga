module bare_tester (
    input               clk,
    input               clk_x1,
    output reg          rstn,
    input               init_calib_complete,
    output reg  [  5:0] app_burst_number,
    output wire [ 26:0] app_addr,
    output reg          app_cmd_en,
    output reg  [  2:0] app_cmd,
    input               app_cmd_rdy,
    output reg          app_wdata_en,
    output reg          app_wdata_end,
    output reg  [ 15:0] app_wdata_mask,
    output reg  [127:0] app_wdata,
    input               app_wdata_rdy,
    input               app_rdata_valid,
    input               app_rdata_end,
    input       [127:0] app_rdata,
    output              txp
);

  // always @(posedge clk_x1) begin
  //   app_wdata_mask <= 'd0;
  // end

  reg [31:0] rst_cnt;
  always @(posedge clk) begin
    rst_cnt <= rst_cnt + 1;
    if (rst_cnt > 32'd2_700_000_000 - 32'd1) begin
      rstn    <= 1'b0;
      rst_cnt <= 0;
    end else begin
      rstn <= 1'b1;
    end
  end

  localparam BURST_LEN = 8;
  localparam BURST_LEN1 = 7;

  localparam WORK_WAIT_INIT = 4'd0;
  localparam WORK_DETECT_SIZE = 4'd1;
  localparam WORK_FILL = 4'd2;
  localparam WORK_CHECK = 4'd3;
  localparam WORK_INV_FILL = 4'd4;
  localparam WORK_INV_CHECK = 4'd5;
  localparam WORK_CHECK_FAIL = 4'd6;
  localparam WORK_FINAL = 4'd7;
  localparam WORK_NA_FILL = 4'd8;
  localparam WORK_CC_FILL = 4'd9;
  localparam WORK_CC_CHECK = 4'd10;


  localparam DETECT_SIZE_WR0 = 2'd0;
  localparam DETECT_SIZE_WR1 = 2'd1;
  localparam DETECT_SIZE_RP0 = 2'd2;
  localparam DETECT_SIZE_RP1 = 2'd3;

  localparam FILL_RST = 2'd0;
  localparam FILL_RNG = 2'd1;
  localparam FILL_WRT = 2'd2;
  localparam FILL_CMD = 2'd3;

  localparam CHECK_RST = 2'd0;
  localparam CHECK_CMD = 2'd1;
  localparam CHECK_DAT = 2'd2;
  localparam CHECK_RNG = 2'd3;

  localparam WR_CMD = 3'h0;
  localparam RD_CMD = 3'h1;

  localparam DDR_SIZE_1G = 1'b0;
  localparam DDR_SIZE_2G = 1'b1;

  localparam DET_SIZE_WR_VAL1 = 128'h5A01_23FA_4567_89AB_CDEF_0123_4567_89AB;
  localparam DET_SIZE_WR_VAL2 = 128'h5329_0AB2_FA05_00FF_89AB_CDEF_0123_4567;
  localparam RNG_INIT_VAL = 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;

  reg [ 3:0] work_state;
  reg [ 1:0] detect_state;
  reg [ 1:0] fill_state;
  reg [ 1:0] check_state;
  reg [ 7:0] init_cnt;
  reg        ddr_size;
  reg [26:0] int_app_addr;

  //remap the addr, row -> bank -> col
  //it makes simpler to detect the size
  //the addr is the real ddr address
  //counted in 2 Bytes
  //So in every Single-Busrt, the addr should increse by 8
  //In a 64-Burst, the addr should increse by 512
  assign app_addr = {int_app_addr[12:10], int_app_addr[26:13], int_app_addr[9:0]};

  reg [127:0] rng;
  reg [127:0] rng_inv;
  reg [127:0] ext_mask;
  reg [ 15:0] mask;

  reg [127:0] rng_i;
  reg [127:0] rng_init_pattern;
  reg [ 15:0] mask_i;
  reg [  6:0] rng_cnt;
  reg         rng_rst;
  reg         rng_tick;

  always @(*) begin
    for (integer i = 0; i < 16; i = i + 1) begin
      ext_mask[(i+1)*8-1-:8] = {8{~mask[i]}};
    end
  end

  always @(posedge clk_x1) begin
    rng     <= rng_i;
    rng_inv <= ~rng_i;
    mask    <= mask_i;

    if (rng_tick) begin
      rng_i   <= {rng_i[126:0], rng_i[68] ^ rng_i[67] ^ rng_i[66] ^ rng_i[63]};
      // mask_i  <= {mask_i[14:0], mask_i[11] ^ mask_i[10] ^ mask_i[4]};
      mask_i  <= {mask_i[14:0], mask_i[15]};
      rng_cnt <= rng_cnt + 7'd1;
    end

    if (rng_rst) begin
      rng_i   <= rng_init_pattern;
      mask_i  <= 'hFFFE;
      // mask_i  <= 'hF8FC;
      rng_cnt <= 7'd0;
    end
  end

  //2 stages buffer for higher Fmax
  reg [127:0] rd_buf_d1;
  reg [127:0] rd_buf_d2;
  reg [127:0] rd_data   [7:0];
  reg [  2:0] rd_idx;
  reg [  5:0] wt_cnt;
  reg         error_bit;

  always @(posedge clk_x1 or negedge rstn) begin
    if (rstn == 1'b0) begin
      init_cnt      <= 'd0;
      wt_cnt        <= 'd0;

      work_state    <= WORK_WAIT_INIT;
      detect_state  <= DETECT_SIZE_WR0;
      fill_state    <= FILL_RST;
      check_state   <= CHECK_RST;

      app_cmd_en    <= 1'b0;
      app_wdata_en  <= 1'b0;
      app_wdata_end <= 1'b0;
      error_bit     <= 1'b0;
    end else begin
      init_cnt  <= init_cnt + 8'd1;
      rd_buf_d2 <= rd_buf_d1;
      rd_buf_d1 <= rd_data[rd_idx];

      case (work_state)
        WORK_WAIT_INIT: begin
          if (init_calib_complete == 1'b0) init_cnt <= 8'd0;
          if (init_cnt == 8'd255) work_state <= WORK_DETECT_SIZE;
        end

        WORK_DETECT_SIZE: begin
          app_burst_number <= 6'd0;  //one data burst
          app_cmd_en       <= 1'b0;
          app_wdata_en     <= 1'b0;
          app_wdata_end    <= 1'b0;

          case (detect_state)
            DETECT_SIZE_WR0:
            if (app_cmd_rdy && app_wdata_rdy && (init_cnt == 8'd0)) begin
              app_cmd_en    <= 1'b1;
              app_cmd       <= WR_CMD;
              int_app_addr  <= 27'h000_0000;

              app_wdata_en  <= 1'b1;
              app_wdata     <= DET_SIZE_WR_VAL1;
              app_wdata_end <= 1'b1;

              detect_state  <= DETECT_SIZE_WR1;
            end
            DETECT_SIZE_WR1:
            if (app_cmd_rdy && app_wdata_rdy && (init_cnt == 8'd0)) begin
              app_cmd_en    <= 1'b1;
              app_cmd       <= WR_CMD;
              int_app_addr  <= 27'h400_0000;  //Set highest adr line to 1 to detect ddr size

              app_wdata_en  <= 1'b1;
              app_wdata     <= DET_SIZE_WR_VAL2;
              app_wdata_end <= 1'b1;

              detect_state  <= DETECT_SIZE_RP0;
            end
            DETECT_SIZE_RP0:
            if (app_cmd_rdy && (init_cnt == 8'd0)) begin
              app_cmd_en   <= 1'b1;
              app_cmd      <= RD_CMD;
              int_app_addr <= 27'h000_0000;

              detect_state <= DETECT_SIZE_RP1;
            end
            DETECT_SIZE_RP1:
            if (app_rdata_valid) begin
              work_state <= WORK_FILL;
              if (app_rdata != DET_SIZE_WR_VAL1 && app_rdata != DET_SIZE_WR_VAL2) begin
                work_state <= WORK_FINAL;
                error_bit  <= 1'b1;
              end

              ddr_size <= app_rdata == DET_SIZE_WR_VAL1 ? DDR_SIZE_2G : DDR_SIZE_1G;
            end
          endcase
        end

        WORK_FILL: begin
          app_burst_number <= BURST_LEN - 1;  // 8-burst

          rng_rst          <= 1'b0;
          rng_tick         <= 1'b0;
          rng_init_pattern <= RNG_INIT_VAL;

          app_wdata_en     <= 1'b0;
          app_wdata_end    <= 1'b0;
          app_cmd_en       <= 1'b0;
          case (fill_state)
            FILL_RST: begin
              rng_rst      <= 1'b1;
              //set adr to the prev pos, so after add 64, it will be 0
              int_app_addr <= 28'h800_0000 - 28'd64;
              fill_state   <= FILL_RNG;
            end
            FILL_RNG: begin
              rng_tick <= 1'b1;
              if (rng_cnt == 7'd127) begin
                fill_state <= FILL_WRT;
              end
            end
            FILL_WRT: begin
              if (app_wdata_rdy) begin
                app_wdata_en   <= 1'b1;
                app_wdata_end  <= 1'b1;
                app_wdata      <= rng;
                app_wdata_mask <= mask;
                wt_cnt         <= wt_cnt + 6'd1;
                if (wt_cnt == BURST_LEN - 1) begin
                  fill_state <= FILL_CMD;
                  wt_cnt     <= 6'd0;
                end else fill_state <= FILL_RNG;
              end
            end
            FILL_CMD: begin
              if (app_cmd_rdy) begin
                app_cmd_en   <= 1'b1;
                app_cmd      <= WR_CMD;
                int_app_addr <= int_app_addr + 27'd64;  //8-burst

                fill_state   <= FILL_RNG;
                if (ddr_size == DDR_SIZE_1G) begin
                  if ({1'b0, int_app_addr} == 28'h400_0000 - 28'd128) begin
                    work_state <= WORK_CHECK;
                    fill_state <= FILL_RST;
                  end
                end else begin
                  if ({1'b0, int_app_addr} == 28'h800_0000 - 28'd128) begin
                    work_state <= WORK_CHECK;
                    fill_state <= FILL_RST;
                  end
                end
              end
            end
          endcase
        end
        WORK_CHECK: begin
          //perform the read cmd, then read the data and compare with the rng
          app_burst_number <= BURST_LEN - 1;  //8-burst

          rng_rst          <= 1'b0;
          rng_tick         <= 1'b0;
          rng_init_pattern <= RNG_INIT_VAL;

          app_cmd_en       <= 1'b0;
          case (check_state)
            CHECK_RST: begin
              rng_rst      <= 1'b1;
              //set adr to the prev pos, so after add 64, it will be 0
              int_app_addr <= 28'h800_0000 - 28'd64;
              check_state  <= CHECK_CMD;
            end

            CHECK_CMD: begin
              if (app_cmd_rdy) begin
                rng_tick     <= 1'b1;  //one more tick

                app_cmd_en   <= 1'b1;
                app_cmd      <= RD_CMD;
                int_app_addr <= int_app_addr + 27'd64;  //8-burst

                check_state  <= CHECK_DAT;
                rd_idx       <= 3'd0;
              end
            end

            CHECK_DAT: begin
              if (app_rdata_valid) begin
                rd_data[rd_idx] <= app_rdata;

                rd_idx          <= rd_idx + 3'd1;
                if (rd_idx == BURST_LEN - 1) begin
                  check_state <= CHECK_RNG;
                end
              end
            end

            CHECK_RNG: begin
              rng_tick <= 1'b1;

              if (rng_cnt == 7'd0) begin
                if ((rd_buf_d2 & ext_mask) != (rng & ext_mask)) begin
                  work_state <= WORK_CHECK_FAIL;
                end

                rd_idx <= rd_idx + 3'd1;

                if (rd_idx == BURST_LEN - 1) begin
                  check_state <= CHECK_CMD;

                  if (ddr_size == DDR_SIZE_1G) begin
                    if ({1'b0, int_app_addr} == 28'h400_0000 - 28'd64) begin
                      work_state  <= WORK_INV_FILL;
                      check_state <= CHECK_RST;
                    end
                  end else begin
                    if ({1'b0, int_app_addr} == 28'h800_0000 - 28'd64) begin
                      work_state  <= WORK_INV_FILL;
                      check_state <= CHECK_RST;
                    end
                  end
                end
              end
            end
          endcase
        end

        WORK_INV_FILL: begin
          //fill the data, then perform the write cmd
          app_burst_number <= BURST_LEN - 1;  //8-burst

          rng_rst          <= 1'b0;
          rng_tick         <= 1'b0;
          rng_init_pattern <= RNG_INIT_VAL;

          app_wdata_en     <= 1'b0;
          app_wdata_end    <= 1'b0;
          app_cmd_en       <= 1'b0;

          case (fill_state)
            FILL_RST: begin
              rng_rst      <= 1'b1;
              //set adr to the prev pos, so after add 64, it will be 0
              int_app_addr <= 28'h800_0000 - 28'd64;
              fill_state   <= FILL_RNG;
            end
            FILL_RNG: begin
              rng_tick <= 1'b1;
              if (rng_cnt == 7'd127) begin
                fill_state <= FILL_WRT;
              end
            end
            FILL_WRT: begin
              if (app_wdata_rdy) begin
                app_wdata_en   <= 1'b1;
                app_wdata_end  <= 1'b1;
                app_wdata      <= rng_inv;
                app_wdata_mask <= mask;
                wt_cnt         <= wt_cnt + 6'd1;
                if (wt_cnt == BURST_LEN - 1) begin
                  fill_state <= FILL_CMD;
                  wt_cnt     <= 6'd0;
                end else fill_state <= FILL_RNG;
              end
            end
            FILL_CMD: begin
              if (app_cmd_rdy) begin
                app_cmd_en   <= 1'b1;
                app_cmd      <= WR_CMD;
                int_app_addr <= int_app_addr + 27'd64;  //8-burst

                fill_state   <= FILL_RNG;
                if (ddr_size == DDR_SIZE_1G) begin
                  if ({1'b0, int_app_addr} == 28'h400_0000 - 28'd128) begin
                    work_state <= WORK_INV_CHECK;
                    fill_state <= FILL_RST;
                  end
                end else begin
                  if ({1'b0, int_app_addr} == 28'h800_0000 - 28'd128) begin
                    work_state <= WORK_INV_CHECK;
                    fill_state <= FILL_RST;
                  end
                end
              end
            end
          endcase
        end

        WORK_INV_CHECK: begin
          //asser the read cmd, then read the data and compare with the rng
          app_burst_number <= BURST_LEN - 1;  //8-burst

          rng_rst          <= 1'b0;
          rng_tick         <= 1'b0;
          rng_init_pattern <= RNG_INIT_VAL;

          app_cmd_en       <= 1'b0;
          case (check_state)
            CHECK_RST: begin
              rng_rst      <= 1'b1;
              //set adr to the prev pos, so after add 64, it will be 0
              int_app_addr <= 28'h800_0000 - 28'd64;
              check_state  <= CHECK_CMD;
            end

            CHECK_CMD: begin
              if (app_cmd_rdy) begin
                rng_tick     <= 1'b1;  //one more tick

                app_cmd_en   <= 1'b1;
                app_cmd      <= RD_CMD;
                int_app_addr <= int_app_addr + 27'd64;  //8-burst

                check_state  <= CHECK_DAT;
                rd_idx       <= 3'd0;
              end
            end

            CHECK_DAT: begin
              if (app_rdata_valid) begin
                rd_data[rd_idx] <= app_rdata;
                rd_idx          <= rd_idx + 3'd1;
                if (rd_idx == BURST_LEN - 1) begin
                  check_state <= CHECK_RNG;
                end
              end
            end

            CHECK_RNG: begin
              rng_tick <= 1'b1;
              if (rng_cnt == 7'd0) begin
                if ((rd_buf_d2 & ext_mask) != (rng_inv & ext_mask)) begin
                  work_state <= WORK_CHECK_FAIL;
                end

                rd_idx <= rd_idx + 3'd1;
                if (rd_idx == BURST_LEN - 1) begin
                  check_state <= CHECK_CMD;

                  if (ddr_size == DDR_SIZE_1G) begin
                    if ({1'b0, int_app_addr} == 28'h400_0000 - 28'd64) begin
                      work_state  <= WORK_CC_FILL;
                      check_state <= CHECK_RST;
                    end
                  end else begin
                    if ({1'b0, int_app_addr} == 28'h800_0000 - 28'd64) begin
                      work_state  <= WORK_CC_FILL;
                      check_state <= CHECK_RST;
                    end
                  end
                end
              end
            end
          endcase
        end

        WORK_CC_FILL: begin
          app_burst_number <= BURST_LEN1 - 1;
          rng_rst          <= 'd0;
          rng_tick         <= 'd0;
          rng_init_pattern <= RNG_INIT_VAL;

          app_wdata_en     <= 'd0;
          app_wdata_end    <= 'd0;
          app_cmd_en       <= 'd0;
          case (fill_state)
            FILL_RST: begin
              rng_rst      <= 1'd1;
              int_app_addr <= 28'h000_0300 - BURST_LEN1 * 8;
              fill_state   <= FILL_RNG;
            end
            FILL_RNG: begin
              rng_tick <= 1'd1;
              if (rng_cnt == 7'd127) begin
                fill_state <= FILL_WRT;
              end
            end
            FILL_WRT: begin
              if (app_wdata_rdy) begin
                app_wdata_en   <= 1'd1;
                app_wdata_end  <= 1'd1;
                app_wdata      <= rng;
                app_wdata_mask <= mask;
                wt_cnt         <= wt_cnt + 6'd1;
                if (wt_cnt == BURST_LEN - 1) begin
                  fill_state <= FILL_CMD;
                  wt_cnt     <= 6'd0;
                end else fill_state <= FILL_RNG;
              end
            end
            FILL_CMD: begin
              if (app_cmd_rdy) begin
                app_cmd_en   <= 1'b1;
                app_cmd      <= WR_CMD;
                int_app_addr <= int_app_addr + BURST_LEN1 * 8;

                fill_state   <= FILL_RNG;
                if (ddr_size == DDR_SIZE_1G) begin
                  if ({1'b0, int_app_addr} >= 28'h000_0500 - 28'd128) begin
                    work_state <= WORK_CC_CHECK;
                    fill_state <= FILL_RST;
                  end
                end else begin
                  if ({1'b0, int_app_addr} >= 28'h800_0000 - 28'd128) begin
                    work_state <= WORK_CC_CHECK;
                    fill_state <= FILL_RST;
                  end
                end
              end
            end
          endcase
        end
        WORK_CC_CHECK: begin
          //perform the read cmd, then read the data and compare with the rng
          app_burst_number <= BURST_LEN - 1;  //8-burst

          rng_rst          <= 1'b0;
          rng_tick         <= 1'b0;
          rng_init_pattern <= RNG_INIT_VAL;

          app_cmd_en       <= 1'b0;
          case (check_state)
            CHECK_RST: begin
              rng_rst      <= 1'b1;
              //set adr to the prev pos, so after add 64, it will be 0
              int_app_addr <= 28'h000_0300 - BURST_LEN1 * 8;
              check_state  <= CHECK_CMD;
            end
            CHECK_CMD: begin
              if (app_cmd_rdy) begin
                rng_tick     <= 1'b1;  //one more tick

                app_cmd_en   <= 1'b1;
                app_cmd      <= RD_CMD;
                int_app_addr <= int_app_addr + BURST_LEN1 * 8;

                check_state  <= CHECK_DAT;
                rd_idx       <= 3'd0;
              end
            end
            CHECK_DAT: begin
              if (app_rdata_valid) begin
                rd_data[rd_idx] <= app_rdata;
                rd_idx          <= rd_idx + 3'd1;
                if (rd_idx == BURST_LEN - 1) begin
                  check_state <= CHECK_RNG;
                end
              end
            end
            CHECK_RNG: begin
              rng_tick <= 1'b1;
              if (rng_cnt == 7'd0) begin
                if ((rd_buf_d2 & ext_mask) != (rng & ext_mask)) begin
                  work_state <= WORK_CHECK_FAIL;
                end

                rd_idx <= rd_idx + 3'd1;
                if (rd_idx == BURST_LEN - 1) begin
                  check_state <= CHECK_CMD;
                  if (ddr_size == DDR_SIZE_1G) begin
                    if ({1'b0, int_app_addr} >= 28'h000_0500 - 28'd64) begin
                      work_state  <= WORK_NA_FILL;
                      check_state <= CHECK_RST;
                    end
                  end else begin
                    if ({1'b0, int_app_addr} >= 28'h800_0000 - 28'd64) begin
                      work_state  <= WORK_NA_FILL;
                      check_state <= CHECK_RST;
                    end
                  end
                end
              end
            end
          endcase
        end
        WORK_NA_FILL: begin
          work_state <= WORK_FINAL;
        end
        WORK_CHECK_FAIL: begin
        end
        WORK_FINAL: begin
        end
      endcase
    end
  end

  `include "print.v"
  defparam u_uart_tx.bsp = 115200; defparam u_uart_tx.freq = 27_000_000;
  assign print_clk = clk;
  assign txp       = uart_txp;

  reg  [ 3:0]                       state_d1;
  reg  [ 3:0]                       state_d2;
  reg  [ 3:0]                       state_old;
  wire [ 3:0] state_new = state_d2;

  reg  [31:0]                       data_tmp = 32'h21_22_23_24;

  always @(posedge clk) begin
    state_d2 <= state_d1;
    state_d1 <= work_state;

    if (state_d1 == state_d2) begin
      state_old <= state_new;

      if (state_old != state_new) begin
        if (state_old == WORK_WAIT_INIT) begin
          `print("======DDR Memory Write/Read Test======\nDDR3 Init Complete\n", STR);
          // `print(data_tmp, 4);
          // `print(RNG_INIT_VAL, 16);
        end

        if (state_new == WORK_FILL)
          if (ddr_size == DDR_SIZE_1G)
            `print(
                "DDR Size Detect: 1Gb(64M x 16bits)\n\n===8-Burst Aligned Write Test===\nBegin Write...\n",
                STR);
          else
            `print(
                "DDR Size Detect: 2Gb(128M x 16bits)\n\n===8-Burst Aligned Write Test===\nBegin Write...\n",
                STR);

        if (state_new == WORK_CHECK) begin
          `print("Write Finished\nBegin to Check...\n", STR);
        end

        if (state_new == WORK_INV_FILL) begin
          `print("Check SUCCEEDED!\n\n===8-Burst Aligned Inverse Write Test===\nBegin Write...\n",
                 STR);
        end

        if (state_new == WORK_INV_CHECK) begin
          `print("Write Finished\nBegin to Check...\n", STR);
        end

        if (state_new == WORK_CHECK_FAIL) begin
          `print("Check Failed. Mismatch Occured\n", STR);
        end

        if (state_new == WORK_CC_FILL) begin
          `print("Check SUCCEEDED!\n\n===8-Burst Cross Column Write Test===\nBegin Write...\n",
                 STR);
        end

        if (state_new == WORK_CC_CHECK) begin
          `print("Write Finished\nBegin to Check...\n", STR);
        end

        if (state_new == WORK_NA_FILL) begin
          `print("Check SUCCEEDED!\n\n===8-Burst Not-Aligned Write Test===\nBegin Write...\n", STR);
        end

        if (state_new == WORK_FINAL) begin
          if (error_bit) begin
            `print("Error Occured\n\n", STR);
          end else
            `print("Check SUCCEEDED!\nTest Finished\n\n", STR);
        end
      end
    end

    if (rstn == 1'b0)
      `print("Reset DDR3 Test Every 100s\n", STR);
  end

endmodule
