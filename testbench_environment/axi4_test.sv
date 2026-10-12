class axi4_base_test extends uvm_test;
    `uvm_component_utils(axi4_base_test)

    axi4_env env;
    int      num_txns = 50;          

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        axi4_agent_cfg cfg;
        super.build_phase(phase);
        cfg = axi4_agent_cfg::type_id::create("cfg");
        cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(axi4_agent_cfg)::set(this, "env.agent", "cfg", cfg);

        env = axi4_env::type_id::create("env", this);
        uvm_top.set_timeout(200us, 0);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi4_sequence seq;

        phase.raise_objection(this, "test started");     

        seq = axi4_sequence::type_id::create("seq");
        seq.num_txns = num_txns;
        seq.start(env.agent.sqr);                        

        #200;                                            
        phase.drop_objection(this, "test finished");
    endtask
endclass


// 10 transactions ? fast regression
class axi4_smoke_test extends axi4_base_test;
    `uvm_component_utils(axi4_smoke_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        num_txns = 10;
    endfunction
endclass


// 200 transactions ? soak / coverage
class axi4_long_test extends axi4_base_test;
    `uvm_component_utils(axi4_long_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        num_txns = 200;
    endfunction
endclass