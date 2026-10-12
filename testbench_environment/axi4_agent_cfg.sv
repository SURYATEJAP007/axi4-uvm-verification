`include "uvm_macros.svh"
import uvm_pkg::*;


class axi4_agent_cfg extends uvm_object;
    `uvm_object_utils(axi4_agent_cfg)

    uvm_active_passive_enum is_active  = UVM_ACTIVE;
    bit                     has_coverage = 1;

    function new(string name = "axi4_agent_cfg");
        super.new(name);
    endfunction
endclass