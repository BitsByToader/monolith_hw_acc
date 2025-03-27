`ifndef MONOLITH_TOP_SV
`define MONOLITH_TOP_SV

`include "monolith_round.sv"

module monolith_top(
    input logic clk,
    input logic reset,
    
    input bit [30:0] in,
    output bit [30:0] out
);

    bit [30:0] state_in [0:15];
    bit [30:0] state_out [0:15];
    
    integer i;
    always_ff @(posedge clk) begin
        if (reset) begin
            for(i = 0; i < 16; i=i+1) begin
                //state_in[i] <= 0;
            end
        end
    end
    
    bit [3:0] in_counter;
    always_ff @(posedge clk) begin
        if (reset) begin
            in_counter <= 0;
        end else begin
            if ( in_counter != 15 ) begin
                in_counter <= in_counter + 1;
                state_in[in_counter] <= in;
            end
        end
    end
    
    bit [3:0] out_counter;
    bit out_valid;
    always_ff @(posedge clk) begin
        if (out_valid == 0 || reset == 1) begin
            out_counter <= 0;
        end else begin
            if (out_counter != 15 ) begin
                out_counter <= out_counter + 1;
                out <= state_out[out_counter];
            end
        end
    end

    monolith_round round(
        .clk(clk),
        .reset(reset),
        .state_in(state_in),
        .state_out(state_out),
        .valid(out_valid)
    );

endmodule

`endif