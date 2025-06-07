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
	localparam integer FIFO_WR_ADDR_SIZE = $clog2(NUMBER_OF_INPUT_WORDS);
	localparam integer FIFO_RD_ADDR_SIZE = $clog2(FIFO_CHUNK_COUNT);
	localparam integer FIFO_CHUNK_ADDR_SIZE = $clog2(FIFO_CHUNK_SIZE);
	
	// FIFO Data Streaming FSM States.
	// TODO: Change parameters to enum!
	localparam IDLE        = 1'b0,  // Initial/idle state 
	           WRITE_FIFO  = 1'b1; // Write FIFO with input stream data S_AXIS_TDATA 
	
	// FIFO memory
	logic [C_S_AXIS_TDATA_WIDTH-1:0] stream_data_fifo [0:NUMBER_OF_INPUT_WORDS-1];
	
	wire axis_tready;
	
	// State variable
	logic mst_exec_state;  
	
	// FIFO full flag.
	logic fifo_full;
	
	// FIFO write enable
	wire fifo_wren;
	
	// FIFO read enable
	wire fifo_rden;
	
	// FIFO pointers
	logic [FIFO_WR_ADDR_SIZE-1:0] write_pointer;
	logic [FIFO_RD_ADDR_SIZE-1:0] read_pointer;
	
	// sink has accepted all the streaming data and stored in FIFO
	logic writes_done;
	
	// I/O Connections assignments
	assign S_AXIS_TREADY	= axis_tready;
	
	// Control state machine implementation
	// TODO: Redo FSM as it wastes a clock cycle every tvalid strobe.
	always @(posedge S_AXIS_ACLK) begin  
	   if (!S_AXIS_ARESETN) begin // Synchronous reset (active low)
	       mst_exec_state <= IDLE;
	   end else
	       case (mst_exec_state)
	           IDLE: 
                   // The sink starts accepting tdata when 
                   // there tvalid is asserted to mark the
                   // presence of valid streaming data 
                   if (S_AXIS_TVALID) begin
                       mst_exec_state <= WRITE_FIFO;
                   end else begin
                       mst_exec_state <= IDLE;
                   end
	       
	           WRITE_FIFO: 
                   // When the sink has accepted all the streaming input data,
                   // the interface swiches functionality to a streaming master
                   if (writes_done) begin
                       mst_exec_state <= IDLE;
                   end else begin
                       // The sink accepts and stores tdata 
                       // into FIFO
                       mst_exec_state <= WRITE_FIFO;
                   end
	       endcase
    end

    // Write logic.
	assign fifo_full = ( (write_pointer[FIFO_WR_ADDR_SIZE-1:FIFO_CHUNK_ADDR_SIZE]+1) == read_pointer );
	assign axis_tready = ((mst_exec_state == WRITE_FIFO) && !fifo_full); // Always accept data until FIFO is full.
    assign fifo_wren = S_AXIS_TVALID && axis_tready;
    
    always @(posedge S_AXIS_ACLK) begin
        if(!S_AXIS_ARESETN) begin
	       write_pointer <= 0;
	       writes_done <= 1'b0;
        end else begin
            if (fifo_wren && !fifo_full) begin
                // write pointer is incremented after every write to the FIFO
                // when FIFO write signal is enabled.
                write_pointer <= write_pointer + 1;
                writes_done <= 1'b0;
            end
            
            if ((write_pointer == NUMBER_OF_INPUT_WORDS-1) || S_AXIS_TLAST) begin
                // reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
                // has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
                writes_done <= 1'b1;
            end
       end
	end

    always @(posedge S_AXIS_ACLK) begin
        if (fifo_wren) begin
            stream_data_fifo[write_pointer] <= S_AXIS_TDATA;
        end
    end

    // Read logic.
    assign fifo_empty = (write_pointer[FIFO_WR_ADDR_SIZE-1:FIFO_CHUNK_ADDR_SIZE] == read_pointer);
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