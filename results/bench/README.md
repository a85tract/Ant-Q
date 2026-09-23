# results/bench/ -- bench experiments

Raw data of every bench experiment in the paper. The ZCU216 has no quantum device attached: the DSP cores execute the
compiled programs and the readout channels acquire the board's own signals. No derived tables are stored; the scripts in
`experiments/` rebuild every derived quantity.

| Experiment | Files | Image (`benchmark/bitstreams/`) | Produced by |
|---|---|---|---|
| Single circuits, 30-circuit batches with and without pooled tables, the six physics experiments with their calibration series, oscilloscope cadence, fixed-cost decomposition, early stop (steps A1-A7, 2026-09-20; the `std` and `c1` single circuits, step A3b, 2026-09-23) | `raw_runs*.csv`, `cnr_log.csv`, `scope_cadence/raw/*.npz`, the workload definitions | `zcu216_14_2_c3_13b440c3` (`c3` rows), `zcu216_14_2_c1_0071783e` (`std` and `c1` rows) | `experiments/board/recampaign_run.sh` |
| Realized shot length of the 20 circuits on the baseline image (step A3r, 2026-09-24) | `per_shot_realized_raw.csv`, `per_shot_realized_real.csv` | `zcu216_14_2_c1_0071783e` | `experiments/board/c1_slope_real.py` (`recampaign_run.sh` step A3r) |
| Command-buffer handover time (2026-09-19) | `handover_scope/*.npz` | `zcu216_14_2_c3_13b440c3` | `experiments/device_x6y3/handover_scope.py` (`recampaign_accept.sh` step 3) |
| Batch-completion stress (2026-09-19) | `stress/stress_K3.csv`, `stress/stress_K1.csv` | `zcu216_14_2_c3_13b440c3` | `experiments/board/acceptance/ce_stress.py` (`recampaign_accept.sh` step 2) |
| Command-refill condition (2026-09-19) | `refill/refill_sweep_13b440c3.csv`, `refill/refill_sweep_c26942c0.csv` | `zcu216_14_2_c3_13b440c3`, `zcu216_8_2_c3_c26942c0` | `experiments/board/acceptance/refill_threshold_sweep.py` |
| Cost of the early-stop checkpoint update on the ZCU216 PS | `early_stop_kernel/bench_early_stop_results_arm.csv` | none (ARM Cortex-A53 of the PS) | `experiments/rq3_noise_study/bench_early_stop.c` |

## Steps A1-A7, A3b and A3r

| File | Contents |
|---|---|
| `raw_runs.csv` | Single-circuit and batch runs of the 20 paper circuits on every path (`mode` = `c3`, `c1`, `std`), with and without pooled tables (`pool_tables`). |
| `raw_runs_phys.csv` | The six physics experiments, their calibration series, and the runs recorded by the oscilloscope captures (tags `scope_*`). |
| `raw_runs_decomp.csv` | Single-circuit runs carrying the batch_server stage timestamps (first DMA done, start written, first circuit id, batch done). |
| `raw_runs_stop.csv` | Early-stop pairs (full run / preset stop), with the stop records. |
| `cnr_log.csv` | Per hardware group: the command-supply witness (`cnr`, `cnr_wait_cycles`) of every c3 run. |
| `scope_cadence/raw/*.npz` | Oscilloscope records of the drive output (int8 samples in `raw`, acquisition settings in `meta`), one per capture. |
| `batch_manifest.csv`, `batch_manifest_provenance.csv` | The 32 batch manifests (circuit order) and how each random manifest was drawn. |
| `pool_sequence.csv`, `stop_sequence.csv`, `calib_sequence.csv` | The pre-generated execution orders the drivers consume (`experiments/board/make_sequences.py` regenerates them byte for byte). |
| `shots_verification.csv` | Shot count of every paper circuit with its literature source. |
| `per_shot_realized_raw.csv` | Every run of the realized-shot-length measurement (step A3r, 2026-09-24, image `zcu216_14_2_c1_0071783e`): circuit, shots (100 or 50100), repeat (`-1` = warm-up), elapsed time on the stock path with DDR readout. |
| `per_shot_realized_real.csv` | Realized shot length of each paper circuit, (interval at 50100 shots - interval at 100 shots) / 50000, mean and s.d. of 3 repeats; `experiments/board/c1_slope_real.py --from-raw` rebuilds it from the raw rows, and the table builders read it. |

