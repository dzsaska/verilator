// DESCRIPTION: Verilator: FSM if-chain default transitions
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkd(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0d exp=%0d\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
// verilog_format: on

module if_default_one (
    input logic clk,
    input logic rst,
    output logic [1:0] result
);
  typedef enum logic [1:0] { IDLE, RUN, DONE } state_t;
  state_t state;

  always_ff @(posedge clk) begin
    if (rst) state <= IDLE;
    else if (state == IDLE) state <= RUN;
    else if (state == RUN) state <= DONE;
    else state <= DONE;
  end
  assign result = state;
endmodule

module if_default_noreset (
    input logic clk,
    output logic [1:0] result
);
  typedef enum logic [1:0] { IDLE, RUN, DONE } state_t;
  state_t state = IDLE;

  always_ff @(posedge clk) begin
    if (state == IDLE) state <= RUN;
    else if (state == RUN) state <= DONE;
    else state <= IDLE;
  end
  assign result = state;
endmodule

module if_default_two #(
    parameter int MODE = 0
) (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [2:0] other,
    output logic [2:0] result,
    output logic side_effect
);
  typedef enum logic [2:0] { IDLE = 0, RUN = 1, DONE = 3, RETRY = 5 } state_t;
  typedef state_t state_alias_t;
  state_alias_t state_q;
  state_alias_t state_d;

  always_comb begin
    state_d = state_q;
    side_effect = 0;
    if (state_q == IDLE && ((MODE != 1 && MODE != 5 && MODE != 7) || enable)) state_d = RUN;
    else if (MODE != 5 && state_q == RUN && (MODE != 6 || enable)) state_d = DONE;
    else begin
      if (MODE == 0) state_d = DONE;
      else if (MODE == 1 || MODE == 5 || MODE == 6) state_d = RETRY;
      else if (MODE == 2) begin
        state_d = RETRY;
        side_effect = enable;
      end
      else if (MODE == 3) state_d = state_t'(other);
      else if (MODE == 7) state_d = RUN;
      else begin
        // Keep this ternary as an expression to exercise both default targets.
        // verilator coverage_off
        state_d = enable ? IDLE : RETRY;
        // verilator coverage_on
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) state_q <= IDLE;
    else state_q <= state_d;
  end
  assign result = state_q;
endmodule

module if_default_nonenum (
    input logic clk,
    input logic rst,
    output logic [2:0] result
);
  logic [2:0] state;
  always_ff @(posedge clk) begin
    if (rst) state <= 0;
    else if (state == 0) state <= 1;
    else state <= 3;
  end
  assign result = state;
endmodule

// A single equality plus a final else is sufficient, including states never visited.
module if_default_single #(
    parameter bit TWO_PROCESS = 0
) (
    input logic clk,
    output logic [2:0] result
);
  typedef enum logic [2:0] { IDLE = 0, RUN = 1, UNUSED = 5 } state_t;
  state_t state = IDLE;
  if (TWO_PROCESS) begin
    state_t next_state;
    always_comb begin
      if (state == IDLE) next_state = RUN;
      else next_state = IDLE;
    end
    always_ff @(posedge clk) state <= next_state;
  end
  else begin
    always_ff @(posedge clk) begin
      if (state == IDLE) state <= RUN;
      else state <= IDLE;
    end
  end
  assign result = state;
endmodule

// Compare the next-state variable through a local alias, with the guard first.
module if_default_alias (
    input logic clk,
    input logic enable,
    output logic [2:0] result
);
  typedef enum logic [2:0] { IDLE = 0, RUN = 1, DONE = 3 } state_t;
  state_t state = IDLE;
  state_t next_state;
  logic idle;
  always_comb begin
    next_state = state;
    idle = (IDLE == next_state);
    if (enable && idle) next_state = RUN;
    else if (next_state == RUN) next_state = DONE;
    else next_state = IDLE;
  end
  always_ff @(posedge clk) state <= next_state;
  assign result = state;
endmodule

