`include "circ_mtx_vec_mul.sv"

module circ_mtx_vec_mul_tb();
    reg [30:0] vec [0:15];
    reg [30:0] mtx [0:15];
    reg [30:0] out [0:15];
    reg [30:0] correct_out [0:15];
    
    circ_mtx_vec_mul mat_mult(
        .mtx_row(mtx),
        .vec(vec),
        .result(out)
    );
    
    initial begin
        #10
        $readmemh("m32_mds_mtx.mem", mtx);
        $readmemh("input_vec_16.mem", vec);
        $readmemh("mds_mul_vec_out_16.mem", correct_out);
        #10
        for (int i = 0; i < 16; i = i+1) begin
            assert(out[i] == correct_out[i]);
        end
        #10
        $finish();
    end
endmodule