`timescale 1 ns / 1 ps

module monolith_axis_ip_master_sif #(
    parameter integer FIFO_CHUNK_SIZE       = 16,
    parameter integer FIFO_CHUNK_COUNT      = 2,
    
	parameter integer C_M_AXIS_TDATA_WIDTH	= 32
) (
    input logic fifo_write_strobe,
    input logic [C_M_AXIS_TDATA_WIDTH-1:0] fifo_in [0:FIFO_CHUNK_SIZE-1],
    output logic fifo_full,

	// Global ports
	input wire  M_AXIS_ACLK,
	// 
	input wire  M_AXIS_ARESETN,
	// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
	output wire  M_AXIS_TVALID,
	// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
	output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
	// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
	output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
	// TLAST indicates the boundary of a packet.
	output wire  M_AXIS_TLAST,
	// TREADY indicates that the slave can accept a transfer in the current cycle.
	input wire  M_AXIS_TREADY
);
	
	localparam integer NUMBER_OF_OUTPUT_WORDS = FIFO_CHUNK_SIZE * FIFO_CHUNK_COUNT;
	localparam integer FIFO_LEVEL_SIZE = $clog2(NUMBER_OF_OUTPUT_WORDS);
	localparam integer FIFO_RD_ADDR_SIZE = $clog2(NUMBER_OF_OUTPUT_WORDS);
	localparam integer FIFO_WR_ADDR_SIZE = $clog2(FIFO_CHUNK_COUNT);
	localparam integer FIFO_CHUNK_ADDR_SIZE = $clog2(FIFO_CHUNK_SIZE);
	
	/******* FIFO *******/
	// TODO: Change something someting here to use block ram (bc why not, might be better?)
    (*ram_style = "registers" *) logic [C_M_AXIS_TDATA_WIDTH-1:0] fifo_mem [0:NUMBER_OF_OUTPUT_WORDS-1]; // memory
    reg [C_M_AXIS_TDATA_WIDTH-1 : 0] stream_data_out; // serial output
    wire tx_en; // read enable
	logic fifo_wren; // write enable
    // Pointers
    logic [FIFO_RD_ADDR_SIZE-1:0] read_pointer;
    logic [FIFO_WR_ADDR_SIZE-1:0] write_pointer;
    // FIFO status
    logic [FIFO_LEVEL_SIZE:0] fifo_level;
    logic fifo_empty;
    logic fifo_almost_empty;
	// and fifo_full which is output port...
	
	// AXI Stream handshaking internal signals
	wire axis_tvalid;
	wire axis_tlast;

	// I/O Connections assignments
	assign M_AXIS_TDATA    = stream_data_out;
	assign M_AXIS_TVALID   = axis_tvalid;
	assign M_AXIS_TLAST    = axis_tlast;
	assign M_AXIS_TSTRB    = {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};

    // FIFO Status Flags logic is based on level.
    always_ff @(posedge M_AXIS_ACLK) begin
        if (!M_AXIS_ARESETN) begin
            fifo_level <= 0;
        end else begin
            case({tx_en, fifo_wren})
                2'b00: fifo_level <= fifo_level;
                2'b01: fifo_level <= fifo_level + FIFO_CHUNK_SIZE;
                2'b10: fifo_level <= fifo_level - 1;
                2'b11: fifo_level <= fifo_level + FIFO_CHUNK_SIZE - 1;
            endcase
        end
    end
    
    assign fifo_full            = ( fifo_level == NUMBER_OF_OUTPUT_WORDS );
    assign fifo_empty           = ( fifo_level == 0 );
    assign fifo_almost_empty    = ( fifo_level == 1 );

	// Streaming output data is valid if there is at least one element in the FIFO to send.
	assign axis_tvalid = ~fifo_empty;
	assign axis_tlast = fifo_almost_empty;

    // Read out data while handshake is complete and there is data to send.
    assign tx_en = M_AXIS_TREADY & axis_tvalid & ~fifo_empty;

	// Read logic.
	always_ff @(posedge M_AXIS_ACLK) begin                                                                            
	   if(!M_AXIS_ARESETN) begin                                                                        
	       read_pointer <= 0;
	   end else begin      
	        if (tx_en) read_pointer <= read_pointer + 1;
	   end
    end
                                                      
    // Streaming output data is read from FIFO
    assign stream_data_out = fifo_mem[read_pointer];

    // Write logic.
    assign fifo_wren = fifo_write_strobe & !fifo_full;
    
    always @(posedge M_AXIS_ACLK) begin
        if (!M_AXIS_ARESETN) begin
            write_pointer <= 0;
        end else begin
            if (fifo_wren) begin
                write_pointer <= write_pointer + 1;
            end
        end
    end
    
    // FIFO memory is written into chunks.
    genvar idx;
    generate
        for (idx = 0; idx < FIFO_CHUNK_SIZE; idx = idx+1) begin
            logic [FIFO_CHUNK_ADDR_SIZE-1:0] fifo_chunk;
            assign fifo_chunk = idx;
            
            logic [NUMBER_OF_OUTPUT_WORDS-1:0] fifo_addr;
            assign fifo_addr = {write_pointer, fifo_chunk};
            
            always_ff @(posedge M_AXIS_ACLK) begin
                // TODO: Memory should be initialized as good practice, although not necessary here.
                if (fifo_wren) fifo_mem[fifo_addr] <= fifo_in[fifo_chunk];
            end
        end
    endgenerate

endmodule