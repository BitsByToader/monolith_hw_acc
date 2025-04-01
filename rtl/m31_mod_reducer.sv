`ifndef M31_MOD_REDUCER_SV
`define M31_MOD_REDUCER_SV

`include "mod_reduction_if.svh"

module m31_partial_reduce(
    mod_reduction_inout_if.rcv in,
    mod_reduction_inout_if.drv out
);

    bit [30:0] limb_lhs;
    bit [out.DATA_WIDTH-1:0] limb_rhs;
    
    assign limb_lhs = in.data[30:0]; // gets least significat 31bits of the word
    assign limb_rhs = in.data >> 31; // rest of the word
    assign out.data = limb_rhs + limb_lhs; // partially reduced output as wide as word.

endmodule

/// Modular reduction for p = 2^31-1 = 31'h7FFFFFFF.
/// Creates M31 field element from larger or equal to 31 bit wide words.
module m31_mod_reduce(
    mod_reduction_inout_if.rcv in,
    mod_reduction_inout_if.drv out
);
    
    mod_reduction_inout_if #(.DATA_WIDTH(in.DATA_WIDTH)) partial_output();
    
    m31_partial_reduce reduce1(in, partial_output.drv);
    m31_partial_reduce reduce2(partial_output.rcv, out);
    
endmodule

`endif
