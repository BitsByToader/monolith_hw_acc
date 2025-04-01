`ifndef M31_ADDER_SV
`define M31_ADDER_SV

`include "adder_if.svh"
`include "m31_mod_reducer.sv"

module m31_adder (
    adder_input_if.async_rcv inputs,
    adder_output_if.async_drv outputs
);
    
    adder_output_if #(.OUTPUT_DATA_WIDTH(outputs.OUTPUT_DATA_WIDTH)) unreduced_add();
    inferred_adder adder(inputs, unreduced_add.async_drv);
    
    mod_reduction_inout_if #(.DATA_WIDTH(unreduced_add.OUTPUT_DATA_WIDTH)) reduce_in();
    mod_reduction_inout_if #(.DATA_WIDTH(unreduced_add.OUTPUT_DATA_WIDTH)) reduce_out();
    assign reduce_in.data = unreduced_add.out;
    
    m31_mod_reduce reduce(reduce_in.rcv, reduce_out.drv);
    
    assign outputs.out = reduce_out.data;

endmodule

`endif
