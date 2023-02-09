module FIFO_HS_CMD (
    input  [178:0] Data,
    input          Reset,
    input          WrClk,
    input          RdClk,
    input          WrEn,
    input          RdEn,
    output [178:0] Q,
    output         Empty,
    output         Full
);

  assign Q     = 179'd0;
  assign Empty = 1'b0;
  assign Full  = 1'b1;
endmodule
