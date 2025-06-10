`timescale 1ns / 1ps

import axi4stream_vip_pkg::*;
import design_1_axi4stream_vip_0_0_pkg::*;
import design_1_axi4stream_vip_1_0_pkg::*;

module tb(
  );
  
  design_1_axi4stream_vip_0_0_mst_t mst_agent;
  design_1_axi4stream_vip_1_0_slv_t slv_agent;
  
  // instantiate block diagram design
  design_1_wrapper DUT();
    
  axi4stream_ready_gen ready_gen;
  axi4stream_transaction wr_transaction;
  
  axi4stream_monitor_transaction mt_trx;
  xil_axi4stream_data_byte mt_data[4];

  initial begin
    #1ns // different paths are used in design for synthesis, replace constants with correct path for sim here
    $readmemh("m31_mds_mtx.mem", DUT.streaming_hash_ip.hash.round.concrete.mtx);
    $readmemh("monolith_6round_constants.mem", DUT.streaming_hash_ip.hash.round_constants);
  end

  initial begin
    mst_agent = new("master vip agent",DUT.design_1_i.axi4stream_vip_0.inst.IF);
    slv_agent = new("slave vip agent",DUT.design_1_i.axi4stream_vip_1.inst.IF);
    mst_agent.start_master();
    slv_agent.start_slave();
    
    #50ns
    
    fork begin
        forever begin
            slv_agent.monitor.item_collected_port.get(mt_trx);
            mt_trx.get_data(mt_data);
            $display("Got master if trx. Data: %0h", {mt_data[3], mt_data[2], mt_data[1], mt_data[0]});
        end
    end join_none
    
    wr_transaction = mst_agent.driver.create_transaction("write transaction");
    wr_transaction.set_data({8'h1, 8'h0, 8'h0, 8'h0});
    for (int i = 0; i < 16; i=i+1)
        mst_agent.driver.send(wr_transaction);
        
    wr_transaction.set_data({8'h2, 8'h0, 8'h0, 8'h0});
    for (int i = 0; i < 16; i=i+1)
        mst_agent.driver.send(wr_transaction);
    
    wr_transaction.set_data({8'h3, 8'h0, 8'h0, 8'h0});
    for (int i = 0; i < 16; i=i+1)
        mst_agent.driver.send(wr_transaction);
        
    wr_transaction.set_data({8'h4, 8'h0, 8'h0, 8'h0});
    for (int i = 0; i < 16; i=i+1)
        mst_agent.driver.send(wr_transaction);
    
//    ready_gen = slv_agent.driver.create_ready("ready_gen");
//    ready_gen.set_ready_policy(XIL_AXI4STREAM_READY_GEN_OSC);
//    ready_gen.set_low_time(1);
//    ready_gen.set_high_time(2);
//    slv_agent.driver.send_tready(ready_gen);
    
    #2500ns
    
    $finish;

  end

endmodule