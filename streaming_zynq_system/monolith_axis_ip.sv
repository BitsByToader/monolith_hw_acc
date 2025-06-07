`timescale 1 ns / 1 ps

`include "includes.svh"

module monolith_axis_ip # (
    parameter integer C_S00_AXIS_TDATA_WIDTH	= 31, // TODO: Change back to 32 and fix mismatched width error.
	parameter integer C_M00_AXIS_TDATA_WIDTH	= 31,
	
	parameter integer PERM_SIZE = 16,
	parameter integer FIFO_SIZE = 2 // Number of permutations that the FIFO can store.
) (
	// Ports of Axi Slave Bus Interface S00_AXIS
	input wire  s00_axis_aclk,
	input wire  s00_axis_aresetn,
	output wire  s00_axis_tready,
	input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
	input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
	input wire  s00_axis_tlast,
	input wire  s00_axis_tvalid,

	// Ports of Axi Master Bus Interface M00_AXIS
	input wire  m00_axis_aclk,
	input wire  m00_axis_aresetn,
	output wire  m00_axis_tvalid,
	output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
	output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
	output wire  m00_axis_tlast,
	input wire  m00_axis_tready
);

    logic [30:0] state_in [0:PERM_SIZE-1];
    logic [30:0] state_out [0:PERM_SIZE-1];
    
    // Currently, this IP requires that master and slave interfaces have the same clock and reset, for simplicity.
    // The hash engine and coordinations FSM will use the same clock as well.
    logic global_clk, global_rst;
    assign global_clk = s00_axis_aclk;
    assign global_rst = ~s00_axis_aresetn;

    // FSM outputs
    logic hash_rst, read_req, write_req;
    
    // FSM inputs
    logic hash_valid;
    logic slave_fifo_empty, master_fifo_full;

	// Instantiation of Slave Axi Bus Interface
	// The slave interface is the input interface of the IP.
	monolith_axis_ip_slave_sif # ( 
	   .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
	   .FIFO_CHUNK_SIZE(PERM_SIZE),
	   .FIFO_CHUNK_COUNT(FIFO_SIZE)
	) slave_sif (
	   .S_AXIS_ACLK(s00_axis_aclk),
	   .S_AXIS_ARESETN(s00_axis_aresetn),
	   .S_AXIS_TREADY(s00_axis_tready),
	   .S_AXIS_TDATA(s00_axis_tdata),
	   .S_AXIS_TSTRB(s00_axis_tstrb),
	   .S_AXIS_TLAST(s00_axis_tlast),
	   .S_AXIS_TVALID(s00_axis_tvalid),
	   .fifo_read_strobe(read_req),
	   .fifo_out(state_in),
	   .fifo_empty(slave_fifo_empty)
	);

	// Instantiation of Master Axi Bus Interface
	// The master interface is the output interface of the IP.
    monolith_axis_ip_master_sif # ( 
	   .C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
	   .FIFO_CHUNK_SIZE(PERM_SIZE),
       .FIFO_CHUNK_COUNT(FIFO_SIZE)
	) master_sif (
	   .M_AXIS_ACLK(m00_axis_aclk),
	   .M_AXIS_ARESETN(m00_axis_aresetn),
	   .M_AXIS_TVALID(m00_axis_tvalid),
	   .M_AXIS_TDATA(m00_axis_tdata),
	   .M_AXIS_TSTRB(m00_axis_tstrb),
	   .M_AXIS_TLAST(m00_axis_tlast),
	   .M_AXIS_TREADY(m00_axis_tready),
	   .fifo_write_strobe(write_req),
	   .fifo_in(state_out),
	   .fifo_full(master_fifo_full)
	);
	
	// Hash engine instantiation
	monolith_hash hash(
	   .clk(global_clk), // Will assume that both slave and master interfaces are driven by same clock.
	   .reset(hash_rst),
	   .state_in(state_in),
	   .state_out(state_out),
	   .valid(hash_valid)
	);
	
	// Streaming Coordination FSM
    typedef enum logic [2:0] {
        IDLE,
        INPUT_DATA_AVAILABLE,
        REQ_NEXT_DATA,
        WAIT_COMPUTE,
        FLUSH_COMPUTE
    } STREAMING_STATE_e;
    STREAMING_STATE_e cs, ns;

    always_ff @(posedge global_clk) begin
        if (global_rst) begin
            cs <= IDLE;
        end else begin
            cs <= ns;
        end
    end

    // State transition logic
    always_comb begin
        case(cs)
            IDLE: begin
                // Wait for compute requests on the slave interface.
                if (slave_fifo_empty)
                    ns = IDLE;
                else
                    ns = INPUT_DATA_AVAILABLE;
            end
            
            INPUT_DATA_AVAILABLE: begin
                // FIFO will always output the next readout value.
                // It will be sampled in this state by the hash engine
                // Immediatly req next data in the next CC to have it available.
                ns = REQ_NEXT_DATA;
            end
            
            REQ_NEXT_DATA: begin
                // Once data is requested, the read strobe must be deasserted until the next computation.
                ns = WAIT_COMPUTE;
            end
            
            WAIT_COMPUTE: begin
                // Wait for the hash engine to finish the computation.
                // The FIFO will write the memory every cycle in anticipation of a write strobe.
                if (!hash_valid)
                    ns = WAIT_COMPUTE;
                else
                    ns = FLUSH_COMPUTE;
            end
            
            FLUSH_COMPUTE: begin
                // The write request will lock the output state in the memory at the current wr pointer, by increasing the pointer.
                // After flushing to the master IF's fifo, idle back by waiting for the next request.
                ns = IDLE;
            end
            
            default: ns = IDLE;
        endcase
    end
    
    // FSM output logic
    always_comb begin
        case(cs)
            IDLE: begin
                hash_rst <= 1;
                read_req <= 0;
                write_req <= 0;
            end
            
            INPUT_DATA_AVAILABLE: begin
                hash_rst <= 0;
                read_req <= 0;
                write_req <= 0;
            end
            
            REQ_NEXT_DATA: begin
                hash_rst <= 0;
                read_req <= 1;
                write_req <= 0;
            end
            
            WAIT_COMPUTE: begin
                hash_rst <= 0;
                read_req <= 0;
                write_req <= 0;
            end
            
            FLUSH_COMPUTE: begin
                hash_rst <= 1;
                read_req <= 0;
                write_req <= 1;
            end
        endcase
    end

endmodule