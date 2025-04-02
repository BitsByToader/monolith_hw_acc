`ifndef VECTOR_DOT_PRODUCT_SV
`define VECTOR_DOT_PRODUCT_SV

/// Computes the dot product of two vectors.
module vector_dot_product #(
    int WORD_WIDTH = 31,
    int VECTOR_SIZE = 16
) (
    input logic clk,
    input logic reset,
    
    input bit [WORD_WIDTH-1:0] vec1 [0:VECTOR_SIZE-1],
    input bit [WORD_WIDTH-1:0] vec2 [0:VECTOR_SIZE-1],
    
    output bit [WORD_WIDTH-1:0] result
);

    // Holds all outputs computed by execution elements.
    // Array holds data structured as a binary tree.
    // Second half is leaves: multiplier outputs.
    // First half is intermediate nodes: adder outputs.
    // Root is final compression result.
    bit [WORD_WIDTH-1:0] alu_outputs [0:2*VECTOR_SIZE-1-1];
    
    genvar i;
    generate
        // Generate a multiplier for each element of the vector.
        for (i = 0; i < VECTOR_SIZE; i = i + 1) begin
            multiplier_input_if #(WORD_WIDTH) mul_in();
            multiplier_output_if #(WORD_WIDTH*2) mul_out();
            m31_multiplier mul(mul_in, mul_out);
            
            assign mul_in.in1 = vec1[i];
            assign mul_in.in2 = vec2[i];
            assign alu_outputs[VECTOR_SIZE+i-1] = mul_out.out;
        end
    endgenerate
    
    genvar j;
    generate
        // Generate an adder for each pair of elements.
        for (j = 0; j < VECTOR_SIZE-1; j = j + 1 ) begin
            adder_input_if #(WORD_WIDTH) add_in();
            adder_output_if #(WORD_WIDTH+1) add_out();
            m31_adder add(add_in.async_rcv, add_out.async_drv);
            
            assign add_in.in1 = alu_outputs[j*2+1];
            assign add_in.in2 = alu_outputs[j*2+2];
            assign alu_outputs[j] = add_out.out;
        end
    endgenerate
    
    assign result = alu_outputs[0];
    
endmodule

`endif