// Every named state can reach the final else when its guard is false.
module if_default_all_guarded #(
    parameter bit GUARDED = 1
) (
    input logic clk,
    input logic enable,
    output logic [2:0] result
);
  typedef enum logic [2:0] { IDLE = 0, RUN = 1, DONE = 3 } state_t;
  state_t state = IDLE;
  always_ff @(posedge clk) begin
    if (state == IDLE && (!GUARDED || enable)) state <= RUN;
    else if (state == RUN && (!GUARDED || enable)) state <= DONE;
    else if (state == DONE && (!GUARDED || enable)) state <= IDLE;
    else state <= RUN;
  end
  assign result = state;
endmodule

// The common assignment moves after an if containing only coverage increments.
module if_default_common_tail (
    input logic clk,
    input logic enable,
    output logic [1:0] result
);
  typedef enum logic [1:0] { IDLE, RUN, DONE } state_t;
  state_t state = IDLE;
  always_ff @(posedge clk) begin
    if (state == IDLE) state <= RUN;
    else if (state == RUN) state <= DONE;
    else begin
      if (enable) state <= IDLE;
      else state <= IDLE;
    end
  end
  assign result = state;
endmodule

// High bits distinguish states with identical low 32 bits.
module if_default_wide (
    input logic clk,
    output logic [32:0] result
);
  typedef enum logic [32:0] {
    IDLE = 33'h0, RUN = 33'h1_0000_0000, DONE = 33'h1_0000_0003, UNUSED = 33'h3
  } state_t;
  state_t state = IDLE;
  always_ff @(posedge clk) begin
    if (state == IDLE) state <= RUN;
    else if (state == RUN) state <= DONE;
    else state <= IDLE;
  end
  assign result = state;
endmodule

// A later conditional write makes the default's first assignment unsafe to infer.
module if_default_overwrite (
    input logic clk,
    input logic enable,
    output logic [2:0] result
);
  typedef enum logic [2:0] { IDLE = 0, RUN = 1, DONE = 3 } state_t;
  state_t state = IDLE;
  state_t next_state;
  always_comb begin
    if (state == IDLE) next_state = RUN;
    else if (state == RUN) next_state = DONE;
    else begin
      next_state = IDLE;
      if (enable) next_state = RUN;
    end
  end
  always_ff @(posedge clk) state <= next_state;
  assign result = state;
endmodule

// Localparams do not enumerate the complete state space of the register.
module if_default_localparam (
    input logic clk,
    output logic [2:0] result
);
  localparam logic [2:0] IDLE = 0, RUN = 1, DONE = 3;
  logic [2:0] state = IDLE;
  always_ff @(posedge clk) begin
    if (state == IDLE) state <= RUN;
    else if (state == RUN) state <= DONE;
    else state <= IDLE;
  end
  assign result = state;
endmodule

