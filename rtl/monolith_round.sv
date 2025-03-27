`ifndef MONOLITH_ROUND_SV
`define MONOLITH_ROUND_SV

`include "monolith_bars.sv"
`include "monolith_bricks.sv"
`include "monolith_concrete.sv"


module monolith_round #(
    int WORD_WIDTH = 31,
    int STATE_SIZE = 16
) (
    input logic clk,
    input logic reset,
    
    input bit [WORD_WIDTH-1:0] state_in [0:STATE_SIZE-1],
    output bit [WORD_WIDTH-1:0] state_out [0:STATE_SIZE-1],
    output bit valid
);

    bit [WORD_WIDTH-1:0] state_after_bars [0:STATE_SIZE-1];
    bit [WORD_WIDTH-1:0] state_after_bricks [0:STATE_SIZE-1];
    
    monolith_bars #(WORD_WIDTH, STATE_SIZE) bars(
        clk, reset,
        state_in, state_after_bars
    );

    monolith_bricks #(WORD_WIDTH, STATE_SIZE) bricks(
        clk, reset,
        state_after_bars, state_after_bricks
    );

    monolith_concrete #(WORD_WIDTH, STATE_SIZE) concrete(
        clk, reset,
        state_after_bricks, state_out,
        valid
    );

endmodule

`endif