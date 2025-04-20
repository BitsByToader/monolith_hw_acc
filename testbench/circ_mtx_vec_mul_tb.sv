`include "../rtl/includes.svh"

module circ_mtx_vec_mul_tb();
    reg [30:0] vec [0:15];
    reg [30:0] mtx [0:15];
    reg [30:0] out [0:15];
    reg [30:0] correct_out [0:15];
    
    reg clk, reset, valid;
    
    circ_mtx_vec_mul mat_mult(
        .clk(clk),
        .reset(reset),
        .mtx_row(mtx),
        .vec(vec),
        .result(out),
        .valid(valid)
    );
    
    initial begin
        clk <= 0; reset <= 1;
        #10 reset <= 0;
    end
    
    always #5 clk <= ~clk;
    
    initial begin
        #10
        $readmemh("m31_mds_mtx.mem", mtx);
        $readmemh("input_vec_16.mem", vec);
        $readmemh("mds_mul_vec_out_16.mem", correct_out);
        
        @(valid == 1);
        for (int i = 0; i < 16; i = i+1) begin
            assert(out[i] == correct_out[i]);
        end
        
        #10 $finish();
    end
endmodule