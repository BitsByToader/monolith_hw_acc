`ifndef MONOLITH_ROUND_SV
`define MONOLITH_ROUND_SV

module monolith_round #(
    int WORD_WIDTH      = 31,
    int STATE_SIZE      = 16,
    int BAR_OP_COUNT    = 8
) (
    input logic clk,
    input logic reset,
   
    input bit pre_round, 
    input bit [WORD_WIDTH-1:0] state_in [0:STATE_SIZE-1],
    input bit [WORD_WIDTH-1:0] constants [0:STATE_SIZE-1],
    
    output bit [WORD_WIDTH-1:0] state_out [0:STATE_SIZE-1],
    output bit valid
);

    bit [WORD_WIDTH-1:0] state_after_bars [0:STATE_SIZE-1];
    bit [WORD_WIDTH-1:0] state_after_bricks [0:STATE_SIZE-1];    
    bit [WORD_WIDTH-1:0] state_after_concrete [0:STATE_SIZE-1]; 
    
    bit [WORD_WIDTH-1:0] concrete_input [0:STATE_SIZE-1];
    bit [WORD_WIDTH-1:0] state_after_constants [0:STATE_SIZE-1];

    bit pre_round_saved;
    bit [WORD_WIDTH-1:0] input_saved [0:STATE_SIZE-1];
    bit [WORD_WIDTH-1:0] constants_saved [0:STATE_SIZE-1];

    // Auxiliary reset used for bars and bricks.
    // Will disable the two components in the pre round.
    // Power-saving attempt.
    logic aux_reset;

    monolith_bars #(WORD_WIDTH, STATE_SIZE, BAR_OP_COUNT) bars(
        clk, aux_reset,
        input_saved, state_after_bars
    );

    monolith_bricks #(WORD_WIDTH, STATE_SIZE) bricks(
        clk, aux_reset,
        state_after_bars, state_after_bricks
    );

    monolith_concrete #(WORD_WIDTH, STATE_SIZE) concrete(
        clk, reset,
        concrete_input, state_after_concrete,
        valid
    );

    vector_adder #(WORD_WIDTH, STATE_SIZE) add_constants(
        state_after_concrete, constants_saved,
        state_after_constants
    );

    assign concrete_input = (pre_round_saved == 1) ? input_saved : state_after_bricks;
    assign state_out = (pre_round_saved == 1) ? state_after_concrete : state_after_constants;
    assign aux_reset = (pre_round_saved == 1) ? 1 : reset; // Assumes active-high reset.

    always_ff @(posedge clk) begin
        if (reset) begin
            pre_round_saved <= pre_round;
            input_saved <= state_in;
            constants_saved <= constants;
        end
    end

endmodule

`endif
