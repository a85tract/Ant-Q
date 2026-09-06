# Ant-Q: Breaking Memory Bottlenecks in Quantum Control Systems

Ant-Q is a memory-hierarchy design for the FPGA-based quantum control system QubiC. It uses the control board's PL-DRAM as
the main memory for circuit commands and readout results and keeps BRAM as a cache with ping-pong buffers, so that circuits
longer than the command buffer and acquisitions longer than the accumulator buffer run with deterministic timing, and
readout results reach the host while the remaining shots are still executing.

> **Breaking Memory Bottlenecks in Quantum Control Systems for More Precise Experiments and Higher Throughput Computing**
> Yicheng Guang, Neel Vora, Yilun Xu, Yueqi Chen, Gang Huang
> *University of Colorado Boulder & Lawrence Berkeley National Laboratory*

This repository is the artifact of the paper: it pins the exact gateware, software and benchmark versions behind every
number in the paper and holds the measurement scripts, the raw data and the analysis reports.

## Repository structure

| Path | What it is | Pinned commit |
|---|---|---|
| [`gateware/`](https://gitlab.com/yguang1/gateware/-/tree/c3-stop-ce) | Submodule: QubiC gateware with the Ant-Q downlink and uplink integrated (the "C3" image, ZCU216, 14 qubits). The measured bitstream was built from exactly this commit (`xsa_commit` 63329aaf, timing closed, WNS 0.000 ns). The uplink-only "C1" image used for the baseline columns is commit 0071783e of the same repository (tag `antq-qst-c1-image-0071783e`). | `63329aaf` (branch `c3-stop-ce`, tag `antq-qst-c3-image-63329aaf`) |
| [`software/`](https://gitlab.com/yguang1/software/-/tree/ddr-stop-c3) | Submodule: QubiC host software plus the Ant-Q PS servers (`scripts/batch_server.c`, `scripts/dma_server.c`, `scripts/std_server.c`) and the batch client (`qubic/rpc_client.py`) | `a1eefb5` (branch `ddr-stop-c3`) |
| [`benchmark/`](https://gitlab.com/yguang1/benchmark_qce) | Submodule: the 20 computing circuits and 6 physics experiments as QubiC pulse-level programs (`circuits_le14.py`, `physic_experiment.py`), the same 20 circuits as Qiskit objects (`circuits_qiskit.py`, used by the noise study) and the 14-qubit configuration. The hardware rows in `results/` were measured with revision `8baf102` of this suite; `dda8d37` changes only the angles of the two 14-qubit template circuits (see "Version provenance") | `dda8d37` |
| [`experiments/`](experiments/README.md) | Measurement and analysis code: `board/` (the runner and campaign drivers that produced every hardware number), `rq3_noise_study/` (the simulator study behind RQ3), `patches/` (one small patch to the QubiC assembler) | this repository |
| [`results/`](results/README.md) | Every measured row, the derived tables, the campaign logs and the analysis reports | this repository |

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/a85tract/Ant-Q.git
```

## What was measured, and what was not

All hardware numbers come from a ZCU216 control board **without a quantum device attached**: the DSP cores execute the
real compiled programs (the paper's circuits with fast-reset branches, real gates and readouts), the readout channels
acquire the board's own signals, and the PS records timestamps. What this validates is execution (every program runs
to completion), data integrity (every run returns exactly the programmed number of IQ words, in order, per channel),
timing (from the first transfer-initiating PS operation to the last readout word in PS memory) and physical output
cadence (drive pulses on an oscilloscope). It does **not** validate the physics results of the six reconstructed
experiments (T2*, 1/f spectrum, charge parity, RB fidelities): their observables were never measured. "QPU time" in the
tables means the compiled duration of the program (shots x compiled shot length), i.e. the time a quantum device would
be busy. "Realized" QPU time uses the shot length measured on the board by the slope method
(`per_shot_realized_real.csv`): the 20 computing circuits, each of whose shots ends with a readout followed by a
conditional-reset branch, run 0.14-0.17 us per shot longer than their compiled duration (the same on every path, so it
cancels in the comparisons); the loop programs of the physics experiments show no such offset -- their fitted loop
period equals the compiled one within a few nanoseconds (`table2_phys.csv`, `loop_overhead_ns`), which the oscilloscope
measurement confirms to its 80 ns resolution.

## What the paper claims and where the evidence is

| Paper item | Claim (revised manuscript) | How it is computed | Where |
|---|---|---|---|
| RQ1, Table "functionality" | All six reconstructed experiments execute on the integrated image with the programmed number of readouts returned; (3) 50000 x 2 ms Ramsey and (4) the 6 us trace need the uplink (more than 1024 shots with deterministic timing), (5) 5101-Clifford 1Q RB and (6) 500-Clifford 2Q RB need the downlink and run as sub-circuit streams (5 and 3 segments cut at gate boundaries, replayed from DDR) with `circuit_not_ready` = 0 at every one of the 5119 and 14999 buffer boundaries | `run_phys_campaign.py`; loop periods fitted from 9-point calibration series (`P_meas` vs `P_compiled`, table columns `loop_overhead_ns`, `loop_overhead_ci95_ns`) | `results/table2_phys.csv` (one row per configuration x experiment), rows in `results/raw_runs_phys.csv`, report `reports/report_20260902.md` section A |
| RQ1, physical cadence | Oscilloscope on the drive output: the measured shot period equals the compiled period within the 80 ns sampling bin -- 8.9320 us over 3 complete 8000-shot runs of the 6 us trace, 2003.6476 us over 10 one-second windows (490-499 shots each) of the 2 ms Ramsey, no missing shot, no interval deviating by more than 132 ns; in the streamed RB every command-buffer handover adds 141 ns (0.706 us per 5-unit shot, constant to within the 80 ns bins over 3 x 1024 shots), and no pulse gap inside the RB bodies exceeded one bin (stall criterion) at any of the 3 x 4096 intra-shot boundaries | `scope_cadence.py analyze` on the per-record pulse timestamps (gap-segmented shots; the timestamps allow every interval and gap statistic to be recomputed, the raw waveforms are not in git) | `results/scope_cadence/cadence_summary.csv`, `results/scope_cadence/ts/`, addendum section G |
| RQ2, batches (Table "speedup") | For the 10 random 30-circuit batches: **G_stack = T_std_pool / T_c3_pool - 1 = +51.1 %** (manifest-mean; block-level 95 % CI over the 5 execution blocks 46.9-55.3 %, the confirmatory estimate), **G_sys = T_std_native / T_c3_pool - 1 = +60.0 %**, uplink alone **T_std_native / T_c1_native - 1 = +40.9 %**; T = mean complete-run latency of a configuration on a manifest (n = 5 runs per manifest x block). Total elapsed-time excess of a c3 batch over its compiled QPU time: 0.62-1.80 % (`delta_pct`, configuration `c3_pool`); this includes the circuits' intrinsic 0.14-0.17 us/shot realized-shot-length excess, so Ant-Q's own share is smaller (see the single-circuit row) | `run_pool_campaign.py` (rows tagged `*_pool1`), `make_pool_tables.py` | `results/table4_pool_summary.csv` rows `k = 30`, estimands `G_stack`, `G_sys`, `G_up_native` (`mean`, `ci95_lo_block`, `ci95_hi_block`); inputs `results/table4_pool.csv` (per manifest x block x configuration); report section C |
| RQ2, single circuits | Fixed cost of a c3 run ~25 us + ~10 us per active core: 26-108 us for 2-8 cores, 172-205 us for 12-14 cores, i.e. below 0.7 % of the realized QPU time for every circuit with >= 1000 shots, 1.0 % at 400 shots, 3.1 % at 128 shots and 11.2 % for the 32-shot GHZ-8; everything else in "elapsed minus compiled QPU" is the 0.15 us/shot realized-shot-length difference, a property of the DSP program shared with the baseline | `run_decomp.sh` (batch_server protocol v7 stage timestamps), `make_decomp_table.py` | `results/table_decomp.csv` (`fixed_realized_us`, `fixed_realized_pct`, stage columns), rows `results/raw_runs_decomp.csv`, addendum section D; the first single-circuit campaign in `results/table3_single.csv` and report `campaign_notes_20260829.md` |
| RQ3, Table "noise study" | Readability of the 20 circuits on six Qiskit fake backends over 20 seeds each: 2400 runs, of which 240 are not runnable (circuit wider than the 5- and 7-qubit backends, `grade = SKIP`) and 2160 are graded on the full noisy sample: 1698 PASS, 345 MARGINAL, 117 FAIL (`grade` column). The stop rule fired in 120 of the 2160: 117 of the 117 FAIL runs (no missed stop), 3 of the 345 MARGINAL runs, 0 of the 1698 PASS runs (no false stop) -- columns `stop_cp_paper`, `stop_correct_paper`. The six circuits with at least one FAIL cell are the paper's table; the adequacy gate is a separate evaluability check, not a filter of this accounting | `run_rq3_stats.sh` (`CIRCUITS=v2 REF=exact`), `make_rq3_tables.py`, `rq3_adequacy_gate.py` | `results/rq3_v2/rq3_<backend>.csv` (one row per circuit x seed), `results/table_rq3_cells_v2.csv` (per cell), `results/rq3_v2/adequacy_gate.csv`, addendum sections E-F |
| RQ3, hardware early stop | Stop points chosen in the simulator study and preset on the PS, checkpoint latency injected from the ARM microbenchmark; 24.7-69.6 % of the QPU time saved on the six stopped circuits, overshoot 6-27 shots, n = 5 pairs each | `run_stop_campaign.py`, `make_phys_tables.py`; `bench_early_stop.c` for the latencies | `results/table_stop.csv`, rows `results/raw_runs_stop.csv`, report section B |

Uncertainty conventions: hardware timing cells are n = 5 (or more) repeats with the sample standard deviation and the
warm-up run excluded; batch gains are paired per-manifest ratios with t confidence intervals over manifests and over the 5
execution blocks; RQ3 cells are counts over 20 seeds; the oscilloscope numbers are limited by the 80 ns sampling bin, not
by repeat scatter. Every report states the definition used for each table.

## Version provenance

| Component | Used for the published rows | Notes |
|---|---|---|
| Gateware C3 image | `63329aaf` (`xsa_commit` on the board, `bitfile` column of the rows) | all `c3` rows |
| Gateware C1 image | `0071783e` | all `std` and `c1` rows |
| Software | `software_commit` column of every row; the final rows use `a1eefb5` and its predecessors on `ddr-stop-c3` (the commit of each fix is named in the reports) | |
| Benchmark | `8baf102` for every hardware row | `dda8d37` re-parameterizes the two 14-qubit templates for the noise study; their instruction counts, pulse counts and compiled durations are unchanged (idx 19: 290 / 178 / 46.416 us, idx 22: 304 / 192 / 50.124 us) and only the pulse-amplitude fields differ, so the hardware rows were not repeated |
| QubiC `distributed_processor` | `c22cce8` + `experiments/patches/distributed_processor_elem_cfg_pool.patch` | the patch adds the shared table pool used for heterogeneous batches |
| Simulator | qiskit 2.3.1, qiskit-aer 0.17.2, qiskit-ibm-runtime 0.46.1 | recorded in every RQ3 row |

## Status of the components (what is and is not implemented)

| Component | Where | Status |
|---|---|---|
| Uplink (readout DDR streaming) | `gateware/`, `software/` | Integrated, measured (`c1` and `c3` modes) |
| Downlink (command streaming, ping-pong command buffers, `circuit_not_ready` detector) | `gateware/`, `software/` | Integrated with the uplink in the C3 image, board-validated, measured. The official QubiC `feat/ddr_mem` branch carries an earlier prototype; the merge request of the integrated version is pending, so the submodules point at the authors' fork |
| Pool-wide envelope/frequency tables (heterogeneous batches without table reloads) | `software/` + `experiments/patches/` | Implemented in the host toolchain (two-pass assembly); the patch is against `distributed_processor` `c22cce8` and will be upstreamed |
| Early termination | `software/scripts/dma_server.c` (policy stream), `experiments/rq3_noise_study/` | The stop mechanism (PS-side stop records, checkpoint bookkeeping, late-stop guard) is implemented and measured. The decision is **not** a live host service in this version: stop points come from the simulator study and are preset on the PS, and the checkpoint latency of the decision kernel is injected from the ARM microbenchmark. The paper states this |
| Bitstreams (34 MB `.bit`, 19 MB `.xsa` per image) | not in git | Not yet published as release assets. Until they are, request them from the corresponding author (contact in the paper); `results/bitstreams.sha256` gives their checksums, sizes and source commits |

## Reproducing

**Simulator study (no hardware).** Environment: Python 3.11+, `qiskit 2.3.1`, `qiskit-aer 0.17.2`, `qiskit-ibm-runtime 0.46.1`
(fake backends), `numpy`. From `experiments/rq3_noise_study/`:

```bash
CIRCUITS=v2 REF=exact ./run_rq3_stats.sh       # the paper's study: 6 backends in parallel, seeds 0-19 -> results/rq3_v2/rq3_<backend>.csv (~15 min)
python make_rq3_tables.py                       # -> results/table_rq3_cells_v2.csv and the paper's table in multi-seed form
python rq3_adequacy_gate.py                     # -> results/rq3_v2/adequacy_gate.csv (which circuits are evaluable at which checkpoint)
BACKEND=FakeAlgiers SEEDS=0-19 python rq3_stats.py   # one backend only (partial run, same settings)
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
