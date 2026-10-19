// DESCRIPTION: Verilator: FSM rejects unknown enum constants in direct and conditional transitions
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2026 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0

// Group the same unsupported warning family across direct, conditional, and
// reset-driven enum assignments that use constants outside the declared enum.

module unknown_then (
    input logic clk
);
  typedef enum logic [1:0] {
    S0 = 2'd0,
    S1 = 2'd1
  } state_t;

  logic sel;
  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  always_comb begin
    state_d = state_q;
    case (state_q)
      /* verilator lint_off ENUMVALUE */
      S0: state_d = sel ? 2'd3 : S1;
      /* verilator lint_on ENUMVALUE */
      default: state_d = S0;
    endcase
  end

  always_ff @(posedge clk) begin
    state_q <= state_d;
  end
endmodule

module unknown_else (
    input logic clk
);
  typedef enum logic [1:0] {
    S0 = 2'd0,
    S1 = 2'd1
  } state_t;

  logic sel;
  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  always_comb begin
    state_d = state_q;
    case (state_q)
      /* verilator lint_off ENUMVALUE */
      S0: state_d = sel ? S1 : 2'd3;
      /* verilator lint_on ENUMVALUE */
      default: state_d = S0;
    endcase
  end

  always_ff @(posedge clk) begin
    state_q <= state_d;
  end
endmodule

module unknown_direct (
    input logic clk
);
  typedef enum logic [1:0] {
    S0 = 2'd0,
    S1 = 2'd1
  } state_t;

  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  always_comb begin
    state_d = state_q;
    case (state_q)
      /* verilator lint_off ENUMVALUE */
      S0: state_d = 2'd3;
      /* verilator lint_on ENUMVALUE */
      default: state_d = S0;
    endcase
  end

  always_ff @(posedge clk) begin
    state_q <= state_d;
  end
endmodule

module unknown_reset (
    input logic clk
);
  typedef enum logic [1:0] {
    S0 = 2'd0,
    S1 = 2'd1
  } state_t;

  logic rst;
  integer cyc;
  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  initial begin
    rst = 1'b1;
    cyc = 0;
  end

  always @(posedge clk) begin
    cyc <= cyc + 1;
    if (cyc == 1) rst <= 1'b0;
  end

  always_comb begin
    state_d = state_q;
    case (state_q)
      S0: state_d = S1;
      default: state_d = S0;
    endcase
  end

  // Reset-arc extraction uses a separate path from steady-state case-item arc
  // extraction, so keep one reset-only bad enum target in this grouped test.
  always_ff @(posedge clk) begin
    if (rst) begin
      /* verilator lint_off ENUMVALUE */
      state_q <= 2'd3;
      /* verilator lint_on ENUMVALUE */
    end
    else begin
      state_q <= state_d;
    end
  end
endmodule

module unknown_source (
    input logic clk
);
  typedef enum logic [1:0] {
    S0 = 2'd0,
    S1 = 2'd1
  } state_t;

  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  always_comb begin
    state_d = state_q;
    case (state_q)
      /* verilator lint_off ENUMVALUE */
      2'd3: state_d = S0;
      /* verilator lint_on ENUMVALUE */
      default: state_d = S0;
    endcase
  end

  always_ff @(posedge clk) begin
    state_q <= state_d;
  end
endmodule

