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
        $readmemh("input_vec_16.mem", in);
        $readmemh("monolith_hash_out.mem", correct_out);
        
        @(valid == 1);
        for (int i = 0; i < 16; i = i+1) begin
            assert(out[i] == correct_out[i]);
        end
        
        #10 $finish();
    end

endmodule