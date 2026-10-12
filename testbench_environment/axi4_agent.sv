class axi4_agent extends uvm_agent;
    `uvm_component_utils(axi4_agent)

    axi4_agent_cfg       cfg;
    axi4_sequencer       sqr;
    axi4_driver          drv;
    axi4_monitor         mon;

    uvm_analysis_port #(axi4_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(axi4_agent_cfg)::get(this, "", "cfg", cfg)) begin
            cfg = axi4_agent_cfg::type_id::create("cfg");
            `uvm_info("AGT", "no cfg in config_db - using defaults (UVM_ACTIVE)", UVM_LOW);
        end

        mon = axi4_monitor::type_id::create("mon", this);

        ap = new("ap", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            sqr = axi4_sequencer::type_id::create("sqr", this);
            drv = axi4_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);  
            mon.ap.connect(ap);                                 
    endfunction
endclass