module unknown_if_source (
    input logic clk
);
  typedef enum logic [1:0] {
    S0 = 2'd0,
    S1 = 2'd1
  } state_t;

  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  always_comb begin
    state_d = state_q;
    /* verilator lint_off ENUMVALUE */
    if (state_q == 2'd3) state_d = S0;
    /* verilator lint_on ENUMVALUE */
    else if (state_q == S1) state_d = S0;
  end

  always_ff @(posedge clk) begin
    state_q <= state_d;
  end
endmodule

module unknown_if_direct_target (
    input logic clk
);
  typedef enum logic [1:0] {
    S0 = 2'd0,
    S1 = 2'd1
  } state_t;

  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  always_comb begin
    state_d = state_q;
    /* verilator lint_off ENUMVALUE */
    if (state_q == S0) state_d = 2'd3;
    /* verilator lint_on ENUMVALUE */
    else if (state_q == S1) state_d = S0;
  end

  always_ff @(posedge clk) begin
    state_q <= state_d;
  end
endmodule

module unknown_if_then_target (
    input logic clk
);
  typedef enum logic [1:0] {
    S0 = 2'd0,
    S1 = 2'd1
  } state_t;

  logic sel;
  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  always_comb begin
    state_d = state_q;
    /* verilator lint_off ENUMVALUE */
    if (state_q == S0) state_d = sel ? 2'd3 : S1;
    /* verilator lint_on ENUMVALUE */
    else if (state_q == S1) state_d = S0;
  end

  always_ff @(posedge clk) begin
    state_q <= state_d;
  end
endmodule

module unknown_if_else_target (
    input logic clk
);
  typedef enum logic [1:0] {
    S0 = 2'd0,
    S1 = 2'd1
  } state_t;

  logic sel;
  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  always_comb begin
    state_d = state_q;
    /* verilator lint_off ENUMVALUE */
    if (state_q == S0) state_d = sel ? S1 : 2'd3;
    /* verilator lint_on ENUMVALUE */
    else if (state_q == S1) state_d = S0;
  end

  always_ff @(posedge clk) begin
    state_q <= state_d;
  end
endmodule

module unknown_wide_direct (
    input logic clk
);
  typedef enum logic [39:0] {
    S0 = 40'h0000_0000_01,
    S1 = 40'h8000_0000_02
  } state_t;

  state_t state_q  /*verilator fsm_state*/;
  state_t state_d;

  always_comb begin
    state_d = state_q;
    case (state_q)
      /* verilator lint_off ENUMVALUE */
      S0: state_d = 40'hffff_ffff_ff;
      /* verilator lint_on ENUMVALUE */
      default: state_d = S0;
    endcase
  end

  always_ff @(posedge clk) begin
    state_q <= state_d;
  end
endmodule

module unknown_if_default (
    input logic clk
);
  typedef enum logic [2:0] { S0, S1, S2 } state_t;
  state_t state_q;
  state_t state_d;
  always_comb begin
    if (state_q == S0) state_d = S1;
    else if (state_q == S1) state_d = S2;
    else state_d = state_t'(7);
  end
  always_ff @(posedge clk) state_q <= state_d;
endmodule

module unknown_if_default_cond #(
    parameter bit BAD_THEN = 0
) (
    input logic clk,
    input logic sel
);
  typedef enum logic [2:0] { S0, S1, S2 } state_t;
  state_t state_q;
  state_t state_d;
  always_comb begin
    if (state_q == S0) state_d = S1;
    else if (state_q == S1) state_d = S2;
    else begin
      // Keep the conditional target as an expression.
      // verilator coverage_off
      if (BAD_THEN) state_d = sel ? state_t'(7) : S0;
      else state_d = sel ? S0 : state_t'(7);
      // verilator coverage_on
    end
  end
  always_ff @(posedge clk) state_q <= state_d;
endmodule

module t_default;
  logic clk;
  logic sel;
  unknown_if_default unknown_if_default_u (.clk);
  unknown_if_default_cond #(.BAD_THEN(1)) unknown_if_default_then_u (.clk, .sel);
  unknown_if_default_cond unknown_if_default_else_u (.clk, .sel);
endmodule

module t;
  logic clk;
  unknown_then unknown_then_u (.clk(clk));
  unknown_else unknown_else_u (.clk(clk));
  unknown_direct unknown_direct_u (.clk(clk));
  unknown_reset unknown_reset_u (.clk(clk));
  unknown_source unknown_source_u (.clk(clk));
  unknown_if_source unknown_if_source_u (.clk(clk));
  unknown_if_direct_target unknown_if_direct_target_u (.clk(clk));
  unknown_if_then_target unknown_if_then_target_u (.clk(clk));
  unknown_if_else_target unknown_if_else_target_u (.clk(clk));
  unknown_wide_direct unknown_wide_direct_u (.clk(clk));
endmodule
