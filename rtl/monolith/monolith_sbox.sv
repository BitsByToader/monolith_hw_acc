`ifndef MONOLITH_SBOX_SV
`define MONOLITH_SBOX_SV

module static_rotate_left #(
    WIDTH = 8,
    ROTATE_CNT = 1
)(
    input logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);

    assign out = { in[WIDTH-ROTATE_CNT-1:0], in[WIDTH-1:WIDTH-ROTATE_CNT] };

endmodule

module monolith_sbox #(
    BIT_WIDTH = 8
)(
    input logic [BIT_WIDTH-1:0] in,
    output logic [BIT_WIDTH-1:0] out
);

    if ( BIT_WIDTH != 8 && BIT_WIDTH != 7 )
        $error("M31 S-Box data can only be 7 or 8 bits wide!");

    logic [BIT_WIDTH-1:0] sh_and;
    logic [BIT_WIDTH-1:0] sh_and_xor;

    generate
        if ( BIT_WIDTH == 8 ) begin
            logic [BIT_WIDTH-1:0] y1, y2, y3;
            
            static_rotate_left #(BIT_WIDTH, 1) rot1(~in, y1);
            static_rotate_left #(BIT_WIDTH, 2) rot2(in, y2);
            static_rotate_left #(BIT_WIDTH, 3) rot3(in, y3);
            
            assign sh_and = y1 & y2 & y3;
        end else if ( BIT_WIDTH == 7 ) begin
            logic [BIT_WIDTH-1:0] y1, y2;
            
            static_rotate_left #(BIT_WIDTH, 1) rot1(~in, y1);
            static_rotate_left #(BIT_WIDTH, 2) rot2(in, y2);
            
            assign sh_and = y1 & y2;
        end
    endgenerate
    
    assign sh_and_xor = in ^ sh_and;
    
    static_rotate_left #(BIT_WIDTH, 1) fin_rot(sh_and_xor, out);

endmodule

`endif