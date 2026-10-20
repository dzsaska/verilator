// DESCRIPTION: Verilator: FSM defaults must respect preceding state branches
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Hudson River Trading LLC
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkd(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0d exp=%0d\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
// verilog_format: on

module t (
    input logic clk
);
  typedef enum logic [1:0] { IDLE = 0, RUN = 1, DONE = 2 } state_t;
  state_t state = IDLE;
  int cyc = 0;
  wire [1:0] other = 2'(cyc);

  always_ff @(posedge clk) begin
    // This nonconstant target prevents recognition of the complete chain.
    // IDLE can only stay IDLE or go to DONE; it cannot reach the final else.
    if (state == IDLE) state <= state_t'(other & 2'b10);
    else if (state == RUN) state <= DONE;
    else state <= RUN;
  end

  // verilator coverage_off
  state_t previous;
  logic [2:0] visited = 0;
  always @(posedge clk) begin
    previous <= state;
    cyc <= cyc + 1;
  end
  always @(negedge clk) begin
    visited[state] = 1;
    if (previous == IDLE) `checkd(state == RUN, 1'b0);
    if (cyc == 16) begin
      `checkd(visited, 3'b111);
      $write("*-* All Finished *-*\n");
      $finish;
    end
  end
endmodule
