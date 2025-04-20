`ifndef VECTOR_ADDER_SV
`define VECTOR_ADDER_SV

/// Adds two vectors together, element wise.
module vector_adder #(
    int WORD_WIDTH = 31,
    int VECTOR_SIZE = 16
) (
    input logic [WORD_WIDTH-1:0] vec1 [0:VECTOR_SIZE-1],
    input logic [WORD_WIDTH-1:0] vec2 [0:VECTOR_SIZE-1],
    
    output logic [WORD_WIDTH-1:0] result [0:VECTOR_SIZE-1]
);

    genvar i;
    generate
        // Generate a adder for each element of the vector.
        for (i = 0; i < VECTOR_SIZE; i = i + 1) begin
            adder_input_if #(WORD_WIDTH) add_in();
            adder_output_if #(WORD_WIDTH+1) add_out();
            m31_adder add(add_in, add_out);
            
            assign add_in.in1 = vec1[i];
            assign add_in.in2 = vec2[i];
            assign result[i] = add_out.out[WORD_WIDTH-1:0];
        end
    endgenerate
    
endmodule

`endif
