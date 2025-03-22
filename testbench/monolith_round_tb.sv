`include "monolith_round.sv"

module monolith_round_tb();

    reg [30:0] in [0:15];
    reg [30:0] out [0:15];
    reg [30:0] correct_out [0:15];
    
    monolith_round round(
        .state_in(in),
        .state_out(out)
    );
    
    initial begin
        #10
        $readmemh("input_vec_16.mem", in);
        $readmemh("monolith_round_out.mem", correct_out);
        #10
        for (int i = 0; i < 16; i = i+1) begin
            assert(out[i] == correct_out[i]);
        end
        #10
        $finish();
    end

endmodule