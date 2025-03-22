`include "m31_multiplier.sv"

module multiplier_tb();

    multiplier_input_if #(.INPUT_DATA_WIDTH(31)) in_if();
    multiplier_output_if #(.OUTPUT_DATA_WIDTH(62)) out_if();
    
    m31_multiplier mul(
        in_if,
        out_if
    );
    
    initial begin
        in_if.in1 <= 0;
        in_if.in2 <= 0;
        #10
        in_if.in1 <= 686829796;
        in_if.in2 <= 742061112;
        #10
        
        // calculated using plonly3 rs impls
        // result will definitely wrap around,
        // test both mul and mod reduce.
        assert(out_if.out == 888237472);
        
        $finish();
    end

endmodule