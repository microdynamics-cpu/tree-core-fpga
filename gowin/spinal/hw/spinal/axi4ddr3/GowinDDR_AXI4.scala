package axi4ddr3

import spinal.core._
import spinal.lib.bus.amba4.axi.Axi4Shared
import spinal.lib.{master, slave}

// sys_clk: 27MHz mem_clk: 400MHz
case class GowinDDR_AXI4(sys_clk: ClockDomain, mem_clk: ClockDomain) extends Component {

  val gowin_DDR3 = Gowin_DDR3(
    sys_clk,
    mem_clk
  )
  val ddr_ref_clk = gowin_DDR3.clk_out

  val axi4cache = GowinDDR_AXI4WithCache(
    sys_clk,
    32,
    27,
    4
  )

  val axi4ctrl = GowinDDR14_Controller(
    sys_clk,
    ddr_ref_clk,
    contextType = axi4cache.context_type,
    fifo_length = 4
  )

  val io = new Bundle() {
    val pll_lock  = in.Bool()
    val axi       = slave(Axi4Shared(axi4cache.axiConfig))
    val ddr_iface = master(DDR3_Interface())
  }

  val sys_area = new ClockingArea(sys_clk) {
    axi4cache.io.ddr_cmd >> axi4ctrl.io.ddr_cmd
    axi4cache.io.ddr_rsp << axi4ctrl.io.ddr_rsp

    io.axi.sharedCmd >> axi4cache.io.axi.sharedCmd
    io.axi.writeData >> axi4cache.io.axi.writeData
    io.axi.writeRsp << axi4cache.io.axi.writeRsp
    io.axi.readRsp << axi4cache.io.axi.readRsp

    gowin_DDR3.io.sr_req            := False
    gowin_DDR3.io.ref_req           := False
    gowin_DDR3.io.burst             := True
    gowin_DDR3.io.pll_lock          := io.pll_lock
    gowin_DDR3.io.app_burst_number  := axi4ctrl.io.app_burst_number
    gowin_DDR3.io.cmd               := axi4ctrl.io.cmd
    gowin_DDR3.io.cmd_en            := axi4ctrl.io.cmd_en
    gowin_DDR3.io.addr              := axi4ctrl.io.addr
    gowin_DDR3.io.wr_data           := axi4ctrl.io.wr_data
    gowin_DDR3.io.wr_data_en        := axi4ctrl.io.wr_data_en
    gowin_DDR3.io.wr_data_end       := axi4ctrl.io.wr_data_en
    gowin_DDR3.io.wr_data_mask      := axi4ctrl.io.wr_data_mask
    axi4ctrl.io.cmd_ready           := gowin_DDR3.io.cmd_ready
    axi4ctrl.io.wr_data_rdy         := gowin_DDR3.io.wr_data_rdy
    axi4ctrl.io.rd_data             := gowin_DDR3.io.rd_data
    axi4ctrl.io.rd_data_valid       := gowin_DDR3.io.rd_data_valid
    axi4ctrl.io.init_calib_complete := gowin_DDR3.io.init_calib_complete

    gowin_DDR3.connectDDR3Interface(io.ddr_iface)
  }

}
