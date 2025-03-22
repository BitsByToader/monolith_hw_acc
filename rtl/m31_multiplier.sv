`ifndef M31_MULTIPLIER_SV
`define M31_MULTIPLIER_SV

`include "multiplier_if.svh"
`include "m31_mod_reducer.sv"

module m31_multiplier (
    multiplier_input_if inputs,
    multiplier_output_if outputs
);
    
    multiplier_output_if #(.OUTPUT_DATA_WIDTH(outputs.OUTPUT_DATA_WIDTH)) unreduced_mul();
    inferred_multiplier mul(inputs.async_rcv, unreduced_mul.async_drv);
    
    mod_reduction_inout_if #(.DATA_WIDTH(unreduced_mul.OUTPUT_DATA_WIDTH)) reduce_in();
    mod_reduction_inout_if #(.DATA_WIDTH(unreduced_mul.OUTPUT_DATA_WIDTH)) reduce_out();
    assign reduce_in.data = unreduced_mul.out;
    
    m31_mod_reduce reduce(reduce_in.rcv, reduce_out.drv);
    
    assign outputs.out = reduce_out.data;

endmodule

`endif