`ifndef MULTIPLIER_IF_SVH
`define MULTIPLIER_IF_SVH

// TODO: Asymmetric multipilier?

interface multiplier_input_if #(
    int INPUT_DATA_WIDTH = 32
) ();
    // For pipelined designs
    bit clk, reset;
    bit inputs_valid;
    
    // Inputs
    bit [INPUT_DATA_WIDTH-1:0] in1;
    bit [INPUT_DATA_WIDTH-1:0] in2;
    
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
    clocking drv_cb @(clk);
        output in1;
        output in2;
        output inputs_valid;
    endclocking
    modport sync_drv(clocking drv_cb, input clk, input reset);
    
    clocking rcv_cb @(clk);
        input in1;
        input in2;
        input inputs_valid;
    endclocking
    modport sync_rcv(clocking rcv_cb, input clk, input reset);
endinterface

interface multiplier_output_if #(
    int OUTPUT_DATA_WIDTH = 64
) ();
    // For multi-cycle/pipelined designs
    bit clk, reset;
    bit output_valid;

    // Outputs
    bit [OUTPUT_DATA_WIDTH-1:0] out;
    
    // Combinatorial multiplier ports
    modport async_drv(
        output out
    );
    
    modport async_rcv(
        input out
    );
    
    // Multi-cycle multiplier ports
    clocking drv_cb @(clk);
        output out;
        output output_valid;
    endclocking
    modport sync_drv(clocking drv_cb, input clk, input reset);
    
    clocking rcv_cb @(clk);
        input out;
        input output_valid;
    endclocking
    modport sync_rcv(clocking rcv_cb, input clk, input reset);
endinterface

`endif