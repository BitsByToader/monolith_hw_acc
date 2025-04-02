`ifndef MONOLITH_CONCRETE_SV
`define MONOLITH_CONCRETE_SV

module monolith_concrete #(
    int WORD_WIDTH = 31,
    int STATE_SIZE = 16
) (
    input logic clk,
    input logic reset,
    
    input bit [WORD_WIDTH-1:0] state_in [0:STATE_SIZE-1],
    output bit [WORD_WIDTH-1:0] state_out [0:STATE_SIZE-1],
    output bit valid
);

    reg [WORD_WIDTH-1:0] mtx [0:STATE_SIZE-1];

    initial begin
        $readmemh("m31_mds_mtx.mem", mtx);
    end
    
    circ_mtx_vec_mul #(WORD_WIDTH, STATE_SIZE) mvmul(
        .clk(clk), 
        .reset(reset), 
        .mtx_row(mtx),
        .vec(state_in),
        .result(state_out),
        .valid(valid)
    );

endmodule

`endif