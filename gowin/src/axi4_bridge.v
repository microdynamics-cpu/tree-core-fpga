module axi4_bridge (
    input clk, // 100MHz
    input clk_sys, // 27MHz
    input rstn,

    // axi4 interface
    output        io_axi4_awready,
    input         io_axi4_awvalid,
    input [ 3:0]  io_axi4_awid,
    input [31:0]  io_axi4_awaddr,
    input [ 7:0]  io_axi4_awlen,
    input [ 2:0]  io_axi4_awsize,
    input [ 1:0]  io_axi4_awburst,

    output        io_axi4_wready,
    input         io_axi4_wvalid,
    input [63:0]  io_axi4_wdata,
    input [ 7:0]  io_axi4_wstrb,
    input         io_axi4_wlast,

    input         io_axi4_bready,
    output        io_axi4_bvalid,
    output [ 3:0] io_axi4_bid,
    output [ 1:0] io_axi4_bresp,

    output        io_axi4_arready,
    input         io_axi4_arvalid,
    input [ 3:0]  io_axi4_arid,
    input [31:0]  io_axi4_araddr,
    input [ 7:0]  io_axi4_arlen,
    input [ 2:0]  io_axi4_arsize,
    input [ 1:0]  io_axi4_arburst,

    input         io_axi4_rready,
    output        io_axi4_rvalid,
    output [ 3:0] io_axi4_rid,
    output [63:0] io_axi4_rdata,
    output [ 1:0] io_axi4_rresp,
    output        io_axi4_rlast,

    // ddr3 interface
    input              init_calib_complete,
    output reg [5:0]   app_burst_number,
    output [27:0]      app_addr,

    output reg         app_cmd_en,
    output reg [2:0]   app_cmd,
    input              app_cmd_rdy,

    output reg         app_wdata_en,
    output reg         app_wdata_end,
    output reg [127:0] app_wdata,
    input              app_wdata_rdy,

    input              app_rdata_valid,
    input              app_rdata_end,
    input [127:0]      app_rdata
);












localparam FSM_IDLE = 3'd0;
localparam FSM_AW   = 3'd1;
localparam FSM_WT   = 3'd2;
localparam FSM_RSP  = 3'd3;
localparam FSM_AR   = 3'd4;
localparam FSM_RD   = 3'd5;

localparam WT_CMD = 3'd0;
localparam RD_CMD = 3'd1;

reg [3:0] state;
reg [26:0] int_app_addr;
assign app_addr = {1'b0, int_app_addr};

reg cmd_free;
wire cmd_can_send;
assign cmd_can_send = app_cmd_rdy && app_wdata_rdy && init_calib_complete;

// handshake signal
wire wt_fire;
wire rd_fire;
wire data_fire;

assign wt_fire = app_wdata_en && app_wdata_rdy;
assign rd_fire = app_rdata_valid;
assign data_fire = wt_fire || rd_fire;

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            state <= FSM_IDLE;
            int_app_addr <= 27'd0;

            app_burst_number <= 6'd0;
            app_cmd_en <= 1'b0;
            app_cmd <= 3'd0;
            app_wdata_en <= 1'b0;
            app_wdata_end <= 1'b0;
            app_wdata <= 128'd0;
        end
        else begin
        end
    end
endmodule