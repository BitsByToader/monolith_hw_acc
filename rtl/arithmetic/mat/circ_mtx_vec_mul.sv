`ifndef CIRC_MTX_VEC_MUL_SV
`define CIRC_MTX_VEC_MUL_SV

///// Computes a matrix-vector-multiplication,
///// where the matrix is circulant.
///// The matrix is defined by its first row only,
///// subsequent rows are circularly shifted right
///// to form a square matrix.
//module circ_mtx_vec_mul #(
//    int WORD_WIDTH = 31,
//    int MTX_SIZE = 16
//) (
//    input logic clk,
//    input logic reset,
    
//    input logic [WORD_WIDTH-1:0] mtx_row [0:MTX_SIZE-1],
//    input logic [WORD_WIDTH-1:0] vec [0:MTX_SIZE-1],
    
//    output logic [WORD_WIDTH-1:0] result [0:MTX_SIZE-1],
//    output logic valid
//);

//    logic [MTX_SIZE-1:0] row_valids;
//    assign valid = &row_valids;

//    genvar i;
//    generate
//        // Compute dot product for every line of the matrix
//        for ( i = 0; i < MTX_SIZE; i = i + 1 ) begin
//            logic [WORD_WIDTH-1:0] row [0:MTX_SIZE-1];
//            logic [WORD_WIDTH-1:0] result_left, result_right;
//            logic valid_left, valid_right;
            
//            vector_dot_product_mc #(.VECTOR_SIZE(8)) vdp_left (
//                .clk(clk),
//                .reset(reset),
//                .vec1(row[0:MTX_SIZE/2-1]),
//                .vec2(vec[0:MTX_SIZE/2-1]),
//                .result(result_left),
//                .valid(valid_left)
//            );
            
//            vector_dot_product_mc #(.VECTOR_SIZE(8)) vdp_right (
//                .clk(clk),
//                .reset(reset),
//                .vec1(row[MTX_SIZE/2:MTX_SIZE-1]),
//                .vec2(vec[MTX_SIZE/2:MTX_SIZE-1]),
//                .result(result_right),
//                .valid(valid_right)
//            );
            
//            adder_input_if #(WORD_WIDTH) add_in();
//            adder_output_if #(WORD_WIDTH+1) add_out();
//            m31_adder add(add_in.async_rcv, add_out.async_drv);
            
//            assign add_in.in1 = result_left;
//            assign add_in.in2 = result_right;
            
//            assign row_valids[i] = valid_right & valid_left;
//            assign result[i] = add_out.out[WORD_WIDTH-1:0];
            
//            // Generate a shifted row
//            genvar j;
//            for ( j = 0; j < MTX_SIZE; j = j + 1 ) begin
//                if (j>=i) begin
//                    assign row[j] = mtx_row[j-i];
//                end else begin
//                    assign row[j] = mtx_row[MTX_SIZE-i+j];
//                end
//            end
//        end
//    endgenerate

//endmodule

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
    
    input logic [WORD_WIDTH-1:0] mtx_row [0:MTX_SIZE-1],
    input logic [WORD_WIDTH-1:0] vec [0:MTX_SIZE-1],
    input logic inputs_valid,
    
    output logic [WORD_WIDTH-1:0] result [0:MTX_SIZE-1],
    output logic result_valid
);

    logic [MTX_SIZE-1:0] row_valids;
    assign result_valid = &row_valids;

    genvar i;
    generate
        // Compute dot product for every line of the matrix
        for ( i = 0; i < MTX_SIZE; i = i + 1 ) begin
            logic [WORD_WIDTH-1:0] row [0:MTX_SIZE-1];
            
            vector_dot_product vdp (
                .clk(clk),
                .reset(reset),
                .vec1(row),
                .vec2(vec),
                .result(result[i])
            );
            
            assign row_valids[i] = inputs_valid;
            
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