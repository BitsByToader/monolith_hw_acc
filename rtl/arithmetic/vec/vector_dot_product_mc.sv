`ifndef VECTOR_DOT_PRODUCT_MC_SV
`define VECTOR_DOT_PRODUCT_MC_SV

/// Computes the dot product of two vectors.
module vector_dot_product_mc #(
    int WORD_WIDTH = 31,
    int VECTOR_SIZE = 16
) (
    input logic clk,
    input logic reset,
    
    input logic [WORD_WIDTH-1:0] vec1 [0:VECTOR_SIZE-1],
    input logic [WORD_WIDTH-1:0] vec2 [0:VECTOR_SIZE-1],
    
    output logic [WORD_WIDTH-1:0] result,
    output logic valid
);
    // TODO: Generate non-pipelined multiplier for values smaller than 2.
    localparam int DSP_PIPELINE_STAGES = 2;
    localparam int NEEDED_CYCLES = VECTOR_SIZE+DSP_PIPELINE_STAGES-1;
    localparam int STAGE_COUNTER_WIDTH = $clog2(NEEDED_CYCLES);
    localparam int VECTOR_SEL = $clog2(VECTOR_SIZE);
    
    logic [2*WORD_WIDTH:0] full_result;
    logic [2*WORD_WIDTH-1:0] mul_res;
    logic [WORD_WIDTH-1:0] reduced_result, reduced_result_d, acum_result;
    
    logic [STAGE_COUNTER_WIDTH-1:0] stage_counter;
    logic [VECTOR_SEL-1:0] element_counter;
    assign element_counter = (stage_counter >= VECTOR_SIZE) ? (VECTOR_SIZE-1) : stage_counter;

    mod_reduction_inout_if #(.DATA_WIDTH(2*WORD_WIDTH+1)) reduce_in();
    mod_reduction_inout_if #(.DATA_WIDTH(WORD_WIDTH)) reduce_out();
    m31_mod_reduce reduce(reduce_in.rcv, reduce_out.drv);

    assign reduce_in.data = full_result;
    assign reduced_result = reduce_out.data;
    
    // Multiplier
    multiplier_input_if #(WORD_WIDTH) mul_in();
    multiplier_output_if #(WORD_WIDTH*2) mul_out();
    m31_multiplier_pl #(DSP_PIPELINE_STAGES) mul(mul_in, mul_out);
    
    assign mul_in.clk = clk;
    assign mul_in.reset = reset;
    assign mul_out.clk = clk;
    assign mul_out.reset = reset;
    
    assign mul_in.in1 = vec1[element_counter];
    assign mul_in.in2 = vec2[element_counter];
    assign mul_res = mul_out.out;

    // MACC
    assign full_result = {WORD_WIDTH'('h0), acum_result} + mul_res;

    always_ff @(posedge clk) begin
        if (reset) begin
            acum_result <= 0;
            reduced_result_d <= 0;
        end else begin
            if (!valid)
                acum_result <= reduced_result;
                reduced_result_d <= reduced_result;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            stage_counter <= 0;
        end else begin
            if ((stage_counter) != NEEDED_CYCLES) begin
                stage_counter <= stage_counter + 1;
            end
        end
    end

    assign result = reduced_result;
    assign valid = ((stage_counter) == NEEDED_CYCLES);

endmodule

`endif