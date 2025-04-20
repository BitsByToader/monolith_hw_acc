`ifndef MONOLITH_TOP_SV
`define MONOLITH_TOP_SV

`include "includes.svh"

module monolith_top(
    input logic clk, // Clocked on positive edge
    input logic reset, // Active high
    
    input logic [30:0] in1, // Input to hash
    input logic [30:0] in2, // Second input for compression, ignored in hashing mode
    input logic hash_or_compress, // 0 ~~ HASH, 1 ~~ COMPRESS
    input logic go, // Active high. Keep asserted for whole computation, hard reset of engine otherwise.
    
    output logic [30:0] out, // Result of hash
    output logic valid // Out has valid data when asserted. Remains asserted as out is stable until go cycle or reset.
);

    logic [30:0] state_in [0:15];
    logic [30:0] state_out [0:15];

    monolith_hash hash(
        .clk(clk),
        .reset(~go),
        .state_in(state_in),
        .state_out(state_out),
        .valid(valid)
    );
    
    assign out = state_out[0];
    
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 16; i=i+1) begin
                state_in[i] <= 0;
            end
        end else begin
            state_in[0] <= in1;
            state_in[1] <= (hash_or_compress == 1) ? in2 : 0;
        end
    end

endmodule

`endif
