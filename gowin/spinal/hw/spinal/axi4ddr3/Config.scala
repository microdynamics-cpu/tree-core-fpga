package axi4ddr3

import spinal.core._
import spinal.core.sim._

object Config {
  def spinal = SpinalConfig(
    targetDirectory = "hw/gen"
  )
}

object GOWIN_AXI4_DDR3 extends App {
  Config.spinal.generateVerilog(GowinDDR_AXI4(ClockDomain.external("sys_clk"), ClockDomain.external("mem_clk")))
}
