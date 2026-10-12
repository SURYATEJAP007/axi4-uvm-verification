class axi4_transaction extends uvm_sequence_item;
`uvm_object_utils(axi4_transaction)

    localparam MEM_DEPTH   = 256;
    localparam DATA_WIDTH  = 32;
    localparam STRB_WIDTH  = DATA_WIDTH / 8;

    // ========================================
    // Randomizable Fields
    // ========================================
    rand logic [7:0]   len;
    rand logic [2:0]   size;
    rand logic [1:0]   burst_type;
    rand logic [31:0]  addr;
    rand logic [3:0]   id;
    rand bit           is_write;

    rand logic [31:0]           data[];
    rand logic [STRB_WIDTH-1:0] wstrb[];

    // ========================================
    // DUT responses
    // ========================================
    logic [1:0] bresp;
    logic [1:0] rresp[];
    logic [3:0] rid_seen;

    // ========================================
    // Constraints
    // ========================================
    constraint const_len {
        len inside {[1:15]};
    }

    constraint const_size {
        size inside {[0:2]};
    }

    constraint const_burst {
        burst_type inside {0,1,2};
        if (burst_type == 2)
            (len + 1) inside {2,4,8,16};
    }

    constraint const_addr {
        addr < (MEM_DEPTH * 4);
    }

    constraint const_addr_align {
        addr % (1 << size) == 0;
    }

    // NEW - INCR bursts must not run past the end of memory
    constraint const_burst_in_range {
        if (burst_type == 1)
            (addr + ((len + 1) << size) - 1) < (MEM_DEPTH * 4);
    }

    constraint const_id {
        id inside {[0:15]};
    }

    constraint const_data_size {
        data.size()  == (len + 1);
    }

    constraint const_wstrb_size {
        wstrb.size() == (len + 1);
    }

    // ========================================
    // Constructor
    // ========================================
    function new(string name = "axi4_transaction");
        super.new(name);
        addr       = 32'h0;
        len        = 1;
        size       = 0;
        burst_type = 1;
        id         = 0;
        is_write   = 1'b0;
        data       = new[1];
        wstrb      = new[1];
    endfunction

    // ========================================
    // Beat address - mirrors axi4_read_slave / axi4_write_slave
    // ========================================
    function automatic logic [31:0] beat_addr(input int unsigned beat);
        int unsigned nbytes = 1 << size;
        int unsigned blk    = nbytes * (len + 1);
        logic [31:0] base   = addr & ~(blk - 1);
        logic [31:0] a;

        case (burst_type)
            2'd0:    a = addr;                            // FIXED - never advances
            2'd1:    a = addr + beat * nbytes;            // INCR
            2'd2:    begin                                // WRAP
                         a = addr + beat * nbytes;
                         if (a >= base + blk) a = a - blk;
                     end
            default: a = addr + beat * nbytes;
        endcase
        return a;
    endfunction

    // ========================================
    // POST RANDOMIZE - wstrb is DERIVED, never random
    // ========================================
    function void post_randomize();
        int unsigned lane;
        int unsigned nbytes = 1 << size;

        data  = new[len+1];
        wstrb = new[len+1];

        if (is_write) begin
            foreach (data[i]) begin
                data[i]  = $urandom;
                lane     = beat_addr(i) % STRB_WIDTH;
                wstrb[i] = ((1 << nbytes) - 1) << lane;
            end
        end
        else begin
            rresp = new[len+1];
        end
    endfunction

    // ========================================
    // DISPLAY
    // ========================================
    function void display(string tag="TX");
        int bytes_per_beat = 1 << size;
        $display("[%s] id=%0d addr=0x%h len=%0d size=%0d (%0d bytes/beat) burst=%0d is_write=%0d",
                 tag, id, addr, len, size, bytes_per_beat, burst_type, is_write);
        if (is_write) begin
            foreach (data[i])
                $display("  data[%0d]=0x%h wstrb=%b", i, data[i], wstrb[i]);
        end
    endfunction

    function string convert2string();
        return $sformatf("id=%0d addr=0x%h len=%0d burst=%0d is_write=%0d",
                         id, addr, len, burst_type, is_write);
    endfunction

endclass
