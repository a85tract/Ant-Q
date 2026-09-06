# Ant-Q: Breaking Memory Bottlenecks in Quantum Control Systems

Ant-Q is a memory-hierarchy design for the FPGA-based quantum control system QubiC. It uses the control board's PL-DRAM as
the main memory for circuit commands and readout results and keeps BRAM as a cache with ping-pong buffers, so that circuits
longer than the command buffer and acquisitions longer than the accumulator buffer run with deterministic timing, and
readout results reach the host while the remaining shots are still executing.

> **Breaking Memory Bottlenecks in Quantum Control Systems for More Precise Experiments and Higher Throughput Computing**
> Yicheng Guang, Neel Vora, Yilun Xu, Yueqi Chen, Gang Huang
> *University of Colorado Boulder & Lawrence Berkeley National Laboratory*

This repository is the artifact of the paper: it pins the exact gateware, software and benchmark versions that produced
every number in the paper, and holds the measurement scripts, the raw data and the analysis reports.

## Repository structure

| Path | What it is | Pinned version |
|---|---|---|
| [`gateware/`](https://gitlab.com/yguang1/gateware/-/tree/c3-stop-ce) | Submodule: QubiC gateware with the Ant-Q downlink and uplink integrated (the "C3" image, ZCU216, 14 qubits). The measured bitstream was built from exactly this commit (`xsa_commit` 63329aaf, timing closed: WNS 0.000 ns). The uplink-only image used for the baseline columns is commit 0071783e of the same repository. | `63329aaf`, branch `c3-stop-ce` |
| [`software/`](https://gitlab.com/yguang1/software/-/tree/ddr-stop-c3) | Submodule: QubiC host software plus the Ant-Q PS servers (`scripts/batch_server.c`, `scripts/dma_server.c`, `scripts/std_server.c`) and the batch client (`qubic/rpc_client.py`) | `a1eefb5`, branch `ddr-stop-c3` |
| [`benchmark/`](https://gitlab.com/yguang1/benchmark_qce) | Submodule: the 20 computing circuits and 6 physics experiments as QubiC pulse-level programs (`circuits_le14.py`, `physic_experiment.py`), the same 20 circuits as Qiskit objects (`circuits_qiskit.py`, used by the noise study), and the 14-qubit configuration | `7edc3f5` |
| [`experiments/`](experiments/README.md) | Measurement and analysis code: `board/` (the runner and campaign drivers that produced every hardware number), `rq3_noise_study/` (the simulator study behind RQ3), `patches/` (one small patch to the QubiC assembler) | this repository |
| [`results/`](results/README.md) | Every measured row, the derived tables, the campaign logs and the analysis reports | this repository |

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/a85tract/Ant-Q.git
```

## What the paper claims and where the evidence is

| Paper item | Claim (revised manuscript) | How it was measured | Data |
|---|---|---|---|
| RQ1, Table "functionality" | All six reconstructed experiments execute on the integrated image; (3) repeated Ramsey (50000 shots at 2 ms) and (4) the 6 us trace need the uplink, (5) restless 1Q RB at 5101 Cliffords and (6) 2Q RB at 500 Cliffords need the downlink and run as sub-circuit streams with zero detected boundary stalls | `experiments/board/run_phys_campaign.py` (runner in `--phys` mode; `phys_split.py` cuts (5) and (6) at gate boundaries) | `results/table2_phys.csv`, `results/raw_runs_phys.csv`, `results/reports/report_20260902.md` section A |
| RQ1, physical cadence | The measured inter-shot period equals the compiled period within the 80 ns oscilloscope resolution over 8000 (6 us trace) and ~5000 (2 ms Ramsey) consecutive shots; every command-buffer handover in the streamed RB costs a fixed 141 ns and none stalled | `experiments/board/scope_cadence.py` (Tektronix MSO71254C on the drive output) | `results/scope_cadence/`, addendum section G |
| RQ2, Tables "speedup" | Single circuits: Ant-Q overhead over the realized QPU time 0.6-1.8 % (fixed cost ~25 us + ~10 us per active core); 30-circuit batches: throughput gain +51.1 % from the downlink/uplink stack (block CI 46.9-55.3 %), +60.0 % at system level, +40.9 % with the uplink alone | `experiments/board/antq_runner.py` (`--real`, modes `std` / `c1` / `c3`), `run_pool_campaign.py` (pool-wide envelope tables for heterogeneous batches), `make_tables.py`, `make_pool_tables.py`, `make_decomp_table.py` | `results/table3_single.csv`, `results/table4_pool*.csv`, `results/table_decomp.csv`, `results/raw_runs.csv`, report section C, addendum section D |
| RQ3, Table "noise study" and early stop | Readability of the 20 circuits on six Qiskit fake backends over 20 seeds; six circuits fail on at least one backend; the TVD/HF stop rule fires at checkpoint 3-6 with 0 false stops on 1698 readable runs | `experiments/rq3_noise_study/run_rq3_stats.sh`, `make_rq3_tables.py`, `rq3_adequacy_gate.py` | `results/rq3_v2/`, `results/table_rq3_cells_v2.csv`, addendum sections E-F |
| RQ3, hardware early stop | Stop points preset on the PS with the ARM-measured checkpoint latency injected; 24.7-69.6 % of the QPU time saved, 6-27 shots overshoot | `experiments/board/run_stop_campaign.py`, `make_phys_tables.py`; `experiments/rq3_noise_study/bench_early_stop.c` (the checkpoint-latency microbenchmark) | `results/table_stop.csv`, `results/raw_runs_stop.csv`, report section B |

All numbers are n = 5 or more repeats with sample standard deviations; the reports state the timing definition (first
transfer-initiating PS operation to the last readout word in PS memory), the software and image commits of every run, and
the statistical tests used.

## Status of the components (what is and is not implemented)

| Component | Where | Status |
|---|---|---|
| Uplink (readout DDR streaming) | `gateware/`, `software/` | Integrated, measured (`c1` and `c3` modes) |
| Downlink (command streaming, ping-pong command buffers, `circuit_not_ready` detector) | `gateware/`, `software/` | Integrated with the uplink in the C3 image, board-validated, measured. The official QubiC `feat/ddr_mem` branch carries an earlier prototype; the merge request of the integrated version is pending, so the submodules point at the authors' fork |
| Pool-wide envelope/frequency tables (heterogeneous batches without table reloads) | `software/` + `experiments/patches/distributed_processor_elem_cfg_pool.patch` | Implemented in the host toolchain (two-pass assembly); the patch is against `distributed_processor` commit `c22cce8` and will be upstreamed |
| Early termination | `software/scripts/dma_server.c` (policy stream), `experiments/rq3_noise_study/` | The stop mechanism (PS-side stop records, checkpoint bookkeeping, late-stop guard) is implemented and measured. The decision itself is **not** a live host service in this version: stop points are chosen in the simulator study and preset on the PS, and the checkpoint latency of the decision kernel is injected from the ARM microbenchmark. The paper states this |
| Bitstreams | not in git (34 MB `.bit`, 19 MB `.xsa`) | Built from the pinned gateware commits; available from the authors on request or as a release asset |

## Reproducing

**Simulator study (no hardware).** Environment: Python 3.11+, `qiskit 2.3.1`, `qiskit-aer 0.17.2`, `qiskit-ibm-runtime 0.46.1`
(fake backends), `numpy`. From `experiments/rq3_noise_study/`:

```bash
BACKEND=FakeAlgiers SEEDS=0-19 python rq3_stats.py      # one backend; run_rq3_stats.sh runs all six in parallel
python make_rq3_tables.py                                # -> results/table_rq3_cells_v2.csv and the paper's table in multi-seed form
python rq3_adequacy_gate.py                              # the sampling-adequacy gate of addendum section E.4
```

**Hardware measurements.** A ZCU216 running the pinned image with the three PS servers from `software/scripts/` (build and
service notes in the software submodule), the QubiC host environment with `software/` on `PYTHONPATH`, `distributed_processor`
at `c22cce8` with `experiments/patches/distributed_processor_elem_cfg_pool.patch` applied, and the gateware build directory
of the image (`bram.json`, `dspregs.json`, `gensrc/channel_config.json`). The runner is the single entry point:

```bash
cd experiments/board
python antq_runner.py --real --mode c3 --bits <build dir> --gw <build dir> --num-ch 14 --what single --idx 1,2,3 --repeats 5 --tag mytest
python antq_runner.py --real --mode c3 --bits <build dir> --gw <build dir> --num-ch 14 --what batch --batches rand30_t4 --pool-tables --repeats 5 --tag mytest
python antq_runner.py --phys --mode c3 --bits <build dir> --gw <build dir> --num-ch 14 --what single --idx 5 --pool-tables --repeats 3 --tag mytest
```

Rows are appended to `results/raw_runs*.csv`; the `make_*` scripts rebuild the tables from the rows. The campaign drivers in
`experiments/board/` are the exact sequences that produced the published rows (see `experiments/README.md`).

## Hardware platform

- AMD Xilinx ZCU216 RFSoC evaluation board (Zynq UltraScale+, quad-core ARM Cortex-A53 PS + PL), 4 GB PL-DDR
- DSP cores at 500 MHz; DDR data paths at 333 MHz; 14 drive / 14 readout channels (up to 14 qubits per board)
- Timing metrology: Tektronix MSO71254C on a drive DAC output

Upstream project: [QubiC](https://gitlab.com/LBL-QubiC), an open-source FPGA-based qubit control system developed at Lawrence
Berkeley National Laboratory.

## Acknowledgements

This work is supported by a collaboration between the US DOE and the National Science Foundation (NSF). This material is based
upon work supported by the U.S. Department of Energy, Office of Science, National Quantum Information Science Research Centers,
Quantum Systems Accelerator (Award No. DE-SCL0000121). Additional support is acknowledged from the NSF Safe-OSE program
(Award No. 2533222).
