# experiments/sim_handover/ -- cycle-level simulation of the command-buffer handover

cocotb/Verilator simulation of the ZCU216 board top with the QubiC DSP core and the Ant-Q command path (DDR command
bundle, ping-pong buffer, command sequencer, CNR detector) in the 8-core configuration. Two tests in
`tests/test_plsv_v2b_handover.py`:

| Test | Program | Output |
|---|---|---|
| `test_handover_k3` | three back-to-back circuits, each one 200 ns pulse on qubit 0 at start time T0 = 2000 cycles, fed through the ping-pong buffer | per boundary: cycle offsets from the last DAC sample of circuit k to each control event and to the first DAC sample of circuit k+1, and H = DAC gap - T0 |
| `test_intershot_k1_n2` | one circuit with two shots, no buffer switch | the DSP core's gap between the two shots minus T0 |

H has the definition of the oscilloscope measurement in `results/bench/handover_scope/`: the gap between the pulses
minus the program's own first-pulse start time. The output of both tests is in `results/sim_handover/`.

Run (Python 3.12, cocotb 2.0.1, Verilator 5.040, with `qubic` from `software/` and `distproc` from
`distributed_processor` importable):

```bash
cd experiments/sim_handover
PYTHONPATH=../../software:<distributed_processor>/python make -f Makefile_v2b MODULE=test_plsv_v2b_handover
```

| Path | Contents |
|---|---|
| `Makefile_v2b`, `plsv_v2b.d` | build through cocotb and the source list |
| `rtl/` | simulation top and integration: board top with the command bundle (`plsv_v2b.sv`), board configuration without the stock command reads (`boardcfg_v2b.sv`), command sequencer, CNR detector, command/readout bundle (`nopgap_bundle/`), stubs |
| `vendor/` | copies of the QubiC gateware modules (DSP core, element, processor, bus and memory blocks) and of the Ant-Q memory-path modules of the integration model; the QubiC license is `vendor/QUBIC_LICENSE` |
| `sim/gensrc/` | generated configuration of the 8-core build (channel configuration, register and memory maps, core instances) |
| `cocotb/preinclude.py` | inlines the `.vh` includes for Verilator |
| `tests/` | the handover tests and their shared helpers (`test_plsv_v2b_cnr.py`) |

The memory-path modules are those of the Ant-Q integration model; the released design is the pinned `gateware/`.
