`ifndef INFERRED_MULTIPLIER_SV
`define INFERRED_MULTIPLIER_SV

module inferred_multiplier (
    multiplier_input_if.async_rcv inputs,
    multiplier_output_if.async_drv outputs
);
    assign outputs.out = inputs.in1 * inputs.in2;

endmodule

`endif