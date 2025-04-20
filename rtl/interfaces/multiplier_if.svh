`ifndef MULTIPLIER_IF_SVH
`define MULTIPLIER_IF_SVH

// TODO: Asymmetric multipilier?

interface multiplier_input_if #(
    int INPUT_DATA_WIDTH = 32
) ();
    // For pipelined designs
    logic clk, reset;
    logic inputs_valid;
    
    // Inputs
    logic [INPUT_DATA_WIDTH-1:0] in1;
    logic [INPUT_DATA_WIDTH-1:0] in2;
    
    // Combinatorial multiplier ports
    modport async_drv(
        output in1,
        output in2
    );
    
    modport async_rcv(
        input in1,
        input in2
    );
    
    // Multi-cycle multiplier ports
    modport sync_drv(
        input clk, input reset,
        output in1, output in2,
        output inputs_valid
    );

    modport sync_rcv(
        input clk, input reset,
        input in1, input in2,
        input inputs_valid
    );

endinterface

interface multiplier_output_if #(
    int OUTPUT_DATA_WIDTH = 64
) ();
    // For multi-cycle/pipelined designs
    logic clk, reset;
    logic output_valid;

    // Outputs
    logic [OUTPUT_DATA_WIDTH-1:0] out;
    
    // Combinatorial multiplier ports
    modport async_drv(
        output out
    );
    
    modport async_rcv(
        input out
    );
    
    // Multi-cycle multiplier ports
    modport sync_drv(
        input clk, input reset,
        output out,
        output output_valid
    );

    modport sync_rcv(
        input clk, input reset,
        input out,
        input output_valid
    );

endinterface

`endif