`timescale 1 ns / 1 ps

`include "includes.svh"

module monolith_axis_ip # (
    parameter integer C_S00_AXIS_TDATA_WIDTH	= 31,
	parameter integer C_M00_AXIS_TDATA_WIDTH	= 31,
	
	parameter integer PERM_SIZE = 16,
	parameter integer FIFO_SIZE = 4 // Number of permutations that the FIFO can store.
) (
	// Ports of Axi Slave Bus Interface S00_AXIS
	input wire                                      s00_axis_aclk,
	input wire                                      s00_axis_aresetn,
	output wire                                     s00_axis_tready,
	input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0]       s00_axis_tdata,
	input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0]   s00_axis_tstrb,
	input wire  s00_axis_tlast,
	input wire  s00_axis_tvalid,

	// Ports of Axi Master Bus Interface M00_AXIS
	input wire                                      m00_axis_aclk,
	input wire                                      m00_axis_aresetn,
	output wire                                     m00_axis_tvalid,
	output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0]      m00_axis_tdata,
	output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0]  m00_axis_tstrb,
	output wire                                     m00_axis_tlast,
	input wire                                      m00_axis_tready
);

    logic [30:0] state_in [0:PERM_SIZE-1];
    logic [30:0] state_out [0:PERM_SIZE-1];
    
    // Currently, this IP requires that master and slave interfaces have the same clock and reset, for simplicity.
    // The hash engine and coordinations FSM will use the same clock as well.
    logic global_clk, global_rst;
    assign global_clk = s00_axis_aclk;
    assign global_rst = ~s00_axis_aresetn;

    // Handshaking signals.
    logic hash_valid;
    logic slave_fifo_empty, master_fifo_full;

	// Instantiation of Slave Axi Bus Interface
	// The slave interface is the input (RX) interface of the IP.
	monolith_axis_ip_slave_sif # ( 
	   .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
	   .FIFO_CHUNK_SIZE(PERM_SIZE),
	   .FIFO_CHUNK_COUNT(FIFO_SIZE)
	) slave_sif (
        .S_AXIS_ACLK        (s00_axis_aclk),
        .S_AXIS_ARESETN     (s00_axis_aresetn),
        .S_AXIS_TREADY      (s00_axis_tready),
        .S_AXIS_TDATA       (s00_axis_tdata),
        .S_AXIS_TSTRB       (s00_axis_tstrb),
        .S_AXIS_TLAST       (s00_axis_tlast),
        .S_AXIS_TVALID      (s00_axis_tvalid),
        .fifo_read_strobe   (~master_fifo_full), // FIXME: Enough for stall control?
        .fifo_out           (state_in),
        .fifo_empty         (slave_fifo_empty)
	);

    // Hash engine instantiation
	monolith_hash hash(
	    .clk        (global_clk),
	    .reset      (global_rst),
	    .state_in   (state_in),
	    .in_valid   (~slave_fifo_empty),
        .state_out  (state_out),
	    .out_valid  (hash_valid)
        // TODO: Input Stall pipeline signal for when TX side is full.
    );
    
	// Instantiation of Master Axi Bus Interface
	// The master interface is the output (TX) interface of the IP.
    monolith_axis_ip_master_sif # ( 
	   .C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
	   .FIFO_CHUNK_SIZE(PERM_SIZE),
       .FIFO_CHUNK_COUNT(FIFO_SIZE)
    ) master_sif (
        .M_AXIS_ACLK        (m00_axis_aclk),
        .M_AXIS_ARESETN     (m00_axis_aresetn),
        .M_AXIS_TVALID      (m00_axis_tvalid),
        .M_AXIS_TDATA       (m00_axis_tdata),
        .M_AXIS_TSTRB       (m00_axis_tstrb),
        .M_AXIS_TLAST       (m00_axis_tlast),
        .M_AXIS_TREADY      (m00_axis_tready),
        .fifo_write_strobe  (hash_valid),
        .fifo_in            (state_out),
        .fifo_full          (master_fifo_full)
	);

endmodule