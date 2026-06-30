`ifndef MONOLITH_HASH_SV
`define MONOLITH_HASH_SV

module monolith_hash #(
    int WORD_WIDTH      = 31,
    int STATE_SIZE      = 16,
    int BAR_OP_COUNT    = 8,
    int ROUND_COUNT     = 6
) (
    input logic                     clk,
    input logic                     reset,
    
    input logic [WORD_WIDTH-1:0]    state_in [0:STATE_SIZE-1],
    input logic                     in_valid,
    
    output logic [WORD_WIDTH-1:0]   state_out [0:STATE_SIZE-1],
    output logic                    out_valid
);

    logic [WORD_WIDTH-1:0] round_constants [0:ROUND_COUNT-1][0:STATE_SIZE-1]; 
    
    logic [WORD_WIDTH-1:0] round_input [0:ROUND_COUNT-1][0:STATE_SIZE-1];
    logic round_input_valid [0:ROUND_COUNT-1];
    
    logic [WORD_WIDTH-1:0] round_output [0:ROUND_COUNT-1][0:STATE_SIZE-1];
    logic round_output_valid [0:ROUND_COUNT-1];

    monolith_concrete #(WORD_WIDTH, STATE_SIZE) pre_round (
        .clk            (clk),
        .reset          (reset),
        .state_in       (state_in),
        .input_valid    (in_valid),
        .state_out      (round_input[0]),
        .output_valid   (round_input_valid[0])
    );

    generate
        for (genvar i = 0; i < ROUND_COUNT; i=i+1) begin
            if (i > 0) begin
                assign round_input[i] = round_output[i-1];
                assign round_input_valid[i] = round_output_valid[i-1];
            end
            
            monolith_round #(
                .WORD_WIDTH(WORD_WIDTH),
                .STATE_SIZE(STATE_SIZE),
                .BAR_OP_COUNT(BAR_OP_COUNT)
            ) round (
                .clk            (clk),
                .reset          (reset),
                .constants      (round_constants[i]),
                .state_in       (round_input[i]),
                .input_valid    (round_input_valid[i]),
                .state_out      (round_output[i]),
                .output_valid   (round_output_valid[i])
            );
        end
    endgenerate

    assign state_out = round_output[ROUND_COUNT-1];
    assign out_valid = round_output_valid[ROUND_COUNT-1];
   
    `ifndef ROUND_CONSTANTS_MEM_FILE
        `define ROUND_CONSTANTS_MEM_FILE "/Users/tudor/Developer/monolith_asic_test/rtl/constants/monolith_6round_constants.mem"
    `endif

    initial begin
        for(int i = 0; i < STATE_SIZE;i=i+1) begin
            for (int j = 0; j < ROUND_COUNT;j=j+1)
                round_constants[j][i] = j+i;
        end
        $readmemh(`ROUND_CONSTANTS_MEM_FILE, round_constants);
    end

endmodule

`endif