module t (
    input logic clk
);
  int cyc = 0;
  wire rst = cyc == 0 || cyc == 8;
  wire enable = cyc[0];
  // Take the guarded branch before the second reset, then reach its final else.
  wire guard_enable = cyc[0] && !cyc[3];
  logic [1:0] one_result;
  logic [1:0] noreset_result;
  logic [2:0] two_result;
  logic [2:0] guarded_result;
  logic [2:0] multiple_result;
  logic [2:0] nonconst_result;
  logic [2:0] ternary_result;
  logic [2:0] single_guard_result;
  logic [2:0] later_guard_result;
  logic [2:0] same_target_result;
  logic [2:0] nonenum_result;
  logic side_effect;
  logic [2:0] single_result;
  logic [2:0] single_two_result;
  logic [2:0] alias_result;
  logic [2:0] all_guarded_result;
  logic [2:0] all_unguarded_result;
  logic [1:0] common_tail_result;
  logic [32:0] wide_result;
  logic [2:0] overwrite_result;
  logic [2:0] localparam_result;
  if_default_single single (.clk, .result(single_result));
  if_default_single #(.TWO_PROCESS(1)) single_two (.clk, .result(single_two_result));
  if_default_alias alias_guard (.clk, .enable, .result(alias_result));
  if_default_all_guarded all_guarded (.clk, .enable, .result(all_guarded_result));
  if_default_all_guarded #(.GUARDED(0)) all_unguarded (.clk, .enable, .result(all_unguarded_result));
  if_default_common_tail common_tail (.clk, .enable, .result(common_tail_result));
  if_default_wide wide_state (.clk, .result(wide_result));
  if_default_overwrite overwrite (.clk, .enable, .result(overwrite_result));
  if_default_localparam localparam_state (.clk, .result(localparam_result));
  if_default_one one (.clk, .rst, .result(one_result));
  if_default_noreset noreset (.clk, .result(noreset_result));
  if_default_two two (.clk, .rst, .enable, .other(3'(cyc)), .result(two_result),
                      .side_effect());
  if_default_two #(.MODE(1)) guarded (.clk, .rst, .enable(guard_enable), .other(3'(cyc)),
                                     .result(guarded_result), .side_effect());
  if_default_two #(.MODE(2)) multiple (.clk, .rst, .enable, .other(3'(cyc)),
                                      .result(multiple_result), .side_effect);
  if_default_two #(.MODE(3)) nonconst (.clk, .rst, .enable, .other(3'(cyc)),
                                     .result(nonconst_result), .side_effect());
  if_default_two #(.MODE(4)) ternary (.clk, .rst, .enable, .other(3'(cyc)),
                                    .result(ternary_result), .side_effect());
  if_default_two #(.MODE(5)) single_guard (.clk, .rst, .enable(guard_enable), .other(3'(cyc)),
                                         .result(single_guard_result), .side_effect());
  if_default_two #(.MODE(6)) later_guard (.clk, .rst, .enable(!cyc[3]), .other(3'(cyc)),
                                        .result(later_guard_result), .side_effect());
  if_default_two #(.MODE(7)) same_target (.clk, .rst, .enable(guard_enable), .other(3'(cyc)),
                                        .result(same_target_result), .side_effect());
  if_default_nonenum nonenum (.clk, .rst, .result(nonenum_result));

  // verilator coverage_off
  always @(posedge clk) cyc <= cyc + 1;
  always @(negedge clk) begin
    `checkd(int'(one_result), (cyc - 1) % 8 < 2 ? (cyc - 1) % 8 : 2);
    `checkd(int'(noreset_result), cyc % 3);
    `checkd(int'(two_result), (cyc - 1) % 8 < 2 ? (cyc - 1) % 8 : 3);
    `checkd(nonenum_result, two_result);
    `checkd(int'(single_result), cyc % 2);
    `checkd(single_two_result, single_result);
    `checkd(int'(common_tail_result), cyc % 3);
    `checkd(wide_result, cyc % 3 == 0 ? 33'h0 : cyc % 3 == 1 ? 33'h1_0000_0000 : 33'h1_0000_0003);
    `checkd(localparam_result, cyc % 3 == 0 ? 3'd0 : cyc % 3 == 1 ? 3'd1 : 3'd3);
    `checkd(alias_result, cyc % 4 == 2 ? 3'd1 : cyc % 4 == 3 ? 3'd3 : 3'd0);
    `checkd(all_guarded_result, cyc % 2 == 1 ? 3'd1 : 3'd3);
    `checkd(all_unguarded_result, localparam_result);
    if (cyc == 16) begin
      `checkd(guarded_result, 3'd5);
      `checkd(multiple_result, 3'd5);
      `checkd(nonconst_result, 3'd7);
      `checkd(ternary_result, 3'd0);
      `checkd(single_guard_result, 3'd5);
      `checkd(later_guard_result, 3'd5);
      `checkd(same_target_result, 3'd1);
      `checkd(side_effect, 1'b0);
      `checkd(overwrite_result, 3'd1);
      $write("*-* All Finished *-*\n");
      $finish;
    end
  end
endmodule
