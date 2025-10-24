`ifndef MONOLITH_BRICKS_SV
`define MONOLITH_BRICKS_SV

module monolith_bricks #(
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

    // First element is passed through
    assign state_out[0] = state_in[0];
    
    genvar i;
    generate
        for ( i = 1; i < STATE_SIZE; i = i + 1 ) begin
            multiplier_input_if #(WORD_WIDTH) mul_in();
            multiplier_output_if #(WORD_WIDTH*2) mul_out();
            adder_input_if #(WORD_WIDTH) add_in();
            adder_output_if #(WORD_WIDTH+1) add_out();
            
            m31_multiplier mul(mul_in, mul_out);
            m31_adder add(add_in.async_rcv, add_out.async_drv);
            
            assign mul_out.clk = clk;
            assign mul_out.reset = reset;
            
            assign mul_in.clk = clk;
            assign mul_in.reset = reset;
            assign mul_in.in1 = state_in[i-1];
            assign mul_in.in2 = state_in[i-1];
            
            assign add_in.in1 = state_in[i];
            assign add_in.in2 = mul_out.out[WORD_WIDTH-1:0];
            
            assign state_out[i] = add_out.out[WORD_WIDTH-1:0];
        end
    endgenerate
    
    assign output_valid = input_valid;

endmodule

`endif