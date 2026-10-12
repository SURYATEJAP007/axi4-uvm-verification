class axi4_sequencer extends uvm_sequencer #(axi4_transaction);
`uvm_component_utils(axi4_sequencer)

function new(string name="axi4_sequencer",uvm_component parent=null);
super.new(name,parent);
endfunction

endclass
