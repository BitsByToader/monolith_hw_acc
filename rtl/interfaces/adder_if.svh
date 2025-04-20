`ifndef ADDER_IF_SVH
`define ADDER_IF_SVH

interface adder_input_if #(
    int INPUT_DATA_WIDTH = 32
) ();
    // For pipelined designs
    logic clk, reset;
    logic inputs_valid;
    
    // Inputs
    logic [INPUT_DATA_WIDTH-1:0] in1;
    logic [INPUT_DATA_WIDTH-1:0] in2;
    
    // Combinatorial adder ports
    modport async_drv(
        output in1,
        output in2
    );
    
    modport async_rcv(
        input in1,
        input in2
    );
endinterface

interface adder_output_if #(
    int OUTPUT_DATA_WIDTH = 33
) ();
    // For multi-cycle/pipelined designs
    logic clk, reset;
    logic output_valid;

    // Outputs
    logic [OUTPUT_DATA_WIDTH-1:0] out;
    
    // Combinatorial adder ports
    modport async_drv(
        output out
    );
    
    modport async_rcv(
        input out
    );
endinterface

`endif