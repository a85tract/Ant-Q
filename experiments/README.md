# experiments/ -- measurement and analysis code

Two independent parts: `board/` needs the ZCU216 with the pinned image and servers; `rq3_noise_study/` runs on any
machine with Qiskit. Every script reads and writes `<repo>/results/` (the directory next to `experiments/`; the board scripts
accept `ANTQ_RESULTS` to redirect). Re-runs of the first-study scripts (`run_noise_exp.py`, `run_early_stop.py`) write to
`<repo>/results/rq3_v0/` so that the archived outputs in `results/rq3_v0_archive/` stay untouched.

## board/ -- hardware measurements

| File | Purpose |
|---|---|
| `antq_runner.py` | The single measurement entry point. Compiles a benchmark circuit (`--real`), a physics experiment (`--phys`) or a readout-simulation surrogate, runs it through one of three paths -- `std` (stock QubiC RPC), `c1` (uplink only), `c3` (downlink + uplink) -- and appends one row per attempt to `results/raw_runs.csv` (`raw_runs_phys.csv` for `--phys`, `raw_runs_stop.csv` for early-stop pairs, `raw_runs_decomp.csv` with `--decomp`). Records the PS timestamps that define the interval, the `circuit_not_ready` flag of every hardware group, image and software commits. |
| `phys_split.py` | Cuts the unrolled RB bodies of experiments (5) and (6) into <= 2046-pulse segments at gate boundaries, carries the drive phase across segments and verifies by compile-and-diff that the segments reproduce the unbroken program. |
| `run_pool_campaign.py` | Table 4 campaign: the 32 heterogeneous batch manifests x {std, c1, c3, c3 with pool tables}, block-randomized, warm-up + 5 repeats per cell, image switching and service restarts. |
| `run_stop_campaign.py` | Early-stop pairs (full run / preset stop at the simulator's checkpoint) on the C3 image, with the dma_server poll interval as a parameter. |
| `run_phys_campaign.py` | The six physics experiments on c3 / c1 / std, including the calibration series used to fit the realized loop period. |
| `run_decomp.sh` | Single-circuit fixed-cost decomposition (batch_server protocol v7 stage timestamps). |
| `run_*.sh`, `run_after_*.sh`, `run_c*_campaign.sh`, `run_phase2_*.sh`, `run_c*_batches_resilient.sh` | The exact driver sequences of the earlier campaigns and diagnostics (unit-floor root cause, prefill / start-threshold diagnostics). They hard-code the authors' gateware build directories and software checkout; kept as the record of what was run, not as portable tools. |
| `deploy_servers.sh` | Pushes the three PS servers to the board and restarts the QubiC service. |
| `pool_preflight.py`, `pool_smoke_test.py`, `make_pool_tables.py` | Pool-wide table checks (group compatibility of the 32 manifests, remapped-pulse byte verification, abs-IQ-histogram equivalence) and the Table 4 tables with block-level confidence intervals. |
| `make_tables.py`, `make_phys_tables.py`, `make_decomp_table.py`, `make_sequences.py`, `calib_feasibility.py`, `build_real_vs_surrogate.py`, `nonmatching_mechanism.py`, `c1_slope.py`, `c1_slope_real.py` | Table builders and the analyses referenced in the reports (realized shot length by the slope method, surrogate-vs-real equivalence, the std-mode mechanism model). |
| `scope_cadence.py` | Oscilloscope cadence metrology: capture loop (Tektronix MSO71254C, SCPI over TCP) and the gap-segmented shot-period analysis. |
| `data/benchmark_results_20.json` | Per-circuit shots and compiled per-shot durations used by the surrogate mode. |

Environment variables read by the scripts (all optional, defaults are the authors' paths):

| Variable | Meaning |
|---|---|
| `ANTQ_RESULTS` | results directory (default `<repo>/results`) |
| `ANTQ_BENCH_DIR` | benchmark directory (default `<repo>/benchmark`) |
| `ANTQ_BENCH_JSON` | the surrogate-mode JSON (default `board/data/benchmark_results_20.json`) |
| `ANTQ_GW_C1`, `ANTQ_GW_C3` | gateware build directories of the two images (campaign drivers) |
| `SOFTWARE_C3` | the software checkout put on `PYTHONPATH` (default the authors' worktree; use `<repo>/software`) |
| `SCOPE_QUBIT_OFFSET`, `SCOPE_READ_AMP`, `SCOPE_READ_FREQ`, `SCOPE_DRIVE_FREQ` | oscilloscope-metrology knobs of the runner (move a physics program to another qubit, change pulse amplitude or carrier; none of them changes the schedule) |

Host environment used for every published row: the QubiC host software of the `software/` submodule, `distributed_processor`
at commit `c22cce8` with `patches/distributed_processor_elem_cfg_pool.patch` applied, `qubitconfig` from the QubiC
`experiments/qubitconfig` repository, Python 3.12 (conda environment `qubic_clean`).

## rq3_noise_study/ -- the simulator study (no hardware)

| File | Purpose |
|---|---|
| `run_noise_exp.py`, `run_early_stop.py` | The first study (single seed, one backend per run): readability grades and the early-stop checkpoints. Their outputs as archived are in `results/rq3_v0_archive/`. |
| `rq3_stats.py`, `run_rq3_stats.sh` | The multi-seed study: 20 circuits x 6 fake backends x seeds 0-19, paper rule and the archived TVD-only rule side by side, ground-truth grade per seed, false/missed-stop accounting. `CIRCUITS=v1` or `v2`, `REF=sample` or `exact` (see `rq3_common.py`). |
| `make_rq3_tables.py` | Per-cell counts, stop checkpoints and the paper's table in multi-seed form (`results/table_rq3_cells*.csv`). |
| `rq3_adequacy_gate.py` | Sampling-adequacy gate: noiseless replicate pairs per checkpoint; a circuit is evaluable only where the noiseless null stays inside PASS. |
| `rq3_ideal_stats.py`, `rq3_sampling_floor.py`, `rq3_xeb_probe.py` | Exact ideal-distribution statistics (entropy, collision ratio), the noiseless TVD/HF floor, and the exact-probability fidelity probe used in the addendum. |
| `metrics.py`, `circuits.py` | TVD / Hellinger fidelity / grading; `circuits.py` is an import shim onto `benchmark/circuits_qiskit.py` for the first-study scripts. |
| `bench_early_stop.c`, `bench_early_stop_results*.csv` | Microbenchmark of the checkpoint decision kernel on x86 and on the ZCU216 ARM cores; the ARM latencies are the ones injected in the hardware early-stop runs. |

## patches/

`distributed_processor_elem_cfg_pool.patch` -- adds an optional `elem_cfg_pool` argument to `GlobalAssembler` so that
several programs are assembled against one shared envelope/frequency table layout (the pool-wide tables of Table 4).
Applies to `distributed_processor` commit `c22cce8`.
