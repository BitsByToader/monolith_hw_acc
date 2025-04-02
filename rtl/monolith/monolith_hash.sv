`ifndef MONOLITH_HASH_SV
`define MONOLITH_HASH_SV

module monolith_hash #(
    int WORD_WIDTH      = 31,
    int STATE_SIZE      = 16,
    int BAR_OP_COUNT    = 8,
    int ROUND_COUNT     = 6
) (
    input logic clk,
    input logic reset,
    
    input bit [WORD_WIDTH-1:0] state_in [0:STATE_SIZE-1],
    output bit [WORD_WIDTH-1:0] state_out [0:STATE_SIZE-1],
    output bit valid
);
    
    // (LOCAL) PARAMETERS
    localparam int ROUND_COUNTER_SIZE = $clog2(ROUND_COUNT) + 1;

    bit [WORD_WIDTH-1:0] round_constants [0:ROUND_COUNT-1][0:STATE_SIZE-1];

    // INSTANTIATIONS
    bit [ROUND_COUNTER_SIZE-1:0] round_count;
    bit [ROUND_COUNTER_SIZE-1:0] round_count_d;
    bit [ROUND_COUNTER_SIZE-1:0] round_count_next;
    
    bit round_zero;
    bit round_final;
   
    bit round_reset; 
    bit round_valid, round_valid_d, round_valid_rose;
    
    bit [WORD_WIDTH-1:0] round_input [0:STATE_SIZE-1];
    bit [WORD_WIDTH-1:0] round_input_next [0:STATE_SIZE-1];

    monolith_round #(WORD_WIDTH, STATE_SIZE, BAR_OP_COUNT) round (
        .clk(clk), .reset(round_reset),
        .pre_round(round_zero),
        .state_in(round_input), .constants(round_constants[round_count-1]),
        .state_out(state_out), .valid(round_valid)
    );

    // (COMBINATORIAL) LOGIC
    assign round_zero = (round_count == 0);
    assign round_final = (round_count == ROUND_COUNT+1);
    
    assign round_count_next = round_final ? round_count : round_count + 1; 
    assign round_input_next = round_zero ? state_in : state_out;
    
    assign round_valid_rose = round_valid & ~round_valid_d;
    assign valid = round_valid & round_final;
    
     // (SEQUENTIAL) LOGIC
//    always_ff @(posedge clk) begin
//        if (reset) begin
//            round_reset <= 1;
//            round_count <= 0;
//            round_count_d <= 0;
//            round_valid_d <= 0;
//            round_input <= round_input_next;
//        end else begin
//            round_valid_d <= round_valid;
        
//            if ( round_valid_rose ) begin
//                round_reset <= 1;
//                round_count <= round_count_next;
//                round_count_d <= round_count;
                
//                round_input <= round_input_next;
//            end else begin
//                round_reset <= 0;
//             end
//        end 
//    end
    
    localparam RST_STATE                = 0;
    localparam BEGIN_ROUND_STATE        = 1;
    localparam PREP_NEXT_ROUND_STATE    = 2;
    localparam ROUND_FINISHED_STATE     = 3;
    
    bit [3:0] cs, ns;
    always_ff @(posedge clk) begin
        if (reset) begin
            cs <= RST_STATE;
        end else begin
            cs <= ns;
        end
    end
    
    always_comb begin
        case(cs)
        RST_STATE: begin
            ns <= BEGIN_ROUND_STATE;
        end
        
        BEGIN_ROUND_STATE: begin
            ns <= PREP_NEXT_ROUND_STATE;
        end
        
        PREP_NEXT_ROUND_STATE: begin
            if (round_valid)
                ns <= ROUND_FINISHED_STATE;
            else
                ns <= PREP_NEXT_ROUND_STATE; 
        end
        
        ROUND_FINISHED_STATE: begin
            ns <= BEGIN_ROUND_STATE;
        end
        endcase
    end
    
    always_comb begin
        case(cs)
        RST_STATE: begin
            round_reset <= 1;
            round_count <= 0;
            round_input <= state_in;
        end
        
        BEGIN_ROUND_STATE: begin
            round_reset <= 0;
            round_count <= round_count + 1;
        end
        
        PREP_NEXT_ROUND_STATE: begin
            round_count <= round_count;
            round_input <= state_out;
        end
        
        ROUND_FINISHED_STATE: begin
            round_reset <= 1;
        end
        endcase
    end
    
    initial begin
        $readmemh("monolith_6round_constants.mem", round_constants);
    end

endmodule

`endif
