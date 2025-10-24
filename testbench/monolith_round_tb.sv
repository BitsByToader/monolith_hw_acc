`include "../rtl/includes.svh"

module monolith_round_tb();

    reg clk, reset, out_valid, in_valid;
    reg [30:0] in [0:15];
    reg [30:0] out [0:15];
    reg [30:0] correct_out [0:15];
    reg [30:0] constants [0:15];
    
    monolith_round round(
        .clk(clk),
        .reset(reset),
        .state_in(in),
        .state_out(out),
        .input_valid(in_valid),
        .output_valid(out_valid),
        .pre_round(1'b0),
        .constants(constants)
    );
    
    initial begin
        clk <= 0; reset <= 1; in_valid <= 0;
        #10 reset <= 0;
    end
    
    always #5 clk <= ~clk;
    
    initial begin
        $readmemh("input_vec_16.mem", in);
        $readmemh("monolith_round_out.mem", correct_out);
        
        #1
        $readmemh("m31_mds_mtx.mem", round.concrete.mtx);
        $readmemh("monolith_6round_constants.mem", constants);
        
        @reset;
        #10;
        in_valid <= 1;
        
        @(out_valid == 1);
        for (int i = 0; i < 16; i = i+1) begin
            assert(out[i] == correct_out[i]);
        end
        
        #10 $finish();
    end

endmodule