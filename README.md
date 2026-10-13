# AXI4 Slave: UVM Verification Environment

An AMBA AXI4 slave written in SystemVerilog, verified with a UVM testbench (constrained-random stimulus, reference-model scoreboard, SVA assertions, functional coverage) and simulated in QuestaSim.

**Author:** Teja ([github.com/SURYATEJAP007](https://github.com/SURYATEJAP007))

---

## What

**Design under test (DUT)**
- AXI4 slave with all five channels (AW, W, B, AR, R)
- Burst types: FIXED, INCR, WRAP
- Transfer sizes: 1, 2 and 4 bytes per beat on a 32-bit data bus
- `WSTRB` byte-lane writes
- Shared memory of 256 x 32-bit words (1 KB), with the write and read slaves merged in `axi4_slave_wrapper`

**Verification environment (UVM)**

```
                     axi4_test
                         |
                      axi4_env
        +----------------+----------------+
        |                |                |
   axi4_agent      axi4_scoreboard   axi4_coverages
  +-----+-----+     (reference         (covergroup,
  |     |     |       memory model)      uvm_subscriber)
 sqr   drv   mon -----> analysis port ----> sb + cov
        |     |
        +--- virtual axi4_if --- DUT (axi4_slave_wrapper)
```

- **Sequence / transaction:** random write bursts, plus reads that replay earlier writes. `WSTRB` is derived from the beat address so it always matches the active byte lanes.
- **Driver:** drives AW, W and B for writes and AR and R for reads through clocking blocks.
- **Monitor:** reconstructs complete write and read transactions from handshakes and publishes them on an analysis port.
- **Scoreboard:** keeps a reference memory, applies byte strobes, steps addresses for FIXED, INCR and WRAP, and checks every read beat.
- **Coverage:** burst type, size, length, address range, ID and direction, with crosses.
- **Assertions:** SVA channel-stability checks (13 asserts and 7 covers) bound to the interface.
- **Config:** the virtual interface is passed through `uvm_config_db`, and the agent's active/passive mode through a config object.

## Why

I built this to learn design verification the hands-on way: write a real protocol design, then build the testbench layer by layer. I started with a plain SystemVerilog layered testbench and then moved it to real UVM, so each component maps onto a UVM class and a standard UVM mechanism (factory, `config_db`, sequencer-driver handshake, analysis ports).



| File | Role |
|---|---|
| `axi4_interface.sv` | AXI4 interface, clocking blocks and modports |
| `axi4_write_slave.sv`, `axi4_read_slave.sv` | DUT write and read paths |
| `wrapper_module.sv` | `axi4_slave_wrapper`, shared memory |
| `axi4_assertions.sv` | SVA protocol assertions |
| `axi4_transaction.sv` | `uvm_sequence_item` with constraints |
| `axi4_generator.sv` | `uvm_sequence` |
| `axi4_sequencer.sv`, `axi4_driver.sv`, `axi4_monitor.sv` | Agent components |
| `axi4_agent_cfg.sv`, `axi4_agent.sv` | Agent and its config object |
| `axi4_scoreboard.sv`, `axi4_coverages.sv` | Checking and coverage |
| `axi4_environment.sv` | `uvm_env` |
| `axi4_test.sv` | `axi4_base_test`, `axi4_smoke_test` (10 txns), `axi4_long_test` (200 txns) |
| `axi4_testbench_top.sv` | Top module: clock, reset, DUT, `bind`, `run_test` |

**Run (QuestaSim)**

Adjust the paths to your install. The commands below are the general shape:

```
vlog -sv axi4_interface.sv axi4_write_slave.sv axi4_read_slave.sv wrapper_module.sv axi4_assertions.sv axi4_testbench_top.sv
vsim -c axi4_tb -do "run -all; quit"
```

The top module starts `axi4_long_test`. To run another test, change the name in `run_test()`, or pass `+UVM_TESTNAME=axi4_smoke_test` and call `run_test()` with no argument.

**Result of the 200-transaction run (QuestaSim 10.7c, UVM 1.1d)**

| Metric | Value |
|---|---|
| Transactions | 200 (94 writes, 106 reads) |
| Read beats checked | 1009 |
| Read mismatches | 0 |
| Functional coverage | 100% of the defined bins |
| Simulator errors | 0 |



## Limitations

- **Single-beat bursts are not generated.** Lengths run from 2 to 16 beats (`len` 1 to 15), so `len = 0` is never exercised, and the length coverage bin `[0:3]` does not show that.
- **Strobe checking is partly blind.** Reads replay a write with the same address and size, so bytes that `WSTRB` disabled are not read back independently.
- **The driver is sequential.** It runs AW, then W, then B, with no outstanding transactions and no ready/valid delays. The monitor assumes the same ordering.
- **Responses are not checked.** `bresp`, `rresp` and ID match are printed or ignored, and only OKAY is ever returned.
- **No negative testing:** no error injection, illegal sizes, out-of-range addresses or mid-transfer reset.
- **Single seed.** The 100% coverage figure covers only the bins defined in the covergroup.
- **Logging is mixed.** Some components use `uvm_info` and others use `$display`.


