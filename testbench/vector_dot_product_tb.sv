`include "vector_dot_product.sv"

module vec_dp_tb();

    reg [30:0] vec1 [0:3];
    reg [30:0] vec2 [0:3];
    reg [30:0] out;

    vector_dot_product #(.VECTOR_SIZE(4)) vdp(
        .vec1(vec1),
        .vec2(vec2),
        .result(out)
    );
    
    initial begin
        vec1 <= {0,0,0,0};
        vec2 <= {0,0,0,0};
        #10
        vec1[0] <= 0; vec1[1] = 1; vec1[2] = 2; vec1[3] = 3;
        vec2[0] <= 4; vec2[1] = 5; vec2[2] = 6; vec2[3] = 7;
        #10
        $finish();
    end
    
endmodule