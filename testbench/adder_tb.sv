`include "m31_adder.sv"

module adder_tb();

    adder_input_if #(31) in_if();
    adder_output_if #(32) out_if();
    
    m31_adder add(
        in_if.async_rcv,
        out_if.async_drv
    );
    
    initial begin
        in_if.in1 <= 0;
        in_if.in2 <= 0;
        #10
        in_if.in1 <= 1319499870;
        in_if.in2 <= 505241007;
        #10
        $finish();
    end

endmodule