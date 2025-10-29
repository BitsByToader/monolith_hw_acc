`include "../rtl/includes.svh"

module monolith_hash_tb();

    logic clk, reset;
    logic [30:0] in [0:15];
    logic [30:0] out [0:15];
    logic in_valid, out_valid;
    logic [30:0] correct_out [0:15];
    
    monolith_hash hash(
        .clk(clk),
        .reset(reset),
        .state_in(in),
        .in_valid(in_valid),
        .state_out(out),
        .out_valid(out_valid)
        );
    
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars();
        
        clk = 1; reset = 1;
        
        forever #5 clk = ~clk;
    end
    
    initial begin
        $readmemh("input_vec_16.mem", in);
        $readmemh("monolith_hash_out.mem", correct_out);
        
        #10 reset = 0;
        
        @(negedge clk);
        in_valid = 1;
        @(negedge clk);
        in_valid = 0;
        
        @(out_valid == 1);
        for (int i = 0; i < 16; i = i+1) begin
            assert(out[i] == correct_out[i]);
        end
        
        #100 $finish();
    end

endmodule