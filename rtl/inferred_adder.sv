`ifndef INFERRED_ADDER_SV
`define INFERRED_ADDER_SV

`include "adder_if.svh"

module inferred_adder (
    adder_input_if.async_rcv inputs,
    adder_output_if.async_drv outputs
);
    assign outputs.out = inputs.in1 + inputs.in2;

endmodule

`endif