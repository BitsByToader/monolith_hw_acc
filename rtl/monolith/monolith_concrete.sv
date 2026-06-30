`ifndef MONOLITH_CONCRETE_SV
`define MONOLITH_CONCRETE_SV

module monolith_concrete #(
    int WORD_WIDTH = 31,
    int STATE_SIZE = 16
) (
    input logic clk,
    input logic reset,
    
    input logic [WORD_WIDTH-1:0] state_in [0:STATE_SIZE-1],
    input logic input_valid,
    output logic [WORD_WIDTH-1:0] state_out [0:STATE_SIZE-1],
    output logic output_valid
);

    reg [WORD_WIDTH-1:0] mtx [0:STATE_SIZE-1];

    `ifndef MTX_MEM_FILE
        `define MTX_MEM_FILE "/Users/tudor/Developer/monolith_asic_test/rtl/constants/m31_mds_mtx.mem"
    `endif

    initial begin
        for(int i = 0; i < STATE_SIZE;i=i+1) begin
            mtx[i] = i;
        end
        $readmemh(`MTX_MEM_FILE, mtx);
    end
    
    circ_mtx_vec_mul #(WORD_WIDTH, STATE_SIZE) mv_mul(
        .clk(clk), 
        .reset(reset), 
        .mtx_row(mtx),
        .vec(state_in),
        .inputs_valid(input_valid),
        .result(state_out),
        .result_valid(output_valid)
    );

endmodule

`endif
