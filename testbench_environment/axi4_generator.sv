class axi4_sequence extends uvm_sequence #(axi4_transaction);
`uvm_object_utils(axi4_sequence)

    int transaction_count;
    int num_txns;
    axi4_transaction written_txns[$];

    function new(string name = "axi4_sequence");
        super.new(name);
        transaction_count = 0;
        num_txns          = 50;
    endfunction

    task body();

        axi4_transaction txn;
        int idx;

        $display("[GENERATOR] Starting to generate %0d transactions", num_txns);

        repeat (num_txns) begin

            txn = axi4_transaction::type_id::create("txn");

            start_item(txn);

            if (written_txns.size() == 0) begin

                if (!txn.randomize() with { is_write == 1; })
                    $fatal("SEQ", "WRITE randomization failed");
            end
            else begin

                // Randomly choose WRITE or READ
                if ($urandom_range(0,1) == 1) begin

                    if (!txn.randomize() with {
                            is_write   == 1;
                            len        inside {[1:15]};
                            size       inside {[0:2]};
                            burst_type inside {0,1,2};
                        })
                        $fatal("SEQ", "WRITE randomization failed");
                end
                else begin

                    idx = $urandom_range(0, written_txns.size()-1);

                    txn.is_write   = 0;
                    txn.addr       = written_txns[idx].addr;
                    txn.len        = written_txns[idx].len;
                    txn.size       = written_txns[idx].size;
                    txn.burst_type = written_txns[idx].burst_type;
                    txn.id         = $urandom_range(0,15);

                    txn.data       = new[txn.len + 1];
                    txn.wstrb      = new[txn.len + 1];
                    txn.rresp      = new[txn.len + 1];

                    $display("[SEQUENCE] READ selected from stored WRITE[%0d]", idx);
                    $display("[SEQUENCE] READ: addr=0x%08h len=%0d size=%0d burst=%0d",
                             txn.addr, txn.len, txn.size, txn.burst_type);
                end
            end

            if (txn.is_write) begin

                foreach (txn.data[i])
                    $display("[SEQUENCE] Beat %0d: data=0x%08h wstrb=%b",
                             i, txn.data[i], txn.wstrb[i]);

                written_txns.push_back(txn);

                $display("[GENERATOR] Stored WRITE[%0d]: addr=0x%08h len=%0d size=%0d burst=%0d",
                         written_txns.size()-1,
                         txn.addr, txn.len, txn.size, txn.burst_type);
            end

            transaction_count++;

            $display("[SEQUENCE] Transaction [%0d]: len=%0d size=%0d burst=%0d addr=0x%08h is_write=%0d",
                     transaction_count,
                     txn.len, txn.size, txn.burst_type, txn.addr, txn.is_write);

            finish_item(txn);

        end

        `uvm_info("SEQ", $sformatf("All %0d transactions generated successfully", transaction_count), UVM_LOW)

    endtask

endclass
