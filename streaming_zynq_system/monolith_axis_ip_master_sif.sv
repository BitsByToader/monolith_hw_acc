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
	localparam integer FIFO_RD_ADDR_SIZE = $clog2(NUMBER_OF_OUTPUT_WORDS);
	localparam integer FIFO_WR_ADDR_SIZE = $clog2(FIFO_CHUNK_COUNT);
	localparam integer FIFO_CHUNK_ADDR_SIZE = $clog2(FIFO_CHUNK_SIZE);
	                                                                          
	// Streaming FSM states
	// TODO: Change parameters to enum!
	localparam IDLE            = 1'b0,
	           SEND_STREAM     = 1'b1;
	
	// State variable                                                                    
	reg mst_exec_state;                                                            
                      
	logic [FIFO_RD_ADDR_SIZE-1:0] read_pointer;
    logic [FIFO_WR_ADDR_SIZE-1:0] write_pointer;
	
	logic fifo_empty;
	
	logic fifo_wren;
	
	// FIFO memory
    logic [C_M_AXIS_TDATA_WIDTH-1:0] fifo_mem [0:NUMBER_OF_OUTPUT_WORDS-1];
	
	// AXI Stream internal signals
	wire  	axis_tvalid;
	//streaming data valid delayed by one clock cycle
	reg  	axis_tvalid_delay;
	//Last of the streaming data 
	wire  	axis_tlast;
	//Last of the streaming data delayed by one clock cycle
	reg  	axis_tlast_delay;
	//FIFO implementation signals
	reg [C_M_AXIS_TDATA_WIDTH-1 : 0] 	stream_data_out;
	wire  	tx_en;
	//The master has issued all the streaming data stored in FIFO
	reg  	tx_done;

	// I/O Connections assignments
	assign M_AXIS_TVALID	= axis_tvalid; // TODO: Removed delay, needs further investigation.
	assign M_AXIS_TDATA	= stream_data_out;
	assign M_AXIS_TLAST	= axis_tlast; // TODO: Removed delay, needs further investigation.
	assign M_AXIS_TSTRB	= {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};


	// Control state machine implementation
	// TODO: REDO FSM as it is broken!
    always @(posedge M_AXIS_ACLK) begin                                                                     
        if (!M_AXIS_ARESETN) begin // Synchronous reset (active low)                                            
            mst_exec_state <= IDLE;
        end else begin
            case (mst_exec_state)                                                 
                IDLE:                                                               
                    // The slave starts accepting tdata when                          
                    // there tvalid is asserted to mark the                           
                    // presence of valid streaming data
                    mst_exec_state  <= SEND_STREAM;                                                             
                                                                                  
                SEND_STREAM:                                                        
                    // The example design streaming master functionality starts       
                    // when the master drives output tdata from the FIFO and the slave
                    // has finished storing the S_AXIS_TDATA                          
                    if (tx_done) begin                                                           
                        mst_exec_state <= IDLE;                                       
                    end else begin                                                           
                        mst_exec_state <= SEND_STREAM;
                    end
            endcase
        end
    end

    assign fifo_full = ( (read_pointer[FIFO_RD_ADDR_SIZE-1:FIFO_CHUNK_ADDR_SIZE]+1) == write_pointer );
    assign fifo_empty = (read_pointer[FIFO_RD_ADDR_SIZE-1:FIFO_CHUNK_ADDR_SIZE] == write_pointer);

	// axis_tvalid is asserted when the control state machine's state is SEND_STREAM and fifo is not empty
	assign axis_tvalid = ((mst_exec_state == SEND_STREAM) && !fifo_empty);
	                                                                                               
	// AXI tlast generation
	// axis_tlast is asserted right when FIFO becomes empty, when last element was popped out. (TODO: this is probably incorrect!)
	assign axis_tlast = fifo_empty;                                           
	                                                                                               
	// Delay the axis_tvalid and axis_tlast signal by one clock cycle
	// to match the latency of M_AXIS_TDATA
	// TODO: This might not be needed for tlast!
	always @(posedge M_AXIS_ACLK) begin                                                                                          
	   if (!M_AXIS_ARESETN) begin                                                                                      
	       axis_tvalid_delay <= 1'b0;                                                               
	       axis_tlast_delay <= 1'b0;                                                               
	   end else begin                                                                                      
	       axis_tvalid_delay <= axis_tvalid;                                                        
	       axis_tlast_delay <= axis_tlast;                                                          
	   end                                                                                        
    end                                                                                            

    assign tx_en = M_AXIS_TREADY && axis_tvalid;

	// Read logic.
	always@(posedge M_AXIS_ACLK) begin                                                                            
	   if(!M_AXIS_ARESETN) begin                                                                        
	       read_pointer <= 0;                                                         
	       tx_done <= 1'b0;                                                           
	   end else begin
	       if (!fifo_empty) begin                                                                      
	           if (tx_en) begin                                                               
	               // read pointer is incremented after every read from the FIFO          
	               // when FIFO read signal is enabled.
	               read_pointer <= read_pointer + 1;
	               tx_done <= 1'b0;                                                     
	           end                                                                    
	       end else begin                                                                      
	           // tx_done is asserted when fifo has been emptied.                                             
	           tx_done <= 1'b1;
	       end                                                                        
	   end
    end
                                                      
    // Streaming output data is read from FIFO       
    always @( posedge M_AXIS_ACLK ) begin                                            
        if(!M_AXIS_ARESETN) begin                                        
            stream_data_out <= 1;                      
        end else if (tx_en /*&& M_AXIS_TSTRB[byte_index]*/) begin                    
            stream_data_out <= fifo_mem[read_pointer];
        end
    end


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
    
    genvar idx;
    generate
        for (idx = 0; idx < FIFO_CHUNK_SIZE; idx = idx+1) begin
            logic [FIFO_CHUNK_ADDR_SIZE-1:0] fifo_chunk;
            assign fifo_chunk = idx;
            
            logic [NUMBER_OF_OUTPUT_WORDS-1:0] fifo_addr;
            assign fifo_addr = {write_pointer, fifo_chunk};
            
            always @(posedge M_AXIS_ACLK) begin
                if (fifo_wren)
                    fifo_mem[fifo_addr] <= fifo_in[fifo_chunk];
            end
        end
    endgenerate

endmodule