`ifndef CIRC_MTX_VEC_MUL_SV
`define CIRC_MTX_VEC_MUL_SV

`include "vector_dot_product.sv"
`include "vector_dot_product_mc.sv"

/// Computes a matrix-vector-multiplication,
/// where the matrix is circulant.
/// The matrix is defined by its first row only,
/// subsequent rows are circularly shifted right
/// to form a square matrix.
module circ_mtx_vec_mul #(
    int WORD_WIDTH = 31,
    int MTX_SIZE = 16
) (
    input logic clk,
    input logic reset,
    
    input bit [WORD_WIDTH-1:0] mtx_row [0:MTX_SIZE-1],
    input bit [WORD_WIDTH-1:0] vec [0:MTX_SIZE-1],
    
    output bit [WORD_WIDTH-1:0] result [0:MTX_SIZE-1],
    output bit valid
);

    bit [MTX_SIZE-1:0] row_valids;
    assign valid = &row_valids;

    genvar i;
    generate
        // Compute dot product for every line of the matrix
        for ( i = 0; i < MTX_SIZE; i = i + 1 ) begin
            bit [WORD_WIDTH-1:0] row [0:MTX_SIZE-1];
            
            vector_dot_product_mc vdp(
                .clk(clk),
                .reset(reset),
                .vec1(row),
                .vec2(vec),
                .result(result[i]),
                .valid(row_valids[i])
            );
            
            // Generate a shifted row
            genvar j;
            for ( j = 0; j < MTX_SIZE; j = j + 1 ) begin
                if (j>=i) begin
                    assign row[j] = mtx_row[j-i];
                end else begin
                    assign row[j] = mtx_row[MTX_SIZE-i+j];
                end
            end
        end
    endgenerate

endmodule

`endif