`ifndef MONOLITH_ROUND_SV
`define MONOLITH_ROUND_SV

module monolith_round #(
    int WORD_WIDTH      = 31,
    int STATE_SIZE      = 16,
    int BAR_OP_COUNT    = 8
) (
    input logic clk,
    input logic reset,
   
    input logic [WORD_WIDTH-1:0] constants [0:STATE_SIZE-1],
   
    // input logic pre_round,
    input logic [WORD_WIDTH-1:0] state_in [0:STATE_SIZE-1],
    input logic input_valid,
    
    output logic [WORD_WIDTH-1:0] state_out [0:STATE_SIZE-1],
    output logic output_valid
);

    logic [WORD_WIDTH-1:0] bars_input [0:STATE_SIZE-1];
    logic [WORD_WIDTH-1:0] bars_output [0:STATE_SIZE-1];
    logic bars_in_valid, bars_out_valid;

    logic [WORD_WIDTH-1:0] bricks_input [0:STATE_SIZE-1];
    logic [WORD_WIDTH-1:0] bricks_output [0:STATE_SIZE-1];
    logic bricks_in_valid, bricks_out_valid;

    logic [WORD_WIDTH-1:0] concrete_input [0:STATE_SIZE-1];
    logic [WORD_WIDTH-1:0] concrete_output [0:STATE_SIZE-1];
    logic concrete_in_valid, concrete_out_valid;

    logic [WORD_WIDTH-1:0] constants_input [0:STATE_SIZE-1];
    logic [WORD_WIDTH-1:0] constants_output [0:STATE_SIZE-1];
    logic constants_in_valid, constants_out_valid;

    // Input saved here at reset.
    monolith_bars #(WORD_WIDTH, STATE_SIZE, BAR_OP_COUNT) bars(
        clk, reset,
        bars_input, bars_in_valid,
        bars_output, bars_out_valid
    );
    // Pipeline Stage.
    monolith_bricks #(WORD_WIDTH, STATE_SIZE) bricks(
        clk, reset,
        bricks_input, bricks_in_valid,
        bricks_output, bricks_out_valid
    );
    // Pipeline Stage.
    monolith_concrete #(WORD_WIDTH, STATE_SIZE) concrete(
        .clk(clk), .reset(reset),
        .state_in(concrete_input), .input_valid(concrete_in_valid),
        .state_out(concrete_output), .output_valid(concrete_out_valid)
    );
    // Pipeline Stage.
    vector_adder #(WORD_WIDTH, STATE_SIZE) add_constants(
        constants_input, constants,
        constants_output
    );
    // Pipeline Stage to output.
    
    always_ff @(posedge clk) begin
        if (reset) begin
            bars_in_valid       <= 0;
            bricks_in_valid     <= 0;
            concrete_in_valid   <= 0;
            constants_in_valid  <= 0;
            constants_out_valid <= 0;
            output_valid        <= 0;
            
            bars_input      <= '{default: '0};
            bricks_input    <= '{default: '0};
            concrete_input  <= '{default: '0};
            constants_input <= '{default: '0};
            state_out       <= '{default: '0};
        end else begin
            bars_in_valid       <= input_valid;
            bricks_in_valid     <= bars_out_valid;
            concrete_in_valid   <= bricks_out_valid;
            constants_in_valid  <= concrete_out_valid;
            constants_out_valid <= constants_in_valid;
            output_valid        <= constants_out_valid;
        
            if (input_valid)
                bars_input <= state_in;
        
            if (bars_out_valid)
                bricks_input <= bars_output;
            
            if (bricks_out_valid)
                concrete_input <= bricks_output;
                
            if (concrete_out_valid)
                constants_input <= concrete_output;
                
            if (constants_out_valid)
                state_out <= constants_output;
        end
    end

endmodule

`endif
