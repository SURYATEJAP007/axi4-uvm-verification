

class axi4_env extends uvm_env;
`uvm_component_utils(axi4_env)

    // ========================================
    // Component Classes
    // ========================================
    axi4_agent      agent;      // Generator + Driver + Monitor
    axi4_scoreboard sb;         // Verification/checking
    axi4_coverages  cov;        // Coverage collection


    // ========================================
    // Constructor
    // ========================================
    function new(string name, uvm_component parent);
        super.new(name,parent);
        $display("[ENV] Environment created");
    endfunction

    // ========================================
    // Build: Create All Components
    // ========================================
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        $display("[ENV] Building environment...");
      
        agent = axi4_agent::type_id::create("agent",this); 
        $display("[ENV]   Agent created and built");
        
        sb = axi4_scoreboard::type_id::create("sb",this);
        $display("[ENV]   Scoreboard created");
  
        cov = axi4_coverages::type_id::create("cov",this);
        $display("[ENV]   Coverage created");
        
        $display("[ENV] Build complete\n");
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(sb.fifo.analysis_export);
        agent.ap.connect(cov.analysis_export);
    endfunction

endclass
