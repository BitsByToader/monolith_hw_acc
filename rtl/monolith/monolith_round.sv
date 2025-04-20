`ifndef MONOLITH_ROUND_SV
`define MONOLITH_ROUND_SV

module monolith_round #(
    int WORD_WIDTH      = 31,
    int STATE_SIZE      = 16,
    int BAR_OP_COUNT    = 8
) (
    input logic clk,
    input logic reset,
   
    input logic pre_round,
    input logic [WORD_WIDTH-1:0] state_in [0:STATE_SIZE-1],
    input logic [WORD_WIDTH-1:0] constants [0:STATE_SIZE-1],
    
    output logic [WORD_WIDTH-1:0] state_out [0:STATE_SIZE-1],
    output logic valid
);

    // Delay reset for concrete in pre round to catch stable inputs.
    logic reset_d;

    logic pre_round_saved;
    logic [WORD_WIDTH-1:0] input_saved [0:STATE_SIZE-1];
    logic [WORD_WIDTH-1:0] constants_saved [0:STATE_SIZE-1];
    
    // Auxiliary reset used for bars and bricks.
    // Power-saving attempt in the pre round when they are not used.
    logic aux_reset;
    assign aux_reset = pre_round_saved ? 1 : reset; // Assumes active-high reset, will hold in reset in pre round.

    logic [WORD_WIDTH-1:0] bars_input [0:STATE_SIZE-1];
    logic [WORD_WIDTH-1:0] bars_output [0:STATE_SIZE-1];
    logic bars_valid;

    logic [WORD_WIDTH-1:0] bricks_input [0:STATE_SIZE-1];
    logic [WORD_WIDTH-1:0] bricks_output [0:STATE_SIZE-1];
    logic bricks_valid;

    logic [WORD_WIDTH-1:0] concrete_input [0:STATE_SIZE-1];
    logic [WORD_WIDTH-1:0] concrete_output [0:STATE_SIZE-1];
    logic concrete_valid;

    logic [WORD_WIDTH-1:0] constants_input [0:STATE_SIZE-1];
    logic [WORD_WIDTH-1:0] constants_output [0:STATE_SIZE-1];
    logic constants_valid;

    // Input saved here at reset.
    monolith_bars #(WORD_WIDTH, STATE_SIZE, BAR_OP_COUNT) bars(
        clk, aux_reset,
        bars_input, bars_output
    );
    // Pipeline Stage.
    monolith_bricks #(WORD_WIDTH, STATE_SIZE) bricks(
        clk, (reset | ~bars_valid),
        bricks_input, bricks_output
    );
    // Pipeline Stage.
    monolith_concrete #(WORD_WIDTH, STATE_SIZE) concrete(
        clk, (reset | (pre_round_saved ? reset_d : ~bricks_valid)),
        concrete_input, concrete_output,
        concrete_valid
    );
    // Pipeline Stage.
    vector_adder #(WORD_WIDTH, STATE_SIZE) add_constants(
        constants_input, constants_saved,
        constants_output
    );
    // Pipeline Stage to output.

    // Stabilize inputs per computantion (one per reset).
    always_ff @(posedge clk) begin
        if (reset) begin
            pre_round_saved <= pre_round;
            input_saved <= state_in;
            constants_saved <= constants;
        end
    end
    
    // input_saved is already registered, so directly assign to bars input.
    integer i;
    assign bars_input  = input_saved;
    always_ff @(posedge clk) begin
        // Always assign round stage inputs to have correct values right out of reset.
        concrete_input <= pre_round_saved ? input_saved : bricks_output;
    
        reset_d <= reset;
    
        if (reset) begin
            // ???
            for(i=0;i<STATE_SIZE;i=i+1)begin
                bricks_input[i] <= 0;
                constants_input[i] <= 0;
            end
        
            valid <= 0;
            bars_valid <= 0;
            bricks_valid <= 0;
            constants_valid <= 0;
        end else begin
            bricks_input <= bars_output;
            constants_input <= concrete_output;   
            
            state_out <= (pre_round_saved == 1) ? concrete_output : constants_output;
            
            valid <= pre_round_saved ? concrete_valid : constants_valid;
            bars_valid <= ~pre_round_saved; // Bars is not used in pre_pround.
            bricks_valid <= bars_valid; // Bricks (not clocked yet) does not have its own valid, delay from bars.
            // Concrete generates its own valid.
            constants_valid <= concrete_valid; // Constants is not clocked, does not generate its own valid, delay from concrete. Should be gated based on pre-round.
        end
    end

endmodule

`endif
