`timescale 1 ns / 1 ps

module monolith_axis_ip_slave_sif #(
    parameter integer FIFO_CHUNK_SIZE       = 16,
    parameter integer FIFO_CHUNK_COUNT      = 2,
	
	parameter integer C_S_AXIS_TDATA_WIDTH  = 32
) (
    input logic fifo_read_strobe,
    output logic [C_S_AXIS_TDATA_WIDTH-1:0] fifo_out [0:FIFO_CHUNK_SIZE-1],
    output logic fifo_empty,

	// AXI4Stream sink: Clock
	input wire  S_AXIS_ACLK,
	// AXI4Stream sink: Reset
	input wire  S_AXIS_ARESETN,
	// Ready to accept data in
	output wire  S_AXIS_TREADY,
	// Data in
	input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
	// Byte qualifier
	input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
	// Indicates boundary of last packet
	input wire  S_AXIS_TLAST,
	// Data is in valid
	input wire  S_AXIS_TVALID
);
	localparam integer NUMBER_OF_INPUT_WORDS = FIFO_CHUNK_SIZE * FIFO_CHUNK_COUNT;
	localparam integer FIFO_LEVEL_SIZE = $clog2(NUMBER_OF_INPUT_WORDS);
	localparam integer FIFO_WR_ADDR_SIZE = $clog2(NUMBER_OF_INPUT_WORDS);
	localparam integer FIFO_RD_ADDR_SIZE = $clog2(FIFO_CHUNK_COUNT);
	localparam integer FIFO_CHUNK_ADDR_SIZE = $clog2(FIFO_CHUNK_SIZE);
	
	// FIFO memory
	logic [C_S_AXIS_TDATA_WIDTH-1:0] stream_data_fifo [0:NUMBER_OF_INPUT_WORDS-1];
	
	// FIFO Status signals
	logic [FIFO_LEVEL_SIZE:0] fifo_level;
	logic fifo_full;
	// ... and fifo empty which is a port.
	
	// FIFO r/w enable
	wire fifo_wren;
	wire fifo_rden;
	
	// FIFO pointers
	logic [FIFO_WR_ADDR_SIZE-1:0] write_pointer;
	logic [FIFO_RD_ADDR_SIZE-1:0] read_pointer;
	
	// I/O AXI Connections assignments
	assign S_AXIS_TREADY = !fifo_full; // Always accept data until FIFO is full.

    // FIFO Status Flags logic is based on level.
    always_ff @(posedge S_AXIS_ACLK) begin
        if (!S_AXIS_ARESETN) begin
            fifo_level <= 0;
        end else begin
            case({fifo_rden, fifo_wren})
                2'b00: fifo_level <= fifo_level;
                2'b01: fifo_level <= fifo_level + 1;
                2'b10: fifo_level <= fifo_level - FIFO_CHUNK_SIZE;
                2'b11: fifo_level <= fifo_level - FIFO_CHUNK_SIZE + 1;
            endcase
        end
    end

    assign fifo_full = ( fifo_level == (NUMBER_OF_INPUT_WORDS-1) );
    assign fifo_empty = (fifo_level < FIFO_CHUNK_SIZE); // TODO: From a reusability PoV, this is less ideal. Keep empty as is, outside of module compute 'true' empty based on chunk using level.

    // Write logic.	
    assign fifo_wren = S_AXIS_TVALID && S_AXIS_TREADY && !fifo_full;
    
    always @(posedge S_AXIS_ACLK) begin
        if(!S_AXIS_ARESETN) begin
	       write_pointer <= 0;
        end else begin
            if (fifo_wren) begin
                write_pointer <= write_pointer + 1;
            end
       end
	end

    always @(posedge S_AXIS_ACLK) begin
        if (fifo_wren) begin
            stream_data_fifo[write_pointer] <= S_AXIS_TDATA;
        end
    end

    // Read logic.
    assign fifo_rden = fifo_read_strobe & !fifo_empty;
    
    always @(posedge S_AXIS_ACLK) begin
        if (!S_AXIS_ARESETN) begin
            read_pointer <= 0;
        end else begin
            if (fifo_rden) begin
                read_pointer <= read_pointer + 1;
            end
        end
    end
    
    genvar idx;
    generate
        for (idx = 0; idx < FIFO_CHUNK_SIZE; idx = idx+1) begin
            logic [FIFO_CHUNK_ADDR_SIZE-1:0] fifo_chunk;
            assign fifo_chunk = idx;
            
            logic [NUMBER_OF_INPUT_WORDS-1:0] fifo_addr;
            assign fifo_addr = {read_pointer, fifo_chunk};
            
            always @(posedge S_AXIS_ACLK) begin
                fifo_out[fifo_chunk] <= stream_data_fifo[fifo_addr];
            end
        end
    endgenerate

endmodule