`include "../rtl/includes.svh"

module monolith_hash_tb();

    reg clk, reset, valid;
    reg [30:0] in [0:15];
    reg [30:0] out [0:15];
    reg [30:0] correct_out [0:15];
    
    monolith_hash hash(
        .clk(clk),
        .reset(reset),
        .state_in(in),
        .state_out(out),
        .valid(valid)
    );
    
    initial begin
        clk <= 0; reset <= 1;
        #10 reset <= 0;
    end
    
    always #5 clk <= ~clk;
    
    initial begin
        //$readmemh("input_vec_16.mem", in);
        //$readmemh("monolith_hash_out.mem", correct_out);
        in[0] <= 54;
        for(int i = 1; i < 16; i=i+1)begin
            in[i] = 0;
        end
        
        #1 // different paths are used in design for synthesis, replace constants with correct path for sim here
        $readmemh("m31_mds_mtx.mem", hash.round.concrete.mtx);
        $readmemh("monolith_6round_constants.mem", hash.round_constants);
        
        @(valid == 1);
        for (int i = 0; i < 16; i = i+1) begin
            assert(out[i] == correct_out[i]);
        end
        
        #100 $finish();
    end

endmodule