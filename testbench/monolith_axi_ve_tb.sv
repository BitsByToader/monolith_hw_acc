`timescale 1ns / 1ps

import axi_vip_pkg::*;
import axi_vip_bd_axi_vip_0_0_pkg::*;

module tb(
  );
     
  bit                                     clock;
  bit                                     reset_n;
  bit                                     irq;
  
  axi_vip_bd_axi_vip_0_0_mst_t              master_agent;
   
  xil_axi_ulong hashin1     = 32'h4000_0000;
  xil_axi_ulong hashin2     = 32'h4000_0004;
  xil_axi_ulong hashout     = 32'h4000_0008;
  xil_axi_prot_t prot = 0;
  xil_axi_resp_t resp;
  bit[31:0] read_data;
  
  // instantiate block diagram design
  axi_vip_bd_wrapper design_i
       (.aclk_0(clock),
        .aresetn_0(reset_n));

  assign irq = design_i.monolith_axi.monolith.valid;
  
  always #5ns clock <= ~clock;

  initial begin
    #1ns // different paths are used in design for synthesis, replace constants with correct path for sim here
    $readmemh("m31_mds_mtx.mem", design_i.monolith_axi.monolith.hash.round.concrete.mtx);
    $readmemh("monolith_6round_constants.mem", design_i.monolith_axi.monolith.hash.round_constants);
  end

  initial begin
    master_agent = new("master vip agent", design_i.axi_vip_bd_i.axi_vip_0.inst.IF);
    
    //Start the agent
    master_agent.start_master();
    
    #50ns
    reset_n = 1'b1;
    
    #50ns
    $display("%t Begin writes for load&start!", $time);
    master_agent.AXI4LITE_WRITE_BURST(hashin1, prot, (1965742212 << 1)|1, resp);
    
    $display("%t Wait for valid...", $time);
    @(irq);
    
    master_agent.AXI4LITE_READ_BURST(hashout, prot, read_data, resp);
    $display("%t Read after hash: %0h. Valid: %0h", $time, read_data>>1, read_data&1);
    
    #50ns
    $display("%t Begin writes for load&start!", $time);
    master_agent.AXI4LITE_WRITE_BURST(hashin1, prot, (1965742213 << 1)|1, resp);
    
    $display("%t Wait for valid...", $time);
    @(irq);
    
    master_agent.AXI4LITE_READ_BURST(hashout, prot, read_data, resp);
    $display("%t Read after hash: %0h. Valid: %0h", $time, read_data>>1, read_data&1);
    
    $finish;

  end

endmodule