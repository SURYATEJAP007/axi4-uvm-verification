class axi4_monitor extends uvm_monitor;
`uvm_component_utils(axi4_monitor)

    virtual axi4_if.monitor vif;
    uvm_analysis_port #(axi4_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "virtual interface vif not found")
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        repeat (10) @(vif.monitor_cb);
        fork
            watch_write();
            watch_read();
        join
    endtask

    //==================================================
    // WATCH WRITE (AW + W + B)
    //==================================================
    task watch_write();
        axi4_transaction txn;
        int burst_len;

        forever begin

            // ---- wait for a REAL AW handshake (both signals HIGH) ----
            do @(vif.monitor_cb);
            while (!(vif.monitor_cb.awvalid && vif.monitor_cb.awready));

            txn            = axi4_transaction::type_id::create("wr_txn");
            txn.is_write   = 1'b1;
            txn.id         = vif.monitor_cb.awid;
            txn.addr       = vif.monitor_cb.awaddr;
            txn.size       = vif.monitor_cb.awsize;
            txn.burst_type = vif.monitor_cb.awburst;

            burst_len = vif.monitor_cb.awlen;
            txn.len   = burst_len;

            txn.data  = new[txn.len + 1];
            txn.wstrb = new[txn.len + 1];

            $display("[MONITOR] Write: addr=0x%h, len=%0d, size=%0d, burst=%0d",
                     txn.addr, txn.len, txn.size, txn.burst_type);

            // ---- capture W beats: BOTH wvalid and wready must be HIGH ----
            for (int i = 0; i <= txn.len; i++) begin
                do @(vif.monitor_cb);
                while (!(vif.monitor_cb.wvalid && vif.monitor_cb.wready));

                txn.data[i]  = vif.monitor_cb.wdata;
                txn.wstrb[i] = vif.monitor_cb.wstrb;

                if (vif.monitor_cb.wlast) begin
                    $display("[MONITOR] Write: Captured WLAST at beat %0d (len=%0d)", i, txn.len);
                    break;
                end
            end

            // ---- wait for B handshake ----
            do @(vif.monitor_cb);
            while (!(vif.monitor_cb.bvalid && vif.monitor_cb.bready));

            txn.bresp = vif.monitor_cb.bresp;
            $display("[MONITOR] About  write txn: addr=0x%h, id=%0d, time=%0t",
                     txn.addr, txn.id, $time);
            ap.write(txn);

        end
    endtask


    //==================================================
    // WATCH READ (AR + R)
    //==================================================
    task watch_read();
        axi4_transaction txn;
        int burst_len;

        forever begin

            while (vif.monitor_cb.aresetn !== 1'b1) @(vif.monitor_cb);

            // ---- wait for a REAL AR handshake (both signals HIGH) ----
            do @(vif.monitor_cb);
            while (!(vif.monitor_cb.arvalid && vif.monitor_cb.arready));

            txn            = axi4_transaction::type_id::create("rd_txn");
            txn.is_write   = 1'b0;
            txn.id         = vif.monitor_cb.arid;
            txn.addr       = vif.monitor_cb.araddr;
            txn.size       = vif.monitor_cb.arsize;
            txn.burst_type = vif.monitor_cb.arburst;

            burst_len = vif.monitor_cb.arlen;
            txn.len   = burst_len;

            txn.data  = new[txn.len + 1];
            txn.rresp = new[txn.len + 1];

            $display("[MONITOR] Read: addr=0x%h, len=%0d, size=%0d, burst=%0d , time =%0t",
                     txn.addr, txn.len, txn.size, txn.burst_type, $time);

            // ---- capture R beats: BOTH rvalid and rready must be HIGH ----
            for (int i = 0; i <= txn.len; i++) begin
                do @(vif.monitor_cb);
                while (!(vif.monitor_cb.rvalid && vif.monitor_cb.rready));

                txn.data[i]  = vif.monitor_cb.rdata;
                txn.rresp[i] = vif.monitor_cb.rresp;

                $display("[MONITOR] Read: Beat %0d: data=0x%h, resp=%0d, rlast=%0d",
                         i, txn.data[i], txn.rresp[i], vif.monitor_cb.rlast);

                if (vif.monitor_cb.rlast) begin
                    $display("[MONITOR] Read: Captured RLAST at beat %0d (expected len=%0d)", i, txn.len);
                    break;
                end
            end

            ap.write(txn);

        end
    endtask

endclass
