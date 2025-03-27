`include "vector_dot_product.sv"
`include "../rtl/vector_dot_product_mc.sv"

module vec_dp_tb();

    reg clk, reset, valid;

    reg [30:0] vec1 [0:3];
    reg [30:0] vec2 [0:3];
    reg [30:0] out;

    vector_dot_product_mc #(.VECTOR_SIZE(4)) vdp(
        .clk(clk),
        .reset(reset),
        .vec1(vec1),
        .vec2(vec2),
        .result(out),
        .valid(valid)
    );
    
    initial begin
        clk <= 0; reset <= 1;
        #10 reset <= 0;
    end
    
    always #5 clk <= ~clk;
    
    initial begin
        vec1 <= {0,0,0,0};
        vec2 <= {0,0,0,0};
        #10
        vec1[0] <= 1; vec1[1] = 2; vec1[2] = 3; vec1[3] = 4;
        vec2[0] <= 5; vec2[1] = 6; vec2[2] = 7; vec2[3] = 8;
        
        @(valid == 1);
        assert(out == 70);
        
        #10 $finish();
    end
    
endmodule