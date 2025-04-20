`ifndef INCLUDES_SVH
`define INCLUDES_SVH

/// Helper function which resets all values of a bit vector to 0.
/// When synthesized, will generate hardware to reset the flip-flop.
/// Wrapped in a class to allow parameterization.
class reset_vector_wrapper #(int WORD_WIDTH=31, int STATE_SIZE=16);
    static function void create(inout logic [WORD_WIDTH-1:0] vec [0:STATE_SIZE-1]);
        integer i;
        for (i=0; i<STATE_SIZE; i=i+1) begin
            vec[i] = 0;
        end
    endfunction
endclass

`include "interfaces/adder_if.svh"
`include "interfaces/mod_reduction_if.svh"
`include "interfaces/multiplier_if.svh"

`include "arithmetic/inferred/inferred_adder.sv"
`include "arithmetic/inferred/inferred_multiplier.sv"

`include "arithmetic/m31/m31_adder.sv"
`include "arithmetic/m31/m31_mod_reducer.sv"
`include "arithmetic/m31/m31_multiplier.sv"

`include "arithmetic/mat/circ_mtx_vec_mul.sv"

`include "arithmetic/vec/vector_adder.sv"
`include "arithmetic/vec/vector_dot_product_mc.sv"

`include "monolith/monolith_sbox.sv"
`include "monolith/monolith_bars.sv"
`include "monolith/monolith_bricks.sv"
`include "monolith/monolith_concrete.sv"
`include "monolith/monolith_round.sv"
`include "monolith/monolith_hash.sv"

`endif
