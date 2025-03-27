`ifndef VECTOR_DOT_PRODUCT_MC_SV
`define VECTOR_DOT_PRODUCT_MC_SV

`include "m31_multiplier.sv"
`include "m31_adder.sv"

/// Computes the dot product of two vectors.
module vector_dot_product_mc #(
    int WORD_WIDTH = 31,
    int VECTOR_SIZE = 16
) (
    input logic clk,
    input logic reset,
    
    input bit [WORD_WIDTH-1:0] vec1 [0:VECTOR_SIZE-1],
    input bit [WORD_WIDTH-1:0] vec2 [0:VECTOR_SIZE-1],
    
    output bit [WORD_WIDTH-1:0] result,
    output bit valid
);
    
    bit [2*WORD_WIDTH:0] full_result;
    bit [WORD_WIDTH-1:0] reduced_result, acum_result;
    bit [$clog2(VECTOR_SIZE)-1:0] counter, next_cnt;

    assign next_cnt = counter + 1;

    mod_reduction_inout_if #(.DATA_WIDTH(2*WORD_WIDTH+1)) reduce_in();
    mod_reduction_inout_if #(.DATA_WIDTH(WORD_WIDTH)) reduce_out();
    m31_mod_reduce reduce(reduce_in.rcv, reduce_out.drv);

    assign reduce_in.data = full_result;
    assign reduced_result = reduce_out.data;
    
    // Atempt to infer a MACC via DSP slice.
    assign full_result = acum_result + vec1[counter] * vec2[counter];

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            acum_result <= 0;
        end else begin
            if ( next_cnt != 0 ) begin
                counter <= next_cnt;
                acum_result <= reduced_result;
            end
        end
    end

    assign result = reduced_result;
    assign valid = (counter == VECTOR_SIZE-1);

endmodule

`endif