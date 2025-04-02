`ifndef MOD_REDUCTION_IF_SVH
`define MOD_REDUCTION_IF_SVH

interface mod_reduction_inout_if #(
    int DATA_WIDTH = 64
) ();

    bit [DATA_WIDTH-1:0] data;

    modport drv(output data);
    modport rcv(input data);

endinterface

`endif