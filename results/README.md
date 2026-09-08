# results/ -- measured data, derived tables, reports

Start with the reports; every table below is referenced from them with the statistics behind each number.

## Reports (`reports/`)

| File | Contents |
|---|---|
| `report_20260902.md` | The three integrated-image campaigns: C. heterogeneous batches with pool-wide tables (Table 4), B. early stop on the C3 image, A. the six physics experiments incl. the sub-circuit streams, the unit-floor root cause and the start-up stall fix. |
| `report_20260903_addendum.md` | D. single-circuit fixed-cost decomposition, E. RQ3 multi-seed statistics and the undersampling finding, F. RQ3 with the re-parameterized templates and the exact reference (the version the paper uses), G. oscilloscope cadence metrology. |
| `README_20260901_addendum.md` | Method notes for the pool-table, early-stop and physics campaigns (definitions, sequences, statistics). |
| `campaign_notes_20260829.md` | The first re-measurement campaign (real command streams, closed-timing image, surrogate-vs-real equivalence, the E2 finding). |
| `unit_floor_rootcause_20260902.md` | Workflow record of the 64 us unit-floor diagnosis (PS `usleep` on the non-RT kernel). |

## Raw rows (never deleted; `status` marks ok / timeout / data_mismatch / capacity; warm-up runs have `repeat = -1`)

| File | One row per |
|---|---|
| `raw_runs.csv` | single-circuit and batch attempt (all modes, all campaigns; 32 columns incl. PS timestamps, image, software commit, `circuit_not_ready`) |
| `raw_runs_phys.csv` | physics-experiment attempt (loop count, compiled period, segments, units) |
| `raw_runs_stop.csv` | early-stop pair member (stop point, checkpoint step, emulated delay, stop record, overshoot, latency) |
| `raw_runs_decomp.csv` | fixed-cost decomposition run (batch_server v7 stage timestamps) |
| `cnr_log.csv` | c3 run x hardware group: `circuit_not_ready` flag and wait counter |

## Derived tables

| File | Paper item |
|---|---|
| `table2_phys.csv` | Table "functionality": per config x experiment, status, measured vs compiled loop period with CI, `circuit_not_ready`, segments |
| `table3_single.csv` | Table "speedup", single circuits: n, mean, s.d., QPU time, overhead (first campaign) |
| `table4_batch.csv`, `table4_pool.csv`, `table4_pool_summary.csv` | Table "speedup", batches: per manifest x config, block-level confidence intervals, throughput gains (`table4_pool*` = the pool-table campaign the paper uses) |
| `table_decomp.csv` | Fixed cost per circuit and stage (addendum D) |
| `table_stop.csv` | Early-stop pairs: time saved, overshoot, latency (report B) |
| `table_rq3_cells_v2.csv`, `table_rq3_cells.csv` | RQ3 per circuit x backend over 20 seeds: grades, stops, false/missed stops (v2 = the paper; v1 = the first parameter set) |
| `per_shot_realized_real.csv`, `per_shot_c1_slope.csv`, `per_shot_realized.csv` | Realized shot length of every program (slope method). Denominator of the realized-time columns (`*_delta_real_ms`, `*_delta_real_pct` in `table3_single.csv`; `fixed_realized_*` in `table_decomp.csv`). The `delta_pct` columns of `table4_pool*.csv` / `table4_batch.csv` and `*_delta_pct` of `table3_single.csv` are relative to the compiled QPU time (`qpu_ms`) |
| `real_vs_surrogate.csv`, `nonmatching_mechanism.csv` | Surrogate-vs-real equivalence cells and the std-mode mechanism model (first campaign) |
| `shots_verification.csv` | The 20 circuits' shot counts with source provenance |
| `batch_manifest.csv`, `batch_manifest_provenance.csv` | The 32 immutable batch manifests (seed 42) and their per-circuit provenance |
| `pool_sequence.csv`, `stop_sequence.csv`, `calib_sequence.csv`, `smoke_sequence.csv` | The block-randomized run orders of the campaigns |
| `calib_feasibility.csv`, `pool_reliability.csv`, `smoke_test.csv`, `smoke_test.json`, `ghz8_fill_sweep.csv` | Calibration-series feasibility, pool-campaign attempt statistics, the abs-IQ-histogram smoke test, the GHZ-8 fill-latency sweep |

## Sub-directories

| Directory | Contents |
|---|---|
| `rq3_v2/` | RQ3 multi-seed study as used in the paper: `rq3_<backend>.csv` (one row per circuit x seed), `*_checkpoints.csv` (TVD/HF at every checkpoint), `adequacy_gate.csv`, `ideal_distribution_stats.csv`, `angles_v2.json` (the template parameters), logs |
| `rq3/` | The same study with the first parameter set and the sampled reference (the version that exposed the undersampling problem; addendum E) plus `sampling_floor.csv` |
| `rq3_v0_archive/` | The first single-seed study's outputs (`noise_results.csv`, `early_stop_*.csv`, `stop_experiment.csv`, report); re-runs of those scripts write to `rq3_v0/` |
| `scope_cadence/` | Oscilloscope metrology: `cadence_summary.csv` (one row per record), `ts/` (pulse-start timestamps of every record, microseconds), `campaign.log`. The raw waveform records (94 files, 74 MB) are not in git; available from the authors |
| `pool_tables/` | Identity of the pool-wide tables: `sha256.json` of the binaries, `preflight_report.json`; the binaries are regenerated by `experiments/board/make_pool_tables.py` / `pool_preflight.py` |
| `logs/` | Runner and campaign logs as written during the campaigns |

`bitstreams.sha256` lists the two measured bitstreams (C3 image 63329aaf, C1 image 0071783e; `.bit` and `.xsa`) with sizes and checksums. The files themselves are published in the benchmark submodule, `benchmark/bitstreams/`, together with each image's register/channel description files.