Row identification: `tag` names the configuration and round, `workload_id` the circuit index or batch id, `repeat` the
repetition (`-1` = warm-up), `status` whether the run completed. `bitfile` names the gateware build directory,
`software_commit` the host client. Timing: `t_start_ns`/`t_end_ns` are PS timestamps (CLOCK_MONOTONIC) on every path, from the
first command store (`std`, `c1`) or the first command image submitted (`c3`) to the last readout data in PS memory.

Host environment: the host client and the PS servers `dma_server` / `batch_server` of the software commit named in
`software_commit`, the `std` baseline server `experiments/board/std_server.c`, the board service start script
`software/scripts/start_qubic_server.sh` (socket send-buffer limit, `BS_NUM_CH` from the configured bitfile, each PS server
pinned to its own PS core), and one ssh connection per board port.

Tables: `ANTQ_RESULTS=results/bench python experiments/board/make_tables.py` (likewise `make_pool_tables.py`,
`make_phys_tables.py`, `make_decomp_table.py`) writes the derived tables (`table*.csv`, `pool_reliability.csv`) next to the
rows; these paths are git-ignored.

## Command-buffer handover

`handover_scope/hand_13b440c3_<idx>_<k>.npz`: oscilloscope records around the marker pulses of a two-segment program
(idx 700, one handover between the markers) and its unbroken twin (idx 701), 12 records each: `v` = samples, `dt` = sample
interval, `pulses` = detected marker edges. The handover time is the difference of the two marker gaps minus the 10 ns
first-pulse offset of a segment (`experiments/device_x6y3/handover_scope_analyze.py hand_13b440c3 results/bench`). The
programs are idx 700/701 of `experiments/device_x6y3/aqt_programs.py`, compiled with the bench configuration
`benchmark/qubitcfg_14q_gate.json`.

## Batch-completion stress

`stress/stress_K3.csv`, `stress/stress_K1.csv`: one row per batch of the stress test, 3000 back-to-back batches of K = 3 units
and 3000 of K = 1, the channel mask cycling through `fe`, `7f`, `00` (batch index modulo 3).

| Column | Meaning |
|---|---|
| `batch`, `K` | batch index (0-2999) and units per batch |
| `mask` | `fe` / `7f`: only core 0 / core 7 reads, the other channels' command images are masked; `00`: every channel's image |
| `outcome` | `ok`; `exception` = the client lost the dma_server stream, the batch is not evaluable; `wedge` = no batch completion within the 25 s watchdog |
| `seamless` | `1` = no unit boundary of the batch waited more than 8 DSP cycles (16 ns) for its commands (the hardware's CNR flag is clear) |
| `last_boundary_wait_cycles` | wait at the batch's last unit boundary in DSP cycles (2 ns each), given for batches that were not seamless; an earlier boundary may have waited longer |
| `note` | the exception message, or a failed data check (record count, zeros, missing channel) |

The rows of this run were rebuilt from the test's console output (one line per batch), and the rebuilt counts agree with the
test's own running counters at every 100 batches; `ce_stress.py` writes the same rows directly.

## Command refill

One row per batch of `K` single-shot units (`refill_threshold_sweep.py`):

| Column | Meaning |
|---|---|
| `mode` | `full` = every channel's command image; `compact` = one enabled channel, the others masked |
| `prefill` | `all` = every unit staged in DDR before the start; `0` = start after the first unit |
| `D_us` | added duration of each unit, in µs (the sweep variable: a grid, then a bisection) |
| `cnr`, `cnr_wait_cycles`, `cnr_wait_us` | command-supply witness of the gateware: `cnr` = 1 if any unit boundary waited more than 8 DSP cycles (16 ns) for its commands; the wait at the last boundary in cycles and in µs |
| `seamless`, `status`, `elapsed_s`, `error` | run bookkeeping |

## Early-stop checkpoint cost

`bench_early_stop.c` on the PS (`./bench_early_stop > <file>`): the median time of one full checkpoint update (consume
the new shots, update the counts, normalize, TVD and HF against the reference, stop decision) per circuit.

| Column | Meaning |
|---|---|
| `idx`, `name` | circuit (index of `experiments/board/data/benchmark_results_20.json`) |
| `n_qubits`, `n_states` | qubits and outcome count (2^n) |
| `shots_per_checkpoint` | shots added per checkpoint (one tenth of the shot budget) |
| `cp1_us` ... `cp5_us` | median time of the 1st ... 5th checkpoint update, in µs |

`experiments/board/run_stop_campaign.py` injects the mean of a circuit's five values (rounded to 0.01 µs, `CP_US_ARM`) as
the checkpoint cost of the hardware early-stop runs (`--cp-ns`).
