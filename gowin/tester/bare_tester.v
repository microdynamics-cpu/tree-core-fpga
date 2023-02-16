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
    output reg  [127:0] app_wdata,
    input               app_wdata_rdy,
    input               app_rdata_valid,
    input               app_rdata_end,
    input       [127:0] app_rdata,
    output              txp
);


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

  localparam WORK_WAIT_INIT = 3'd0;
  localparam WORK_DETECT_SIZE = 3'd1;
  localparam WORK_FILL = 3'd2;
  localparam WORK_CHECK = 3'd3;
  localparam WORK_INV_FILL = 3'd4;
  localparam WORK_INV_CHECK = 3'd5;

  localparam WORK_CHECK_FAIL = 3'd6;
  localparam WORK_FIN = 3'd7;


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

  reg [ 2:0] work_state;
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

  //rng part ------------------------------------------------
  reg [127:0] rng;
  reg [127:0] rng_inv;

  reg [127:0] rng_i;
  reg [127:0] rng_init_pattern;
  reg [  6:0] rng_cnt;
  reg         rng_rst;
  reg         rng_tick;

  always @(posedge clk_x1) begin
    rng     <= rng_i;
    rng_inv <= rng_i;

    if (rng_tick) begin
      rng_i   <= {rng_i[126:0], rng_i[68] ^ rng_i[67] ^ rng_i[66] ^ rng_i[63]};
      rng_cnt <= rng_cnt + 7'd1;
    end

    if (rng_rst) begin
      rng_i   <= rng_init_pattern;
      rng_cnt <= 7'd0;
    end
  end
  //rng part ------------------------------------------------

  reg [  5:0] wt_cnt;
  reg [127:0] read_buf_s0;  //2 stages buffer for higher Fmax
  reg [127:0] read_buf_s1;
  reg [127:0] read_data                                      [7:0];
  reg [  2:0] read_data_pos;
  reg         error_bit;

  always @(posedge clk_x1 or negedge rstn) begin
    if (rstn == 1'b0) begin
      //init counter
      init_cnt      <= 'd0;
      wt_cnt        <= 'd0;

      //init state
      work_state    <= WORK_WAIT_INIT;
      detect_state  <= DETECT_SIZE_WR0;
      fill_state    <= FILL_RST;
      check_state   <= CHECK_RST;

      //init interface
      app_cmd_en    <= 1'b0;
      app_wdata_en  <= 1'b0;
      app_wdata_end <= 1'b0;

      //init regs
      error_bit     <= 1'b0;
    end else begin
      init_cnt    <= init_cnt + 8'd1;

      read_buf_s1 <= read_buf_s0;
      read_buf_s0 <= read_data[read_data_pos];

      case (work_state)
        //wait init finish--------------------------------------------
        WORK_WAIT_INIT: begin
          if (init_calib_complete == 1'b0) init_cnt <= 8'd0;

          //exit
          if (init_cnt == 8'd255) work_state <= WORK_DETECT_SIZE;
        end

        //detect ddr size---------------------------------------------
        WORK_DETECT_SIZE: begin
          app_burst_number <= 6'd0;  //one data burst
          app_cmd_en       <= 1'b0;
          app_wdata_en     <= 1'b0;
          app_wdata_end    <= 1'b0;

          case (detect_state)
            DETECT_SIZE_WR0:
            if (app_cmd_rdy && app_wdata_rdy && init_cnt == 8'd0) begin
              app_cmd_en    <= 1'b1;
              app_cmd       <= WR_CMD;
              int_app_addr  <= 27'h000_0000;

              //write data
              app_wdata_en  <= 1'b1;
              app_wdata     <= 128'h5A01_23FA_4567_89AB_CDEF_0123_4567_89AB;
              app_wdata_end <= 1'b1;

              //exit
              detect_state  <= DETECT_SIZE_WR1;
            end
            DETECT_SIZE_WR1:
            if (app_cmd_rdy && app_wdata_rdy && init_cnt == 8'd0) begin
              app_cmd_en    <= 1'b1;
              app_cmd       <= WR_CMD;
              int_app_addr  <= 27'h400_0000;  //Set highest adr line to 1 to detect ddr size

              //write data
              app_wdata_en  <= 1'b1;
              app_wdata     <= 128'h5329_0AB2_FA05_00FF_89AB_CDEF_0123_4567;
              app_wdata_end <= 1'b1;

              //exit
              detect_state  <= DETECT_SIZE_RP0;
            end
            DETECT_SIZE_RP0:
            if (app_cmd_rdy && init_cnt == 8'd0) begin
              app_cmd_en   <= 1'b1;
              app_cmd      <= RD_CMD;
              int_app_addr <= 27'h000_0000;

              //exit
              detect_state <= DETECT_SIZE_RP1;
            end
            DETECT_SIZE_RP1:
            if (app_rdata_valid) begin
              //exit
              work_state <= WORK_FILL;

              //exit if error
              if(
                app_rdata!=128'h5A01_23FA_4567_89AB_CDEF_0123_4567_89AB
              &&
                app_rdata!=128'h5329_0AB2_FA05_00FF_89AB_CDEF_0123_4567
              )begin
                work_state <= WORK_FIN;
                error_bit  <= 1'b1;
              end

              //detect size
              ddr_size<= app_rdata==128'h5A01_23FA_4567_89AB_CDEF_0123_4567_89AB ? DDR_SIZE_2G : DDR_SIZE_1G;
            end
          endcase
        end

        //fill data----------------------------------------------------
        WORK_FILL: begin
          //fill the data, then perform the write cmd
          app_burst_number <= 6'd7;  //8-burst

          rng_rst          <= 1'b0;
          rng_tick         <= 1'b0;
          rng_init_pattern <= 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;

          app_wdata_en     <= 1'b0;
          app_wdata_end    <= 1'b0;
          app_cmd_en       <= 1'b0;

          case (fill_state)
            FILL_RST: begin
              rng_rst      <= 1'b1;

              //set adr to the prev pos, so after add 64, it will be 0
              int_app_addr <= 28'h800_0000 - 28'd64;

              //exit
              fill_state   <= FILL_RNG;
            end

            FILL_RNG: begin
              rng_tick <= 1'b1;

              //exit
              if (rng_cnt == 7'd127) begin
                fill_state <= FILL_WRT;
              end
            end

            FILL_WRT: begin
              if (app_wdata_rdy) begin
                app_wdata_en  <= 1'b1;
                app_wdata_end <= 1'b1;
                app_wdata     <= rng;

                wt_cnt        <= wt_cnt + 6'd1;

                //exit
                if (wt_cnt == 6'd7) begin
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

                //exit
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

        //check data----------------------------------------------------
        WORK_CHECK: begin
          //perform the read cmd, then read the data and compare with the rng
          app_burst_number <= 6'd7;  //8-burst

          rng_rst          <= 1'b0;
          rng_tick         <= 1'b0;
          rng_init_pattern <= 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;

          app_cmd_en       <= 1'b0;

          case (check_state)
            CHECK_RST: begin
              rng_rst      <= 1'b1;

              //set adr to the prev pos, so after add 64, it will be 0
              int_app_addr <= 28'h800_0000 - 28'd64;

              //exit
              check_state  <= CHECK_CMD;
            end

            CHECK_CMD: begin
              if (app_cmd_rdy) begin
                rng_tick      <= 1'b1;  //one more tick

                app_cmd_en    <= 1'b1;
                app_cmd       <= RD_CMD;
                int_app_addr  <= int_app_addr + 27'd64;  //8-burst

                check_state   <= CHECK_DAT;
                read_data_pos <= 3'd0;
              end
            end

            CHECK_DAT: begin
              if (app_rdata_valid) begin
                read_data[read_data_pos] <= app_rdata;

                read_data_pos            <= read_data_pos + 3'd1;
                if (read_data_pos == 3'd7) begin
                  check_state <= CHECK_RNG;
                end
              end
            end

            CHECK_RNG: begin
              rng_tick <= 1'b1;

              if (rng_cnt == 7'd0) begin
                if (read_buf_s1 != rng) begin
                  work_state <= WORK_CHECK_FAIL;
                end

                read_data_pos <= read_data_pos + 3'd1;

                //exit
                if (read_data_pos == 3'd7) begin
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


        //fill with inv data----------------------------------------------------
        WORK_INV_FILL: begin
          //fill the data, then perform the write cmd
          app_burst_number <= 6'd7;  //8-burst

          rng_rst          <= 1'b0;
          rng_tick         <= 1'b0;
          rng_init_pattern <= 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;

          app_wdata_en     <= 1'b0;
          app_wdata_end    <= 1'b0;
          app_cmd_en       <= 1'b0;

          case (fill_state)
            FILL_RST: begin
              rng_rst      <= 1'b1;

              //set adr to the prev pos, so after add 64, it will be 0
              int_app_addr <= 28'h800_0000 - 28'd64;

              //exit
              fill_state   <= FILL_RNG;
            end

            FILL_RNG: begin
              rng_tick <= 1'b1;

              //exit
              if (rng_cnt == 7'd127) begin
                fill_state <= FILL_WRT;
              end
            end

            FILL_WRT: begin
              if (app_wdata_rdy) begin
                app_wdata_en  <= 1'b1;
                app_wdata_end <= 1'b1;
                app_wdata     <= rng_inv;

                wt_cnt        <= wt_cnt + 6'd1;

                //exit
                if (wt_cnt == 6'd7) begin
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

                //exit
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

        //check data----------------------------------------------------
        WORK_INV_CHECK: begin
          //asser the read cmd, then read the data and compare with the rng
          app_burst_number <= 6'd7;  //8-burst

          rng_rst          <= 1'b0;
          rng_tick         <= 1'b0;
          rng_init_pattern <= 128'h0123_4567_890A_BCDE_FEDC_BA98_7654_3210;

          app_cmd_en       <= 1'b0;

          case (check_state)
            CHECK_RST: begin
              rng_rst      <= 1'b1;

              //set adr to the prev pos, so after add 64, it will be 0
              int_app_addr <= 28'h800_0000 - 28'd64;

              //exit
              check_state  <= CHECK_CMD;
            end

            CHECK_CMD: begin
              if (app_cmd_rdy) begin
                rng_tick      <= 1'b1;  //one more tick

                app_cmd_en    <= 1'b1;
                app_cmd       <= RD_CMD;
                int_app_addr  <= int_app_addr + 27'd64;  //8-burst

                check_state   <= CHECK_DAT;
                read_data_pos <= 3'd0;
              end
            end

            CHECK_DAT: begin
              if (app_rdata_valid) begin
                read_data[read_data_pos] <= app_rdata;

                read_data_pos            <= read_data_pos + 3'd1;
                if (read_data_pos == 3'd7) begin
                  check_state <= CHECK_RNG;
                end
              end
            end

            CHECK_RNG: begin
              rng_tick <= 1'b1;

              if (rng_cnt == 7'd0) begin

                if (read_buf_s1 != rng_inv) begin
                  work_state <= WORK_CHECK_FAIL;
                end

                read_data_pos <= read_data_pos + 3'd1;

                //exit
                if (read_data_pos == 3'd7) begin
                  check_state <= CHECK_CMD;

                  if (ddr_size == DDR_SIZE_1G) begin
                    if ({1'b0, int_app_addr} == 28'h400_0000 - 28'd64) begin
                      work_state  <= WORK_FIN;
                      check_state <= CHECK_RST;
                    end
                  end else begin
                    if ({1'b0, int_app_addr} == 28'h800_0000 - 28'd64) begin
                      work_state  <= WORK_FIN;
                      check_state <= CHECK_RST;
                    end
                  end
                end
              end
            end
          endcase
        end

        //check error----------------------------------------------------
        WORK_CHECK_FAIL: begin
        end
        //error-------------------------------------------------------
        WORK_FIN: begin
        end
      endcase
    end
  end

  `include "print.v"
  defparam u_uart_tx.bsp = 115200; defparam u_uart_tx.freq = 27_000_000;
  assign print_clk = clk;
  assign txp       = uart_txp;

  reg  [2:0]                       state_d1;
  reg  [2:0]                       state_d2;
  reg  [2:0]                       state_old;
  wire [2:0] state_new = state_d2;


  always @(posedge clk) begin
    state_d2 <= state_d1;
    state_d1 <= work_state;

    if (state_d1 == state_d2) begin
      state_old <= state_new;

      if (state_old != state_new) begin
        if (state_old == WORK_WAIT_INIT)
          `print("======DDR Memory Write/Read Test======\nDDR3 Init Complete\n", STR);

        if (state_new == WORK_FILL)
          if (ddr_size == DDR_SIZE_1G)
            `print("DDR Size Detect: 1G\nBegin 8-Burst Aligned Write...\n", STR);
          else
            `print("DDR Size Detect: 2G\nBegin 8-Burst Aligned Write...\n", STR);

        if (state_new == WORK_CHECK)
          `print("Write Finished\nBegin to Check...\n", STR);

        if (state_new == WORK_INV_FILL)
          `print("Check Finished without Mismatch\nBegin 8-Burst Aligned Inverse Data Write...\n", STR);

        if (state_new == WORK_INV_CHECK)
          `print("Write Finished\nBegin to Check...\n", STR);

        if (state_new == WORK_CHECK_FAIL)
          `print("Check Failed. Mismatch Occured\n", STR);

        if (state_new == WORK_FIN) begin
          if (error_bit)
            `print("Error Occured\n\n", STR);
          else
            `print("Check Finished without Mismatch\nTest Finished\n\n", STR);
        end
      end
    end

    if (rstn == 1'b0)
      `print("Perform Reset\nAuto Reset Every 100s\n", STR);
  end

endmodule
