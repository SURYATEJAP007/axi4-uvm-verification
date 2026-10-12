`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi4_transaction.sv"
`include "axi4_sequencer.sv"
`include "axi4_generator.sv"
`include "axi4_driver.sv"
`include "axi4_monitor.sv"
`include "axi4_agent_cfg.sv"
`include "axi4_agent.sv"
`include "axi4_scoreboard.sv"
`include "axi4_coverages.sv"
`include "axi4_environment.sv"
`include "axi4_test.sv"
        
module axi4_tb;

    logic aclk;
    logic aresetn;

    axi4_if vif(aclk, aresetn);

    axi4_slave_wrapper dut (.bus(vif.slave));

    bind axi4_if axi4_assertions u_assertions (
        .aclk    (aclk),
        .aresetn (aresetn),
        .awvalid (vif.awvalid), .awready (vif.awready),
        .wvalid  (vif.wvalid),  .wready  (vif.wready), .wlast(vif.wlast),
        .bvalid  (vif.bvalid),  .bready  (vif.bready),
        .arvalid (vif.arvalid), .arready (vif.arready),
        .rvalid  (vif.rvalid),  .rready  (vif.rready), .rlast(vif.rlast)
    );

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    initial begin
        aresetn = 0;
        repeat (10) @(posedge aclk);
        aresetn = 1;
    end
    initial begin
        uvm_config_db#(virtual axi4_if)::set(null, "*", "vif", vif);
        run_test("axi4_long_test");
    end

endmodule
