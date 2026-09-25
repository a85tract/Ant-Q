# experiments/ -- measurement and analysis code

Three independent parts: `board/` needs a ZCU216 with one of the pinned images and the PS servers; `device_x6y3/` holds the
programs and analysis of the real-device session; `rq3_noise_study/` runs on any machine with Qiskit. Every analysis and
table builder also runs on the published rows in `results/` without hardware (see the top-level README).

**Site configuration.** No script in this directory contains a host name, network address, credential or absolute path.
Everything machine-specific lives in `board/site_env.sh`, which is not tracked: copy `board/site_env.sh.example`, fill it in,
and source `board/recampaign_env.sh` (it sources `site_env.sh`, checks the required variables and derives the rest).
Privileged commands on the board go through `ANTQ_SUDO` (default `sudo -n`); if your board needs a password, export
`ANTQ_SUDO` for that shell only and never store it in a file.

## board/ -- hardware measurements

| File | Purpose |
|---|---|
| `antq_runner.py` | The single measurement entry point. Compiles a benchmark circuit (`--real`), a physics experiment (`--phys`) or a readout-simulation surrogate, runs it through one of four paths -- `std` (the stock QubiC PS procedure, BRAM command stores + accumulator reads, in C: `std_server.c`), `c1` (that downlink + the Ant-Q uplink), `c3` (Ant-Q downlink + uplink), `rpc` (stock QubiC RPC; the device session's classic path) -- and appends one row per attempt to `$ANTQ_RESULTS/raw_runs.csv` (`raw_runs_phys.csv` for `--phys`, `raw_runs_stop.csv` for early-stop pairs, `raw_runs_decomp.csv` with `--decomp`). Records the PS timestamps that define the interval, the `circuit_not_ready` flag of every hardware group, image and software commits. |
| `phys_split.py` | Cuts the unrolled RB bodies of experiments (5) and (6) into <= 2046-pulse segments at gate boundaries, carries the drive phase across segments and verifies by compile-and-diff that the segments reproduce the unbroken program. |
| `run_pool_campaign.py` | Table 4 campaign: the 32 heterogeneous batch manifests x {std, c1, c3, c3 with pool tables}, block-randomized, warm-up + 5 repeats per cell, image switching and service restarts. |
| `run_stop_campaign.py` | Early-stop pairs (full run / preset stop at the simulator's checkpoint) on the C3 image, with the dma_server poll interval as a parameter; the injected checkpoint cost comes from `results/bench/early_stop_kernel/`. |
| `run_phys_campaign.py` | The six physics experiments on c3 / c1 / std, including the calibration series used to fit the realized loop period. Experiments (5) and (6) run as sub-circuit streams with pooled tables and prefill 16: a drive-only segment carries empty readout tables, which the client's table-grouping predicate treats as a conflict with the final segment's tables; the pool gives every segment identical tables so the stream runs as one hardware group. |
| `run_decomp.sh` | Single-circuit fixed-cost decomposition (batch_server protocol v7 stage timestamps). |
| `recampaign_env.sh`, `recampaign_env_markers.sh` | Campaign environment: sources `site_env.sh`, resolves the image's build directory, opens one ssh forward per board port; the markers variant adds the device program module for the handover measurement and the device session. |
| `recampaign_accept.sh` | Image preparation and the acceptance measurements of the paper (steps 0-3): seed the results directory with the workload definitions, deploy the bits slot, switch and verify the image, the batch-completion stress test (`stress/`), the command-buffer handover measurement (`handover_scope/`). |
| `recampaign_run.sh` | The campaign step sequence A1-A7 with A3b (the `std` and `c1` single circuits) and A3r (the realized shot length), both on the baseline image, then the tables (step T); an optional stop step ends the run after that step. |
| `recampaign_check.py` | Row-coverage check after each campaign step. |
| `acceptance/` | `ce_stress.py`: the batch-completion stress test (`results/bench/stress/`); `refill_threshold_sweep.py`: the command-refill condition sweep (`results/bench/refill/`); `integ_test_lib.py`: their shared helpers. |
| `std_server.c`, `std_client.py` | The stock QubiC PS path (BRAM command load + accumulator readback) re-implemented in C, with its host client: the `std` baseline of every timing table, so that the baseline pays no Python interpreter cost per MMIO word. Measurement instruments, not QubiC features. |
| `deploy_servers.sh`, `deploy_slot_board.sh`, `switch_board_image.sh` | Push the PS servers (`dma_server.c`, `batch_server.c` from the software submodule, `std_server.c` from here) and a gateware build's bits slot to the board named in `site_env.sh`, and switch the board's image with a check of the loaded bitfile. |
| `pool_preflight.py` | Host-only pool checks: group compatibility of the 32 manifests, remapped-pulse byte verification of pooled against native assembly. |
| `make_tables.py`, `make_pool_tables.py`, `make_phys_tables.py`, `make_decomp_table.py` | Table builders: they read the rows in `$ANTQ_RESULTS` and write `table*.csv` next to them. |
| `make_stop_figure.py` | The paper's early-stop figure from `table_stop.csv` (run `make_phys_tables.py` first): preset stop point and shots actually executed per circuit. |
| `make_sequences.py` | Regenerates the pre-generated execution orders (`pool_sequence.csv`, `stop_sequence.csv`, `calib_sequence.csv`, `batch_manifest_provenance.csv`) from their seeds. |
| `c1_slope_real.py` | Realized shot length of each paper circuit on the baseline image by the slope method: every run to `per_shot_realized_raw.csv`, the per-circuit table to `per_shot_realized_real.csv`; `--from-raw` rebuilds the table without hardware. |
| `scope_cadence.py`, `scope_cadence_runs.py` | Oscilloscope cadence metrology: capture loop (Tektronix MSO71254C, SCPI over TCP) and the gap-segmented shot-period analysis; per-run analysis of records that hold more than one program run. |
| `data/benchmark_results_20.json` | Per-circuit shots and compiled per-shot durations used by the surrogate mode. |
| `site_env.sh.example` | Template of the site configuration. |

Variables the scripts read (set by `site_env.sh` unless noted):

| Variable | Meaning |
|---|---|
| `ANTQ_PY`, `ANTQ_SOFTWARE` | host interpreter and the client checkout put on `PYTHONPATH` |
| `ANTQ_BOARD_SSH`, `ANTQ_BOARD_LAN`, `ANTQ_JUMP_SSH`, `ANTQ_TUNNEL_IP` | how to reach the board (ssh destination, its lab address, an optional jump host, the loopback the per-port forwards bind to) |
| `ANTQ_BOARD`, `ANTQ_RPC_PORT` | address and port of the qubic RPC server as seen by the host (derived by `recampaign_env.sh`) |
| `ANTQ_BOARD_SW`, `ANTQ_BOARD_CFG`, `ANTQ_SUDO` | the board's software tree, its server config, the privileged-command prefix |
| `ANTQ_REGDUMP_SCRIPT` | optional register-dump script run on the board when a stress batch wedges (`ce_stress.py`) |
| `ANTQ_GW_ROOT`, `ANTQ_GW_C3_GLOB`, `ANTQ_GW_C1` | where the gateware builds live; the campaign resolves `ANTQ_GW_C3` from `ANTQ_IMG` |
| `ANTQ_IMG`, `ANTQ_WNS_C3` | per run: the image slot under test and its sign-off WNS, recorded in every row; `ANTQ_XSA_C3` = `ANTQ_IMG` (derived) |
| `ANTQ_RESULTS_ROOT`, `ANTQ_RESULTS` | where result directories are created; `ANTQ_RESULTS` pins one |
| `ANTQ_TESTS_DIR`, `ANTQ_SEQ_DIR` | the acceptance tests (default `board/acceptance`); the workload definitions seeded into a new results directory (default `results/bench`) |
| `ANTQ_BENCH_DIR`, `ANTQ_BENCH_JSON` | benchmark directory (default `<repo>/benchmark`); the surrogate-mode JSON (default `board/data/benchmark_results_20.json`) |
| `ANTQ_PHYS_MODULE`, `ANTQ_QCHIP`, `ANTQ_QCHIP_PATCH` | an alternative physics-program module (the device programs); a device's chip configuration and calibrated pulse export (unset: `benchmark/qubitcfg_14q_gate.json`) |
| `ANTQ_WORKDIR` | working directory of the runner processes that `handover_scope.py` starts |
| `SCOPE_HOST`, `SCOPE_PORT` | the oscilloscope's SCPI socket (cadence and handover steps only) |
| `SCOPE_QUBIT_OFFSET`, `SCOPE_READ_AMP`, `SCOPE_READ_FREQ`, `SCOPE_DRIVE_FREQ` | oscilloscope-metrology knobs of the runner (move a physics program to another qubit, change pulse amplitude or carrier; none of them changes the schedule) |

Host environment of the published rows: the host client and the PS servers `dma_server` / `batch_server` of the software
commit named in each row's `software_commit`, the `std` baseline server `board/std_server.c` of this repository,
`distributed_processor` at the official QubiC commit `0653425` (branch `feat/ddr_mem`), `qubitconfig`
25.5.0 from the QubiC `qubitconfig` repository, Python 3.12.

## device_x6y3/ -- the real-device session

| File | Purpose |
|---|---|
| `aqt_programs.py` | The device program module in the `physic_experiment` format: readout-classifier preparations, the phase fringe, the fixed-cadence timing loop, the paired Ramsey plus its slope calibration, Clifford randomized benchmarking (the 24-element group generated and decomposed on the pi/2 grid), the streamed, unbroken and idling (UD) boundary programs and the handover marker programs. Loaded through the runner with `ANTQ_PHYS_MODULE`. |
| `PREREGISTRATION.md` | What was fixed in writing before the device session: the programs and their analysis, the equivalence margins with the two-pass decision rule, the declaration for the reported blocks, and where the reported analysis departs from them. |
| `pulses_q5_20260917.json` | The calibrated pulse export of the measured qubit (X90 envelope, readout drive and demodulation, frequencies, T1/T2*) as patched into the chip configuration by `patch_qchip`. |
| `export_qcal_pulses.py` | Produces such a file from a calibration configuration directory; run with the operator's environment. |
| `analyze_block.py`, `compare_blocks.py`, `summarize_abab.py` | Per-block estimators of the two-command-path comparison (classifier, fringe fit, cadence, Ramsey pair statistics, RB decay), the comparison of two blocks against the pre-registered margins, and the four-block summary with its figure. |
| `ramsey_noise_spectrum.py` | The pre-registered noise analysis of the paired Ramsey records: per-record spectra with a Whittle fit of a 1/f term plus white noise, the Monte-Carlo-calibrated upper bound on the 1/f level, the test for lines at the stock run rate, the excess-variance bound on noise slower than one pair, and the paper's noise-spectrum figure. |
| `noise_mc_uncertainty.py` | Monte Carlo intervals of the detection levels, their spectral-density ratio and the upper limits of `ramsey_noise_spectrum.py`, from binomial resampling of its stored simulated rates. |
| `boundary_analysis.py` | Fringe and RB analysis of the streamed (S) and unbroken (U) boundary programs and of the unbroken programs with a 152-ns idle at the cut (UD), the control for the time a handover adds. |
| `deep_rb_analysis.py` | RB to 5101 Cliffords on both command paths: survival per length, the joint fit over the shared lengths, the execution flags of every program. |
| `make_device_figure.py` | The paper's device figure from the outputs of `deep_rb_analysis.py` and `boundary_analysis.py`: RB survival on both command paths with the Ant-Q-only lengths marked, and the boundary fringe. |
| `handover_scope.py`, `handover_scope_analyze.py` | Direct oscilloscope measurement of the command-buffer handover from marker-pulse gaps. |
| `fringe_phase_words.py` | Host-only check: compiles the same program through both command paths and decodes the pulse phase words, so a frame difference between the paths would be visible without a board. |

The device chip configuration (`ANTQ_QCHIP`) is the operator's calibration of their device and is not part of this
repository; supply your own. `results/device_x6y3/` holds the rows and per-run IQ of the session.

## sim_handover/ -- cycle-level simulation of the command-buffer handover

A cocotb/Verilator model of the board top with the QubiC DSP core and the Ant-Q command path; its two tests count the cycles of a
command-buffer handover and of the DSP core's gap between two shots. Contents and run command: `sim_handover/README.md`;
output: `results/sim_handover/`.

## rq3_noise_study/ -- the simulator study (no hardware)

| File | Purpose |
|---|---|
| `rq3_stats.py`, `run_rq3_stats.sh` | The multi-seed study: 20 circuits x 6 fake backends x seeds 0-19, paper rule and the archived TVD-only rule side by side, ground-truth grade per seed, false/missed-stop accounting. `CIRCUITS=v1` or `v2`, `REF=sample` or `exact` (see `rq3_common.py`). |
| `rq3_extended.py` | Stop rates per ground-truth grade with Clopper-Pearson bounds for seeds 0-19 and 20-119 (`SEEDS=20-119 SUFFIX=_s20-119` run of `rq3_stats.py`), the stop decisions under 27 settings of the rule's thresholds, and the board time saved at the simulated stop checkpoints of the six board circuits (per-shot time and stop latency from `results/bench/table_stop.csv`). |
| `make_rq3_tables.py` | Per-cell counts, stop checkpoints and the paper's table in multi-seed form. |
| `rq3_adequacy_gate.py` | Sampling-adequacy gate: noiseless replicate pairs per checkpoint; a circuit is evaluable only where the noiseless null stays inside PASS. |
| `rq3_common.py` | The study's switches (`CIRCUITS`, `REF`) and output directory. |
| `run_early_stop.py` | The first study's early-stop code; `rq3_stats.py` imports its backend map, checkpoint schedule and thresholds. |
| `metrics.py`, `circuits.py` | TVD / Hellinger fidelity / grading; `circuits.py` is an import shim onto `benchmark/circuits_qiskit.py` for `run_early_stop.py`. |
| `bench_early_stop.c` | Microbenchmark of the checkpoint update, run on the ZCU216 ARM cores; its output is in `results/bench/early_stop_kernel/`. |
