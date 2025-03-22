`ifndef MONOLITH_BARS_SV
`define MONOLITH_BARS_SV

`include "monolith_sbox.sv"

module monolith_bars #(
    int WORD_WIDTH = 31,
    int STATE_SIZE = 16,
    int BAR_OP_COUNT = 8
) (
    input logic clk,
    input logic reset,
    
    input bit [WORD_WIDTH-1:0] state_in [0:STATE_SIZE-1],
    output bit [WORD_WIDTH-1:0] state_out [0:STATE_SIZE-1]
);

    genvar i,j;
    generate
        for ( i = 0; i < STATE_SIZE; i = i+1 ) begin
            if ( i < BAR_OP_COUNT ) begin
                // Apply S-Boxes to state.
                monolith_sbox #(8) s1(state_in[i][7:0], state_out[i][7:0]);
                monolith_sbox #(8) s2(state_in[i][15:8], state_out[i][15:8]);
                monolith_sbox #(8) s3(state_in[i][23:16], state_out[i][23:16]);
                monolith_sbox #(7) s4(state_in[i][30:24], state_out[i][30:24]);
                
            end else begin
                // Propagate to next layer.
                assign state_out[i] = state_in[i];
            end
        end 
    endgenerate

endmodule

`endif