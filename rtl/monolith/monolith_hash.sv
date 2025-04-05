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
    bit round_counter_enable;
    bit [ROUND_COUNTER_SIZE-1:0] round_counter, pre_round;
    
    bit round_zero;
    bit round_final;
   
    bit round_reset; 
    bit round_valid;
    
    bit [WORD_WIDTH-1:0] round_input [0:STATE_SIZE-1];

    monolith_round #(WORD_WIDTH, STATE_SIZE, BAR_OP_COUNT) round (
        .clk(clk), .reset(round_reset),
        .pre_round(round_zero),
        .state_in(round_input), .constants(round_constants[pre_round]),
        .state_out(state_out), .valid(round_valid)
    );

    // (COMBINATORIAL) LOGIC
    assign pre_round = round_zero ? 0 : (round_counter - 1);
    assign round_zero = (round_counter == 0);
    // +1 because counter will hold next round value when processing current round
    // implemented as such to preprocess next round inputs,to save some cycles.
    assign round_final = (round_counter == ROUND_COUNT+1);
    
     // (SEQUENTIAL) LOGIC
    localparam RST_STATE                = 0;
    localparam BEGIN_ROUND_STATE        = 1;
    localparam PREP_NEXT_ROUND_STATE    = 2;
    localparam ROUND_FINISHED_STATE     = 3;
    localparam FINISH_STATE             = 4;
    
    // HASH Round Engine FSM
    bit [2:0] cs, ns;
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
            casex({round_valid, round_final})
                2'b11: ns <= FINISH_STATE;
                2'b10: ns <= ROUND_FINISHED_STATE;
                2'b0x: ns <= PREP_NEXT_ROUND_STATE;
            endcase
        end
        
        ROUND_FINISHED_STATE: begin
            ns <= BEGIN_ROUND_STATE;
        end
        
        FINISH_STATE: begin
            ns <= FINISH_STATE;
        end
        
        default: ns <= RST_STATE;
        endcase
    end
    
    integer i; // counter for input reset.
    always_comb begin
        case(cs)
        RST_STATE: begin
            round_reset <= 1;
            round_counter_enable <= 0; // Assume FSM and counter share reset, counter will be 0 here.
            round_input <= state_in;
            valid <= 0;
        end
        
        BEGIN_ROUND_STATE: begin
            round_reset <= 0;
            round_counter_enable <= 1;
            round_input <= round_zero ? state_in : state_out;
            valid <= 0;
        end
        
        PREP_NEXT_ROUND_STATE: begin
            round_counter_enable <= 0;
            round_input <= state_out;
            round_reset <= 0;
            valid <= 0;
        end
        
        ROUND_FINISHED_STATE: begin
            valid <= 0;
            round_counter_enable <= 0;
            round_input <= state_out;
            round_reset <= 1;
        end
        
        FINISH_STATE: begin
            valid <= 1;
            round_reset <= 1;
            round_input <= state_out;
            round_counter_enable <= 0;
        end
        
        default: begin
            round_reset <= 1;
            round_counter_enable <= 0;
            for(i=0; i<STATE_SIZE; i=i+1) begin
                round_input[i] <= 0;
            end
            valid <= 0;
        end
        endcase
    end
    
    // Round Counter Logic
    always_ff @(posedge clk) begin
        if(reset) begin
            round_counter <= 0;
        end else begin
            if ( round_counter_enable )
                round_counter <= round_counter + 1;
        end
    end
    
    initial begin
        $readmemh("../constants/monolith_6round_constants.mem", round_constants);
    end

endmodule

`endif
