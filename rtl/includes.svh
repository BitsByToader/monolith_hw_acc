`ifndef INCLUDES_SVH
`define INCLUDES_SVH

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
`include "arithmetic/vec/vector_dot_product.sv"
`include "arithmetic/vec/vector_dot_product_mc.sv"

`include "monolith/monolith_sbox.sv"
`include "monolith/monolith_bars.sv"
`include "monolith/monolith_bricks.sv"
`include "monolith/monolith_concrete.sv"
`include "monolith/monolith_round.sv"
`include "monolith/monolith_hash.sv"

`endif
