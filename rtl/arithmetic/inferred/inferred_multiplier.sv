`ifndef INFERRED_MULTIPLIER_SV
`define INFERRED_MULTIPLIER_SV

module inferred_multiplier (
    multiplier_input_if inputs,
    multiplier_output_if outputs
);
    assign outputs.out = inputs.in1 * inputs.in2;
    
endmodule

/// Pipelined version of the above
module inferred_multiplier_pl #(
    int PIPELINE_STAGES=7
) (
    multiplier_input_if inputs,
    multiplier_output_if outputs
);
    bit [outputs.OUTPUT_DATA_WIDTH-1:0] stages [0:PIPELINE_STAGES-1];

    integer i,j;
    always_ff @(posedge outputs.clk) begin
        if (outputs.reset) begin
            for (i=0; i < PIPELINE_STAGES; i=i+1) begin
                stages[i] <= 0;
            end
        end else begin
            stages[0] <= inputs.in1 * inputs.in2;
            for (j=1; j < PIPELINE_STAGES; j=j+1) begin
                stages[j] <= stages[j-1];    
            end
        end
    end

    assign outputs.out = stages[PIPELINE_STAGES-1];
    
endmodule

`endif