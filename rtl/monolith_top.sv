`ifndef MONOLITH_TOP_SV
`define MONOLITH_TOP_SV

`include "includes.svh"

// TODO: Add AXI Stream interfaces to top.
// TODO: Mod reduce data data from AXI before hash.

module monolith_top(
    input logic clk, // Clocked on positive edge
    input logic reset, // Active high
    
    input bit [30:0] in1, // Input to hash
    input bit [30:0] in2, // Second input for compression, ignored in hashing mode
    input bit hash_or_compress_flag, // 0 ~~ HASH, 1 ~~ COMPRESS
    input bit go, // Active high. Keep asserted for whole computation, hard reset of engine otherwise.
    
    output bit [30:0] out, // Result of hash
    output bit valid // Out has valid data when asserted. Remains asserted as out is stable until go cycle or reset.
);

    bit [30:0] state_in [0:15];
    bit [30:0] state_out [0:15];

    monolith_hash hash(
        .clk(clk),
        .reset(~go),
        .state_in(state_in),
        .state_out(state_out),
        .valid(valid)
    );
    
    assign out = state_out[0];
    
    always_ff @(posedge clk) begin
        if (reset | ~go) begin // Negative go also resets module.
            for (int i = 0; i < 16; i=i+1) begin
                state_in[i] <= 0;
            end
        end else begin
            state_in[0] <= in1;
            state_in[1] <= (hash_or_compress_flag == 1) ? in2 : 0;
        end
    end

endmodule

`endif
